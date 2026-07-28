-- =============================================================================
-- ROZGAR — Update nearby_workers RPC to return lat/lng coordinates
-- The map screen needs coordinates to place markers. The original RPC
-- (20240730000000) omitted them, making it unusable for map rendering.
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
  distance_km double precision,
  lat double precision,
  lng double precision,
  profile_photo_url text
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
    st_distancesphere(wd.location, st_setsrid(st_makepoint(p_lng, p_lat), 4326)) / 1000.0 as distance_km,
    (wd.current_location->>'lat')::double precision as lat,
    (wd.current_location->>'lng')::double precision as lng,
    p.profile_photo_url
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
