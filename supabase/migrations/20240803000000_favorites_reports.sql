-- =============================================================================
-- ROZGAR — Favorites and Reports tables
-- =============================================================================

create table if not exists favorites (
  id text primary key,
  profile_id text not null references profiles(id) on delete cascade,
  favorited_profile_id text not null references profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique(profile_id, favorited_profile_id)
);

create index if not exists idx_favorites_profile on favorites(profile_id);

alter table favorites enable row level security;

create policy "Users manage own favorites"
  on favorites for all
  using (profile_id in (select id from profiles where auth_identity_id = auth.uid()::text))
  with check (profile_id in (select id from profiles where auth_identity_id = auth.uid()::text));

create table if not exists reports (
  id text primary key,
  reporter_profile_id text not null references profiles(id) on delete cascade,
  reported_profile_id text not null references profiles(id) on delete cascade,
  job_id text references jobs(id) on delete set null,
  reason text not null,
  details text,
  status text not null default 'open' check (status in ('open', 'reviewed', 'resolved', 'dismissed')),
  created_at timestamptz not null default now()
);

create index if not exists idx_reports_reporter on reports(reporter_profile_id);
create index if not exists idx_reports_reported on reports(reported_profile_id);

alter table reports enable row level security;

create policy "Users insert own reports"
  on reports for insert
  with check (reporter_profile_id in (select id from profiles where auth_identity_id = auth.uid()::text));

create policy "Users view own reports"
  on reports for select
  using (reporter_profile_id in (select id from profiles where auth_identity_id = auth.uid()::text));

create policy "Admins manage reports"
  on reports for all
  using (auth.role() = 'service_role');
