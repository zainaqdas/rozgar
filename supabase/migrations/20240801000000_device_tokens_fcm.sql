-- =============================================================================
-- ROZGAR — Device tokens for FCM push notifications
-- =============================================================================

create table if not exists device_tokens (
  id text primary key,
  profile_id text not null references profiles(id) on delete cascade,
  token text not null,
  platform text not null default 'android' check (platform in ('android', 'ios', 'web')),
  created_at timestamptz not null default now(),
  unique(profile_id, token)
);

create index if not exists idx_device_tokens_profile on device_tokens(profile_id);

alter table device_tokens enable row level security;

create policy "Users manage own device tokens"
  on device_tokens for all
  using (
    profile_id in (
      select id from profiles where auth_identity_id = auth.uid()::text
    )
  )
  with check (
    profile_id in (
      select id from profiles where auth_identity_id = auth.uid()::text
    )
  );

-- Trigger: on notification insert, invoke Edge Function to send FCM push
create or replace function notify_push_on_notification()
returns trigger
language plpgsql
security definer
as $$
begin
  perform net.http_post(
    url := 'https://hjnhudboyjkagicosrba.supabase.co/functions/v1/send-push',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key', true)
    ),
    body := jsonb_build_object(
      'profile_id', new.profile_id,
      'title_en', new.title_en,
      'title_ur', new.title_ur,
      'body_en', new.body_en,
      'body_ur', new.body_ur,
      'payload', new.payload,
      'type', new.type
    )
  );
  return new;
end;
$$;

drop trigger if exists trg_push_on_notification on notifications;
create trigger trg_push_on_notification
  after insert on notifications
  for each row
  execute function notify_push_on_notification();
