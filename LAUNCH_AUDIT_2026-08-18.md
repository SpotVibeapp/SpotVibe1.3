<<<<<<< HEAD
# SpotVibe — Store readiness (as of 2026-08-18)

**Verdict: No. The app is not store-ready.**

Code is in unusually good shape for a first release. Nothing left in this repo will get you rejected *by itself*. You still cannot submit — or even produce a store binary — until you finish the account/console work below.

Package / bundle ID: `app.spotvibe` (both stores). Version: `1.0.0+1`. Firebase: `spotvibe-cfa08`. Deep-link base: `https://spotvibe.app`.

---

## What “store-ready” actually means

| Gate | Status |
|---|---|
| Code would survive review | **Mostly yes** — privacy manifest, account deletion, no unused photo permission, no leftover vibely deep links, social login hidden, targetSdk 36, fail-loud release signing |
| You can build a signed AAB / IPA today | **No** |
| A real user can sign up today | **No** |
| Play will accept a production rollout today | **No** (closed test + listing + IAPs) |
| App Store will accept a first review today | **No** (signing + listing + IAPs + TestFlight) |

---

## Already done in this repo (do not redo)

- `targetSdk = 36` pinned in `android/app/build.gradle.kts` (Play requires API 36 for new submissions starting **Aug 31, 2026** — 13 days).
- Release builds **throw** if `android/key.properties` is missing. No more debug-signed AAB.
- iOS deploy target unified to **15.0**. Privacy manifest no longer over-declares Photos/Videos.
- Ticketmaster key is dart-define only (no hardcoded fallback).
- RevenueCat keys are dart-define only.
- Deep-link manifests/plist only declare `spotvibe.app` + `spotvibe://`.
- Auth + claim-proof l10n keys added to `app_en.arb` / `app_es.arb` (502/502, matched).
- Admin event delete goes through `ModerationProvider`.
- New app icon generated for Android / iOS / web + in-app `AppIconMark`.
- Firebase Hosting no longer ignores `.well-known/` (`**/.*` removed from `firebase.json`).

Sandbox git (not on GitHub):

```
9d27ea2 icon change
0057026 Launch readiness: target API 36, fail-loud signing, l10n auth keys, moderation provider, cleanup
```

Working tree had those two commits clean; `firebase.json` is a new uncommitted fix on top.

---

## Blockers only you can clear

These are ordered by “how soon this stops you.”

### 1. Enable Firebase Auth + Firestore — users cannot sign up

README smoke test **2026-08-10**: `CONFIGURATION_NOT_FOUND`. Authentication is not enabled.

1. https://console.firebase.google.com → project **spotvibe-cfa08**
2. Authentication → enable **Email/Password**
3. Firestore → create DB (production) if it does not exist
4. `firebase deploy --only firestore:rules,firestore:indexes`
5. On your Mac/PC: `flutterfire configure --project=spotvibe-cfa08` for Android + iOS (`app.spotvibe`)

Until this is done, a store reviewer who taps Sign up gets a dead app. Instant reject.

### 2. Android upload keystore

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Create `android/key.properties` (gitignored):

```
storePassword=…
keyPassword=…
keyAlias=upload
storeFile=/absolute/path/to/upload-keystore.jks
```

Back the keystore up somewhere that is not this laptop. Lose it = you can never update the Play listing.

Then:

```bash
flutter build appbundle --release \
  --dart-define=TICKETMASTER_API_KEY=YOUR_NEW_KEY \
  --dart-define=REVENUECAT_ANDROID_KEY=goog_xxx \
  --dart-define=REVENUECAT_APPLE_KEY=appl_xxx
```

### 3. iOS team in Xcode (Mac required)

`DEVELOPMENT_TEAM` is still `""` in `ios/Runner.xcodeproj/project.pbxproj`. You cannot archive.

Xcode → `ios/Runner.xcworkspace` → Signing & Capabilities → select your Team. Confirm Associated Domains = `applinks:spotvibe.app`.

### 4. Start the Play closed test *this week*

If your Play account is **personal and created after Nov 13, 2023**, production is locked until:

**12 opted-in testers × 14 consecutive days** on real devices, genuine opens. [1](https://primetestlab.com/blog/google-play-12-testers-closed-testing-guide)

Organization accounts (D-U-N-S) are exempt. This is the long pole — **14 days minimum**, and Aug 31 is 13 days away. Start the closed test the same day you have a signed AAB, even if IAPs are still cooking.

### 5. Create the two subscriptions in both consoles + RevenueCat

IDs are hardcoded in `lib/data/pricing.dart`:

| ID | Price |
|---|---|
| `spotvibe_premium_monthly` | $12.99 / mo, 7-day trial |
| `spotvibe_premium_founding_monthly` | $9.99 / mo |

RevenueCat: entitlement `pro`, offerings `default` + `founding`. Paid Apps Agreement + Play payments profile must be active or the products stay invisible.

If you ship without keys, the app silently runs a **local 7-day trial and never charges**. Reviewers and founding venues will notice.

### 6. Deploy the legal site

```bash
firebase deploy --only hosting
```

Live URLs you will paste into both store forms:

- Privacy: `https://spotvibe-cfa08.web.app/privacy.html`
- Terms: `https://spotvibe-cfa08.web.app/terms.html`
- Delete account: `https://spotvibe-cfa08.web.app/delete_account.html`

Confirm `blakejohnson@spotvibeapp.com` actually receives mail (domain is `spotvibeapp.com`, app is `spotvibe.app`).

### 7. Push these commits, then reconcile your laptop

This sandbox is **2 commits ahead of GitHub** (`0057026`, `9d27ea2`) plus the `firebase.json` fix. They are **not pushed** — I do not have your credentials.

Your **local** machine also has files this repo does not (`lib/l10n/auth_messages.dart`, `lib/l10n/claim_labels.dart`). Pull will conflict. Order:

```bash
# on your machine, commit your local-only files first
git add lib/l10n/auth_messages.dart lib/l10n/claim_labels.dart
git commit -m "l10n helper files"

# then either push this sandbox (if you give me a token) or cherry-pick
# 0057026 + 9d27ea2 + the firebase.json fix onto your machine
git pull --rebase origin main   # after those commits are on GitHub
flutter pub get
flutter gen-l10n
flutter analyze
flutter test
```

There is no Flutter SDK in this sandbox. Analyze/test have to run on your machine.

### 8. Ticketmaster — revoke the leaked key if it is still live

`ACde2XLPYSODlESFOv3u5TYMAVF1N8F0` is in **public git history** (commits `a213c69`, `05aee11`, `1a8a30c`). Current code does not use it. You said you have a new key. If the old one is still active on the Ticketmaster account, revoke it.

### 9. Deep-link association (after you have a keystore + Team ID)

`legal_site/.well-known/assetlinks.json` still has `REPLACE_WITH_SIGNING_CERT_SHA256`.
`legal_site/.well-known/apple-app-site-association` still has `REPLACE_WITH_TEAM_ID`.

Fill those, redeploy hosting, point `spotvibe.app` DNS at Firebase Hosting. In-app `spotvibe://` shares work without this; https universal links do not.

---

## Not blockers (do not spend time here first)

- Social login flags are all `false` — correct. Do not enable Google/Facebook on iOS unless you also enable Sign in with Apple.
- `SpotVibeLogo` widget is unused; `SpotVibeWordmark` is still used. Harmless.
- Store listings, screenshots, Data Safety form, App Privacy nutrition label — required to *submit*, but they are copy/console work, not code.
- Optional git-history purge of the leaked Ticketmaster key (force-push). Only after the key is revoked.

---

## Fastest path to “submitted”

Same week:

1. Firebase Auth + Firestore + `flutterfire configure`
2. Android keystore + first signed AAB
3. Upload AAB to Play **internal** then **closed** test; recruit 12 testers immediately
4. Xcode team + TestFlight
5. Create both IAPs + RevenueCat
6. `firebase deploy --only hosting` and paste those URLs into both consoles

Then wait out the 14-day closed test (Play) / TestFlight notes (Apple) while you write listings.

---

## I can do next (say the word)

- Draft Play listing + App Store listing + Data Safety / App Privacy answers from the actual code
- One-page store-form cheat sheet (every URL, ID, permission, data type)
- About / Support screen inside the app
- Delete the dead `SpotVibeLogo` class
- Walk you through the keystore + Play closed-test setup step by step
=======
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
>>>>>>> 0057026 (Launch readiness: target API 36, fail-loud signing, l10n auth keys, moderation provider, cleanup)
