-- IMBOP Communications Maturity — Batch 4
-- Controlled administrative/system notices for institution lifecycle changes.
--
-- BUSINESS STATE CHANGE -> COMMUNICATION RECORD -> CHANNEL DELIVERY

create or replace function private.queue_institution_status_change_communications()
returns trigger
language plpgsql
security definer
set search_path to ''
as $function$
declare
  m record;
  v_status text := upper(coalesce(new.status,''));
  v_idempotency_key text;
  v_subject text;
  v_body text;
begin
  if new.status is not distinct from old.status or v_status in ('ACTIVE','') then
    return new;
  end if;

  v_subject := 'IMBOP Institution status update: ' || v_status;
  v_body := 'Your Institution''s IMBOP status has changed to ' || v_status || '.' ||
    case
      when nullif(trim(coalesce(new.status_reason,'')),'') is not null
        then ' Administrative note: ' || trim(new.status_reason)
      else ''
    end;

  for m in
    select distinct mb.user_id, u.email, u.email as recipient_name
      from public.memberships mb
      join public.membership_roles mr on mr.membership_id=mb.id
      join public.roles r on r.id=mr.role_id
      join auth.users u on u.id=mb.user_id
     where mb.institution_id=new.id
       and mb.status='active'
       and r.scope='institution'
       and r.code in ('institution_admin','institution_owner')
       and nullif(trim(coalesce(u.email,'')),'') is not null
  loop
    v_idempotency_key := 'institution:' || new.id::text || ':STATUS:' ||
      coalesce(old.status,'NULL') || ':' || v_status || ':' || m.user_id::text;

    perform private.create_in_app_communication(
      new.id,m.user_id,m.email,m.recipient_name,null,'SYSTEM',
      'INSTITUTION_LIFECYCLE','INSTITUTION_STATUS_CHANGED',
      v_subject,v_body,'institution',new.id,
      jsonb_build_object(
        'institution_id',new.id,
        'from_status',old.status,
        'to_status',new.status,
        'status_reason',new.status_reason,
        'idempotency_key',v_idempotency_key,
        'template_key','institution_status_changed',
        'template_version','1'
      )
    );

    perform private.create_email_communication(
      new.id,m.user_id,m.email,m.recipient_name,null,'SYSTEM',
      'INSTITUTION_LIFECYCLE','INSTITUTION_STATUS_CHANGED',
      v_subject,v_body,'institution',new.id,
      jsonb_build_object(
        'institution_id',new.id,
        'from_status',old.status,
        'to_status',new.status,
        'status_reason',new.status_reason,
        'idempotency_key',v_idempotency_key,
        'template_key','institution_status_changed',
        'template_version','1'
      )
    );
  end loop;

  return new;
end;
$function$;

drop trigger if exists institutions_status_change_communications on public.institutions;
create trigger institutions_status_change_communications
after update of status on public.institutions
for each row
execute function private.queue_institution_status_change_communications();

revoke execute on function private.queue_institution_status_change_communications() from public, anon, authenticated;
