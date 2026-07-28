-- =============================================================================
-- ROZGAR — RLS: Prevent self-reviews on the reviews table
-- =============================================================================

-- Drop the overly permissive insert policy first
drop policy if exists "Authenticated users can create reviews" on reviews;

-- Re-create with a check that prevents self-review
create policy "Authenticated users can create reviews"
  on reviews for insert
  with check (
    auth.role() = 'authenticated'
    and reviewer_profile_id <> reviewee_profile_id
  );
