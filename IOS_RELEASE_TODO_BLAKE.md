# iOS App Store release — steps only Blake can do

Branch `ios-appstore-fixes` (version 1.0.15+15) contains the code-side fixes:
Sign in with Apple enabled, ATT prompt before ads (non-personalized ads if
declined), updated privacy manifest, SKAdNetwork ids, AdMob/Google Sign-In ids
as build-config placeholders with a Release-build check, iOS target 15.6.

Everything below needs your accounts, a Mac, or console access.
**Release builds fail on purpose until steps 1, 3 and 4 are done.**

## 1. Firebase iOS app + GoogleService-Info.plist
1. On a Mac, from the repo root:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure --project=spotvibe-cfa08   # select iOS (and Android)
   ```
   iOS bundle id: `app.spotvibe`. This writes `ios/Runner/GoogleService-Info.plist`
   (gitignored — never commit it) and updates `lib/firebase_options.dart`.
2. In Xcode make sure `GoogleService-Info.plist` is in the **Runner** target.
3. Firebase Console → Crashlytics: confirm the iOS app appears after a first run.
4. (Recommended) App Check with App Attest for iOS.

## 2. Sign in with Apple
1. developer.apple.com → Identifiers → `app.spotvibe` → enable **Sign in with Apple**.
2. Firebase Console → Authentication → Sign-in method → **Apple** → Enable.
   Native iOS sign-in alone works without a Services ID/key, **but account
   deletion revokes the user's Apple token (Guideline 5.1.1(v)), and Firebase
   can only do that with the OAuth code flow configuration filled in:**
   - developer.apple.com → Identifiers → **Services IDs** → create one (e.g.
     `app.spotvibe.signin`), enable Sign in with Apple, and set the return URL
     to the one shown on the Firebase Apple provider page
     (`https://<project>.firebaseapp.com/__/auth/handler`).
   - developer.apple.com → **Keys** → create a key with Sign in with Apple
     enabled (primary App ID `app.spotvibe`) and download the `.p8` (one-time).
   - Firebase Apple provider → OAuth code flow configuration: enter the
     Services ID, Apple Team ID, Key ID, and paste the `.p8` private key. Save.
   No Cloud Function is needed; Firebase Auth calls Apple's revoke endpoint.
   Without this step deletion still works, but the token is not revoked
   (the failure is only logged).
3. Test on a real device: sign in, cancel (should silently return), and sign
   in again (Apple only sends name/email the first time).
4. Test deletion: Profile → Delete Account → Apple sheet appears → confirm →
   account is deleted, and Settings → Apple ID → Sign in with Apple no longer
   lists SpotVibe. Cancelling the Apple sheet must leave the account intact.

## 3. Google Sign-In on iOS
After step 1, run on the Mac:
```bash
./tool/ios_sync_google_ids.sh
```
It copies `CLIENT_ID` / `REVERSED_CLIENT_ID` from `GoogleService-Info.plist`
into `ios/Flutter/AppIds.local.xcconfig` (gitignored). Then test Google sign-in.

## 4. AdMob (iOS)
1. AdMob console → Apps → add **SpotVibe (iOS)**, linked to the App Store
   listing once it exists. Copy the iOS **app id** (`ca-app-pub-…~…`).
2. Add to `ios/Flutter/AppIds.local.xcconfig`:
   ```
   ADMOB_IOS_APP_ID = ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY
   ```
3. Create an iOS **banner ad unit** and put it in `secrets.json`
   (`ADMOB_BANNER_IOS`), built with `--dart-define-from-file=secrets.json`.
4. AdMob → Privacy & messaging: publish a **GDPR** message and an
   **IDFA explainer** message for iOS (UMP shows them before the ATT prompt),
   and add `app-ads.txt` on your developer website.

## 5. Xcode signing (Team ID)
1. Open `ios/Runner.xcworkspace` → Runner target → Signing & Capabilities.
2. Select your **Team** (fills `DEVELOPMENT_TEAM`, currently empty).
3. Confirm capabilities: **Sign in with Apple**, **Associated Domains**
   (`applinks:spotvibeapp.net`, `applinks:spotvibe-cfa08.web.app`).
4. `cd ios && pod install`, then Product → Archive.

## 6. Deep-link association files (AASA / assetlinks)
1. `legal_site/.well-known/apple-app-site-association`: replace
   `REPLACE_WITH_TEAM_ID` with your Team ID.
2. `legal_site/.well-known/assetlinks.json`: replace
   `REPLACE_WITH_SIGNING_CERT_SHA256` with the SHA-256 of the **Play app
   signing** cert (Play Console → App integrity) and your upload key.
3. `firebase deploy --only hosting`, and serve the same files at
   `https://spotvibeapp.net/.well-known/` (no redirect, JSON content type).

## 7. RevenueCat + App Store Connect products
1. App Store Connect → create the app **"SpotVibe - Find Your Vibe"**
   (bundle id `app.spotvibe`), sign the Paid Apps agreement, add tax/banking.
2. Create the subscription group and products exactly as in
   `STORE_PRODUCTS.md` (ids, prices, 7-day trial), with localized names and a
   review screenshot each.
3. RevenueCat → project → add the **iOS app**, upload the App Store Connect
   in-app purchase key, attach products to the same entitlements/offerings as
   Android, and put the **iOS public SDK key** (`appl_…`) in `secrets.json` as
   `REVENUECAT_APPLE_KEY` (read in `lib/services/revenue_cat_service.dart`).
4. Test purchases with a Sandbox tester; make sure Restore Purchases works.

## 8. App Store Connect privacy answers (App Privacy)
Must match `ios/Runner/PrivacyInfo.xcprivacy`:
- **Used to track you:** Device ID, Advertising Data, Product Interaction,
  Coarse Location (AdMob, only when ATT is allowed).
- **Linked to you (app functionality):** Name, Email, User ID, Precise &
  Coarse Location, Photos/Videos, Other User Content, Purchase History.
- **Not linked (diagnostics/analytics):** Crash Data, Performance Data,
  Other Diagnostic Data (Crashlytics, AdMob).
- Privacy policy URL: `https://spotvibe-cfa08.web.app/privacy.html`;
  account deletion is available in-app (Guideline 5.1.1(v)).
- Age rating questionnaire, review notes with a demo account, and screenshots.

## 9. Before submitting
- Build number must be higher than any uploaded (now 1.0.15+15).
- Facebook login stays disabled (`enableFacebookSignIn = false`); don't enable
  it without adding FacebookAppID/ClientToken and URL schemes to Info.plist.
