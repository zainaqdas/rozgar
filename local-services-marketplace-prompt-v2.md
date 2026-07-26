# AI Builder Prompt: Local Services Marketplace App (v2)

Copy everything below this line into your AI builder tool (Bolt, Lovable, Cursor, v0, Claude, etc.).

---

## 1. Project Overview

Build a two-sided, GPS-driven mobile marketplace app connecting **employers** (people who need small, one-off, or short-term local jobs done) with **workers** (skilled and unskilled local labor: electricians, plumbers, cleaners, drivers, tutors, laborers, technicians, etc.).

The interaction model takes direct inspiration from **ride-booking apps (Uber/Careem)** and **food delivery apps**: location is confirmed via an interactive map pin before any action, jobs are pushed to nearby eligible workers in real time, and workers accept/decline much like accepting a ride request. This is layered with a **Facebook-style rich profile system** for trust and matching quality.

Primary launch market is **Pakistan** (starting with a single city, e.g. Lahore). The app must support **Urdu and English**, work well on **low-end Android devices** and **inconsistent mobile data**, and default currency to **PKR**.

**Location access is mandatory for the app to function** — both posting a job and browsing/receiving jobs require GPS to be enabled.

---

## 2. Tech Stack

- **Mobile app:** Flutter (Dart), Android first, iOS second.
- **Backend:** Supabase — Postgres (with **PostGIS** enabled for radius/geo queries), Supabase Auth, Supabase Realtime (chat, live job feed, worker presence), Supabase Storage (photos/videos/portfolios/ID documents).
- **Push notifications:** Firebase Cloud Messaging (FCM), triggered via Supabase Edge Functions on relevant DB events (new job in radius, new interest, hire decision, new message).
- **AI:** Anthropic Claude API — Haiku for cheap/fast classification and extraction, Sonnet for profile generation and match explanations.
- **Maps/Location:** Google Maps Platform (Maps SDK, Places Autocomplete, Geocoding API) — used for both the job-posting pin-drop flow and the live nearby-workers map.
- **Localization:** Flutter `intl`, full Urdu + English, RTL-aware rendering for Urdu strings, Noto Nastaliq Urdu font.
- **State management:** Riverpod, used consistently throughout.

Do not introduce a separate backend API layer unless a feature genuinely cannot be done via Supabase Edge Functions.

---

## 3. Account & Profile Architecture (important — read carefully)

- **One login per person** — via phone number OR email, user's choice (present both options equally prominent at signup; do not default to email over phone or vice versa).
- After login, a user can create **one Employer profile and one Worker profile** under that same login — these are **separate profile entities** with fully separate data (name display, categories, bio, ratings, job history, settings), not a shared "mode toggle."
- If a user only ever creates one profile type, they never see the other's UI at all.
- If a user has both, provide a **profile switcher** (similar to switching Google accounts or Discord servers) accessible from the main menu/avatar — switching is an explicit action, and the two profiles never display merged/blended data.
- Ratings, reviews, and job history belong to the **profile**, not the underlying person — a Worker profile's rating is earned independently of any Employer profile activity by the same login.

**Data model implication:** `auth_identity` (the login/credential record) has a one-to-many relationship to `profiles`, where each profile has a `profile_type` of `employer` or `worker`, and all job/application/review/message records reference `profile_id`, not the raw login identity.

---

## 4. Data Model (Postgres via Supabase, with PostGIS)

**`auth_identities`**
id, phone_number (nullable, unique if set), email (nullable, unique if set), preferred_language (ur/en), created_at.

**`profiles`**
id, auth_identity_id (FK), profile_type (employer/worker), display_name, profile_photo_url, city, home_location (PostGIS geography point), created_at, is_verified, id_verification_status (none/pending/verified), account_status (active/suspended), onboarding_completion_pct.

**`worker_details`** (1:1 with a `profiles` row where profile_type = worker)
profile_id (FK), categories (join table to `categories`), bio, years_experience, rate_note, availability_status (today/tomorrow/weekdays/weekends/morning/evening/busy/offline), notification_radius_km (worker-configurable), is_online_for_map (bool — whether they appear on employer's nearby-workers map), current_location (PostGIS geography point, updated periodically while online), portfolio_media (array of URLs), average_rating, total_jobs_completed, response_time_avg_minutes, is_featured (monetization flag, later).

**`categories`** (seeded, hierarchical: parent_category, subcategory) — same category tree as before: Home (Plumbing, Electrical, Painting, Carpentry, Masonry), Vehicles (Mechanic, Bike Repair, Car Wash), Construction (Labor, Welding, Steel Fixing), Education (Tutor, Language Teacher), Technology (Laptop Repair, Mobile Repair, Web Developer), Events (Photographer, DJ, Cook), Delivery, Cleaning, Moving, Healthcare, Beauty, Pet Care, General Labor.

**`jobs`**
id, employer_profile_id (FK), category_id (FK), title, description (raw text), ai_extracted_summary (jsonb: category, urgency, suggested_budget, estimated_duration, required_skills), budget_amount, budget_type (fixed/hourly/negotiable), pin_location (PostGIS geography point — confirmed via map pin-drop, see Section 6), location_text (reverse-geocoded address string), status (open/hired/completed/cancelled/expired), urgency (instant/today/scheduled), scheduled_for (nullable), created_at.

**`applications`**
id, job_id (FK), worker_profile_id (FK), status (interested/shortlisted/hired/rejected), applied_at, message (optional).

**`conversations`** + **`messages`**
Scoped per (job_id, employer_profile_id, worker_profile_id). Messages: id, conversation_id, sender_profile_id, content_type (text/image/voice/location/file), content, sent_at, read_at.

**`reviews`**
id, job_id (FK), reviewer_profile_id, reviewee_profile_id, rating (1-5), comment, created_at. One review per direction per job.

**`favorites`**
profile_id, favorited_profile_id, created_at.

**`reports`**
id, reporter_profile_id, reported_profile_id, job_id (nullable), reason, details, status, created_at.

**`notifications`**
id, profile_id, type, payload (jsonb), is_read, created_at.

Use **PostGIS `ST_DWithin`** for all radius queries (worker's notification radius, employer's nearby-workers map, job-near-me fallback list) — do not implement radius filtering with naive lat/lng math.

---

## 5. Core Interaction Flows (build these exactly)

### 5.1 Location confirmation (ride-app style) — used both when posting a job AND when a worker sets/updates their location
- On first launch and whenever location is needed, request GPS permission; the app is non-functional without it (show a clear blocking screen explaining why if denied, with a retry/open-settings action).
- Show an interactive map centered on the device's current GPS position with a **fixed center pin** (map moves under the pin, exactly like Uber/Careem pickup selection).
- User can drag the map to adjust, use a "use my current location" recenter button, or search an address via Places Autocomplete.
- A **"Confirm this location"** button locks it in. The confirmed point is reverse-geocoded to a readable address string and stored alongside the raw coordinates.

### 5.2 Posting a job (Employer)
1. Employer taps "Post a Job."
2. Freeform text box: "What do you need done?" — sent to AI parsing (Section 7.1) which pre-fills category, urgency, suggested budget, estimated duration (all editable).
3. Location confirmation screen (Section 5.1) — defaults to employer's current GPS position but must be explicitly confirmed; employer can move the pin to a different address (e.g., posting a job for a different property).
4. Budget and scheduling fields (now/today/specific time).
5. Review screen → Post.
6. On posting, the system finds all Worker profiles where: category matches, `is_online_for_map`/availability isn't "offline," and the job's pin_location is within that worker's `notification_radius_km`. Each gets an FCM push: **"A [category] job is available near you — want to accept it?"**

### 5.3 Worker receives and responds to a job
- Push notification opens directly to the Job Detail screen with two primary actions: **"I'm Interested"** / **"Not now."**
- Additionally, the Worker Home screen always shows a **"Jobs near you"** list — every currently-open job within the worker's radius and category, refreshed live via Supabase Realtime. This is the fallback for missed/dismissed notifications (per your decision, discovery is push-first with this list as backup, not a full open-ended browse feed).
- Tapping "I'm Interested" creates an `applications` row (status: interested) and pushes a notification to the employer: **"[Worker name] is interested in your job."**

### 5.4 Employer reviews interest and hires
- Job Detail screen (employer view) shows a live-updating list of interested workers, each with: photo, rating, distance, response time, verified badge, AI match note (Section 7.3).
- Employer can either tap **"Hire"** directly on a worker, or tap to open **chat first**, then hire from within the chat screen.
- Hiring one worker sets that application to `hired`, sets the job status to `hired`, auto-sets all other applications on that job to `rejected` (with a polite in-app notification to those workers), and removes the job from other workers' "Jobs near you" lists in real time.

### 5.5 Nearby workers map (Employer)
- Separate tab/screen showing a live map (same visual style as a ride-app's "nearby drivers" view) of Worker profiles where `is_online_for_map` is true and within a reasonable default radius of the employer's confirmed location.
- Filter by category. Tapping a worker pin opens their public profile with a direct "Message" or "Invite to a job" action (lets an employer proactively reach out rather than only waiting for applications).

### 5.6 Job completion & review
- Either party can mark the job "Completed" (other party gets a confirmation prompt).
- On completion, both are prompted for a mandatory two-way star rating + optional comment.

---

## 6. Signup Flow

- Login via **phone number or email**, presented as two equally weighted options (not one default with the other as "optional").
- OTP/verification for whichever method is chosen.
- **Choose profile type to create first:** Employer or Worker (with a note that they can add the other type later from the profile switcher).
- **Progressive onboarding, not one long form:**
  - Minimum to get in: display name, primary category (Worker only), city/home location confirmation.
  - Immediately usable after this.
  - A visible **profile completion indicator** (e.g., "Profile 40% complete") nudges the user — especially Worker profiles — to add: additional categories, bio (or AI-generated bio, Section 7.2), experience, portfolio photos/videos, availability, service radius.
  - Employer profiles have a much lighter completion checklist (name, photo, location) since trust weight sits mostly on the Worker side.
- Category selection happens **at signup for Worker profiles** (required to start receiving job notifications), and is chosen per-job for Employer profiles (in addition to being selectable as employer's general interests if useful for future recommendations).

---

## 7. AI Integration Details

### 7.1 Job parsing (on "Post a Job")
Call Claude (Haiku) with a system prompt instructing it to return **only** a JSON object:
```
{
  "category": string (must match a seeded category name),
  "urgency": "instant" | "today" | "scheduled",
  "suggested_budget_pkr": number,
  "estimated_duration_hours": number,
  "required_skills": string[]
}
```
Always show as editable pre-filled fields — never auto-submit without employer confirmation.

### 7.2 Worker profile generation
"Let AI write my profile" — worker types rough freeform experience, Claude (Sonnet) returns a polished 2-3 sentence bio + suggested categories/skills, editable before saving. Offered during progressive onboarding, not forced upfront.

### 7.3 Smart matching / match notes
When an employer views interested workers, generate (weighted scoring function, not necessarily AI, for the ranking itself) a ranked order by distance, rating, category-specific completed jobs, availability match, response speed. Use Claude (Sonnet) only to generate a short one-line human-readable match note (e.g., "Closest match, 4.9★ in Plumbing, usually replies in 5 min") — not for the ranking computation itself, to keep latency and cost low.

### 7.4 Cost control
Haiku by default; Sonnet only for profile generation and match notes; never call AI on keystroke, only on explicit action (Post Job button, "Generate bio" button).

---

## 8. Screens (Phase 1 MVP)

1. Auth/Login (phone or email choice, OTP)
2. Profile type selection + progressive onboarding flow
3. Location confirmation (ride-app style pin-drop) — reusable component
4. Worker Home (Jobs near you list + notification-triggered job detail entry point)
5. Employer Home (Post a Job CTA + list of own posted jobs by status)
6. Post a Job flow (description → AI pre-fill → location confirm → budget/schedule → review)
7. Job Detail (Employer view — interested workers list, hire/chat actions)
8. Job Detail (Worker view — I'm Interested / Not now)
9. Nearby Workers map (Employer)
10. Worker Profile (own, editable, with completion indicator)
11. Worker Profile (public view, with reviews, hire/message/save actions)
12. Chat screen (text/image/voice/location, typing indicator, read receipts)
13. Ratings & Review screen (post-completion, mandatory two-way)
14. Notifications screen
15. Profile switcher (Employer ⇄ Worker, if both exist)
16. Settings (language, notification radius, verification, block/report management, delete account)

---

## 9. Role-Conditional Navigation

Bottom tab bar changes based on the **active profile**, not the login:
- **Employer active profile:** Home (own jobs), Post a Job, Nearby Workers map, Messages, Profile.
- **Worker active profile:** Home (jobs near you), Messages, Earnings/History, Profile.
- Profile switcher is accessible from the Profile tab in both cases, not a separate bottom tab.

---

## 10. Design & UX Guidelines

- Map-centric visual language throughout — the pin-drop location confirmation and nearby-workers/nearby-jobs maps should feel immediately familiar to anyone who has used Careem/Uber/Bykea.
- One-handed use on mid/low-end Android phones, large tap targets, photo-forward over text-dense.
- Full Urdu localization including correct font rendering and RTL text direction for Urdu strings.
- Skeleton loaders and optimistic UI for chat, job posting, and the interested-workers list, since users will often be on patchy 3G.
- Keep "Post a Job" (including location confirmation) achievable in under 45 seconds for a returning employer.

---

## 11. Non-Functional Requirements

- Background location updates for `is_online_for_map` workers must be battery-conscious (periodic updates, not continuous tracking) — clearly disclose this to users and let them toggle "online" off.
- Push notifications must reliably arrive even when the app is backgrounded/killed (test FCM background delivery explicitly).
- All radius/proximity queries via PostGIS `ST_DWithin`, indexed appropriately.
- Queue outgoing messages/job posts locally and sync when connectivity returns.
- Structure schema so payments (JazzCash/Easypaisa), video calling, and dispute resolution can be added later without major refactors.

---

## 12. Explicit Out-of-Scope for This Build

- In-app payments or escrow.
- Video/voice calling (chat only).
- AI fraud detection beyond basic report/block.
- Business/enterprise accounts and analytics dashboards.
- Recurring/scheduled service subscriptions.

---

## 13. Deliverable Expectations

A working Flutter app connected to a real Supabase project (schema + PostGIS + RLS policies included), all screens above implemented and navigable, seeded category data, working phone-or-email auth with OTP, the full location-confirmation component reused across posting and profile flows, a functioning end-to-end job-post → notification → interest → hire → chat → complete → review flow, the profile-switcher working for accounts with both profile types, and the AI job-parsing feature working against the Claude API. Include setup instructions for Supabase project creation (with PostGIS extension enabled), environment variables (Supabase URL/key, Google Maps API key, FCM config, Anthropic API key), and how to run the app locally.
