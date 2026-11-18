drop function if exists public.get_public_imbop_pricing_plans();

create function public.get_public_imbop_pricing_plans()
returns table(
  plan_code text,
  plan_name text,
  min_onboards integer,
  max_onboards integer,
  monthly_fee_kes numeric,
  transition_minimum_kes numeric,
  pricing_mode text,
  description text,
  display_order integer
)
language sql
stable
security definer
set search_path = public
as $function$
  select
    p.plan_code,
    p.plan_name,
    p.min_onboards,
    p.max_onboards,
    p.monthly_fee_kes,
    p.transition_minimum_kes,
    p.pricing_mode,
    p.description,
    p.display_order
  from public.imbop_pricing_plans p
  where p.active = true
  order by p.display_order, p.min_onboards;
$function$;

revoke execute on function public.get_public_imbop_pricing_plans() from public;
grant execute on function public.get_public_imbop_pricing_plans() to anon, authenticated;

revoke insert, update, delete, references, trigger on table public.imbop_pricing_plans from anon;
revoke delete, references, trigger on table public.imbop_pricing_plans from authenticated;

revoke execute on function public.get_imbop_public_stats() from public;
grant execute on function public.get_imbop_public_stats() to anon, authenticated;
