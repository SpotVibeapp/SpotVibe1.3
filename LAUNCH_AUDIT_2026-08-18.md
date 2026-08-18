# SpotVibe — Launch Readiness Audit
**Audited 2026-08-18 · Repo: `SpotVibeapp/SpotVibe1.3` · Flutter · iOS + Android**

## Verdict

**Your app is in unusually good shape for a pre-launch codebase.** Signing, privacy manifest, account deletion, security rules, and legal pages are all already handled correctly. I found **no unrecoverable blockers in code** — but there are **two time-sensitive items, one leaked secret that must be rotated, and a handful of console-side steps** that still require your accounts. Fix the Critical items, then work the Important list in order.

---

## 🔴 Critical — do these first

### 1. Deactivate the old Ticketmaster key (leaked in git history — confirmed, but note: not in use)

Your old Ticketmaster key `ACde2X…` is committed in the **public repo's git history** (commits `a213c69`, `05aee11`, `1a8a30c` all contain `defaultValue: 'ACde2XLPYSODlESFOv3u5TYMAVF1N8F0'`). The current code is clean (dart-define only), and **you've confirmed this key is not the one you'll ship — you have a new key for launch.**

- [ ] If the old key is still **active on your Ticketmaster account**, revoke/deactivate it at developer.ticketmaster.com. Anyone who finds it in history could burn your quota or run up usage against your account. If it was never activated or already dead, there's effectively no risk and you can skip this.
- [ ] (Optional hygiene) Purge it from history: `git clone --mirror` + `git filter-repo --invert-paths --path lib/services/ticketmaster_service.dart`, then force-push.
- [ ] At launch, inject your new key via `--dart-define=TICKETMASTER_API_KEY=…` (the code has no hardcoded fallback — good).

### 2. ⏰ Target Android API 36 — deadline Aug 31, 2026 (13 days away)
Google Play requires **new app submissions to target Android 16 (API level 36) starting Aug 31, 2026** — otherwise Play Console rejects the upload. [[1](https://vadimages.com/news/google-play-api-36-deadline-august-2026-logistics-apps), [3](https://ecorpit.com/android-target-api-36-play-store-deadline-migration-2026/)]

Your `build.gradle.kts` has `compileSdk = 36` (good) but `targetSdk = flutter.targetSdkVersion`, which depends on your Flutter SDK version.

- [ ] Verify what `flutter.targetSdkVersion` resolves to on your machine (must be **36**).
- [ ] Safest fix: hard-code `targetSdk = 36` in `android/app/build.gradle.kts` so the build never silently targets lower.

### 3. Firebase Authentication is not enabled yet
The README documents a `CONFIGURATION_NOT_FOUND` smoke test (2026-08-10) — **sign-up is still failing in the console**. Real users cannot create accounts.

- [ ] Firebase console → project `spotvibe-cfa08` → **Authentication → enable Email/Password**.
- [ ] **Firestore Database** → create (production mode) → deploy `firestore.rules` and `firestore.indexes.json`.

### 4. iOS: `DEVELOPMENT_TEAM` is empty
`ios/Runner.xcodeproj/project.pbxproj` has `DEVELOPMENT_TEAM = ""`. You cannot archive or upload an App Store build until a team is set.

- [ ] Open `ios/Runner.xcworkspace` in Xcode → Signing & Capabilities → select your Team. This is a Mac/Xcode-only step (no way around it).

### 5. Android release signing silently falls back to debug
`android/app/build.gradle.kts` signs release builds with the **debug keystore when `key.properties` is absent**. If you forget to create it, the AAB is debug-signed and Play Console rejects it — a confusing, avoidable failure. (You've applied a "fail loud" philosophy to auth; apply it here too.)

- [ ] Generate a real upload keystore (outside the repo), create `android/key.properties`.
- [ ] (Recommended) Change the `else` branch to **throw/fail the build** instead of falling back to debug signing, so a missing keystore can never produce a silently-wrong AAB.

---

## 🟠 Important — plan for these (store policy / accounts)

### 6. ⏰ Google Play closed test: now 12 testers, not 20
Your `LAUNCH_ACTION_ITEMS.md` says "≥ 20 testers for personal accounts." Google **reduced it to 12 opted-in testers for 14 consecutive days** (Dec 2024) for personal accounts created after Nov 13, 2023. [[2](https://primetestlab.com/blog/google-play-changed-20-to-12-testers)]

- [ ] Confirm your account type. If personal (post-Nov-2023), you **must** run a closed test (12 testers, 14 days, real devices, genuine engagement) before applying for production. This is the biggest Android schedule risk — start it now, in parallel with other work.
- [ ] Update the number in your docs.

### 7. RevenueCat keys must be injected at build time
Keys are read via `String.fromEnvironment('REVENUECAT_ANDROID_KEY'/'APPLE_KEY')`. If you build **without** those `--dart-define` flags, the app silently falls back to a local 7-day trial and **never charges money**.

- [ ] Pass both keys on every release build (and CI, if any).
- [ ] Create and **activate** the two products (`spotvibe_premium_monthly`, `spotvibe_premium_founding_monthly`) in **both** consoles *before* submitting — IAPs must be approved or the subscription flow is broken.

### 8. Deep-link domain ownership
Universal links reference `https://spotvibe.app`. The `.well-known/` templates exist but need real values:

- [ ] Confirm you **own** `spotvibe.app` and have DNS pointed at the hosting.
- [ ] `assetlinks.json` → replace the placeholder with your release signing cert's **SHA-256**.
- [ ] `apple-app-site-association` → replace with your **Apple Team ID**.
- [ ] Re-deploy hosting. (In-app sharing via `spotvibe://` works regardless; this only affects App Links / universal links.)

### 9. Support email must actually receive mail
Both stores verify a monitored support contact. Your legal pages use `blakejohnson@spotvibeapp.com` while the app domain is `spotvibe.app`.

- [ ] Confirm `spotvibeapp.com` MX records exist and the inbox is monitored (or switch everything to one domain you control).

---

## 🟡 Minor / polish (won't block, but clean up)

- **Privacy manifest over-declares "Photos or Videos."** `PrivacyInfo.xcprivacy` lists `NSPrivacyCollectedDataTypePhotosorVideos`, but the app has **no photo-library or camera access** (no `image_picker`, no `NSPhotoLibraryUsageDescription`). Event images come from URLs (which is `OtherUserContent`, already declared). Over-declaring invites Apple review questions — either remove `PhotosorVideos`, or if you plan to let venues upload photos, add `image_picker` + the plist usage string.
- **Two `IPHONEOS_DEPLOYMENT_TARGET` values** (15.0 and 15.6) in `project.pbxproj` — Debug vs Release drift. Unify to 15.0.
- **Legacy "Vibely" remnants** — `vibely.app` / `vibely://` deep links still in `AndroidManifest.xml`, `Info.plist`, and entitlements. They resolve but look stale; drop them if the old domain/scheme is dead.
- **Dead namespace-injection shim** in `android/build.gradle.kts` references the removed `flutter_branch_sdk`. The comment says to remove it once all plugins support AGP 8 — it's harmless but confusing.
- **Social sign-in is disabled** (`app_config.dart` all `false`) — this is *correct* and safe: email/password only means **no "Sign in with Apple" requirement is triggered**. Note: if you ever enable Google/Facebook sign-in on iOS, Apple Guideline 4.8 then **requires** you to also enable Sign in with Apple (your `Runner.entitlements` already declares it, so you're prepped).

---

## ✅ Confirmed good (no action needed)

- **Keystore clean** — no `.p12`/`.jks`/`google-services.json` in current files *or* git history. `.gitignore` correctly excludes all of them.
- **Privacy manifest** present and thorough — collected-data types + required-reason APIs (UserDefaults `CA92.1`, FileTimestamp `C617.1`, SystemBootTime `35F9.1`).
- **Account deletion** — in-app (re-auth) *and* web page + Firestore purge + Cloud Function. Satisfies both stores.
- **Privacy Policy, Terms, Delete page** — professionally written, live-deployable, cover the right bases (children, data sharing, retention, state privacy rights, subscriptions).
- **Firestore rules hardened** — authenticated writes only, admin gating, blocks collection, UGC moderation + user reports.
- **Permissions correct** — `BILLING`, `POST_NOTIFICATIONS`, fine/coarse location, all with iOS usage descriptions.
- **`ITSAppUsesNonExemptEncryption = false`** set.
- **12 test files** present.
- **`compileSdk = 36`, `minSdk = 26`, AGP 8.11.1, Kotlin 2.2.20** — all current.

---

## Suggested order of operations

1. (Optional) Deactivate the old Ticketmaster key if it's still live on your account, then rotate. You'll inject your new key at launch via `--dart-define=TICKETMASTER_API_KEY=…`.
2. Hard-code `targetSdk = 36`; verify Flutter SDK resolves 36 (before Aug 31).
3. Enable Firebase Auth + Firestore, deploy rules/indexes (console).
4. Set Apple Team in Xcode; generate Android upload keystore + `key.properties`.
5. Start the **12-tester / 14-day closed test** on Play *in parallel* (it's the long pole).
6. Create + activate IAPs in both consoles; wire RevenueCat keys into release builds.
7. Finish deep-link association files + deploy legal site.
8. Submit App Store (TestFlight first) and Play (internal → closed → production).
