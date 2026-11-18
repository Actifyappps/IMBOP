-- IMBOP media foundation: controlled authenticated media storage and content attachment metadata.
create table if not exists public.content_media (
 id uuid primary key default gen_random_uuid(),
 institution_id uuid not null references public.institutions(id) on delete cascade,
 owner_user_id uuid not null,
 entity_type text not null check (entity_type in ('MEMBER_PROFILE','BUSINESS','BUSINESS_PROFILE','OFFER','NEED','OPPORTUNITY','INSTITUTION')),
 entity_id uuid not null,
 media_type text not null default 'IMAGE' check (media_type in ('IMAGE','DOCUMENT')),
 storage_path text not null,
 public_url text,
 alt_text text,
 sort_order integer not null default 0,
 visibility text not null default 'INSTITUTION' check (visibility in ('PRIVATE','INSTITUTION','PUBLIC')),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create index if not exists content_media_entity_idx on public.content_media(institution_id,entity_type,entity_id,sort_order);
alter table public.content_media enable row level security;
revoke all on public.content_media from anon;
grant select,insert,update,delete on public.content_media to authenticated;
create policy content_media_select on public.content_media for select to authenticated using (private.is_institution_member(institution_id));
create policy content_media_insert on public.content_media for insert to authenticated with check (private.is_institution_member(institution_id) and owner_user_id=auth.uid());
create policy content_media_update on public.content_media for update to authenticated using (owner_user_id=auth.uid() or private.has_institution_permission(institution_id,'business_manage')) with check (institution_id=institution_id);
create policy content_media_delete on public.content_media for delete to authenticated using (owner_user_id=auth.uid() or private.has_institution_permission(institution_id,'institution_admin'));
insert into storage.buckets (id,name,public,file_size_limit,allowed_mime_types) values ('imbop-media','imbop-media',false,10485760,array['image/jpeg','image/png','image/webp']) on conflict (id) do nothing;
create policy imbop_media_insert on storage.objects for insert to authenticated with check (bucket_id='imbop-media' and (storage.foldername(name))[1]=auth.uid()::text);
create policy imbop_media_select on storage.objects for select to authenticated using (bucket_id='imbop-media' and (storage.foldername(name))[1]=auth.uid()::text);
create policy imbop_media_update on storage.objects for update to authenticated using (bucket_id='imbop-media' and (storage.foldername(name))[1]=auth.uid()::text) with check (bucket_id='imbop-media' and (storage.foldername(name))[1]=auth.uid()::text);
create policy imbop_media_delete on storage.objects for delete to authenticated using (bucket_id='imbop-media' and (storage.foldername(name))[1]=auth.uid()::text);