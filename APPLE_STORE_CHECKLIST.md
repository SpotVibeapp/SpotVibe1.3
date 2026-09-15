# SpotVibe — Apple App Store Launch Checklist

Everything needed to ship SpotVibe on the Apple App Store, including RevenueCat
(subscriptions) and the AdMob/ATT bits. Android-first is the plan — finish and
validate Google Play + RevenueCat first, then do iOS (it goes faster the second
time because the product IDs and RevenueCat entitlement/offerings are shared).

> Product IDs are shared across stores on purpose. Use the EXACT same IDs on
> Apple as on Google so RevenueCat maps them to the same `pro` entitlement:
> - `spotvibe_premium_monthly` — $12.99/mo + 7-day free trial
> - `spotvibe_premium_founding_monthly` — $9.99/mo (+ optional trial)

---

## 1. Apple Developer Account
- [ ] **Apple Developer Program** membership — **$99/year** (developer.apple.com).
  - Individual = fast. Organization = needs a **D-U-N-S number**, takes longer.
- [ ] **A Mac with Xcode** (required to build/upload iOS). No Mac = use a
      macOS cloud build/CI service. There is no Windows-only path for iOS.

## 2. RevenueCat — iOS app setup (mirrors the Google setup already done)
- [ ] RevenueCat → **Project settings → Apps → + New → App Store**.
- [ ] **Bundle ID** = `app.spotvibe` (must match the Xcode project).
- [ ] **App-Specific Shared Secret** — generate in App Store Connect
      (Users and Access → Integrations → In-App Purchase, or the app's
      subscription page) and paste into RevenueCat. (Apple's equivalent of the
      Play service-account JSON — far simpler, just a string.)
- [ ] **In-App Purchase Key (.p8)** — App Store Connect → Users and Access →
      Integrations → In-App Purchase → generate key; upload to RevenueCat for
      server-side validation / refund tracking.
- [ ] Copy the **`appl_` public SDK key** from RevenueCat → API Keys.
- [ ] Build with it via dart-define: `REVENUECAT_APPLE_KEY=appl_...`
      (the app already reads an Apple key path in `revenue_cat_service.dart`).

## 3. App Store Connect — subscription products
- [ ] Create a **Subscription Group** (e.g. "SpotVibe Premium").
- [ ] Add `spotvibe_premium_monthly` — $12.99/mo, **7-day free trial**
      (Introductory Offer).
- [ ] Add `spotvibe_premium_founding_monthly` — $9.99/mo (+ optional trial).
- [ ] Each product: localized **display name + description** and a **review
      screenshot** of the paywall (Apple requires the screenshot).
- [ ] In RevenueCat: attach both products to the **`pro`** entitlement and the
      **`default`** (monthly) + **`founding`** offerings. NO app code change.

## 4. App Store listing / metadata
- [ ] App name, subtitle, promotional text, description, keywords.
- [ ] **Screenshots** — required for **6.7" iPhone** (+ iPad sizes if iPad is
      supported). Apple is stricter than Google about exact sizes.
- [ ] **App icon 1024×1024** — no transparency, no rounded corners (Apple rounds).
- [ ] **Privacy Policy URL** (`legal_site/privacy.html`) + **Support URL**.
- [ ] **App Privacy "nutrition label"** (Apple's Data Safety equivalent) —
      declare location, purchases, identifiers, user content, AND the
      **advertising identifier / tracking** (because of AdMob).

## 5. iOS technical bits
- [ ] **AdMob iOS App ID** in `ios/Runner/Info.plist` — currently a TEST id
      placeholder (`GADApplicationIdentifier`). Replace with the real iOS app id
      before an iOS ads build.
- [ ] **AdMob iOS banner unit id** via dart-define: `ADMOB_BANNER_IOS=ca-app-pub-.../...`.
- [ ] **SKAdNetwork identifiers** in Info.plist for ad attribution (Google
      publishes the list to paste in).
- [ ] **App Tracking Transparency (ATT)** — required due to personalized ads.
      `NSUserTrackingUsageDescription` is ALREADY in Info.plist (added with the
      ads work). The AdMob/UMP flow triggers the ATT prompt.
- [ ] **Sign in with Apple** — REQUIRED by Apple because the app also offers
      Google/Facebook login. `sign_in_with_apple` is already in `pubspec.yaml`;
      enable the capability in Xcode + App Store Connect.
- [ ] **Push notifications** (if enabled on iOS) need an **APNs key**.
- [ ] Build in Xcode → upload via **Transporter** or Xcode → submit in
      App Store Connect.

## 6. Review expectations (differs from Google)
- Apple review is stricter/slower (typically 24–48h, sometimes more) and they
  **test the actual purchase** — subscriptions must be fully live or they reject.
- **Paywall clarity** is enforced: price, billing period, "auto-renews", and
  links to **Terms of Use (EULA)** + **Privacy Policy** must be visible on the
  paywall screen.
- Apple requires a **functional demo/review account** if login is needed to see
  core features.

---

## Quick reference table
| Category | Key items |
|---|---|
| Account | Apple Developer Program ($99/yr) + a Mac with Xcode |
| RevenueCat | iOS app + Shared Secret + .p8 IAP key + `appl_` SDK key |
| Products | Same IDs, in a subscription group, with paywall review screenshot |
| Listing | Screenshots, App Privacy label, privacy/support URLs |
| Tech | Bundle ID `app.spotvibe`, Sign in with Apple, AdMob iOS id + SKAdNetwork, ATT |
| Review | Stricter, tests purchases, paywall must show price/terms/privacy |

## Recommended sequence
1. Finish Google Play + RevenueCat (credentials green → products imported →
   test purchase → public launch).
2. THEN start iOS — reuse the same product IDs, entitlement, and offerings.
3. Do Apple's account + Mac/Xcode setup, add the iOS app in RevenueCat, create
   the products, fill the listing, and submit.
