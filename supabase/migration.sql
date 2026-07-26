-- =============================================================================
-- ROZGAR — Local Services Marketplace: Database Schema
-- Run this in Supabase SQL Editor (Settings > API > SQL Editor)
-- =============================================================================

-- 1. Enable PostGIS for location-based queries
create extension if not exists postgis with schema extensions;

-- =============================================================================
-- PROFILES
-- =============================================================================
create table if not exists profiles (
  id uuid primary key default gen_random_uuid(),
  auth_identity_id text not null,
  profile_type text not null check (profile_type in ('employer', 'worker')),
  display_name text not null default '',
  profile_photo_url text not null default '',
  phone text,
  city text not null default 'Lahore',
  home_location jsonb not null default '{"lat": 31.5204, "lng": 74.3587, "address": "Lahore"}',
  created_at timestamptz not null default now(),
  is_verified boolean not null default false,
  id_verification_status text not null default 'none' check (id_verification_status in ('none', 'pending', 'verified')),
  account_status text not null default 'active' check (account_status in ('active', 'suspended')),
  onboarding_completion_pct real not null default 0
);

alter table profiles enable row level security;

-- Anyone authenticated can read profiles
create policy "Profiles are readable by authenticated users"
  on profiles for select
  using (auth.role() = 'authenticated');

-- Users can insert their own profile
create policy "Users can insert their own profile"
  on profiles for insert
  with check (auth_identity_id = auth.uid()::text);

-- Users can update their own profile
create policy "Users can update their own profile"
  on profiles for update
  using (auth_identity_id = auth.uid()::text);

-- =============================================================================
-- WORKER DETAILS (1:1 with profiles)
-- =============================================================================
create table if not exists worker_details (
  profile_id uuid primary key references profiles(id) on delete cascade,
  category_ids text[] not null default '{}',
  bio text not null default '',
  years_experience int not null default 0,
  rate_note text not null default '',
  availability_status text not null default 'today' check (availability_status in ('today', 'tomorrow', 'weekdays', 'weekends', 'morning', 'evening', 'busy', 'offline')),
  notification_radius_km real not null default 15,
  is_online_for_map boolean not null default true,
  current_location jsonb not null default '{"lat": 31.5204, "lng": 74.3587, "address": "Lahore"}',
  portfolio_media text[] not null default '{}',
  average_rating real not null default 5.0,
  total_jobs_completed int not null default 0,
  response_time_avg_minutes int not null default 5,
  is_featured boolean
);

alter table worker_details enable row level security;

create policy "Worker details are readable by authenticated users"
  on worker_details for select
  using (auth.role() = 'authenticated');

create policy "Workers can insert their own details"
  on worker_details for insert
  with check (exists (select 1 from profiles where id = profile_id and auth_identity_id = auth.uid()::text));

create policy "Workers can update their own details"
  on worker_details for update
  using (exists (select 1 from profiles where id = profile_id and auth_identity_id = auth.uid()::text));

-- =============================================================================
-- JOBS
-- =============================================================================
create table if not exists jobs (
  id uuid primary key default gen_random_uuid(),
  employer_profile_id text not null,
  category_id text not null default '',
  title text not null default '',
  description text not null default '',
  ai_extracted_summary jsonb,
  budget_amount real not null default 0,
  budget_type text not null default 'fixed' check (budget_type in ('fixed', 'hourly', 'negotiable')),
  pin_location jsonb not null default '{"lat": 31.5204, "lng": 74.3587, "address": "Lahore"}',
  location extensions.geometry(point, 4326),
  status text not null default 'open' check (status in ('open', 'hired', 'completed', 'cancelled', 'expired')),
  urgency text not null default 'today' check (urgency in ('instant', 'today', 'scheduled')),
  scheduled_for timestamptz,
  created_at timestamptz not null default now(),
  hired_worker_profile_id text
);

-- Index for geo queries
create index if not exists jobs_location_idx on jobs using gist (location);
create index if not exists jobs_status_idx on jobs (status);
create index if not exists jobs_created_at_idx on jobs (created_at desc);

alter table jobs enable row level security;

create policy "Jobs are readable by authenticated users"
  on jobs for select
  using (auth.role() = 'authenticated');

create policy "Employers can insert jobs"
  on jobs for insert
  with check (auth.role() = 'authenticated');

create policy "Employers can update their own jobs"
  on jobs for update
  using (auth.role() = 'authenticated');

-- =============================================================================
-- APPLICATIONS (worker interest in jobs)
-- =============================================================================
create table if not exists applications (
  id uuid primary key default gen_random_uuid(),
  job_id text not null,
  worker_profile_id text not null,
  status text not null default 'interested' check (status in ('interested', 'shortlisted', 'hired', 'rejected')),
  applied_at timestamptz not null default now(),
  message text,
  ai_match_note text
);

create index if not exists applications_job_id_idx on applications (job_id);
create index if not exists applications_worker_idx on applications (worker_profile_id);

alter table applications enable row level security;

create policy "Applications are readable by authenticated users"
  on applications for select
  using (auth.role() = 'authenticated');

create policy "Workers can apply to jobs"
  on applications for insert
  with check (auth.role() = 'authenticated');

create policy "Employers can update applications for their jobs"
  on applications for update
  using (auth.role() = 'authenticated');

-- =============================================================================
-- CONVERSATIONS
-- =============================================================================
create table if not exists conversations (
  id uuid primary key default gen_random_uuid(),
  job_id text not null,
  employer_profile_id text not null,
  worker_profile_id text not null,
  last_message_text text,
  last_message_time timestamptz,
  unread_count_employer int not null default 0,
  unread_count_worker int not null default 0
);

alter table conversations enable row level security;

create policy "Conversation participants can read"
  on conversations for select
  using (auth.role() = 'authenticated');

create policy "Authenticated users can create conversations"
  on conversations for insert
  with check (auth.role() = 'authenticated');

create policy "Participants can update conversations"
  on conversations for update
  using (auth.role() = 'authenticated');

-- =============================================================================
-- MESSAGES
-- =============================================================================
create table if not exists messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id text not null,
  sender_profile_id text not null,
  content_type text not null default 'text' check (content_type in ('text', 'image', 'voice', 'location', 'quote')),
  content text not null default '',
  sent_at timestamptz not null default now(),
  read_at timestamptz,
  media_url text,
  audio_duration_sec int,
  location_point jsonb
);

create index if not exists messages_conversation_idx on messages (conversation_id, sent_at);

alter table messages enable row level security;

create policy "Conversation participants can read messages"
  on messages for select
  using (auth.role() = 'authenticated');

create policy "Authenticated users can send messages"
  on messages for insert
  with check (auth.role() = 'authenticated');

-- Enable realtime for messages (for live chat)
alter publication supabase_realtime add table messages;

-- =============================================================================
-- REVIEWS
-- =============================================================================
create table if not exists reviews (
  id uuid primary key default gen_random_uuid(),
  job_id text not null,
  reviewer_profile_id text not null,
  reviewee_profile_id text not null,
  rating int not null default 5 check (rating >= 1 and rating <= 5),
  comment text not null default '',
  created_at timestamptz not null default now()
);

alter table reviews enable row level security;

create policy "Reviews are readable by authenticated users"
  on reviews for select
  using (auth.role() = 'authenticated');

create policy "Authenticated users can create reviews"
  on reviews for insert
  with check (auth.role() = 'authenticated');

-- =============================================================================
-- NOTIFICATIONS
-- =============================================================================
create table if not exists notifications (
  id uuid primary key default gen_random_uuid(),
  profile_id text not null,
  type text not null default 'new_job_radius' check (type in ('new_job_radius', 'worker_interested', 'job_hired', 'new_message', 'review_received')),
  title_en text not null default '',
  title_ur text not null default '',
  body_en text not null default '',
  body_ur text not null default '',
  payload jsonb,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists notifications_profile_idx on notifications (profile_id, created_at desc);

alter table notifications enable row level security;

create policy "Users can read their own notifications"
  on notifications for select
  using (auth.role() = 'authenticated');

create policy "Authenticated users can create notifications"
  on notifications for insert
  with check (auth.role() = 'authenticated');

create policy "Users can update their own notifications"
  on notifications for update
  using (auth.role() = 'authenticated');

-- Enable realtime for notifications
alter publication supabase_realtime add table notifications;

-- =============================================================================
-- SEED DATA — Rozgar Demo Profiles & Jobs
-- =============================================================================

-- Insert profiles
insert into profiles (id, auth_identity_id, profile_type, display_name, profile_photo_url, city, home_location, is_verified, id_verification_status, account_status, onboarding_completion_pct) values
  ('00000000-0000-0000-0000-000000000001', 'auth-user-1', 'employer', 'Tariq Mahmood', 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80', 'Lahore', '{"lat": 31.5204, "lng": 74.3587, "address": "Main Boulevard, Gulberg III, Lahore"}', true, 'verified', 'active', 100),
  ('00000000-0000-0000-0000-000000000002', 'auth-user-1', 'worker', 'Muhammad Usman (Master Electrician)', 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&auto=format&fit=crop&q=80', 'Lahore', '{"lat": 31.522, "lng": 74.356, "address": "Liberty Market Area, Lahore"}', true, 'verified', 'active', 90),
  ('00000000-0000-0000-0000-000000000003', 'auth-user-2', 'worker', 'Rashid Ali (Master Plumber)', 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150&auto=format&fit=crop&q=80', 'Lahore', '{"lat": 31.518, "lng": 74.362, "address": "Ferozepur Road, Lahore"}', true, 'verified', 'active', 85),
  ('00000000-0000-0000-0000-000000000004', 'auth-user-3', 'worker', 'Bilal Ahmad (Bike Mechanic)', 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=150&auto=format&fit=crop&q=80', 'Lahore', '{"lat": 31.482, "lng": 74.325, "address": "Model Town, Lahore"}', true, 'verified', 'active', 95),
  ('00000000-0000-0000-0000-000000000005', 'auth-user-4', 'worker', 'Ms. Saima Bibi (House Cleaner)', 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150&auto=format&fit=crop&q=80', 'Lahore', '{"lat": 31.468, "lng": 74.401, "address": "DHA Phase 5, Lahore"}', true, 'verified', 'active', 90);

-- Insert worker details
insert into worker_details (profile_id, category_ids, bio, years_experience, rate_note, availability_status, notification_radius_km, is_online_for_map, current_location, portfolio_media, average_rating, total_jobs_completed, response_time_avg_minutes) values
  ('00000000-0000-0000-0000-000000000002', '{home-electrical,ac-appliance}', 'Certified electrician with 8 years of experience in solar wiring, UPS setup, AC gas refill, and short circuit repairs across Gulberg & Model Town.', 8, 'Rs. 1,500 visiting fee / job quote', 'today', 15, true, '{"lat": 31.522, "lng": 74.356, "address": "Liberty Market Area, Lahore"}', '{"https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=300&auto=format&fit=crop&q=80", "https://images.unsplash.com/photo-1581092160607-ee22621dd758?w=300&auto=format&fit=crop&q=80"}', 4.9, 42, 4),
  ('00000000-0000-0000-0000-000000000003', '{home-plumbing}', 'Expert plumber in sanitary fitting, water tank cleaning, and leak detection.', 6, 'Rs. 1,200 visiting charge', 'today', 12, true, '{"lat": 31.518, "lng": 74.362, "address": "Ferozepur Road, Lahore"}', '{}', 4.8, 28, 6),
  ('00000000-0000-0000-0000-000000000004', '{vehicle-repair}', 'Mobile bike tuning and emergency doorstep motorcycle repair for 70cc & 125cc.', 10, 'Rs. 800 tuning charge', 'today', 20, true, '{"lat": 31.482, "lng": 74.325, "address": "Model Town, Lahore"}', '{}', 5.0, 64, 3),
  ('00000000-0000-0000-0000-000000000005', '{cleaning-maid}', 'Deep house cleaning, sofa washing, and kitchen disinfection services.', 4, 'Rs. 2,000 per visit', 'today', 10, true, '{"lat": 31.468, "lng": 74.401, "address": "DHA Phase 5, Lahore"}', '{}', 4.9, 35, 5);

-- Insert jobs
insert into jobs (id, employer_profile_id, category_id, title, description, ai_extracted_summary, budget_amount, budget_type, pin_location, status, urgency, created_at) values
  ('00000000-0000-0000-0000-000000000010', '00000000-0000-0000-0000-000000000001', 'home-electrical', 'Short Circuit & Ceiling Fan Installation in Gulberg III', 'Main DB breaker keeps tripping and need 2 ceiling fans installed in guest room.',
   '{"category": "Electrical Work", "urgency": "instant", "suggestedBudget": 2500, "estimatedDuration": 2, "requiredSkills": ["Wiring", "Breaker Repair", "Fan Fitting"]}'::jsonb,
   2500, 'fixed', '{"lat": 31.5204, "lng": 74.3587, "address": "Gulberg III, Lahore"}', 'open', 'instant', now() - interval '30 minutes'),
  ('00000000-0000-0000-0000-000000000011', '00000000-0000-0000-0000-000000000001', 'home-plumbing', 'Water Motor Repair & Roof Leakage Fix', '1.5 HP water pump motor is burnt and leaking pipe under kitchen sink.',
   '{"category": "Plumbing", "urgency": "today", "suggestedBudget": 3500, "estimatedDuration": 3, "requiredSkills": ["Motor Rewinding", "Pipe Fitting", "Sanitary"]}'::jsonb,
   3500, 'fixed', '{"lat": 31.4697, "lng": 74.4027, "address": "DHA Phase 5, Lahore"}', 'open', 'today', now() - interval '2 hours');

-- Insert application
insert into applications (id, job_id, worker_profile_id, status, applied_at, message, ai_match_note) values
  ('00000000-0000-0000-0000-000000000020', '00000000-0000-0000-0000-000000000010', '00000000-0000-0000-0000-000000000002', 'interested', now() - interval '15 minutes',
   'Assalam-o-Alaikum! I am 1.2 km away in Gulberg and ready to come with tools immediately.',
   '⚡ Top match! 4.9★ in Electrical, 1.2 km away, responds in 4 mins.');

-- Insert conversation
insert into conversations (id, job_id, employer_profile_id, worker_profile_id, last_message_text, last_message_time, unread_count_employer, unread_count_worker) values
  ('00000000-0000-0000-0000-000000000030', '00000000-0000-0000-0000-000000000010', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000002',
   'I can be there in 15 minutes with my multimeter & ladder.', now() - interval '10 minutes', 1, 0);

-- Insert messages
insert into messages (id, conversation_id, sender_profile_id, content_type, content, sent_at) values
  ('00000000-0000-0000-0000-000000000040', '00000000-0000-0000-0000-000000000030', '00000000-0000-0000-0000-000000000001', 'text',
   'Assalam-o-Alaikum Usman, can you fix the short circuit right now?', now() - interval '12 minutes'),
  ('00000000-0000-0000-0000-000000000041', '00000000-0000-0000-0000-000000000030', '00000000-0000-0000-0000-000000000002', 'text',
   'Walaikum Assalam Tariq Sb! Yes I am in Liberty Market right now. I can be there in 15 minutes with my tools.', now() - interval '10 minutes');

-- Insert review
insert into reviews (id, job_id, reviewer_profile_id, reviewee_profile_id, rating, comment, created_at) values
  ('00000000-0000-0000-0000-000000000050', 'job-old-1', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000002', 5,
   'Excellent work! Solved solar wiring issue quickly and explained everything politely.', now() - interval '5 days');

-- Insert notification
insert into notifications (id, profile_id, type, title_en, title_ur, body_en, body_ur, is_read, created_at) values
  ('00000000-0000-0000-0000-000000000060', '00000000-0000-0000-0000-000000000001', 'worker_interested',
   'Worker Interested in your Job', 'کاریگر نے آپ کے کام میں دلچسپی ظاہر کی',
   'Muhammad Usman expressed interest in "Short Circuit & Ceiling Fan Installation".',
   'محمد عثمان نے آپ کے پوسٹ کردہ کام میں دلچسپی ظاہر کی ہے۔',
   false, now());
