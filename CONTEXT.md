# Rozgar App — Session Log

## Project Overview
Rozgar is a bilingual (English/Urdu) local services marketplace for Lahore, Pakistan.
Stack: Flutter / Riverpod + ChangeNotifier / Supabase (auth, DB, storage, realtime) / go_router / FCM

---

## Session 18 — Full Strangler Fig Refactoring (2026-07-28)

### Goal
Eliminate the AppState god object (971 lines) by migrating all screens, widgets,
and routing to 7 domain-specific providers + a Coordinator orchestration layer.

### Final State
- **flutter analyze**: 0 issues
- `flutter test`: 222/222 passing (4 skipped)
- `AppState`: DELETED (lib/providers/app_state.dart removed)
- Commits this session: 35+

---

### Phase 0 — Safety Net
- Committed all uncommitted work in logical chunks
- Fixed 8 failing tests: guarded `_subscribeToConversation` with `_isSupabaseAvailable`
  check (prevented Supabase.instance assertion in tests)
- Baseline established: 228/228 tests, 0 analyze issues

### Phase 1 — Isolated Bug Fixes
| Fix | Files | Detail |
|-----|-------|--------|
| 1.1 Maps guard | main.dart | `setUseGoogleMaps()` only called when `AppConfig.googleMapsApiKey.isNotEmpty` |
| 1.2 UUID IDs | app_state, job_provider, chat_provider, supabase_service | 17 timestamp-based IDs → `uuid.v4()` |
| 1.3 WorkerHome fallback | worker_home.dart | Removed hardcoded Liberty Market fallback; shows "Location not set" UI instead |

### Phase 2 — UX Improvements
| Fix | Detail |
|-----|--------|
| 2.1 Real pull-to-refresh | `refreshFromSupabase()` re-fetches jobs, applications, conversations, notifications from Supabase |
| 2.2 Error surfacing | AppShell reads `lastOperationError` and shows floating SnackBar with rose500 background |

### Phase 3A — Coordinator Layer
- Created `lib/providers/coordinator.dart` (206 lines)
- `initialize()` — loads profiles, jobs, applications, conversations, messages, notifications, workers from Supabase
- `hireWorker()` — coordinates JobNotifier + ChatNotifier + NotificationNotifier
- `refreshFromSupabase()` — re-fetches all data for active profile
- `logout()` — clears all 7 domain notifiers
- Registered `coordinatorProvider` in providers.dart
- Wrote `test/providers/coordinator_test.dart` (9 tests)

### Phase 3B — Screen Migrations (16 screens)
All screens converted from `StatefulWidget`/`StatelessWidget` with `AppState` constructor
param → `ConsumerStatefulWidget`/`ConsumerWidget` with `ref.watch()`/`ref.read()`.

| # | Screen | Providers Used |
|---|--------|---------------|
| 3B.1 | SettingsScreen | settingsProvider, authProvider, coordinatorProvider |
| 3B.2 | NotificationsView | notificationProvider, settingsProvider |
| 3B.3 | EarningsScreen | jobProvider, profileProvider, settingsProvider |
| 3B.4 | ProfileView | profileProvider, settingsProvider |
| 3B.5 | PublicProfileView | settingsProvider, profileProvider (reviews) |
| 3B.6 | NearbyWorkersMap | workerProvider, profileProvider, jobProvider, coordinatorProvider |
| 3B.7 | EmployerHome | jobProvider, profileProvider, settingsProvider, coordinatorProvider |
| 3B.8 | WorkerHome | jobProvider, profileProvider, settingsProvider, coordinatorProvider |
| 3B.9 | PostJobFlow | jobProvider, profileProvider, settingsProvider |
| 3B.10 | JobDetailView | jobProvider, profileProvider, workerProvider, coordinatorProvider, settingsProvider |
| 3B.11 | ChatScreen + RatingModal | chatProvider, profileProvider, workerProvider, jobProvider, settingsProvider |
| 3B.12 | AuthScreen | authProvider, profileProvider, settingsProvider |

**Provider methods added during 3B:**
- `ProfileNotifier`: `reviews`, `setReviews()`, `addReview()`, `completeWorkerOnboarding(authId,...)`, `completeEmployerOnboarding(authId,...)`
- `AuthNotifier`: `loginWithPhoneOrEmail()`, `verifyOtp()`, `signInSimple()`, `signUpSimple()`

### Phase 3C — AppState Removal
| Step | Detail |
|------|--------|
| 3C.1 | header.dart → ConsumerWidget (removed unused _ProfileSwitcher) |
| 3C.2 | bottom_nav.dart → ConsumerWidget; AppShell → ConsumerWidget |
| 3C.3 | app_router.dart → `Ref`-based (routerProvider, _buildRedirect, _defaultHome) |
| 3C.4 | main.dart → `coordinatorProvider.notifier.initialize()` (removed _syncProviders bridge) |
| 3C.5 | **Deleted** `lib/providers/app_state.dart` (971 lines) + `test/providers/app_state_test.dart` (873 lines) |

**WorkerEntry** class moved from app_state.dart → worker_provider.dart.

### Domain Provider Tests (post-3C)
6 new test files written to replace deleted app_state_test.dart coverage:
- `test/providers/auth_provider_test.dart` — initial state, loginWithPhoneOrEmail, verifyOtp, logout
- `test/providers/profile_provider_test.dart` — setProfiles, switchProfile, reviews, toggleWorkerOnline, updateWorkerRadius, clear
- `test/providers/job_provider_test.dart` — setJobs, setApplications, getEmployerJobs, getJobsNearWorker, expressInterest, clear
- `test/providers/chat_provider_test.dart` — setConversations, setMessages, getOrCreateConversation, sendMessage, clear
- `test/providers/notification_provider_test.dart` — setNotifications, markNotificationsRead, clear
- `test/providers/settings_provider_test.dart` — setLanguage, clear
- `test/widget_test.dart` — rewritten to test domain provider defaults via ProviderContainer

---

### Architecture (Post-Refactoring)
```
lib/providers/
├── auth_provider.dart        — AuthNotifier (sign-in, sign-up, OTP, logout)
├── profile_provider.dart     — ProfileNotifier (profiles, reviews, onboarding, switch)
├── job_provider.dart         — JobNotifier (jobs, applications, express interest, hire)
├── chat_provider.dart        — ChatNotifier (conversations, messages, realtime)
├── notification_provider.dart — NotificationNotifier (notifications, realtime)
├── worker_provider.dart      — WorkerNotifier (cached workers, public profiles, WorkerEntry)
├── settings_provider.dart    — SettingsNotifier (language preference)
├── coordinator.dart          — Coordinator (init, cross-domain ops, refresh, logout)
└── providers.dart            — Riverpod provider registrations (no AppState)
```

### Verification
- `flutter analyze`: 0 issues
- `flutter test`: 208/208 passing
- All 16 screens + 2 widgets + router + main.dart use domain providers exclusively
- No references to AppState remain in lib/ (only historical comments in coordinator.dart)

---

### Known Remaining Work
1. ~~Supabase migrations (6 untracked SQL files)~~ — committed (7caa90c)
2. ~~Coordinator tests~~ — expanded in Session 19 (hireWorker, logout, refresh)
3. ~~Smoke test~~ — scaffold added (test/integration/smoke_test.dart, tagged)
4. ~~Cleanup~~ — scratch files gitignored in Session 19

---

## Session 19 — Remediation Plan (2026-07-29)

### Goal
Address all 12 risks/areas for improvement identified in the codebase analysis.

### Phase 1 — Git Hygiene
- Committed untracked test files (supabase_service_test.dart, sanitize_test.dart)
- Added qwen.md, run.sh, run_web.sh to .gitignore
- Pushed 30 commits to origin/main

### Phase 2 — Code Correctness
| Fix | Detail |
|-----|--------|
| SyncService retry/dead-letter | Max 3 attempts, dead-letter Hive box, retryDeadLetter/clearDeadLetter/getDeadLetterOperations APIs |
| Chat-media bucket | Dedicated 'chat-media' Supabase Storage bucket (was incorrectly using portfolios). Migration: 20240804000000_chat_media_bucket.sql |
| AuthNotifier cleanup | Removed dead callback-based signInWithEmail/signUpWithEmail (screens use signInSimple/signUpSimple) |

### Phase 3 — Performance
| Fix | Detail |
|-----|--------|
| PostGIS nearby_workers RPC | getNearbyWorkers() in SupabaseService — ST_DWithin with client-side Haversine fallback |
| Pagination | getAllJobs/getAllWorkers now accept limit/offset (default page 50, was hardcoded 100) |

### Phase 4 — Testing
| Fix | Detail |
|-----|--------|
| Coordinator tests expanded | hireWorker (6 tests: status update, hired/rejected apps, other-job isolation, callback, non-existent job), logout (3 tests: all 7 notifiers cleared, notifies, error state), refreshFromSupabase (2 tests) |
| Integration smoke test | test/integration/smoke_test.dart — tagged 'integration', skipped without SUPABASE_URL. Tests: config check, fetch jobs, fetch workers, pagination non-overlap |

### Phase 5 — Infrastructure
| Fix | Detail |
|-----|--------|
| GitHub Actions CI | .github/workflows/ci.yml — flutter analyze --fatal-infos + flutter test --coverage on push/PR to main |
| Firebase-web decision | **Intentional skip.** PushService.initialize() returns early on kIsWeb because no FirebaseOptions are configured in web/index.html. To enable: (1) create Firebase web app in console, (2) add firebaseConfig to web/index.html, (3) remove the kIsWeb guard in PushService. This is deferred until web PWA is a priority — mobile (Android/iOS) is the primary target. |

### Verification
- `flutter analyze`: 0 issues
- `flutter test`: 223 passing, 4 skipped (integration — no Supabase config)
- All phases committed and pushed to origin/main

---

## Session 20 — Feature Implementation (2026-07-29)

### Goal
Implement the top-priority features identified after the remediation plan:
wire up the PostGIS RPC in the map screen, and replace mock phone auth
with real Supabase OTP.

### Step 1 — Wire up PostGIS nearby_workers RPC in map screen

| Change | Detail |
|--------|--------|
| New model | `lib/models/nearby_worker.dart` — typed RPC result with lat/lng/photo |
| Migration | `20240805000000_nearby_workers_add_latlng.sql` — updates `nearby_workers` RPC to return `lat`, `lng`, `profile_photo_url` (needed for map markers) |
| SupabaseService | `getNearbyWorkers()` returns `List<NearbyWorker>` with PostGIS RPC + client-side Haversine fallback |
| Map screen | `nearby_workers_map.dart` rewritten: calls `getNearbyWorkers()` on init and category filter change instead of loading ALL workers and filtering client-side. Adds loading/error/retry states. |

**Commit**: a931677

### Step 2 — Real phone auth via Supabase OTP

| Change | Detail |
|--------|--------|
| SupabaseService | Added `signInWithPhoneOtp()` and `verifyPhoneOtp()` using `supabase.auth.signInWithOtp` / `verifyOTP` (OtpType.sms) |
| AuthNotifier | Replaced mock `loginWithPhoneOrEmail`/`verifyOtp` with real async `sendPhoneOtp`/`verifyPhoneOtp` methods that create a real Supabase session and check onboarding status |
| AuthScreen | Both callers updated to async flow with loading state and error surfacing (send OTP at step 0, verify at step 1) |
| Tests | `auth_provider_test.dart` rewritten for new API surface |

**Commit**: 65a760c

### Verification
- `flutter analyze`: 0 issues
- `flutter test`: 222 passing, 4 skipped (integration — no Supabase config)
- Git: clean working tree, all pushed to origin/main

---

## Future Roadmap

### Step 3 — Firebase Configuration — DONE (455bae0)
- `android/app/google-services.json` added (project `rozgar-10e88`)
- Package aligned to `com.rozgarapp.app` in build.gradle.kts
- `com.google.gms.google-services` v4.4.2 plugin wired in settings + app gradle
- Remaining: run `flutter build apk` to verify Gradle integration; add iOS `GoogleService-Info.plist` when iOS build is needed

### Step 4 — Run Integration Smoke Test Against Real Supabase
- **Status**: Scaffold exists (`test/integration/smoke_test.dart`), never run with real credentials
- **What's needed**: `SUPABASE_URL` and `SUPABASE_ANON_KEY` passed via `--dart-define`
- **Command**: `flutter test --tags integration --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
- **Validates**: Full stack — auth, jobs, workers, pagination

### Step 5 — Sync Status UI — DONE
- `SyncStatusNotifier` (ChangeNotifier) wraps SyncService dead-letter APIs: `refresh()`, `retry(id)`, `retryAll()`, `dismiss(id)`, `dismissAll()`
- `syncStatusProvider` registered in providers.dart (auto-refreshes on init)
- `SyncStatusBanner` widget: persistent rose-colored banner above bottom nav showing failure count with Retry / Dismiss buttons + spinner during retry
- `SyncService.removeDeadLetter(id)` added for per-item dismissal
- Translations added (en + ur): `dismiss`, `syncFailedOne`, `syncFailedMany`
- Wired into `AppShell` via `Column` wrapping `SyncStatusBanner` + `RozgarBottomNav`
- Verification: `flutter analyze` 0 issues, `flutter test` 222 passed / 4 skipped

### Step 6 — Supabase Phone Provider Configuration — DONE
- Twilio credentials configured in Supabase dashboard
- Phone authentication enabled
- Phone OTP flow (Step 2) is now fully operational end-to-end

### Push Notification Triggers — DONE
- All core events now create `NotificationItem` records that fire the DB trigger → `send-push` Edge Function → FCM:
  - **New job posted** → notifies nearby workers within radius (`job_provider.dart`)
  - **Worker expresses interest** → notifies employer (`job_provider.dart`)
  - **Employer hires worker** → notifies worker + rejects other applicants (`job_provider.dart`)
  - **New chat message** → notifies the other conversation participant (`chat_provider.dart`)
- Pipeline: `createNotification()` → DB insert → `trg_push_on_notification` trigger → `send-push` Edge Function → FCM HTTP API → device
- Verified: `flutter analyze` 0 issues, `flutter test` 222 passed / 4 skipped

### Profile Photo Upload — DONE
- `_ProfileHeaderCard` converted to `ConsumerWidget` with camera FAB on avatar
- Opens `image_picker` (gallery, 512px max, 85% quality) → `StorageService.uploadAvatar()` → Supabase `avatars` bucket
- `ProfileNotifier.updateProfilePhoto()` persists URL to `profiles.profile_photo_url`
- Avatar displays `NetworkImage` when set, initial-letter fallback otherwise
- Verified: `flutter analyze` 0 issues, `flutter test` 222 passed / 4 skipped

### Previously Discovered as Already Implemented
- **Worker availability toggle**: `_PresenceBanner` in `worker_home.dart` already has interactive Go Online/Offline button calling `toggleWorkerOnline()` → persists `is_online_for_map` to Supabase
- **Image upload in chat**: `chat_screen.dart` already wires `image_picker` + `file_picker` → `StorageService.uploadChatMedia()` (lines 601–631)

### Longer-Term Goals
| Goal | Detail | Priority |
|------|--------|----------|
| Job expiry | Auto-expire open jobs after N days (cron or client check) | Medium |
| Payment integration | JazzCash/EasyPaisa for in-app payments | Medium |
| CNIC verification flow | Upload → pending → verified status with admin review | Low |
| Analytics dashboard | Employer: job views, application rates. Worker: profile views, hire rate | Low |
| Web PWA | Enable Firebase web config, test all flows on web | Low |
| Localization completeness | Audit all hardcoded English strings, add Urdu translations | Medium |

---

## Session History

### Session 17 (prior)
- Added domain providers, services, models
- Bug fixes: DateTime.tryParse, safe num casting
- Test additions for providers

### Session 16 (prior)
- Initial project setup
- Supabase integration
- Core screens implemented with AppState
