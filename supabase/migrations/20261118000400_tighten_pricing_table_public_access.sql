revoke select on table public.imbop_pricing_plans from anon;

create index if not exists imbop_pricing_plans_updated_by_user_id_idx
  on public.imbop_pricing_plans (updated_by_user_id);
