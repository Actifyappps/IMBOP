import { withSupabase } from "npm:@supabase/server@1";
import { dispatchOne } from "../_shared/emailDispatcher.ts";

export default {
  fetch: withSupabase({ auth: "user" }, async (req, ctx) => {
    if (req.method !== "POST") {
      return Response.json({ error: "METHOD_NOT_ALLOWED" }, { status: 405 });
    }

    if (!ctx.userClaims?.sub) {
      return Response.json({ error: "AUTHORIZATION_REQUIRED" }, { status: 401 });
    }

    if (!Deno.env.get("RESEND_API_KEY") || !Deno.env.get("IMBOP_EMAIL_FROM")) {
      return Response.json({
        error: "EMAIL_PROVIDER_NOT_CONFIGURED",
        message: "Set RESEND_API_KEY and IMBOP_EMAIL_FROM before enabling external email delivery.",
      }, { status: 503 });
    }

    let payload: { delivery_id?: string } = {};
    try {
      payload = await req.json();
    } catch {}

    try {
      const result = await dispatchOne(ctx.supabase, payload.delivery_id);
      return Response.json(result, { status: result.ok ? 200 : 502 });
    } catch (error) {
      const message = error instanceof Error ? error.message : "Unknown dispatcher error";
      return Response.json({ ok: false, status: "DISPATCH_ERROR", message }, { status: 500 });
    }
  }),
};
