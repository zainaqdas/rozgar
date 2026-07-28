-- =============================================================================
-- ROZGAR — Supabase Storage buckets for photos, portfolios, CNIC docs
-- =============================================================================

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('avatars', 'avatars', true, 5242880, array['image/jpeg', 'image/png', 'image/webp']),
  ('portfolios', 'portfolios', true, 10485760, array['image/jpeg', 'image/png', 'image/webp', 'video/mp4']),
  ('cnic-docs', 'cnic-docs', false, 10485760, array['image/jpeg', 'image/png', 'application/pdf'])
on conflict (id) do nothing;

-- RLS: avatars — anyone can read, owners can write
create policy "Public read avatars"
on storage.objects for select
using (bucket_id = 'avatars');

create policy "Users upload own avatar"
on storage.objects for insert
with check (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "Users update own avatar"
on storage.objects for update
using (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
);

-- RLS: portfolios — anyone can read, owners can write
create policy "Public read portfolios"
on storage.objects for select
using (bucket_id = 'portfolios');

create policy "Users upload own portfolio"
on storage.objects for insert
with check (
  bucket_id = 'portfolios'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "Users delete own portfolio"
on storage.objects for delete
using (
  bucket_id = 'portfolios'
  and (storage.foldername(name))[1] = auth.uid()::text
);

-- RLS: cnic-docs — private, only owner can read/write
create policy "Users read own cnic"
on storage.objects for select
using (
  bucket_id = 'cnic-docs'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "Users upload own cnic"
on storage.objects for insert
with check (
  bucket_id = 'cnic-docs'
  and (storage.foldername(name))[1] = auth.uid()::text
);
