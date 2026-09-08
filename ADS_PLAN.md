# Banner ads for free users — plan (deferred to a post-first-beta build)

**Decision (yours):** free users see banner ads; **ad-free is a Premium benefit**. Ads are
**NOT** in the first closed-beta upload — that build stays "no ads". This doc is the plan for the
*later* build that turns ads on.

**Recommendations (mine):**
- **Network:** Google **AdMob** (`google_mobile_ads`).
- **Placement:** start with **one** anchored **adaptive bottom banner** on the events/feed screen,
  above the bottom nav. Add event-detail later if wanted. Never on paywall/purchase screens.
- **Gate:** show only when `!subscriptionProvider.isSubscribed` (the `pro` entitlement already is
  the single source of truth — verified in `lib/providers/subscription_provider.dart`).

---

## A. AdMob account setup (you do this in the AdMob console)
1. Create/confirm an AdMob account at https://admob.google.com and **link it to the same Google
   Play app** (AdMob → Apps → Add app → Android → link to Play listing).
2. Create the app → note the **App ID**: `ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY` (has a `~`).
3. Create **one ad unit**: type **Banner** → note the **Ad unit ID**:
   `ca-app-pub-XXXXXXXXXXXXXXXX/ZZZZZZZZZZ` (has a `/`).
4. (Later, iOS) repeat for an iOS app + iOS banner unit — different IDs.
5. In **AdMob → Privacy & messaging**, set up a **GDPR/UMP consent form** and a
   **US-states / CCPA** message. Even US-only, Google's UMP flow is the clean way to stay policy-
   compliant; the SDK includes `UserMessagingPlatform`.
6. Fill **App-ads.txt** later if you monetize a website; not needed for the app itself.

> Until you have real IDs, the code will use **Google's official public test IDs** so nothing
> breaks and you never risk a policy strike for clicking your own live ads during testing.
> Test banner unit (Android): `ca-app-pub-3940256099942544/6300978111`.
> Test App ID (Android): `ca-app-pub-3940256099942544~3347511713`.

---

## B. Code changes (when you say go — NOT yet)
Small and self-contained. Estimated ~1–2 commits.

1. **Dependency:** add `google_mobile_ads: ^5.x` to `pubspec.yaml`.
   - Also pin/verify: it needs `minSdkVersion 23` (check `android/app/build.gradle.kts`).
2. **Manifest** (`android/app/src/main/AndroidManifest.xml`):
   - Add the AdMob **App ID** meta-data:
     ```xml
     <meta-data
         android:name="com.google.android.gms.ads.APPLICATION_ID"
         android:value="ca-app-pub-XXXX~YYYY"/>
     ```
   - Add the required permission (this **reverses** the current no-AD_ID posture):
     ```xml
     <uses-permission android:name="com.google.android.gms.permission.AD_ID"/>
     ```
   - Prefer supplying the App ID via a build value / `--dart-define`-driven manifest placeholder so
     it isn't hardcoded, matching how keys are handled elsewhere.
3. **Init:** `MobileAds.instance.initialize()` in `main.dart` startup (after Firebase). Gate init
   so it's skipped on web.
4. **Consent:** run the UMP consent flow before requesting the first ad (US CCPA + future EU).
5. **A reusable widget** `lib/widgets/common/ad_banner.dart`:
   - Reads `context.watch<SubscriptionProvider>().isSubscribed`.
   - If subscribed → returns `SizedBox.shrink()` (zero height, no ad requested — so Premium truly
     never loads an ad).
   - Else → loads an **adaptive** banner sized to screen width; shows a fixed-height placeholder
     while loading so the layout doesn't jump.
   - Ad unit ID via `String.fromEnvironment('ADMOB_BANNER_ANDROID', defaultValue: <test id>)` so
     real IDs come from `--dart-define`, never committed.
6. **Mount point:** in `events_screen.dart`, place `const AdBanner()` in the bottom slot (a
   `bottomNavigationBar`-adjacent area or a `Column` above the nav), so it's anchored, not inline.
7. **Reactivity:** because it watches the provider, the banner disappears the instant a user buys
   Premium / restores purchases — no restart needed.

**Bracket-balance check** will run on every touched Dart file before committing (per our rules).

---

## C. Store / policy / doc corrections that MUST land in the same build as ads
Turning ads on reverses three things currently declared. When we ship the ads build I will edit:

1. **`PLAY_APP_CONTENT.md` §2 Ads:** `No` → **`Yes, contains ads`**.
2. **`PLAY_APP_CONTENT.md` §6 Data safety:** add **Device or other IDs → Advertising ID**:
   *Collected: Yes; Shared: Yes (Google AdMob); Purpose: Advertising or marketing, Analytics.*
   If you keep personalized ads on, this is "shared for advertising/marketing".
3. **`PLAY_APP_CONTENT.md` §5 Target audience:** ads + AD_ID reinforce **18+** and
   "does not appeal to children = No". Keep it adult-targeted (ad content ratings also apply).
4. **Privacy policy** (`legal_site/privacy.html`): today it says *"We do not sell personal
   information or share it for cross-context behavioral advertising."* That line must change — add
   an **Advertising** section naming Google AdMob, the advertising identifier, a link to Google's
   partner policy, and how users can opt out / reset their ad ID. (Consider **non-personalized
   ads** to keep the disclosure lighter — set `MaxAdContentRating` and request NPA.)
5. **Content rating questionnaire:** re-answer "contains ads = Yes" (may require re-submitting the
   IARC questionnaire).

> Net: ads are a policy-visible change, not just a code change. That's exactly why we're keeping
> them out of the *first* beta and doing them as a clean, self-contained follow-up build with the
> declarations updated in lockstep.

---

## D. Suggested sequence
1. First closed beta → **no ads** (as planned; rotate the TM key, upload signed AAB).
2. You set up AdMob (section A), paste me the **App ID + banner unit ID** (or say "use test IDs").
3. I implement section B + update section C docs in one commit set.
4. You run `flutter analyze` / `test`, then a device check: verify banner shows for a free/guest
   account and is **absent** for a Premium account (buy or restore in a test track).
5. New signed AAB → testing track.
```
