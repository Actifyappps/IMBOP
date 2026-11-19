-- Activate the automatic IMBOP email dispatcher after Vault credentials exist.

select cron.schedule(
  'imbop-email-dispatcher-every-minute',
  '* * * * *',
  $job$
    select net.http_post(
      url := 'https://jvzbrdcudzwbjmwlpzfe.supabase.co/functions/v1/imbop-email-dispatcher-worker',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'apikey', (select decrypted_secret from vault.decrypted_secrets where name = 'imbop_dispatch_publishable_key'),
        'x-imbop-dispatch-secret', (select decrypted_secret from vault.decrypted_secrets where name = 'imbop_email_dispatch_secret')
      ),
      body := jsonb_build_object('source', 'supabase-cron', 'scheduled_at', now()),
      timeout_milliseconds := 5000
    ) as request_id;
  $job$
);
