# SpotVibe — Your Action Items (steps only you can do)

I've made every change that can be made in code (see the summary at the bottom).
These are the steps that need **your accounts, secrets, or console access**.
Do them in roughly this order.

---

## ✅ STATUS — Closed beta PUBLISHED (2026-09-08)

The first **Closed testing** release is live on Google Play and has passed review.

- **Track:** Closed testing — "Beta 09/08/26"
- **Version:** `1.0.1+9` (versionCode **9**)
- **Build flags used:** `--dart-define-from-file=secrets.json`
  `--dart-define=REVIEWER_PREMIUM_EMAIL=beta-review@spotvibeapp.com`

### Play Console fill-in guides written this session
- `PLAY_APP_CONTENT.md` — Data safety, content rating, target audience, ads, store listing copy.
- `ADS_PLAN.md` — banner-ads-for-free-users plan (deferred past first beta).
- `HIDDEN_GEMS_PLAN.md` — "hidden gems" positioning + build plan (awaiting tier decision).
- `TESTER_INVITE.md` — copy-paste message to send testers (this session).

### VersionCode history (Play burns each code permanently — always go up)
| Code | Notes |
|---|---|
| 1, 2 | Early uploads (old TM key + media perms). Do not reuse. |
| 3 | Had `READ_MEDIA_*` perms. |
| 4, 5 | Consumed by deleted uploads (codes stay burned after deletion). |
| 6, 7 | Removed `READ_MEDIA_*` from app manifest + `tools:node="remove"`. |
| 8 | Stripped `com.google.android.gms.permission.AD_ID`. |
| **9** | Also stripped `ACCESS_ADSERVICES_AD_ID`. **← current published build.** |

### Manifest permission notes (why the version churn happened)
- Media picking uses `image_picker` → Android Photo Picker, so no `READ_MEDIA_*`
  permission is needed. Plugins inject them anyway; we strip them via
  `tools:node="remove"` in `android/app/src/main/AndroidManifest.xml`.
- The app has **no ads / no ad SDK**, but plugins injected `AD_ID` /
  `ACCESS_ADSERVICES_AD_ID`; those are also stripped. The built manifest is
  clean (verified: `Select-String ... -Pattern "AD_ID"` returns nothing).
- ⚠️ **Advertising ID declaration:** despite the clean bundle, Play Console would
  not accept "No" (stale-state / older bundles in history), so the declaration
  was set to **Yes → purpose: App functionality**, with Data safety
  "Advertising ID = collected" to match. This is over-declared for the current
  build. **When real ads (AdMob) are added (see `ADS_PLAN.md`) it becomes
  accurate.** Revisit if you ever want it back to an honest "No."

### Still open before PRODUCTION (not just beta)
1. **Ticketmaster key rotation** — confirm the build that testers get was built
   with the *rotated* key in `secrets.json`, not the leaked one (§1 below).
2. **Reviewer Premium flag** — the `REVIEWER_PREMIUM_EMAIL` dart-define must be
   **omitted** from any public production build (it grants Premium to that one
   account without a purchase). Only use it for review/testing builds.
3. `flutter analyze` / `flutter test` after all the manifest edits (Open Item #1).

---

## 0. Validate the code changes on your machine

No Flutter SDK exists in my sandbox, so please run locally:

```bash
flutter pub get
flutter analyze          # expect 0 issues
flutter test             # 12 test files should pass
```

If `flutter analyze` flags anything, it will be a small fix — send me the
output and I'll correct it.

---

## 1. Rotate the Ticketmaster API key (IMPORTANT — do first)

Your API key was committed to a **public** repo, so treat it as compromised.

1. Go to https://developer.ticketmaster.com → your profile → regenerate/revoke the old key (`ACde2X…`).
2. Create a new key and keep it secret.
3. Run/build with it via dart-define (the code now has **no fallback key**):
   ```bash
   flutter run --dart-define=TICKETMASTER_API_KEY=your_new_key
   ```
4. Optional but recommended: purge the old key from git history:
   ```bash
   git clone --mirror <repo> && git filter-repo --invert-paths --path lib/services/ticketmaster_service.dart
   # then force-push
   ```

---

## 2. Configure Firebase (native apps + auth)

1. Sign in at https://console.firebase.google.com → project **spotvibe-cfa08**.
2. **Authentication → Sign-in method:** enable **Email/Password** (required).
   Enable Google / Facebook / Apple only if you plan to ship them (see §9).
3. **Firestore Database:** create it if not created (production mode).
4. Publish the **new security rules** (already written for you):
   ```bash
   firebase deploy --only firestore:rules
   ```
5. Deploy the **Firestore indexes** (the file contains single-field
   collection-group controls needed by account deletion queries):
   ```bash
   firebase deploy --only firestore:indexes
   ```
6. Register the native apps & generate configs **on your machine**:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure --project=spotvibe-cfa08
   ```
   - Android package: **`app.spotvibe`**
   - iOS bundle id: **`app.spotvibe`**
   - This rewrites `lib/firebase_options.dart` with Android/iOS configs and
     downloads `google-services.json` / `GoogleService-Info.plist`
     (both stay gitignored — never commit them).
   - Until you do this, a release build intentionally shows a
     "backend not configured" screen instead of fake auth (that's the new
     fail-loud behavior working as intended).
   - Keep all social-login flags `false` until the provider is configured
     end-to-end; the checked-in release-safe defaults hide those buttons.
7. **Storage (required for profile photos + event videos):**
   Console → **Build → Storage → Get started** (production rules).
   Then deploy the rules already in this repo:
   ```bash
   firebase deploy --only storage
   ```
   Uploads fail with a clear message until this is done. Free creators get one
   cover photo and one video; Premium creators and admins can attach up to
   **5 photos total (including the cover)** and **3 videos**. Photos are
   limited to 6 MB and videos to 30 seconds / 50 MB each.
8. (Recommended) **App Check:** enable Play Integrity + App Attest, and
   enforce it only after testing, so your Firebase keys can't be abused.
9. **Password recovery:** use **Forgot password?** in the app with a real test
   email, then confirm Firebase delivers the reset link and the new password
   can sign in.
10. **AI promo backgrounds + Poster Studio (optional):** The in-app generator
    accepts a bounded visual-direction note and creates only the artwork.
    Poster Studio formats the exact title, date, time, venue, and price locally
    so AI never invents poster text. Configure an OpenAI key as a Firebase
    secret and deploy Cloud Functions:
    ```bash
    firebase functions:secrets:set OPENAI_API_KEY
    firebase deploy --only functions
    ```
    This Google Workspace project enforces Domain Restricted Sharing. After
    deploying `generatePromoImage`, run this in Cloud Shell so the app can
    reach the direct Cloud Run callable endpoint:
    ```bash
    gcloud run services update generatepromoimage --region=us-central1 --project=spotvibe-cfa08 --no-invoker-iam-check
    ```
    Set a Cloud billing alert first. The app keeps the key server-side, limits
    generation to 3 images/day per user (20/day per admin), and stores results
    in the event owner's Firebase Storage path.

---

## 3. Deploy the legal site (privacy / terms / delete account)

```bash
firebase deploy --only hosting
```

This publishes `legal_site/` to `spotvibe-cfa08.web.app`, giving you live URLs:

- Privacy: https://spotvibe-cfa08.web.app/privacy.html
- Terms:    https://spotvibe-cfa08.web.app/terms.html
- Delete:   https://spotvibe-cfa08.web.app/delete_account.html

You'll paste the **privacy** and **delete account** URLs into the store forms.
*(Later, point your custom domain `spotvibe.app` at this hosting for cleaner URLs.)*

---

## 4. Deep links — finish the association files

Templates are already in `legal_site/.well-known/`. Fill in:

1. **`assetlinks.json`** → replace `REPLACE_WITH_SIGNING_CERT_SHA256` with the
   SHA-256 of your release signing cert:
   ```bash
   keytool -list -v -keystore upload-keystore.jks -alias upload \
     | grep SHA256
   ```
2. **`apple-app-site-association`** → replace `REPLACE_WITH_TEAM_ID` with your
   Apple Developer Team ID (visible in https://developer.apple.com/account → Membership).
3. Re-run `firebase deploy --only hosting`.

Note: these only matter if `https://spotvibe.app` (your custom domain) points at
this hosting. In-app sharing still works today via the `spotvibe://` scheme and
share sheet.

---

## 5. Apple signing + Sign in with Apple

1. Open `ios/Runner.xcworkspace` in Xcode (on a Mac).
2. Set your **Team** in Signing & Capabilities (currently empty).
   This fills `DEVELOPMENT_TEAM` in the project.
3. Add the **Sign in with Apple** capability (the `Runner.entitlements` file I
   added already declares it — Xcode will attach it to your provisioning).
4. Confirm **Associated Domains** shows `applinks:spotvibe.app` (also already
   in the entitlements file).

---

## 6. Android release signing

Release builds now **fail** if `android/key.properties` is missing (no
debug-signing fallback). For Play you need a real upload key:

1. Create a keystore (keep it OUT of the repo).
2. Create `android/key.properties`:
   ```
   storePassword=…
   keyPassword=…
   keyAlias=upload
   storeFile=/absolute/path/to/upload-keystore.jks
   ```
3. Build the release artifact:
   ```bash
   flutter build appbundle --release
   ```

---

## 7. Subscriptions (Apple / Google / RevenueCat)

See `STORE_PRODUCTS.md` for full details. Summary:

1. **RevenueCat:** create project → copy the **public SDK keys** → pass them at
   build time (they are no longer placeholders in code). A release build now
   fails a purchase safely rather than granting a local trial when these are
   absent:
   ```bash
   flutter build appbundle --release \
     --dart-define=REVENUECAT_ANDROID_KEY=goog_xxx \
     --dart-define=REVENUECAT_APPLE_KEY=appl_xxx
   ```
2. **Products:** create `spotvibe_premium_monthly` ($12.99, 7-day trial) and
   `spotvibe_premium_founding_monthly` ($9.99) in both App Store Connect and
   Play Console; attach both to the **`pro`** entitlement; offerings `default`
   and `founding`.
3. Sandbox-test **purchase** and **Restore Purchases** on both platforms.

---

## 8. Store submissions

**Google Play Console**
1. Create the app (package `app.spotvibe`), upload the AAB.
2. **Data safety form** — declare: location (precise/approximate), name, email,
   user IDs, photos, purchase history, app interactions, device IDs; shared
   with Firebase, RevenueCat, Ticketmaster, sign-in providers.
3. **Account deletion:** provide the in-app path (already built) **and** the
   web URL `https://spotvibe-cfa08.web.app/delete_account.html`.
4. Complete app content ratings (note: UGC — user events/comments/RSVPs), and
   run a **closed test** (≥ 12 opted-in testers, 14 consecutive days, for
   personal developer accounts) before production.

**App Store Connect**
1. Create the app (bundle id `app.spotvibe`), set up **App Privacy** answers
   matching the privacy policy.
2. Add the **subscription group + two products** (must be approved before the
   app can offer them).
3. Upload via **TestFlight** for internal/external testing before submitting.

---

## 9. Social sign-in (only if you want to ship it)

The buttons are **hidden** until enabled in `lib/config/app_config.dart`.
For each provider you want:

- **Google:** Firebase → enable Google; add your Android **SHA-1/SHA-256**;
  iOS needs `GoogleService-Info.plist` + reversed client ID (comes from
  `flutterfire configure` + an extra `REVERSED_CLIENT_ID` in Info.plist).
- **Facebook:** create a Facebook app, add key hashes (Android), app id +
  URL scheme (iOS), then enable in Firebase.
- **Apple:** enable in Firebase + the Xcode capability from §5.

Then flip the matching flag to `true` in `lib/config/app_config.dart` and
re-test on device.

---

## 10. Optional — deploy Cloud Functions

I added `functions/` with `deleteUser` (authoritative cleanup), comment/event
moderation, `promoteAdmin`, and `bannedUserCleanup` (purges a banned user's
content the moment they're banned):

```bash
cd functions && npm install
firebase deploy --only functions
```

The in-app deletion already works without this; the function is a
belt-and-suspenders fallback + server-side moderation. Note that
`bannedUserCleanup` permanently deletes content (not undone by "unban"), while
the in-app ban list hiding is reversible.

---

## 11. Make yourself an admin

The app now supports an in-app admin role for moderation. To enable it:

1. Deploy the updated security rules (required):
   ```bash
   firebase deploy --only firestore:rules
   ```
2. Find your Firebase Auth UID: Firebase console → **Authentication → Users**
   → click your account → copy the **User UID**.
3. Create the admin doc in the console (fastest):
   Firestore → **Start collection** → id `admins` → document id = your UID,
   fields `role: "admin"`, `email: <your email>`.
   *(Alternatively, deploy functions and use `promoteAdmin` with an
   `ADMIN_SECRET` — see `functions/`.)*
4. Relaunch/sign back in — you'll now see **Profile → Admin Dashboard** with
   reports + event removal, claim moderation, partner-code issuance, and delete
   buttons on event pages and comments.
5. For partner offers, create the actual one-time code batches in App Store
   Connect / Google Play Console first. Then use **Admin Dashboard → Partner
   codes** to stock and issue one store-issued code to one partner. See
   `STORE_PRODUCTS.md` for the required workflow.

## What I changed (for your commit message / review)

- **Account deletion** — in-app (Profile → Delete Account with re-auth), web page,
  Firestore purge, `deleteUser` Cloud Function; privacy/terms updated.
- **Real auth only** — release builds fail loud instead of silently using mock auth.
- **Firestore rules hardened** — no anonymous writes to the public feed; added
  `blocks` collection; `meta` locked down (except the founding counter).
- **Block user** now persists to Firestore (`blocks/{uid}/blocked/{target}`).
- **Ticketmaster key** no longer committed (dart-define only).
- **RevenueCat keys** moved to dart-define (no placeholders in code).
- **Branch.io removed** everywhere (SDK, manifests, plist, main.dart, links).
- **iOS:** added `PrivacyInfo.xcprivacy` (privacy manifest), `Runner.entitlements`
  (Sign in with Apple + associated domains), wired both into the Xcode project;
  removed `NSLocalNetworkUsageDescription`/`NSBonjourServices` from release plist.
- **Android:** added `com.android.vending.BILLING`; removed Branch metadata.
- **Login:** social buttons hidden until configured.
- **Notifications:** removed the unused "Messages" channel + dead DM methods.
- **Deps:** pruned 21 unused packages, deleted root `package.json`/lockfile.
- **Legal:** `delete_account.html`, updated privacy/terms, index links.

Commit it all, then follow this checklist from the top.
