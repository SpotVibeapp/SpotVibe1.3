# SpotVibe Code Analysis

> **Status update (2026-08-10):** all security/build/rebrand fixes in this
> report have been committed, a test suite (31 tests) was added, and **real
> auth via Firebase Auth + Firestore has been wired** (`FirebaseUserRepository`
> with automatic mock fallback). Remaining: enable Authentication in the
> Firebase console (see README § Firebase authentication), real Branch.io
> keys, and a real backend for events/RSVPs.

**Repo:** `SpotVibeapp/SpotVibe` · Flutter app (`primio_app`) · 169 files · ~24,100 lines of Dart
**Generated with:** Primio (AI app builder) · **Date:** 2026-08-10

---

## TL;DR

This is a well-structured **prototype**: clean architecture, good layering, polished UI code — but it has **no real backend**. Auth, events, RSVPs, and users are all simulated in memory with fake delays. It's not shippable as-is: there's a **signing key committed to a public repo**, broken release signing, placeholder deep-link keys, zero tests, and inconsistent branding ("Vibely" vs "SpotVibe").

---

## 🔴 Critical — fix before anything else

### 1. Signing keystore committed to a public repository
`android/app/upload-keystore.p12` is checked into a **public** GitHub repo.
Anyone can download it. Even if it's "just" a Play upload key, treat it as compromised.
- Remove it from git **and from history** (`git filter-repo` or BFG).
- Add `*.p12`, `*.jks`, `*.keystore` to `.gitignore`.
- Regenerate the key; keep it outside version control.

### 2. Authentication is completely simulated
`lib/repositories/user_repository.dart` — `login()` accepts **any** email + any password (≥6 chars) and just fabricates `user_1` in memory:
- No server, no password verification, no token exchange.
- Social logins (Google/Facebook/Apple) fetch real OAuth credentials but **never send them anywhere** — no backend ever validates them.
- Session is memory-only: restarting the app logs everyone out (`getCurrentUser()` always returns `null` after restart — `flutter_secure_storage` is in the dependencies but never used for auth).
- Fine for a demo. Not a product until a real backend (Firebase Auth, Supabase, or your own API) replaces `UserRepository`.

### 3. `Firebase.js` with API keys at repo root
Unused by the Flutter app, yet it exposes your Firebase project config
(`spotvibe-cfa08`). Firebase web keys aren't truly secret, but they must be
protected with **App Check + strict Security Rules**. Delete this file from the
repo and enable App Check on the Firebase project.

### 4. Password handling bug
`auth_service.dart`: `password.trim()` — passwords legitimately containing
leading/trailing spaces get silently altered before "validation". Don't trim
passwords.

---

## 🟠 Release blockers

### 5. Release builds will crash without `key.properties`
`android/app/build.gradle.kts` casts `keystoreProperties["keyAlias"] as String`.
If `key.properties` doesn't exist, this throws a ClassCastException at build time.
Use `as String?` and fall back to the debug signing config when absent.

### 6. Branch.io deep linking is all placeholders
Both `AndroidManifest.xml` and `ios/Runner/Info.plist` still contain
`key_live_REPLACE_WITH_BRANCH_LIVE_KEY`, `key_test_REPLACE_WITH_BRANCH_TEST_KEY`,
and the URI scheme `REPLACE_WITH_BRANCH_URI_SCHEME`. The deferred deep-link flow
(proudly documented in `main.dart`) **cannot work** until real Branch keys are set.

### 7. Branding mismatch everywhere
The product is **SpotVibe**, but the binary says **Vibely/Primio**:
- `applicationId = com.primio.vibely` (Android) — **decide now**; you can't
  change it after publishing without losing your Play listing.
- App label `Vibely` (AndroidManifest + iOS `CFBundleDisplayName/CFBundleName`).
- Deep-link domain `https://vibely.app` (`kDeepLinkBase` in `deep_link_service.dart`).
- pubspec name `primio_app`.

### 8. iOS Info.plist branding + review risk
Location usage strings say "Vibely uses your location…". Also,
`NSLocationAlwaysAndWhenInUseUsageDescription` is declared but the app only ever
requests when-in-use — remove the "Always" key or App Review may ask why.

---

## 🟡 Code quality & architecture

### Strengths ✅
- **Clean layering**: `models → repositories → services → providers → screens/widgets`,
  consistent naming, DI via `get_it` registered in `main.dart`.
- **Well-documented code**: section banners, PRIMIO_ADDED annotations explain every
  dependency addition; `main.dart`'s deep-link priority chain is clearly commented.
- **Good .gitignore** — `key.properties` correctly kept out of git.
- **AI moderation service** (`ai_moderation_service.dart`) is thoughtfully built:
  two-tier (reject/flag), 10 categories, documented upgrade path to a real API.
- Sensible dependency choices (go_router, provider, dio, cached_network_image).

### Issues ⚠️
| Issue | Detail |
|---|---|
| **Zero tests** | No `test/` directory at all. 24k lines, 0 tests. Start with models + repository contracts. |
| **God file** | `event_repository.dart` is **3,038 lines** — mock-data generator, city coordinates table, and repository logic in one file. Split into `mock_event_source.dart` + a thin repository so a real backend can drop in. |
| **Dead dependencies** | `flutter_bloc` + `equatable` declared in pubspec but **never imported** in `lib/` (everything uses `provider`). Remove them. |
| **Fake delays in production code** | `Future.delayed(300–800ms)` scattered through repositories to simulate latency. Remove when wiring a real backend or they become pure added latency. |
| **Hardcoded config** | `kDeepLinkBase = 'https://vibely.app'` in code; no `--dart-define` / env config for staging vs prod. |
| **Inconsistent version pinning** | `video_player: 2.10.0` exact-pinned while everything else uses `^` ranges. |
| **`.flutter-plugins-dependencies` committed** | Generated file; belongs in `.gitignore` (it's already listed but was committed anyway — `git rm --cached`). |

---

## Suggested roadmap to a shippable app

1. **Today:** remove the keystore from git + history, delete `Firebase.js`, rotate anything exposed.
2. **This week:** fix release signing fallback; set real Branch keys (or strip Branch entirely if deferred links aren't needed yet); decide `com.primio.vibely` vs a SpotVibe applicationId.
3. **Next:** wire a real backend — Firebase Auth + Firestore is the fastest path since you already have a Firebase project (`spotvibe-cfa08`). Replace the in-memory `UserRepository` first (persist sessions with `flutter_secure_storage`).
4. **Then:** split `event_repository.dart`, remove `flutter_bloc`, add a `test/` suite starting with models and the moderation service, add a CI check (`flutter analyze` + `flutter test`).

---

*Report generated 2026-08-10 from clone of `main` @ `0820b22`.*
