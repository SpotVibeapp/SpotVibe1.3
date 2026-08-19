# SpotVibe — Your Action Items (steps only you can do)

I've made every change that can be made in code (see the summary at the bottom).
These are the steps that need **your accounts, secrets, or console access**.
Do them in roughly this order.

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
7. **Storage (required for profile photos + event videos):**
   Console → **Build → Storage → Get started** (production rules).
   Then deploy the rules already in this repo:
   ```bash
   firebase deploy --only storage
   ```
   Uploads fail with a clear message until this is done.
8. (Recommended) **App Check:** enable Play Integrity + App Attest, and
   enforce it, so your Firebase keys can't be abused.

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
   build time (they are no longer placeholders in code):
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
   reports + event removal, and delete buttons on event pages and comments.

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
