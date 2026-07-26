# Rozgar — Local Services Marketplace (Flutter)

## Overview

Rozgar is a mobile marketplace connecting employers with nearby skilled/unskilled workers in Lahore, Pakistan. Built with Flutter for Android/iOS/Web, with Urdu and English support.

**Tech Stack:** Flutter 3.x (Dart 3.12+), **Google Maps SDK (enabled)**, **Supabase (live + production-ready)** with PostGIS, ChangeNotifier state management.

---

## Current Status (as of latest update)

| Metric | Value |
|---|---|
| **Dart files** | 42 (lib/) |
| **Test files** | 19 |
| **Screens built** | 14 |
| **Flutter analyze** | **0 issues** |
| **Flutter test** | **131/131 passing** |
| **State management** | ChangeNotifier + Supabase persistence (no fallback data) |
| **Database** | Supabase live: 8 tables with **text IDs**, RLS, PostGIS (seed content data cleared) |
| **Auth** | 🔐 **Full email auth** — Sign In, Sign Up, Forgot Password all wired; post-confirmation onboarding redirect fixed |
| **Maps** | 🗺️ **Google Maps (live)** — API key configured; OSM as fallback |
| **Geocoding** | 🌍 Nominatim (free OSM API) — Pakistan-wide coverage |

### 🔐 Test Accounts

| Role | Email | Password | Profile |
|---|---|---|---|
| **Employer** | `tariq@rozgar.pk` | `test123456` | Tariq Mahmood — 0 jobs (seed content cleared) |
| **Worker** | `usman@rozgar.pk` | `test123456` | Muhammad Usman (Electrician) — no applications (seed content cleared) |
| **Worker 2** | `rashid@rozgar.pk` | `test123456` | Rashid Ali (Plumber) — no applications |

---

## ✅ What's Working End-to-End

| Flow | Status | Notes |
|---|---|---|
| **Email auth — Sign In** | ✅ Wired | `signInWithEmail()` calls Supabase `signInWithPassword` |
| **Email auth — Sign Up** | ✅ Wired | Full registration with name/email/password/confirm password + validation |
| **Email auth — Forgot Password** | ✅ Wired | Link on sign-in → confirmation dialog → sends Supabase password reset |
| **Post-confirmation onboarding redirect** | ✅ Fixed | New sign-ups now see profile choice + onboarding after email confirmation (not empty dashboard) |
| **Onboarding address picker** | ✅ Added | Map pin-drop picker + GPS auto-fetch instead of hardcoded Lahore dropdown |
| **Password visibility toggle** | ✅ Wired | Eye icon on all 3 password fields |
| **Employer login → see jobs** | ✅ Tested | Shows own jobs from Supabase (filtered by employer profile ID) |
| **Worker login → see nearby jobs** | ✅ Ready | Jobs filtered by radius + skill category |
| **Express interest (worker)** | ✅ Wired | Creates Application in Supabase + Notification for employer |
| **Hire worker (employer)** | ✅ Wired | Updates job status, rejects other apps, creates conversation |
| **Send messages** | ✅ Wired | Optimistic insert + Supabase persistence + conversation last_message sync |
| **Chat realtime** | ✅ Wired | Postgres changes subscription for live updates |
| **Conversation list** | ✅ Fixed | Chat tab shows real conversations instead of hardcoded dummy worker |
| **Notifications** | ✅ Wired | Realtime subscriptions + create in DB |
| **Post new job** | ✅ Wired | Creates in Supabase, notifies nearby workers (no more pre-filled demo data) |
| **Workers loaded from Supabase** | ✅ Fixed | `allWorkers` getter includes `_cachedWorkers` from DB |
| **Subscription guard** | ✅ Fixed | Both message channels + notification channel cleaned up on re-initialize |
| **Conversation last_message sync** | ✅ Fixed | `sendMessage()` now updates conversation in Supabase so other users see latest |
| **Bottom nav** | ✅ Fixed | Negative margin crash fixed with `Transform.translate` |
| **All PKs text IDs** | ✅ Migrated | UUID→TEXT columns to match Dart string IDs |
| **Dynamic realtime subscriptions** | ✅ Fixed | New conversations created at runtime now subscribe to realtime messages |
| **RLS policies** | ✅ Fixed | Proper `auth_identity_id = auth.uid()::text` checks on all tables |
| **Geolocation permission** | ✅ Wired | Map screen + onboarding both request location permission + GPS recenter |
| **Location picker on map** | ✅ Added | My Location button on nearby workers map + onboarding + job pin-drop with geolocator |
| **Google Maps integration** | ✅ Enabled | API key configured in AndroidManifest + web/index.html; `setUseGoogleMaps()` active |
| **Search & geocode** | ✅ Wired | Nominatim reverse + forward geocoding (Pakistan-wide); debounced search with enter-key support |
| **Job posting flow** | ✅ Fixed | Step 2 no longer blank; location pin-drop + budget/urgency/review steps all work |

---

## Project Structure

```
rozgar_app/
├── lib/
│   ├── main.dart              # App entry, Supabase init, Google Maps enable, splash screen
│   ├── app.dart               # RozgarShell with bottom nav + onboarding redirect
│   ├── data/categories.dart   # 10 categories, 8 Lahore locations
│   ├── models/                # 8 models with toJson/fromJson (snake_case)
│   ├── providers/
│   │   └── app_state.dart     # ChangeNotifier + SupabaseService (no fallback data)
│   ├── services/
│   │   ├── ai_service.dart
│   │   ├── map_service.dart   # Google Maps (default) / OSM provider selection
│   │   ├── supabase_config.dart  # Supabase init + singleton
│   │   └── supabase_service.dart # CRUD + email auth + forgot password + realtime
│   ├── screens/               # 14 screens (auth, chat, employer, worker, map, etc.)
│   ├── theme/                 # AppColors (teal/amber/slate) + AppTheme + AppFonts
│   ├── utils/                 # translations (70+ en/ur keys), formatters, geo
│   └── widgets/               # animations, error/empty states, loading, header, nav, map, pin-drop
├── supabase/
│   ├── migration.sql          # Original schema (for reference)
│   └── migrations/
│       ├── 20240725000000_initial_schema.sql
│       ├── 20240725000002_use_text_ids.sql    # UUID→TEXT + RLS policies
│       ├── 20240726000001_seed_test_data.sql   # 3 auth users + seed data (content cleared)
│       └── 20240727000001_clear_seed_content.sql  # Removed demo jobs/apps/conversations
├── test/                      # 19 test files, 131 tests
└── pubspec.yaml
```

---

## Key Changes This Session (Session 5)

### 🐛 Bug Fixes

| Issue | Severity | Fix |
|---|---|---|
| **OSM `animateTo` was silent no-op** | 🔴 Critical | `_osmController` was nullable and never initialized; now `final MapController()` with proper initialization |
| **Blank screen at job post step 2** | 🔴 Critical | `LayoutBuilder` + `ConstrainedBox` with `constraints.maxHeight * 0.85` in `SingleChildScrollView` Column gave infinite height → `Expanded` in `LocationPinDrop` couldn't resolve; replaced with `SizedBox(height: screenHeight * 0.75)` |
| **147px Google Maps overflow** | 🔹 Medium | Wrapped `GoogleMap` in `ClipRect`; made `RozgarMap` height optional (no default 360) |
| **Dragging map closes bottom sheet** | 🔹 Medium | Added `enableDrag: false` to `showModalBottomSheet`; added close button via `onClose` callback |
| **Pin not tracking camera position** | 🔹 Medium | Added `_lastCenter` tracking for Google Maps via `_onGmapCameraMove`; `animateTo` now fires callbacks after Google Maps animation; `currentCenter` getter works for both providers |
| **Nominatim requests failing on web** | 🔹 Medium | Removed custom `User-Agent` header (causes CORS preflight failure on web; browser sends UA automatically) |
| **Search suggestions not appearing** | 🔹 Medium | Added 400ms debounce; `_onSearchChanged` was firing on every keystroke without debounce |
| **Enter key doesn't navigate to city** | 🔹 Low | Added `onSubmitted` + `textInputAction: TextInputAction.search` + `_selectFirstResult()` |
| **ListTile ink splash invisible** | 🔹 Low | Wrapped search results `ListView` in `Material(color: Colors.transparent)` |
| **Google Maps dispose-before-buildView** | 🔹 Low | Wrapped `_gmapController?.dispose()` in try-catch |

### 📦 What Changed

| File | Change |
|---|---|
| `lib/main.dart` | Added `MapService.instance.setUseGoogleMaps()` after Supabase init |
| `lib/widgets/rozgar_map.dart` | Fixed `_osmController` init (non-nullable); added `_lastCenter` + `_onGmapCameraMove` for Google Maps tracking; `animateTo` fires callbacks after GMaps animation; `currentCenter` getter replaces `currentOsmCenter`; `ClipRect` wraps Google Maps; height made optional (no default 360); `CancellableNetworkTileProvider` as default tile provider; `tileProvider` param for testing; try-catch on `_gmapController.dispose()` |
| `lib/widgets/location_pin_drop.dart` | Map area uses `Expanded` instead of fixed 360px; Google Maps-style teardrop pin (stacked shadow + main + white dot); `onSubmitted` + `textInputAction.search` on search field; 400ms debounce via `_searchTaskId`; `_selectFirstResult()` for enter key; `_shortenName()` for long Nominatim results; "No locations found" message; `_syncCenterAndGeocode()` for accurate pin position; `Material` wrapper around search ListView; `clipBehavior: Clip.hardEdge` on outer Container |
| `lib/screens/auth/auth_screen.dart` | Added `enableDrag: false` to `showModalBottomSheet`; added `onClose` callback |
| `lib/screens/employer/post_job_flow.dart` | Step 2 replaced `LayoutBuilder` + `ConstrainedBox` with `SizedBox(height: screenHeight * 0.75)` |
| `lib/utils/geo.dart` | Removed `User-Agent` header from `reverseGeocode` and `searchLocations` (CORS fix); removed `countrycodes=pk` restriction |
| `android/app/src/main/AndroidManifest.xml` | Replaced `YOUR_GOOGLE_MAPS_API_KEY` with live key |
| `web/index.html` | Added `async` + `&loading=async` to Google Maps script tag |
| `test/widgets/rozgar_map_test.dart` | Updated pin tests (2 icons → `findsNWidgets(2)`); renamed `currentOsmCenter` → `currentCenter`; test helper wraps in `SizedBox(height: height ?? 360)` |

---

## Future Goals (Priority Order — aligned with v2 prompt)

### Phase 1 — Core (In Progress)
1. ~~**Supabase backend** — Live project, PostGIS, all tables~~ ✅ **DONE**
2. ~~**Test accounts & seed data** — 3 auth users with profiles~~ ✅ **DONE**
3. ~~**Email auth** — Supabase email+password sign-in~~ ✅ **DONE**
4. ~~**Sign-up flow** — Registration UI with validation~~ ✅ **DONE**
5. ~~**Password visibility toggle** — Eye icon on password fields~~ ✅ **DONE**
6. ~~**Forgot Password** — Reset link via Supabase~~ ✅ **DONE**
7. ~~**Codebase audit & fixes** — RLS, dead code, subscriptions, camelCase keys~~ ✅ **DONE**
8. ~~**Post-confirmation onboarding redirect** — New sign-ups see profile choice after email confirm~~ ✅ **FIXED**
9. ~~**Remove all hardcoded fallback/demo data** — Profiles, jobs, worker stats, display names, DB seed content~~ ✅ **DONE**
10. ~~**Fix profile ID collision (409 / profile switching)** — Auth UUID as profile ID, `upsert` instead of `insert`~~ ✅ **DONE**
11. ~~**Google Maps API key** — Configured and enabled; switched from OSM default~~ ✅ **DONE**
12. **Phone OTP auth** — Wire up actual SMS via Supabase Auth; present phone + email equally at signup
13. **PostGIS `ST_DWithin` queries** — Replace client-side Haversine with server-side radius queries
14. **Claude AI integration** — Wire `AIService` to actual Claude API (Haiku for job parsing, Sonnet for bio/match notes)

### Phase 2 — Feature Completion
15. **Conversation list screen** — Build real inbox with unread badges, swipe-to-delete, preview
16. **FCM push notifications** — New job alerts, hire updates, chat messages via Supabase Edge Functions
17. **Categories table in DB** — Migrate from Dart constant to Supabase `categories` table with subcategories
18. **Reports & moderation** — Implement `reports` table, user reporting in settings, content moderation
19. **Worker background location** — Battery-conscious periodic updates for `is_online_for_map` presence
20. **Offline queue** — Cache jobs/messages locally, sync on reconnect
21. **Subscription/payment flow** — JazzCash, EasyPaisa for job fees

### Phase 3 — Polish & Scale
22. **Error boundaries** — Catch async errors globally, show ErrorState with retry
23. **Performance** — Lazy loading, pagination, shimmer polish
24. **Accessibility** — Full Urdu RTL layout, screen reader support
25. **iOS build** — Maps SDK, push certificates, App Store
26. **Admin panel** — User management, analytics dashboard

---

## Configuration

### Supabase
- **Project:** `hjnhudboyjkagicosrba`
- **URL:** `https://hjnhudboyjkagicosrba.supabase.co`
- **Tables:** 8 — profiles, worker_details, jobs, applications, conversations, messages, reviews, notifications
- **Auth:** Email auth enabled (sign in, sign up, password reset), phone OTP pending
- **CLI:** Linked via `supabase link --project-ref hjnhudboyjkagicosrba`
- **Seed content cleared:** Demo jobs, applications, conversations, messages, notifications, worker_details removed. Auth users and profiles kept for test login.

### Google Maps
- **API Key:** `AIzaSyD8nCVglIBmZ7YYFfogyMJWUCHX96wlCmY` (development/demo key)
- **Android:** `android/app/src/main/AndroidManifest.xml` — key injected
- **Web:** `web/index.html` — key injected with `async` + `loading=async`
- **Enabled:** `MapService.instance.setUseGoogleMaps()` called in `main.dart`

### Running Locally
```bash
cd rozgar_app
flutter run -d web-server --web-port 8080
```

---

## Technical Notes

- **Flutter SDK:** `^3.12.2` (3.44.6 installed) — supports wildcard `_` params, null-aware collection elements
- **State:** `ChangeNotifier` singleton — v2 prompt specifies **Riverpod**; consider migrating for better testability and code splitting
- **Profile IDs:** Employer profiles use `_authIdentity!.id` (auth UUID), worker profiles use `'wrk-$authId'` to avoid ID collision between dual profiles
- **Database inserts:** `createProfile` uses `.upsert()` instead of `.insert()` to handle retries without 409
- **Navigation:** `setState`-based view switching — keeps state simple and synchronous
- **Supabase:** `supabase_flutter: ^2.8.4` (2.16.0 installed), uses `publishableKey`
- **Realtime:** `onPostgresChanges` + `PostgresChangeEvent.insert` + `PostgresChangeFilter`
- **PostGIS:** `extensions.geometry(point, 4326)` for spatial queries (currently client-side Haversine; switch to `ST_DWithin`)
- **Maps:** Google Maps (`google_maps_flutter`) enabled by default; OSM (`flutter_map`) with `CancellableNetworkTileProvider` as fallback
- **Geolocation:** `geolocator: ^13.0.2` for GPS permission + current position on map + onboarding location auto-detect
- **Geocoding:** Nominatim (free OSM API, no key) — `reverseGeocode()` + `searchLocations()` with Pakistan-wide coverage; mock fallback when offline
- **Map controller:** `RozgarMapController` exposes `currentCenter` getter for both OSM and Google Maps; `animateTo()` fires `onCameraMove`/`onCameraIdle` on Google Maps
- **Locations:** All primary keys are TEXT type to match Dart string IDs
- **Auth users are seeded directly** in `auth.users` with `extensions.crypt()` — email confirmed
- **Optimistic updates:** UI updates immediately, Supabase calls are fire-and-forget
- **AI service:** Stub — needs wiring to actual Claude API (Haiku/Sonnet)
- **Test suite:** 131 tests across 19 files (models, services, providers, widgets, utils)
- **Key Flutter Analyze:** 0 issues
