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

Release builds now fail a purchase safely if RevenueCat keys, active products, or an entitlement are missing. Configure and sandbox-test the products anyway; a working paywall is still required before launch.

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
