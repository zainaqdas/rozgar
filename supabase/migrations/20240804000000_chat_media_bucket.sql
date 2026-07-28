-- =============================================================================
-- ROZGAR — Dedicated chat-media storage bucket
-- Separates chat media uploads from portfolio items (issue: chat media was
-- incorrectly uploading to the portfolios bucket).
-- =============================================================================

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('chat-media', 'chat-media', true, 10485760, array[
    'image/jpeg', 'image/png', 'image/webp', 'image/gif',
    'video/mp4',
    'audio/aac', 'audio/mpeg', 'audio/ogg', 'audio/wav',
    'application/pdf'
  ])
on conflict (id) do nothing;

-- RLS: chat-media — any authenticated user can read (conversations are
-- between two parties, media URLs are shared in messages).
-- Write access: authenticated users can upload into conversation folders.
create policy "Public read chat-media"
on storage.objects for select
using (bucket_id = 'chat-media');

create policy "Authenticated users upload chat media"
on storage.objects for insert
with check (
  bucket_id = 'chat-media'
  and auth.role() = 'authenticated'
);

create policy "Authenticated users delete own chat media"
on storage.objects for delete
using (
  bucket_id = 'chat-media'
  and auth.role() = 'authenticated'
);
