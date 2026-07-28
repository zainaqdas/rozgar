-- =============================================================================
-- ROZGAR — Performance & Safety Migrations
-- Adds indexes, constraints, and atomic RPC function for hire/reject.
-- =============================================================================

-- 1. Index on auth_identity_id for fast profile lookups during auth
create index if not exists profiles_auth_identity_idx on profiles (auth_identity_id);

-- 2. Index on employer_profile_id for job listing queries
create index if not exists jobs_employer_idx on jobs (employer_profile_id);

-- 3. Indexes on conversation foreign keys for fast joins
create index if not exists conversations_job_idx on conversations (job_id);
create index if not exists conversations_employer_idx on conversations (employer_profile_id);
create index if not exists conversations_worker_idx on conversations (worker_profile_id);

-- 4. Indexes on review foreign keys
create index if not exists reviews_job_idx on reviews (job_id);
create index if not exists reviews_reviewee_idx on reviews (reviewee_profile_id);

-- 5. CHECK constraint: budget_amount must be non-negative
alter table jobs add constraint jobs_budget_amount_check check (budget_amount >= 0);

-- 6. Unique constraint on conversations(job_id, worker_profile_id) to prevent duplicates
--    Requires deleting any existing duplicates first (there shouldn't be any in fresh DB)
delete from conversations a using (
  select min(id) as id, job_id, worker_profile_id
  from conversations
  group by job_id, worker_profile_id
  having count(*) > 1
) b
where a.job_id = b.job_id
  and a.worker_profile_id = b.worker_profile_id
  and a.id <> b.id;

alter table conversations add constraint conversations_job_worker_unique unique (job_id, worker_profile_id);

-- =============================================================================
-- ATOMIC HIRE + REJECT RPC
-- Wraps the hire+reject workflow in a single Postgres transaction.
-- =============================================================================
create or replace function hire_and_reject(
  p_job_id text,
  p_hired_worker_profile_id text,
  p_reject_application_ids text[]
)
returns void
language plpgsql
security definer
as $$
begin
  -- Reject other applications first
  if array_length(p_reject_application_ids, 1) > 0 then
    update applications
    set status = 'rejected'
    where id = any(p_reject_application_ids);
  end if;

  -- Hire the selected worker
  update applications
  set status = 'hired'
  where job_id = p_job_id
    and worker_profile_id = p_hired_worker_profile_id;
end;
$$;
