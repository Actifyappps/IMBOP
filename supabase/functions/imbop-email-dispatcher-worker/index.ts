import { withSupabase } from "npm:@supabase/server@1";
import { dispatchBatch } from "../_shared/emailDispatcher.ts";

export default {
  fetch: withSupabase({ auth: "publishable" }, async (_req, ctx) => {
    try {
      const providedSecret = _req.headers.get("x-imbop-dispatch-secret");
      if (!providedSecret) {
        return Response.json({ ok: false, status: "DISPATCH_AUTH_REQUIRED" }, { status: 401 });
      }

      const { data: authorized, error: authError } = await ctx.supabaseAdmin.rpc(
        "verify_imbop_email_dispatch_secret",
        { p_secret: providedSecret },
      );

      if (authError || authorized !== true) {
        return Response.json({ ok: false, status: "DISPATCH_AUTH_FAILED" }, { status: 401 });
      }

      const result = await dispatchBatch(ctx.supabaseAdmin, 10);
      return Response.json(result);
    } catch (error) {
      const message = error instanceof Error ? error.message : "Unknown dispatcher error";
      return Response.json({ ok: false, status: "DISPATCH_ERROR", message }, { status: 500 });
    }
  }),
};
