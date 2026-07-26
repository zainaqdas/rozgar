-- =============================================================================
-- SEED TEST DATA FOR ROZGAR END-TO-END TESTING
-- =============================================================================
-- Run this in Supabase SQL Editor AFTER the migration.sql has been applied.
--
-- Creates:
--   2 auth users: tariq@rozgar.pk (employer), usman@rozgar.pk (worker)
--   2 profiles, 1 worker_details, 2 jobs, 1 application, 1 conversation,
--   2 messages, 2 notifications
--
-- Auth users have confirmed emails so you can sign in immediately.
-- Password for both: test123456
-- =============================================================================

-- Enable pgcrypto for password hashing
create extension if not exists pgcrypto with schema extensions;

-- ==========================================
-- 1. AUTH USERS (in auth schema)
-- ==========================================

-- Employer: Tariq Mahmood
-- Helper function to safely create auth users
-- Uses auth.admin_create_user if available, otherwise direct insert
do $$
declare
  user_id uuid;
begin
  -- Employer: Tariq Mahmood
  if not exists (select 1 from auth.users where email = 'tariq@rozgar.pk') then
    user_id := extensions.gen_random_uuid();
    insert into auth.users (
      instance_id, id, aud, role,
      email, encrypted_password,
      email_confirmed_at, confirmation_sent_at,
      last_sign_in_at,
      raw_app_meta_data, raw_user_meta_data,
      created_at, updated_at
    ) values (
      '00000000-0000-0000-0000-000000000000',
      'a0000000-0000-0000-0000-000000000001',
      'authenticated',
      'authenticated',
      'tariq@rozgar.pk',
      extensions.crypt('test123456', extensions.gen_salt('bf')),
      now(), now(), now(),
      '{"provider":"email","providers":["email"]}',
      '{"display_name":"Tariq Mahmood"}',
      now(), now()
    );
  end if;

  -- Worker: Muhammad Usman
  if not exists (select 1 from auth.users where email = 'usman@rozgar.pk') then
    user_id := extensions.gen_random_uuid();
    insert into auth.users (
      instance_id, id, aud, role,
      email, encrypted_password,
      email_confirmed_at, confirmation_sent_at,
      last_sign_in_at,
      raw_app_meta_data, raw_user_meta_data,
      created_at, updated_at
    ) values (
      '00000000-0000-0000-0000-000000000000',
      'a0000000-0000-0000-0000-000000000002',
      'authenticated',
      'authenticated',
      'usman@rozgar.pk',
      extensions.crypt('test123456', extensions.gen_salt('bf')),
      now(), now(), now(),
      '{"provider":"email","providers":["email"]}',
      '{"display_name":"Muhammad Usman"}',
      now(), now()
    );
  end if;

  -- Worker 2: Rashid Ali
  if not exists (select 1 from auth.users where email = 'rashid@rozgar.pk') then
    user_id := extensions.gen_random_uuid();
    insert into auth.users (
      instance_id, id, aud, role,
      email, encrypted_password,
      email_confirmed_at, confirmation_sent_at,
      last_sign_in_at,
      raw_app_meta_data, raw_user_meta_data,
      created_at, updated_at
    ) values (
      '00000000-0000-0000-0000-000000000000',
      'a0000000-0000-0000-0000-000000000003',
      'authenticated',
      'authenticated',
      'rashid@rozgar.pk',
      extensions.crypt('test123456', extensions.gen_salt('bf')),
      now(), now(), now(),
      '{"provider":"email","providers":["email"]}',
      '{"display_name":"Rashid Ali"}',
      now(), now()
    );
  end if;
end $$;

-- ==========================================
-- 2. PROFILES
-- ==========================================

insert into public.profiles (id, auth_identity_id, profile_type, display_name, profile_photo_url, phone, city, home_location, created_at, is_verified, id_verification_status, account_status, onboarding_completion_pct)
values
(
  'profile-emp-1',
  'a0000000-0000-0000-0000-000000000001',
  'employer',
  'Tariq Mahmood',
  'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80',
  '+92 300 8451920',
  'Lahore',
  '{"lat": 31.5204, "lng": 74.3587, "address": "Main Boulevard, Gulberg III, Lahore", "city": "Lahore"}',
  now(),
  true,
  'verified',
  'active',
  100
)
on conflict (id) do update set display_name = excluded.display_name, auth_identity_id = excluded.auth_identity_id;

insert into public.profiles (id, auth_identity_id, profile_type, display_name, profile_photo_url, phone, city, home_location, created_at, is_verified, id_verification_status, account_status, onboarding_completion_pct)
values
(
  'profile-wrk-1',
  'a0000000-0000-0000-0000-000000000002',
  'worker',
  'Muhammad Usman (Master Electrician)',
  'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&auto=format&fit=crop&q=80',
  '+92 321 7654321',
  'Lahore',
  '{"lat": 31.522, "lng": 74.356, "address": "Liberty Market Area, Lahore", "city": "Lahore"}',
  now(),
  true,
  'verified',
  'active',
  90
)
on conflict (id) do update set display_name = excluded.display_name, auth_identity_id = excluded.auth_identity_id;

insert into public.profiles (id, auth_identity_id, profile_type, display_name, profile_photo_url, phone, city, home_location, created_at, is_verified, id_verification_status, account_status, onboarding_completion_pct)
values
(
  'profile-wrk-2',
  'a0000000-0000-0000-0000-000000000003',
  'worker',
  'Rashid Ali (Master Plumber)',
  'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150&auto=format&fit=crop&q=80',
  '+92 322 1234567',
  'Lahore',
  '{"lat": 31.518, "lng": 74.362, "address": "Ferozepur Road, Lahore", "city": "Lahore"}',
  now(),
  true,
  'verified',
  'active',
  85
)
on conflict (id) do update set display_name = excluded.display_name, auth_identity_id = excluded.auth_identity_id;

-- ==========================================
-- 3. WORKER DETAILS
-- ==========================================

insert into public.worker_details (
  profile_id, category_ids, bio, years_experience, rate_note,
  availability_status, notification_radius_km, is_online_for_map,
  current_location, portfolio_media,
  average_rating, total_jobs_completed, response_time_avg_minutes, is_featured
)
values
(
  'profile-wrk-1',
  array['home-electrical', 'ac-appliance'],
  'Certified electrician with 8 years of experience in solar wiring, UPS setup, AC gas refill, and short circuit repairs across Gulberg & Model Town.',
  8,
  'Rs. 1,500 visiting fee / job quote',
  'today',
  15,
  true,
  '{"lat": 31.522, "lng": 74.356, "address": "Liberty Market Area, Lahore", "city": "Lahore"}',
  array[
    'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=300&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1581092160607-ee22621dd758?w=300&auto=format&fit=crop&q=80'
  ],
  4.9,
  42,
  4,
  true
)
on conflict (profile_id) do nothing;

insert into public.worker_details (
  profile_id, category_ids, bio, years_experience, rate_note,
  availability_status, notification_radius_km, is_online_for_map,
  current_location, portfolio_media,
  average_rating, total_jobs_completed, response_time_avg_minutes, is_featured
)
values
(
  'profile-wrk-2',
  array['home-plumbing'],
  'Expert plumber in sanitary fitting, water tank cleaning, pipe repair and leak detection. Serving Ferozepur Road & surrounding areas.',
  6,
  'Rs. 1,200 visiting charge',
  'today',
  12,
  true,
  '{"lat": 31.518, "lng": 74.362, "address": "Ferozepur Road, Lahore", "city": "Lahore"}',
  array[]::text[],
  4.8,
  28,
  6,
  false
)
on conflict (profile_id) do nothing;

-- ==========================================
-- 4. JOBS
-- ==========================================

insert into public.jobs (
  id, employer_profile_id, category_id, title, description,
  ai_extracted_summary, budget_amount, budget_type,
  pin_location, location, status, urgency, created_at
)
values
(
  'job-101',
  'profile-emp-1',
  'home-electrical',
  'Short Circuit & Ceiling Fan Installation in Gulberg III',
  'Main DB breaker keeps tripping and need 2 ceiling fans installed in guest room.',
  '{"category": "Electrical Work", "urgency": "instant", "suggested_budget": 2500, "estimated_duration": 2, "required_skills": ["Wiring", "Breaker Repair", "Fan Fitting"]}',
  2500,
  'fixed',
  '{"lat": 31.5204, "lng": 74.3587, "address": "Gulberg III, Lahore", "city": "Lahore"}',
  extensions.ST_SetSRID(extensions.ST_MakePoint(74.3587, 31.5204), 4326),
  'open',
  'instant',
  now() - interval '30 minutes'
)
on conflict (id) do nothing;

insert into public.jobs (
  id, employer_profile_id, category_id, title, description,
  ai_extracted_summary, budget_amount, budget_type,
  pin_location, location, status, urgency, created_at
)
values
(
  'job-102',
  'profile-emp-1',
  'home-plumbing',
  'Water Motor Repair & Roof Leakage Fix',
  '1.5 HP water pump motor is burnt and leaking pipe under kitchen sink. Need an urgent plumber in Gulberg.',
  '{"category": "Plumbing", "urgency": "today", "suggested_budget": 3500, "estimated_duration": 3, "required_skills": ["Motor Rewinding", "Pipe Fitting", "Sanitary"]}',
  3500,
  'fixed',
  '{"lat": 31.5204, "lng": 74.3600, "address": "Gulberg III, Lahore", "city": "Lahore"}',
  extensions.ST_SetSRID(extensions.ST_MakePoint(74.3600, 31.5204), 4326),
  'open',
  'today',
  now() - interval '2 hours'
)
on conflict (id) do nothing;

-- ==========================================
-- 5. APPLICATIONS
-- ==========================================

insert into public.applications (id, job_id, worker_profile_id, status, applied_at, message, ai_match_note)
values
(
  'app-101',
  'job-101',
  'profile-wrk-1',
  'interested',
  now() - interval '15 minutes',
  'Assalam-o-Alaikum! I am 1.2 km away in Gulberg and ready to come with tools immediately.',
  '⚡ Top match! 4.9★ in Electrical, 1.2 km away, responds in 4 mins.'
)
on conflict (id) do nothing;

-- ==========================================
-- 6. CONVERSATIONS
-- ==========================================

insert into public.conversations (id, job_id, employer_profile_id, worker_profile_id, last_message_text, last_message_time, unread_count_employer, unread_count_worker)
values
(
  'conv-101',
  'job-101',
  'profile-emp-1',
  'profile-wrk-1',
  'I can be there in 15 minutes with my multimeter & ladder.',
  now() - interval '10 minutes',
  1,
  0
)
on conflict (id) do nothing;

-- ==========================================
-- 7. MESSAGES
-- ==========================================

insert into public.messages (id, conversation_id, sender_profile_id, content_type, content, sent_at)
values
(
  'msg-101',
  'conv-101',
  'profile-emp-1',
  'text',
  'Assalam-o-Alaikum Usman, can you fix the short circuit right now?',
  now() - interval '12 minutes'
)
on conflict (id) do nothing;

insert into public.messages (id, conversation_id, sender_profile_id, content_type, content, sent_at)
values
(
  'msg-102',
  'conv-101',
  'profile-wrk-1',
  'text',
  'Walaikum Assalam Tariq Sb! Yes I am in Liberty Market right now. I can be there in 15 minutes with my tools.',
  now() - interval '10 minutes'
)
on conflict (id) do nothing;

-- ==========================================
-- 8. NOTIFICATIONS
-- ==========================================

insert into public.notifications (id, profile_id, type, title_en, title_ur, body_en, body_ur, is_read, created_at, payload)
values
(
  'notif-101',
  'profile-emp-1',
  'worker_interested',
  'Worker Interested in your Job',
  'کاریگر نے آپ کے کام میں دلچسپی ظاہر کی',
  'Muhammad Usman expressed interest in "Short Circuit & Ceiling Fan Installation".',
  'محمد عثمان نے آپ کے پوسٹ کردہ کام میں دلچسپی ظاہر کی ہے۔',
  false,
  now() - interval '14 minutes',
  '{"jobId": "job-101"}'
)
on conflict (id) do nothing;
