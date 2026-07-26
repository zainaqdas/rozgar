-- =============================================================================
-- CLEAR SEED CONTENT DATA
-- =============================================================================
-- Removes all demo jobs, applications, conversations, messages, notifications,
-- and worker_details from the seed test data.
-- Keeps auth users and profiles so test login still works (with zero content).
-- =============================================================================

delete from public.notifications
where id in ('notif-101');

delete from public.messages
where id in ('msg-101', 'msg-102');

delete from public.conversations
where id in ('conv-101');

delete from public.applications
where id in ('app-101');

delete from public.jobs
where id in ('job-101', 'job-102');

delete from public.worker_details
where profile_id in ('profile-wrk-1', 'profile-wrk-2');
