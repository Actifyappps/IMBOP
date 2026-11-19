import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY");
const IMBOP_EMAIL_FROM = Deno.env.get("IMBOP_EMAIL_FROM");

function escapeHtml(value: string) {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

function htmlFromText(value: string) {
  return escapeHtml(value).replaceAll("\n", "<br />");
}

type RpcClient = {
  rpc: (name: string, args: Record<string, unknown>) => Promise<{ data: unknown; error: { message?: string } | null }>;
};

async function rpc(client: RpcClient, name: string, args: Record<string, unknown>) {
  const { data, error } = await client.rpc(name, args);
  if (error) throw new Error(error.message || `RPC ${name} failed`);
  return data;
}

export async function dispatchOne(client: RpcClient, deliveryId?: string) {
  if (!RESEND_API_KEY || !IMBOP_EMAIL_FROM) {
    return { ok: false, status: "EMAIL_PROVIDER_NOT_CONFIGURED" };
  }

  let selectedDeliveryId = deliveryId;
  if (!selectedDeliveryId) {
    const queue = await rpc(client, "get_platform_email_queue", {
      p_status: "QUEUED",
      p_limit: 1,
      p_offset: 0,
    }) as Array<{ delivery_id: string }>;
    selectedDeliveryId = queue?.[0]?.delivery_id;
  }

  if (!selectedDeliveryId) return { ok: true, status: "EMPTY_QUEUE" };

  const claimed = await rpc(client, "claim_platform_email_delivery", {
    p_delivery_id: selectedDeliveryId,
  }) as Array<{
    delivery_id: string;
    recipient_email: string;
    subject: string;
    body: string;
  }>;

  const item = claimed?.[0];
  if (!item) return { ok: true, status: "NOT_CLAIMED", delivery_id: selectedDeliveryId };

  const response = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${RESEND_API_KEY}`,
      "Idempotency-Key": `imbop-email-delivery-${item.delivery_id}`,
    },
    body: JSON.stringify({
      from: IMBOP_EMAIL_FROM,
      to: [item.recipient_email],
      subject: item.subject,
      html: `<div style="font-family:Arial,sans-serif;line-height:1.6;">${htmlFromText(item.body)}</div>`,
      text: item.body,
      tags: [
        { name: "system", value: "imbop" },
        { name: "communication", value: "transactional" },
      ],
    }),
  });

  const providerText = await response.text();
  let providerData: { id?: string; message?: string } | null = null;
  try {
    providerData = providerText ? JSON.parse(providerText) : null;
  } catch {}

  if (!response.ok) {
    await rpc(client, "record_platform_email_delivery_result", {
      p_delivery_id: item.delivery_id,
      p_status: "FAILED",
      p_provider_message_id: providerData?.id ?? null,
      p_failure_reason: providerData?.message ?? providerText.slice(0, 1000),
      p_provider_response: { status: response.status, body: providerData ?? providerText.slice(0, 2000) },
    });
    return {
      ok: false,
      status: "FAILED",
      delivery_id: item.delivery_id,
      provider_status: response.status,
    };
  }

  await rpc(client, "record_platform_email_delivery_result", {
    p_delivery_id: item.delivery_id,
    p_status: "DELIVERED",
    p_provider_message_id: providerData?.id ?? null,
    p_provider_response: { status: response.status, body: providerData ?? providerText.slice(0, 2000) },
  });

  return {
    ok: true,
    status: "DELIVERED",
    delivery_id: item.delivery_id,
    provider_message_id: providerData?.id ?? null,
  };
}

export async function dispatchBatch(client: RpcClient, limit = 10) {
  const results: unknown[] = [];
  const max = Math.max(1, Math.min(limit, 10));

  for (let i = 0; i < max; i += 1) {
    const result = await dispatchOne(client);
    results.push(result);
    if (result.status === "EMPTY_QUEUE" || result.status === "EMAIL_PROVIDER_NOT_CONFIGURED") break;
  }

  return {
    ok: results.every((item) => (item as { ok?: boolean }).ok !== false),
    processed: results.filter((item) => ["DELIVERED", "FAILED"].includes((item as { status?: string }).status || "")).length,
    results,
  };
}
