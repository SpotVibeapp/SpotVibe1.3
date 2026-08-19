# Store products — $12.99 monthly + $9.99 founding

The app bills through Apple and Google via RevenueCat. Create **two** auto-renewing subscriptions and attach both to the `pro` entitlement.

Use these IDs **exactly** (they are hardcoded in `lib/data/pricing.dart`):

| Role | Product ID | Price | Intro |
|---|---|---|---|
| Standard Premium | `spotvibe_premium_monthly` | **$12.99 / month** | **7-day free trial**, then $12.99 |
| Founding (first 25 venues) | `spotvibe_premium_founding_monthly` | **$9.99 / month** | 7-day free trial recommended, then $9.99 locked |

Same IDs on iOS and Android. Both products grant the same `pro` entitlement. The app picks the founding SKU while slots remain (or if the account already bought it). After 25 founding purchases it only offers `spotvibe_premium_monthly`.

---

## 1. App Store Connect (iOS)

1. [App Store Connect](https://appstoreconnect.apple.com) → your app → **Subscriptions**.
2. Create a subscription group, e.g. `SpotVibe Premium`.
3. Add subscription **`spotvibe_premium_monthly`**
   - Reference name: SpotVibe Premium Monthly
   - Subscription duration: 1 month
   - Price: **USD 12.99**
   - Introductory offer: **Free**, duration **1 week**, new subscribers
4. Add subscription **`spotvibe_premium_founding_monthly`**
   - Reference name: SpotVibe Premium Founding Monthly
   - Duration: 1 month
   - Price: **USD 9.99**
   - Optional but recommended: same 1-week free intro
5. Add localized display names / descriptions (required before the products go live).
6. Submit the IAPs with an app version, or use a StoreKit Configuration file for local testing.

Paid Apps Agreement + banking + tax must be active or products stay missing in RevenueCat.

---

## 2. Google Play Console (Android)

1. [Play Console](https://play.google.com/console) → your app → **Monetize → Products → Subscriptions**.
2. Create subscription **`spotvibe_premium_monthly`**
   - Name: SpotVibe Premium
   - Base plan: monthly, **$12.99**
   - Offer: free trial **7 days** (new customers)
3. Create subscription **`spotvibe_premium_founding_monthly`**
   - Name: SpotVibe Premium Founding
   - Base plan: monthly, **$9.99**
   - Optional offer: free trial 7 days
4. Activate both. Upload a signed build that includes Billing permission (already in the Flutter app via `purchases_flutter`) to an internal testing track so Play will serve the products.

---

## 3. RevenueCat

1. Upgrade/install dependencies first:
   ```bash
   flutter pub get
   ```
   SpotVibe uses `purchases_flutter` 9+ for current Google Play Billing support
   and automatically identifies RevenueCat customers with their Firebase UID at
   sign-in, so a partner's entitlement follows their SpotVibe account.
2. [RevenueCat](https://app.revenuecat.com) → Project → **API keys**. Get the iOS and Android **public SDK keys** and pass them at build time via dart-define (they are read from `String.fromEnvironment` in `lib/services/revenue_cat_service.dart`):

```bash
flutter build appbundle --release \
  --dart-define=REVENUECAT_ANDROID_KEY=goog_xxx \
  --dart-define=REVENUECAT_APPLE_KEY=appl_xxx
```

Never hardcode the keys in source.

3. **Products** → import / add both store products. Identifiers must match the table above.
4. **Entitlements** → create **`pro`**. Attach **both** products to `pro`.
5. **Offerings**
   - Current offering identifier: `default`
     - Package type **Monthly** → `spotvibe_premium_monthly`
   - Second offering identifier: `founding`
     - Package type **Custom** or Monthly → `spotvibe_premium_founding_monthly`
6. The app reads every offering, so founding does not need to be “current.”

---

## 4. How the app charges

```
if (user already owns founding SKU) OR (founding slots < 25)
    purchase spotvibe_premium_founding_monthly   // Apple/Google bill $9.99
else
    purchase spotvibe_premium_monthly            // Apple/Google bill $12.99 after 7-day intro
```

A successful founding purchase also writes the uid into Firestore `meta/founding` so the 25-slot cap stays in sync. Restoring an Apple/Google founding purchase re-claims that slot.

Debug/profile builds can use a local 7-day trial to exercise the Premium UI before store products are available. A **release** build never grants Premium from that fallback: if RevenueCat keys, active products, or a store entitlement are missing, the purchase fails instead of claiming the customer was charged.

---

## 5. One-time partner offer codes

Do **not** create an app-owned code that directly grants Premium. Apple and
Google must issue the code and process the free or discounted subscription.

1. In **App Store Connect**, create the appropriate subscription offer-code
   batch for a free period supported by that subscription offer.
2. In **Google Play Console**, create the matching one-time subscription promo
   code batch using a supported free-trial duration.
3. In SpotVibe, sign in as an admin → **Profile → Admin Dashboard → Partner
   codes**. Paste each store-issued code into the private inventory, including
   its platform and offer-duration label.
4. When meeting a business partner, tap **Issue** on one available code, record
   the partner, then copy/share that code. An issued code can never be assigned
   to another partner in SpotVibe.

The dashboard is an issuance ledger, not a storefront: it cannot change a
store offer's price or duration, and revoking a record in SpotVibe does not
revoke the code at Apple or Google. Deactivate an unused code in that matching
store console as well.

---

## 6. Checklist before launch

- [ ] Both products Approved / Active in App Store Connect and Play Console
- [ ] 7-day free intro on `spotvibe_premium_monthly`
- [ ] RevenueCat public SDK keys supplied as release-build `--dart-define` values (not committed)
- [ ] Entitlement `pro` includes both products
- [ ] Offerings `default` + `founding` exist
- [ ] Sandbox / license-tester purchase of each SKU
- [ ] Restore Purchases returns `pro` for both products
