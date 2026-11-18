import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY");
const IMBOP_EMAIL_FROM = Deno.env.get("IMBOP_EMAIL_FROM");

const corsHeaders = {
  "Access-Control-Allow-Origin": "https://imbop-operations.vercel.app",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json", ...corsHeaders },
  });
}

function escapeHtml(value: string) {
  return value.replaceAll("&","&amp;").replaceAll("<","&lt;").replaceAll(">","&gt;").replaceAll('"',"&quot;").replaceAll("'","&#039;");
}
function htmlFromText(value: string) { return escapeHtml(value).replaceAll("\n","<br />"); }

async function rpc(name: string, args: Record<string, unknown>, authHeader: string) {
  const response = await fetch(`${SUPABASE_URL}/rest/v1/rpc/${name}`, {
    method:"POST",
    headers:{ "Content-Type":"application/json", apikey:Deno.env.get("SUPABASE_ANON_KEY")!, Authorization:authHeader },
    body:JSON.stringify(args),
  });
  const text = await response.text();
  let data: unknown = null;
  try { data = text ? JSON.parse(text) : null; } catch { data = text; }
  if (!response.ok) throw new Error(typeof data === "string" ? data : JSON.stringify(data));
  return data;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { status: 204, headers: corsHeaders });
  }
  if (req.method !== "POST") return json({error:"METHOD_NOT_ALLOWED"},405);
  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) return json({error:"AUTHORIZATION_REQUIRED"},401);
  if (!RESEND_API_KEY || !IMBOP_EMAIL_FROM) {
    return json({error:"EMAIL_PROVIDER_NOT_CONFIGURED",message:"Set RESEND_API_KEY and IMBOP_EMAIL_FROM before enabling external email delivery."},503);
  }

  let payload:{delivery_id?:string}={};
  try { payload=await req.json(); } catch {}

  try {
    let deliveryId=payload.delivery_id;
    if (!deliveryId) {
      const queue=await rpc("get_platform_email_queue",{p_status:"QUEUED",p_limit:1,p_offset:0},authHeader) as Array<{delivery_id:string}>;
      deliveryId=queue?.[0]?.delivery_id;
    }
    if (!deliveryId) return json({ok:true,status:"EMPTY_QUEUE"});

    const claimed=await rpc("claim_platform_email_delivery",{p_delivery_id:deliveryId},authHeader) as Array<{delivery_id:string;recipient_email:string;subject:string;body:string}>;
    const item=claimed?.[0];
    if (!item) return json({ok:true,status:"NOT_CLAIMED",delivery_id:deliveryId});

    const response=await fetch("https://api.resend.com/emails",{
      method:"POST",
      headers:{
        "Content-Type":"application/json",
        "Authorization":`Bearer ${RESEND_API_KEY}`,
        "Idempotency-Key":`imbop-email-delivery-${item.delivery_id}`,
      },
      body:JSON.stringify({
        from:IMBOP_EMAIL_FROM,
        to:[item.recipient_email],
        subject:item.subject,
        html:`<div style="font-family:Arial,sans-serif;line-height:1.6;">${htmlFromText(item.body)}</div>`,
        text:item.body,
        tags:[{name:"system",value:"imbop"},{name:"communication",value:"transactional"}],
      }),
    });

    const providerText=await response.text();
    let providerData:any=null;
    try { providerData=providerText ? JSON.parse(providerText) : null; } catch {}

    if (!response.ok) {
      await rpc("record_platform_email_delivery_result",{
        p_delivery_id:item.delivery_id,p_status:"FAILED",
        p_provider_message_id:providerData?.id??null,
        p_failure_reason:providerData?.message??providerText.slice(0,1000)
      },authHeader);
      return json({ok:false,status:"FAILED",delivery_id:item.delivery_id,provider_status:response.status},502);
    }

    await rpc("record_platform_email_delivery_result",{
      p_delivery_id:item.delivery_id,p_status:"DELIVERED",p_provider_message_id:providerData?.id??null
    },authHeader);

    return json({ok:true,status:"DELIVERED",delivery_id:item.delivery_id,provider_message_id:providerData?.id??null});
  } catch(error) {
    return json({ok:false,status:"DISPATCH_ERROR",message:error instanceof Error?error.message:"Unknown error"},500);
  }
});