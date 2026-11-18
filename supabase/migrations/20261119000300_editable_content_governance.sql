-- Editable content and media governance for IMBOP.
-- Publication remains institution-controlled; creators may only submit their own content for review.

create table if not exists public.market_items (
  id uuid primary key default gen_random_uuid(),
  institution_id uuid not null references public.institutions(id),
  business_id uuid references public.businesses(id),
  created_by_user_id uuid not null references auth.users(id),
  intent_type text not null check (intent_type in ('OFFER','NEED')),
  title text not null,
  short_summary text,
  description text,
  category text,
  sector text,
  value_chain text,
  quantity text,
  location text,
  price_basis text,
  availability text,
  required_by text,
  contact_preference text,
  status text not null default 'DRAFT' check (status in ('DRAFT','ACTIVE','INACTIVE')),
  publication_state text not null default 'DRAFT' check (publication_state in ('DRAFT','SUBMITTED','PENDING_REVIEW','PUBLISHED','RETURNED','REJECTED','UNPUBLISHED')),
  visibility text not null default 'INSTITUTION' check (visibility in ('PRIVATE','INSTITUTION','PUBLIC')),
  verification_state text not null default 'UNVERIFIED' check (verification_state in ('UNVERIFIED','PENDING','VERIFIED','REJECTED')),
  published_at timestamptz,
  published_by_user_id uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.market_items enable row level security;
revoke all on table public.market_items from anon;
grant select, insert, update, delete on table public.market_items to authenticated;

drop policy if exists market_items_select on public.market_items;
drop policy if exists market_items_insert on public.market_items;
drop policy if exists market_items_update on public.market_items;
drop policy if exists market_items_delete on public.market_items;

create policy market_items_select on public.market_items for select to authenticated using (private.is_institution_member(institution_id));
create policy market_items_insert on public.market_items for insert to authenticated with check (private.is_institution_member(institution_id) and created_by_user_id=(select auth.uid()));
create policy market_items_update on public.market_items for update to authenticated
using (created_by_user_id=(select auth.uid()) or private.has_institution_permission(institution_id,'business_manage'))
with check (private.is_institution_member(institution_id) and (created_by_user_id=(select auth.uid()) or private.has_institution_permission(institution_id,'business_manage')));
create policy market_items_delete on public.market_items for delete to authenticated
using (private.has_institution_permission(institution_id,'institution_admin') or created_by_user_id=(select auth.uid()));

create index if not exists market_items_institution_idx on public.market_items(institution_id,intent_type,publication_state);
create index if not exists market_items_business_idx on public.market_items(business_id);

alter table public.opportunities
  add column if not exists short_summary text,
  add column if not exists sector text,
  add column if not exists value_chain text,
  add column if not exists audience text,
  add column if not exists opportunity_scale text,
  add column if not exists timeline text,
  add column if not exists participation_terms text,
  add column if not exists contact_preference text;

create or replace function private.enforce_market_item_publication()
returns trigger language plpgsql security definer set search_path=''
as $$
begin
  if new.publication_state is distinct from old.publication_state then
    if new.publication_state='SUBMITTED' and old.publication_state='DRAFT' and new.created_by_user_id=(select auth.uid()) then
      null;
    elsif not private.has_institution_permission(new.institution_id,'publication_manage') then
      raise exception 'Publication authority required for publication-state transition';
    end if;
    if old.publication_state='DRAFT' and new.publication_state not in ('SUBMITTED','REJECTED') then raise exception 'Invalid publication transition: DRAFT';
    elsif old.publication_state='SUBMITTED' and new.publication_state not in ('PENDING_REVIEW','DRAFT','REJECTED') then raise exception 'Invalid publication transition: SUBMITTED';
    elsif old.publication_state='PENDING_REVIEW' and new.publication_state not in ('PUBLISHED','RETURNED','REJECTED') then raise exception 'Invalid publication transition: PENDING_REVIEW';
    elsif old.publication_state='RETURNED' and new.publication_state not in ('SUBMITTED','REJECTED') then raise exception 'Invalid publication transition: RETURNED';
    elsif old.publication_state='PUBLISHED' and new.publication_state<>'UNPUBLISHED' then raise exception 'Invalid publication transition: PUBLISHED';
    elsif old.publication_state='REJECTED' and new.publication_state<>'DRAFT' then raise exception 'Invalid publication transition: REJECTED';
    elsif old.publication_state='UNPUBLISHED' and new.publication_state not in ('DRAFT','SUBMITTED') then raise exception 'Invalid publication transition: UNPUBLISHED';
    end if;
  end if;
  if new.publication_state='PUBLISHED' then
    if new.published_at is null or new.published_by_user_id is null then raise exception 'PUBLISHED requires publication metadata'; end if;
  elsif new.published_at is not null or new.published_by_user_id is not null then
    raise exception 'Non-PUBLISHED records cannot carry publication metadata';
  end if;
  new.updated_at=now(); return new;
end $$;

drop trigger if exists market_items_publication_guard on public.market_items;
create trigger market_items_publication_guard before insert or update on public.market_items for each row execute function private.enforce_market_item_publication();

create or replace function private.enforce_publication_transition()
returns trigger language plpgsql security definer set search_path=''
as $$
declare old_state text:=case when TG_OP='UPDATE' then OLD.publication_state::text else null end;
new_state text:=NEW.publication_state::text;
owner_can_submit boolean:=false;
begin
  if TG_OP='UPDATE' and old_state is distinct from new_state then
    if TG_TABLE_NAME='member_profiles' then owner_can_submit:=NEW.user_id=(select auth.uid());
    elsif TG_TABLE_NAME in ('businesses','opportunities') then owner_can_submit:=NEW.created_by_user_id=(select auth.uid());
    elsif TG_TABLE_NAME='business_profiles' then
      select b.created_by_user_id=(select auth.uid()) into owner_can_submit from public.businesses b where b.id=NEW.business_id;
    end if;
    if not (old_state='DRAFT' and new_state='SUBMITTED' and owner_can_submit) and not private.has_institution_permission(NEW.institution_id,'publication_manage') then
      raise exception 'Publication authority required for publication-state transition';
    end if;
    if old_state='DRAFT' and new_state not in ('SUBMITTED','REJECTED') then raise exception 'Invalid publication transition: DRAFT';
    elsif old_state='SUBMITTED' and new_state not in ('PENDING_REVIEW','DRAFT','REJECTED') then raise exception 'Invalid publication transition: SUBMITTED';
    elsif old_state='PENDING_REVIEW' and new_state not in ('PUBLISHED','RETURNED','REJECTED') then raise exception 'Invalid publication transition: PENDING_REVIEW';
    elsif old_state='RETURNED' and new_state not in ('SUBMITTED','REJECTED') then raise exception 'Invalid publication transition: RETURNED';
    elsif old_state='PUBLISHED' and new_state<>'UNPUBLISHED' then raise exception 'Invalid publication transition: PUBLISHED';
    elsif old_state='REJECTED' and new_state<>'DRAFT' then raise exception 'Invalid publication transition: REJECTED';
    elsif old_state='UNPUBLISHED' and new_state not in ('DRAFT','SUBMITTED') then raise exception 'Invalid publication transition: UNPUBLISHED';
    end if;
  end if;
  if new_state='PUBLISHED' then
    if NEW.published_at is null or NEW.published_by_user_id is null then raise exception 'PUBLISHED requires published_at and published_by_user_id'; end if;
  elsif NEW.published_at is not null or NEW.published_by_user_id is not null then raise exception 'Non-PUBLISHED records cannot carry publication metadata';
  end if;
  return NEW;
end $$;

drop policy if exists businesses_update on public.businesses;
create policy businesses_update on public.businesses for update to authenticated
using (private.has_institution_permission(businesses.institution_id,'business_manage') or businesses.created_by_user_id=(select auth.uid()))
with check (private.is_institution_member(businesses.institution_id) and (private.has_institution_permission(businesses.institution_id,'business_manage') or businesses.created_by_user_id=(select auth.uid())));

drop policy if exists business_profiles_update on public.business_profiles;
create policy business_profiles_update on public.business_profiles for update to authenticated
using (private.has_institution_permission(business_profiles.institution_id,'business_manage') or exists(select 1 from public.businesses b where b.id=business_profiles.business_id and b.created_by_user_id=(select auth.uid())))
with check (private.is_institution_member(business_profiles.institution_id) and (private.has_institution_permission(business_profiles.institution_id,'business_manage') or exists(select 1 from public.businesses b where b.id=business_profiles.business_id and b.created_by_user_id=(select auth.uid()))));

drop policy if exists member_profiles_update on public.member_profiles;
create policy member_profiles_update on public.member_profiles for update to authenticated
using ((member_profiles.user_id=(select auth.uid())) or private.has_institution_permission(member_profiles.institution_id,'business_manage'))
with check (private.is_institution_member(member_profiles.institution_id) and ((member_profiles.user_id=(select auth.uid())) or private.has_institution_permission(member_profiles.institution_id,'business_manage')));

drop policy if exists opportunities_update on public.opportunities;
create policy opportunities_update on public.opportunities for update to authenticated
using (private.has_institution_permission(opportunities.institution_id,'business_manage') or opportunities.created_by_user_id=(select auth.uid()))
with check (private.is_institution_member(opportunities.institution_id) and (private.has_institution_permission(opportunities.institution_id,'business_manage') or opportunities.created_by_user_id=(select auth.uid())));
