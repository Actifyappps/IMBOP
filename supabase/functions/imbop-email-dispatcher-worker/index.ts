import { withSupabase } from "npm:@supabase/server@1";
import { dispatchBatch } from "../_shared/emailDispatcher.ts";

export default {
  fetch: withSupabase({ auth: "secret" }, async (_req, ctx) => {
    try {
      const result = await dispatchBatch(ctx.supabaseAdmin, 10);
      return Response.json(result);
    } catch (error) {
      const message = error instanceof Error ? error.message : "Unknown dispatcher error";
      return Response.json({ ok: false, status: "DISPATCH_ERROR", message }, { status: 500 });
    }
  }),
};
