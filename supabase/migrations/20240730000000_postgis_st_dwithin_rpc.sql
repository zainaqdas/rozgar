-- =============================================================================
-- ROZGAR — PostGIS ST_DWithin RPC functions for server-side radius queries.
-- Replaces client-side Haversine filtering for scalability.
-- =============================================================================

-- Add a PostGIS geometry column to worker_details (currently JSONB only)
alter table worker_details add column if not exists location geometry(point, 4326);

-- Populate from existing current_location JSONB data
update worker_details
set location = st_setsrid(st_makepoint(
  (current_location->>'lng')::double precision,
  (current_location->>'lat')::double precision
), 4326)
where location is null
  and current_location is not null
  and current_location->>'lat' is not null
  and current_location->>'lng' is not null;

-- Index for fast radius queries
create index if not exists worker_details_location_idx on worker_details using gist (location);

-- =============================================================================
-- RPC: Find nearby open jobs for a worker by skill categories
-- =============================================================================
create or replace function nearby_jobs(
  p_lat double precision,
  p_lng double precision,
  p_radius_km double precision default 15,
  p_category_ids text[] default '{}'
)
returns table(
  id text,
  employer_profile_id text,
  category_id text,
  title text,
  description text,
  budget_amount real,
  budget_type text,
  pin_location jsonb,
  status text,
  urgency text,
  created_at timestamptz,
  distance_km double precision
)
language plpgsql
security definer
as $$
begin
  return query
  select
    j.id,
    j.employer_profile_id,
    j.category_id,
    j.title,
    j.description,
    j.budget_amount,
    j.budget_type,
    j.pin_location,
    j.status,
    j.urgency,
    j.created_at,
    st_distancesphere(j.location, st_setsrid(st_makepoint(p_lng, p_lat), 4326)) / 1000.0 as distance_km
  from jobs j
  where j.status = 'open'
    and j.location is not null
    and st_dwithin(
      j.location,
      st_setsrid(st_makepoint(p_lng, p_lat), 4326),
      p_radius_km * 1000
    )
    and (
      array_length(p_category_ids, 1) is null
      or p_category_ids = '{}'
      or j.category_id = any(p_category_ids)
    )
  order by distance_km asc;
end;
$$;

-- =============================================================================
-- RPC: Find nearby workers for an employer
-- =============================================================================
create or replace function nearby_workers(
  p_lat double precision,
  p_lng double precision,
  p_radius_km double precision default 15,
  p_category_ids text[] default '{}'
)
returns table(
  profile_id text,
  display_name text,
  category_ids text[],
  bio text,
  average_rating real,
  total_jobs_completed int,
  distance_km double precision
)
language plpgsql
security definer
as $$
begin
  return query
  select
    wd.profile_id,
    p.display_name,
    wd.category_ids,
    wd.bio,
    wd.average_rating,
    wd.total_jobs_completed,
    st_distancesphere(wd.location, st_setsrid(st_makepoint(p_lng, p_lat), 4326)) / 1000.0 as distance_km
  from worker_details wd
  join profiles p on p.id = wd.profile_id
  where wd.is_online_for_map = true
    and wd.location is not null
    and st_dwithin(
      wd.location,
      st_setsrid(st_makepoint(p_lng, p_lat), 4326),
      p_radius_km * 1000
    )
    and (
      array_length(p_category_ids, 1) is null
      or p_category_ids = '{}'
      or wd.category_ids && p_category_ids
    )
  order by distance_km asc;
end;
$$;
