-- =============================================================================
-- Migrate primary key columns from UUID to TEXT
-- =============================================================================
-- The Dart code uses string IDs throughout. This migration changes the schema.
-- Drops RLS policies, drops FKs, alters types, re-creates FKs + policies.
-- =============================================================================

-- Drop RLS policies with exact names from the original migration
drop policy if exists "Profiles are readable by authenticated users" on public.profiles;
drop policy if exists "Users can insert their own profile" on public.profiles;
drop policy if exists "Users can update their own profile" on public.profiles;
drop policy if exists "Worker details are readable by authenticated users" on public.worker_details;
drop policy if exists "Workers can insert their own details" on public.worker_details;
drop policy if exists "Workers can update their own details" on public.worker_details;
drop policy if exists "Jobs are readable by authenticated users" on public.jobs;
drop policy if exists "Employers can insert jobs" on public.jobs;
drop policy if exists "Employers can update their own jobs" on public.jobs;
drop policy if exists "Applications are readable by authenticated users" on public.applications;
drop policy if exists "Workers can apply to jobs" on public.applications;
drop policy if exists "Employers can update applications for their jobs" on public.applications;
drop policy if exists "Conversation participants can read" on public.conversations;
drop policy if exists "Authenticated users can create conversations" on public.conversations;
drop policy if exists "Participants can update conversations" on public.conversations;
drop policy if exists "Message participants can read" on public.messages;
drop policy if exists "Participants can insert messages" on public.messages;
drop policy if exists "Reviews are readable" on public.reviews;
drop policy if exists "Participants can insert reviews" on public.reviews;
drop policy if exists "Users can view their own notifications" on public.notifications;

-- Delete orphaned data that would break FK constraints
-- (review referencing non-existent job)
delete from public.reviews where job_id = 'job-old-1';

-- Clear old seed data that used different ID scheme (will be re-seeded)
truncate table public.notifications cascade;
truncate table public.reviews cascade;
truncate table public.messages cascade;
truncate table public.conversations cascade;
truncate table public.applications cascade;
truncate table public.jobs cascade;
truncate table public.worker_details cascade;
truncate table public.profiles cascade;

-- Drop foreign key constraints
alter table public.worker_details drop constraint if exists worker_details_profile_id_fkey;
alter table public.jobs drop constraint if exists jobs_employer_profile_id_fkey;
alter table public.jobs drop constraint if exists jobs_hired_worker_profile_id_fkey;
alter table public.applications drop constraint if exists applications_job_id_fkey;
alter table public.applications drop constraint if exists applications_worker_profile_id_fkey;
alter table public.conversations drop constraint if exists conversations_job_id_fkey;
alter table public.conversations drop constraint if exists conversations_employer_profile_id_fkey;
alter table public.conversations drop constraint if exists conversations_worker_profile_id_fkey;
alter table public.messages drop constraint if exists messages_conversation_id_fkey;
alter table public.messages drop constraint if exists messages_sender_profile_id_fkey;
alter table public.reviews drop constraint if exists reviews_job_id_fkey;
alter table public.reviews drop constraint if exists reviews_reviewer_profile_id_fkey;
alter table public.reviews drop constraint if exists reviews_reviewee_profile_id_fkey;
alter table public.notifications drop constraint if exists notifications_profile_id_fkey;

-- Alter primary key columns to TEXT
alter table public.profiles alter column id type text;
alter table public.jobs alter column id type text;
alter table public.applications alter column id type text;
alter table public.conversations alter column id type text;
alter table public.messages alter column id type text;
alter table public.reviews alter column id type text;
alter table public.notifications alter column id type text;

-- Alter foreign key columns to TEXT
alter table public.worker_details alter column profile_id type text;
alter table public.jobs alter column employer_profile_id type text;
alter table public.jobs alter column hired_worker_profile_id type text;
alter table public.applications alter column job_id type text;
alter table public.applications alter column worker_profile_id type text;
alter table public.conversations alter column job_id type text;
alter table public.conversations alter column employer_profile_id type text;
alter table public.conversations alter column worker_profile_id type text;
alter table public.messages alter column conversation_id type text;
alter table public.messages alter column sender_profile_id type text;
alter table public.reviews alter column job_id type text;
alter table public.reviews alter column reviewer_profile_id type text;
alter table public.reviews alter column reviewee_profile_id type text;
alter table public.notifications alter column profile_id type text;

-- Re-create foreign key constraints
alter table public.worker_details add constraint worker_details_profile_id_fkey foreign key (profile_id) references public.profiles(id) on delete cascade;
alter table public.jobs add constraint jobs_employer_profile_id_fkey foreign key (employer_profile_id) references public.profiles(id) on delete cascade;
alter table public.jobs add constraint jobs_hired_worker_profile_id_fkey foreign key (hired_worker_profile_id) references public.profiles(id) on delete set null;
alter table public.applications add constraint applications_job_id_fkey foreign key (job_id) references public.jobs(id) on delete cascade;
alter table public.applications add constraint applications_worker_profile_id_fkey foreign key (worker_profile_id) references public.profiles(id) on delete cascade;
alter table public.conversations add constraint conversations_job_id_fkey foreign key (job_id) references public.jobs(id) on delete cascade;
alter table public.conversations add constraint conversations_employer_profile_id_fkey foreign key (employer_profile_id) references public.profiles(id) on delete cascade;
alter table public.conversations add constraint conversations_worker_profile_id_fkey foreign key (worker_profile_id) references public.profiles(id) on delete cascade;
alter table public.messages add constraint messages_conversation_id_fkey foreign key (conversation_id) references public.conversations(id) on delete cascade;
alter table public.messages add constraint messages_sender_profile_id_fkey foreign key (sender_profile_id) references public.profiles(id) on delete cascade;
alter table public.reviews add constraint reviews_job_id_fkey foreign key (job_id) references public.jobs(id) on delete cascade;
alter table public.reviews add constraint reviews_reviewer_profile_id_fkey foreign key (reviewer_profile_id) references public.profiles(id) on delete cascade;
alter table public.reviews add constraint reviews_reviewee_profile_id_fkey foreign key (reviewee_profile_id) references public.profiles(id) on delete cascade;
alter table public.notifications add constraint notifications_profile_id_fkey foreign key (profile_id) references public.profiles(id) on delete cascade;

-- Re-create RLS policies with proper auth_identity_id checks
-- Profiles: users can only access their own
create policy "Users can read their own profile" on public.profiles for select
  using (auth_identity_id = auth.uid()::text);
create policy "Users can insert their own profile" on public.profiles for insert
  with check (auth_identity_id = auth.uid()::text);
create policy "Users can update their own profile" on public.profiles for update
  using (auth_identity_id = auth.uid()::text);

-- Worker details: access through own profile
create policy "Users can read their own worker details" on public.worker_details for select
  using (profile_id in (select id from public.profiles where auth_identity_id = auth.uid()::text));
create policy "Users can insert their own worker details" on public.worker_details for insert
  with check (profile_id in (select id from public.profiles where auth_identity_id = auth.uid()::text));
create policy "Users can update their own worker details" on public.worker_details for update
  using (profile_id in (select id from public.profiles where auth_identity_id = auth.uid()::text));

-- Jobs: readable by all authenticated, only own employer can modify
create policy "Jobs are readable by all authenticated" on public.jobs for select
  using (auth.role() = 'authenticated');
create policy "Employers can insert jobs" on public.jobs for insert
  with check (auth.role() = 'authenticated');
create policy "Employers can update their own jobs" on public.jobs for update
  using (employer_profile_id in (select id from public.profiles where auth_identity_id = auth.uid()::text));

-- Applications: readable by all authenticated, own inserts, employers update for their jobs
create policy "Applications are readable by all authenticated" on public.applications for select
  using (auth.role() = 'authenticated');
create policy "Workers can apply to jobs" on public.applications for insert
  with check (auth.role() = 'authenticated');
create policy "Employers can update applications for their jobs" on public.applications for update
  using (job_id in (select id from public.jobs where employer_profile_id in (select id from public.profiles where auth_identity_id = auth.uid()::text)));

-- Conversations: participants only
create policy "Participants can read their conversations" on public.conversations for select
  using (employer_profile_id in (select id from public.profiles where auth_identity_id = auth.uid()::text)
      or worker_profile_id in (select id from public.profiles where auth_identity_id = auth.uid()::text));
create policy "Authenticated users can create conversations" on public.conversations for insert
  with check (auth.role() = 'authenticated');
create policy "Participants can update conversations" on public.conversations for update
  using (employer_profile_id in (select id from public.profiles where auth_identity_id = auth.uid()::text)
      or worker_profile_id in (select id from public.profiles where auth_identity_id = auth.uid()::text));

-- Messages: participants of the conversation only
create policy "Participants can read messages" on public.messages for select
  using (conversation_id in (select id from public.conversations where
      employer_profile_id in (select id from public.profiles where auth_identity_id = auth.uid()::text)
      or worker_profile_id in (select id from public.profiles where auth_identity_id = auth.uid()::text)));
create policy "Participants can insert messages" on public.messages for insert
  with check (auth.role() = 'authenticated');

-- Reviews: readable by all authenticated, participants can insert
create policy "Reviews are readable by all authenticated" on public.reviews for select
  using (auth.role() = 'authenticated');
create policy "Participants can insert reviews" on public.reviews for insert
  with check (auth.role() = 'authenticated');

-- Notifications: users can only see their own
create policy "Users can view their own notifications" on public.notifications for select
  using (profile_id in (select id from public.profiles where auth_identity_id = auth.uid()::text));
create policy "Users can create notifications" on public.notifications for insert
  with check (auth.role() = 'authenticated');
create policy "Users can update their own notifications" on public.notifications for update
  using (profile_id in (select id from public.profiles where auth_identity_id = auth.uid()::text));
