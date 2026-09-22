# SpotVibe — Open Beta go-live gate

Promote the SAME build through the tracks: closed testing → open testing → (later)
production. Do the verify steps once; the artifact you verify is the one you ship.

Current: branch `arena/01a07f45-spotvibe1-3`, version **1.0.4+12** (versionCode 12).

---

## A. Verify the code (on your machine — do first)

```
git checkout -- lib/l10n/app_localizations.dart lib/l10n/app_localizations_en.dart lib/l10n/app_localizations_es.dart
git pull
flutter pub get
flutter analyze     # expect 0 issues
flutter test        # all files pass
```
Paste any analyze/test failures to me before building.

## B. Smoke-test on the device (SM-F956U), a DEBUG or PROFILE run

- [ ] App launches (no AdMob "Missing application ID" crash).
- [ ] Home feed loads events; banner + "Remove ads with Premium" shows (free user).
- [ ] Event detail: media gallery, photo enlarge, video play.
- [ ] Create/edit: add cover + gallery photo → tap to enlarge; add video → plays.
- [ ] Empty category: no bottom overflow.
- [ ] Map: jump-to-area loads events + gems; "Showing: City, ST" banner; search
      bar clears the home buttons; reset returns to GPS.
- [ ] Paywall opens (from Remove-ads link and profile).
- [ ] Premium/reviewer path: banners + upsell disappear (ad-free is real).

## C. Build the release App Bundle

Store the two ad IDs first (see ADMOB_SETUP_GUIDE.md):
- `secrets.json` → `REVENUECAT_ANDROID_KEY` (goog_…) + `ADMOB_BANNER_ANDROID` (…/…)
- `android/gradle.properties` → `admobAppId=ca-app-pub-…~…`

```
flutter build appbundle --release --dart-define-from-file=secrets.json
```

- [ ] **Do NOT pass `REVIEWER_PREMIUM_EMAIL`** (omit for open beta AND prod).
- [ ] Uses the **rotated** Ticketmaster key in secrets.json.
- [ ] versionCode is 11 (unused). Bump if Play says it's taken.

## D. Google Play Console — declarations (ads are now on)

- [ ] App content → **Ads = Yes, contains ads**.
- [ ] Data safety → **Advertising ID = collected**, purposes Advertising + Analytics.
- [ ] Content rating / target audience still accurate.
- [ ] Privacy policy + account deletion URLs present.

## E. Promote to Open testing

1. Upload the `.aab` to the current **Closed testing** track first (sanity), OR
   directly create/populate the **Open testing** track.
2. Open testing → set up the track → add release notes → **Save**.
3. **Review + roll out** → then **START ROLLOUT** (the step that's been missed
   before — a release sits as "Draft" until you click Start rollout).
4. Copy the **opt-in URL** Play generates for open testers.

## F. Post-launch watch

- [ ] Crashlytics: no fatal spikes (verify with a profile-build test-crash once).
- [ ] AdMob: account approved + ads serving (can take hours–days; blank slots
      until then are normal and handled gracefully).
- [ ] RevenueCat: confirm one real test purchase works (license-test account) —
      do this before promoting to PRODUCTION, not required for open beta.

---

### Not blocking open beta (can follow later)
- AdMob account may still be "in review" — fine, test ads/no-fill until approved.
- Real subscription purchase E2E — required before PRODUCTION, not open beta.
- iOS build — separate track (see IOS_SETUP.md / APPLE_STORE_CHECKLIST.md).
