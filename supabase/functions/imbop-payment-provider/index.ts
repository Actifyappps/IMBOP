import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Content-Type": "application/json",
};
const json = (body: unknown, status = 200) => new Response(JSON.stringify(body), { status, headers: cors });
const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const anonKey = Deno.env.get("SUPABASE_ANON_KEY") || serviceKey;
const service = createClient(supabaseUrl, serviceKey, { auth: { persistSession: false } });

function normalizeKenyanPhone(value: string) {
  const digits = String(value || "").replace(/\D/g, "");
  if (digits.startsWith("254") && digits.length === 12) return digits;
  if (digits.startsWith("0") && digits.length === 10) return "254" + digits.slice(1);
  if (digits.startsWith("7") && digits.length === 9) return "254" + digits;
  if (digits.startsWith("1") && digits.length === 9) return "254" + digits;
  throw new Error("INVALID_KENYAN_MOBILE_NUMBER");
}
function mpesaBaseUrl() { return Deno.env.get("MPESA_BASE_URL") || "https://sandbox.safaricom.co.ke"; }

async function mpesaToken() {
  const key = Deno.env.get("MPESA_CONSUMER_KEY");
  const secret = Deno.env.get("MPESA_CONSUMER_SECRET");
  if (!key || !secret) throw new Error("MPESA_PROVIDER_NOT_CONFIGURED");
  const basic = btoa(key + ":" + secret);
  const res = await fetch(mpesaBaseUrl() + "/oauth/v1/generate?grant_type=client_credentials", {
    headers: { Authorization: "Basic " + basic },
  });
  if (!res.ok) throw new Error("MPESA_AUTH_FAILED_" + res.status);
  const data = await res.json();
  if (!data.access_token) throw new Error("MPESA_ACCESS_TOKEN_MISSING");
  return data.access_token as string;
}

async function mpesaStkPush(intent: any, phone: string) {
  const shortcode = Deno.env.get("MPESA_SHORTCODE");
  const passkey = Deno.env.get("MPESA_PASSKEY");
  const callbackUrl = Deno.env.get("MPESA_CALLBACK_URL");
  if (!shortcode || !passkey || !callbackUrl) throw new Error("MPESA_PROVIDER_NOT_CONFIGURED");
  const token = await mpesaToken();
  const timestamp = new Date().toISOString().replace(/[-:TZ.]/g, "").slice(0, 14);
  const password = btoa(shortcode + passkey + timestamp);
  const payload = {
    BusinessShortCode: shortcode,
    Password: password,
    Timestamp: timestamp,
    TransactionType: Deno.env.get("MPESA_TRANSACTION_TYPE") || "CustomerPayBillOnline",
    Amount: Math.round(Number(intent.amount_kes)),
    PartyA: phone,
    PartyB: shortcode,
    PhoneNumber: phone,
    CallBackURL: callbackUrl,
    AccountReference: intent.invoice_id ? "IMBOP-" + String(intent.invoice_id).slice(0, 8) : "IMBOP-" + String(intent.id).slice(0, 8),
    TransactionDesc: "IMBOP billing payment " + intent.id,
  };
  const res = await fetch(mpesaBaseUrl() + "/mpesa/stkpush/v1/processrequest", {
    method: "POST",
    headers: { Authorization: "Bearer " + token, "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  });
  const data = await res.json();
  if (!res.ok || data.ResponseCode !== "0") throw new Error(data.errorMessage || data.ResponseDescription || "MPESA_STK_PUSH_FAILED");
  return data;
}

async function getUser(req: Request) {
  const auth = req.headers.get("Authorization") || "";
  if (!auth.startsWith("Bearer ")) throw new Error("AUTH_REQUIRED");
  const client = createClient(supabaseUrl, anonKey, { global: { headers: { Authorization: auth } }, auth: { persistSession: false } });
  const { data, error } = await client.auth.getUser();
  if (error || !data.user) throw new Error("AUTH_REQUIRED");
  return { client, user: data.user };
}

async function start(req: Request, body: any) {
  const { client } = await getUser(req);
  const method = String(body.payment_method || "").toUpperCase();
  if (!["MPESA", "AIRTEL_MONEY", "BANK_TRANSFER", "CARD"].includes(method)) throw new Error("INVALID_PAYMENT_METHOD");
  const institutionId = body.institution_id;
  const invoiceId = body.invoice_id;
  const amount = Number(body.amount_kes);
  if (!institutionId || !invoiceId || !Number.isFinite(amount) || amount <= 0) throw new Error("INVALID_PAYMENT_REQUEST");

  const { data: intentId, error: intentError } = await client.rpc("create_my_billing_payment_intent", {
    p_institution_id: institutionId,
    p_amount_kes: amount,
    p_payment_method: method,
    p_invoice_id: invoiceId,
    p_provider: method === "MPESA" ? "SAFARICOM_DARAJA" : method === "AIRTEL_MONEY" ? "AIRTEL_MONEY" : null,
    p_expires_at: null,
    p_metadata: { source: "imbop-payment-provider" },
  });
  if (intentError) throw intentError;

  const { data: intent, error: readError } = await service.from("billing_payment_intents").select("*").eq("id", intentId).single();
  if (readError || !intent) throw new Error("PAYMENT_INTENT_NOT_FOUND");

  if (method === "MPESA") {
    const phone = normalizeKenyanPhone(body.phone);
    try {
      const result = await mpesaStkPush(intent, phone);
      const { error } = await service.rpc("platform_set_payment_intent_provider_state", {
        p_payment_intent_id: intent.id,
        p_status: "PENDING",
        p_external_reference: result.MerchantRequestID || null,
        p_checkout_reference: result.CheckoutRequestID || null,
        p_metadata: { phone_last4: phone.slice(-4), response_code: result.ResponseCode || null, response_description: result.ResponseDescription || null },
      });
      if (error) throw error;
      return json({ ok: true, payment_intent_id: intent.id, status: "PENDING", provider: "SAFARICOM_DARAJA", checkout_request_id: result.CheckoutRequestID || null, customer_message: result.CustomerMessage || "Check your phone and enter your M-PESA PIN." });
    } catch (e) {
      await service.rpc("platform_fail_payment_intent", { p_payment_intent_id: intent.id, p_status: "FAILED", p_metadata: { error: e instanceof Error ? e.message : String(e) } });
      throw e;
    }
  }

  return json({ ok: true, payment_intent_id: intent.id, status: "CREATED", provider: method === "AIRTEL_MONEY" ? "AIRTEL_MONEY" : method, message: "Payment intent created. Provider checkout is pending provider configuration." });
}

async function mpesaCallback(body: any) {
  const callback = body?.Body?.stkCallback;
  if (!callback?.CheckoutRequestID) throw new Error("INVALID_MPESA_CALLBACK");
  const checkoutId = callback.CheckoutRequestID;
  const resultCode = Number(callback.ResultCode);
  const resultDesc = callback.ResultDesc || "";
  const { data: intent, error } = await service.from("billing_payment_intents").select("*").eq("checkout_reference", checkoutId).single();
  if (error || !intent) return json({ ResultCode: 0, ResultDesc: "Accepted" });

  if (resultCode !== 0) {
    await service.rpc("platform_fail_payment_intent", { p_payment_intent_id: intent.id, p_status: "FAILED", p_metadata: { provider_result_code: resultCode, provider_result_desc: resultDesc } });
    return json({ ResultCode: 0, ResultDesc: "Accepted" });
  }

  const items = Array.isArray(callback.CallbackMetadata?.Item) ? callback.CallbackMetadata.Item : [];
  const getItem = (name: string) => items.find((x: any) => x.Name === name)?.Value;
  const amount = Number(getItem("Amount"));
  const receipt = getItem("MpesaReceiptNumber");
  if (!Number.isFinite(amount) || !receipt) {
    await service.rpc("platform_fail_payment_intent", { p_payment_intent_id: intent.id, p_status: "FAILED", p_metadata: { provider_result_code: resultCode, error: "INCOMPLETE_SUCCESS_CALLBACK" } });
    return json({ ResultCode: 0, ResultDesc: "Accepted" });
  }

  try {
    await service.rpc("platform_finalize_payment_intent_from_provider", {
      p_payment_intent_id: intent.id,
      p_provider: "SAFARICOM_DARAJA",
      p_provider_reference: String(receipt),
      p_amount_kes: amount,
      p_received_at: new Date().toISOString(),
      p_metadata: { checkout_request_id: checkoutId, merchant_request_id: intent.external_reference, result_desc: resultDesc },
    });
  } catch (_) {
    return json({ ResultCode: 0, ResultDesc: "Accepted" });
  }
  return json({ ResultCode: 0, ResultDesc: "Accepted" });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json({ error: "METHOD_NOT_ALLOWED" }, 405);
  try {
    const body = await req.json();
    const op = body.operation || "start";
    if (op === "mpesa_callback") return await mpesaCallback(body);
    if (op === "start") return await start(req, body);
    return json({ error: "UNKNOWN_OPERATION" }, 400);
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    return json({ ok: false, error: message }, message === "AUTH_REQUIRED" ? 401 : 400);
  }
});
