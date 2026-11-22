# SpotVibe age-assurance plan: Texas SB 2420 and other app-store age laws (Nov 22, 2026)

**PLAN ONLY.** No code was written, nothing was deployed, and nothing was submitted. This is not legal advice; §9 lists the questions for a lawyer.
Labels:
- **[Fact]** = from the cited source.
- **[Uncertain]** = sources disagree, the item is still in litigation, or it's my reading of it.
- **[Opinion]** = my recommendation.

SpotVibe context [Fact, repo]:
- It's a Flutter app with user-generated events, comments, follows and RSVPs, and a host subscription (Premium $12.99/mo through RevenueCat in-app purchase).
- Android `minSdk 26`; iOS deployment target 15.6.
- Launch metro is El Paso, Texas.
- The Terms say users must be **at least 13**. `PLAY_APP_CONTENT.md` recommends a Play target audience of **18+**.
- The IARC questionnaire answers "users interact" and "users share UGC". The hub notes the app sits on the **Teen** rating question.
- **The 13+ vs 18+ mismatch is the first decision this plan needs (§6, step 0).**

---

## 1. Current status of the laws (as of Nov 22, 2026)

| State | Law | Status | Applies to | Enforcement |
|---|---|---|---|---|
| **Texas** | SB 2420, Bus. & Com. Code ch. 121 ([statute](https://statutes.capitol.texas.gov/docviewer?docName=BC.121.v3.htm)) | Effective Jan 1, 2026. Enjoined Dec 23, 2025. **Enforceable since Jun 4, 2026**, when the Fifth Circuit stayed the injunction pending appeal. The Supreme Court declined to vacate the stay on Jul 6, 2026 (not a merits ruling). Argued Aug 4, 2026; **merits decision pending** ([tracker](https://texasdatalaw.com/tracker/sb-2420/); [Squire Patton Boggs, Nov 19, 2026](https://natlawreview.com/article/app-store-age-verification-laws-your-questions-answered-updated)) [Fact] | App stores **and developers**. **New** app-store accounts only ([SPB](https://natlawreview.com/article/app-store-age-verification-laws-your-questions-answered-updated)) [Fact] | Texas AG under the DTPA; up to $10,000 per violation [Fact] |
| **Utah** | SB 142 as amended by HB 498 | Obligations start **May 6, 2027**; existing accounts within 12 months. Private right of action only, against **app stores**; developers aren't subject to it, but other remedies remain ([SPB](https://natlawreview.com/article/app-store-age-verification-laws-your-questions-answered-updated)) [Fact] | App stores and developers | Private suits ($1,000/violation or actual damages) |
| **Louisiana** | HB 570 as amended by HB 977 / Act 185 | Starts **Jul 1, 2027** ([SPB](https://natlawreview.com/article/app-store-age-verification-laws-your-questions-answered-updated)) [Fact] | App stores and developers. Developers rely on the store signal unless their own data is more accurate [Fact] | AG; up to $10,000/violation after a 45-day cure [Fact] |
| **Alabama** | HB 161 / Act 2026-59 | Starts **Jan 1, 2027**; existing accounts by Oct 1, 2027. CCIA sued Oct 28, 2026; preliminary-injunction motion pending ([SPB](https://natlawreview.com/article/app-store-age-verification-laws-your-questions-answered-updated)) [Fact; outcome **Uncertain**] | App stores and developers | AG; up to $7,500/violation |
| **California** | AB 1043 as amended by AB 1856 (Digital Age Assurance Act) | Starts **Jan 1, 2027**; pre-2027 installs by Jul 1, 2027. Self-declared age, no parental-consent duty. Developers must request the signal at download and launch, and they are deemed to have **actual knowledge** of age ([SPB](https://natlawreview.com/article/app-store-age-verification-laws-your-questions-answered-updated)) [Fact] | OS providers, app stores, developers | AG; $2,500–$7,500 per affected child |
| Federal | App Store Accountability Act (H.R. 3149 / S. 1586) | Reported from House committee Mar 2026; no floor vote ([SPB](https://natlawreview.com/article/app-store-age-verification-laws-your-questions-answered-updated)) [Fact] | — | **Uncertain** whether it passes or preempts state laws |

Apple applied Texas rules to **new Texas Apple Accounts starting Jun 4, 2026** ([Apple, Jun 3, 2026](https://developer.apple.com/news/?id=sg176nne)) [Fact]. Google says Play will verify and share age where a state requires it, following "that specific state's legal requirements and effective dates" ([Play Help](https://support.google.com/googleplay/android-developer/answer/16569691?hl=en)) [Fact].

**[Uncertain]**
- The Fifth Circuit could reinstate the injunction at any time.
- Alabama could be enjoined before Jan 1, 2027.
- These dates have moved twice already. Plan for the strictest live law (Texas) and re-check monthly.

## 2. What the laws require: stores vs developers

### App stores (Apple, Google) [Fact, SPB and statute]
- Verify the age category of each new account with a "commercially reasonable method". The categories are under 13, 13–15, 16–17, and 18+.
- Link minor accounts to a parent.
- Get **parental consent for every download, purchase and in-app purchase** by a minor (TX, UT, LA, AL).
- Re-obtain consent when a developer reports a **significant change**.
- Give developers the age category and consent status.
- Notify developers when a parent **revokes** consent.

### Developers (Texas text, Bus. & Com. Code ch. 121, subch. C) ([statute](https://statutes.capitol.texas.gov/docviewer?docName=BC.121.v3.htm)) [Fact]
1. **§121.052 Age rating.** Assign an age rating to the app **and to each purchase** that can be made in it, using the four categories. Give each store the rating and the content that led to it.
2. **§121.053 Significant change notice.** Notify each store **before** a significant change to the terms of service or privacy policy. A change is significant if it:
   - changes the type or category of personal data collected, stored or shared;
   - changes the rating or the content behind it;
   - adds new monetization (purchases or **ads**); or
   - materially changes functionality or user experience.
3. **§121.054 Age verification.** Build a system that uses the store's information to verify each user's age category and, for minors, whether consent was given.
4. **§121.055 Data use.** Use the store's age data **only** to enforce age restrictions, comply with law, and implement safety features and defaults. **Delete it after verification** ([statute](https://statutes.capitol.texas.gov/docviewer?docName=BC.121.v3.htm)) [Fact; the exact deletion timing is **Uncertain** → §9].
5. **Contracts with minors.** Terms of service can't be enforced against a minor without verifiable parental consent (TX, UT, LA) ([SPB](https://natlawreview.com/article/app-store-age-verification-laws-your-questions-answered-updated)) [Fact].
6. **Safe harbor.** Texas gives one for good-faith reliance on store age and consent data. Utah and Alabama require using the **lowest** age category known to the developer ([SPB](https://natlawreview.com/article/app-store-age-verification-laws-your-questions-answered-updated)) [Fact].

### Knock-on effect: actual knowledge [Fact, SPB]
- Once a store tells SpotVibe a user is under 13, COPPA applies: restrict the account and delete its personal data unless there is verifiable parental consent.
- California treats 13–15 year-olds as needing opt-in for data "sale/sharing".

## 3. Apple: Declared Age Range API and related tools

- **What it returns.**
  - The person's age range against up to three age gates you choose (each range at least 2 years).
  - Whether parental controls are on.
  - The declaration source.
  - In regulated regions the system can share automatically, and the region sets the gates. Otherwise the user (or parent) may decline ([Apple docs](https://developer.apple.com/documentation/declaredagerange/requesting-people-share-their-age-range-with-your-app)) [Fact].
- **Eligibility check.** `isEligibleForAgeFeatures` says whether age assurance applies to this person (by location and account) ([Apple docs](https://developer.apple.com/documentation/declaredagerange/requesting-people-share-their-age-range-with-your-app)) [Fact].
- **Texas.** Age categories for new Texas accounts are shared on request, along with the assurance method (e.g. credit card or ID) and whether consent is needed for a significant change ([Apple, Nov 4, 2025](https://developer.apple.com/news/?id=2ezb6jhj)) [Fact].
- **Also required for Texas** ([Apple, Jun 3, 2026](https://developer.apple.com/news/?id=sg176nne)) [Fact]:
  - the **Significant Change API (PermissionKit)**, which triggers a system parental-consent dialog; the app may restrict access until consent arrives;
  - a **StoreKit age-rating property**, to detect when the app's rating changed on the device;
  - an **App Store Server Notification** for consent revocation;
  - sandbox testing.
- **Entitlement and versions.**
  - Needs `com.apple.developer.declared-age-range` ([Apple docs](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.declared-age-range)) [Fact].
  - The API is **iOS 26+**; eligibility is iOS 26.2+ ([age_range_signals](https://pub.dev/packages/age_range_signals)) [Fact, plugin docs].
  - SpotVibe targets iOS 15.6, so older devices need a fallback (§5).
- **Caching.** Responses are cached. A user who turns 13 keeps the old range until the anniversary of their declaration, unless they update it in Settings ([Apple docs](https://developer.apple.com/documentation/declaredagerange/requesting-people-share-their-age-range-with-your-app)) [Fact].
- **App Store age ratings.**
  - Ratings are now 4+/9+/13+/16+/18+. The new questionnaire was due Jan 31, 2026; updates are blocked until it's answered ([Apple](https://developer.apple.com/news/?id=ks775ehf); [Upcoming requirements](https://developer.apple.com/news/upcoming-requirements/)) [Fact].
  - If the EULA's minimum age is higher than the calculated rating, you **must override** to that higher rating ([App Store Connect Help](https://developer.apple.com/help/app-store-connect/manage-app-information/set-an-app-age-rating/)) [Fact].

## 4. Google Play: Age Signals API (beta)

- **Flow** ([Android docs](https://developer.android.com/google/play/age-signals/request-age-signals)) [Fact]:
  - `getApplicableAgeFeatures()` returns `MANDATORY_SHARING` in regulated regions.
  - `requestAgeSignalsAccess()` returns `SHARED`, `NOT_SHARED` or `VERIFICATION_REQUIRED`. With `VERIFICATION_REQUIRED`, send the user to the Play Store to verify.
  - `checkAgeSignals()` returns `ageLower`/`ageUpper`, `ageRangeSource`, `installId` and `significantChangeApprovalDate`.
- **Play Console** ([Play Help](https://support.google.com/googleplay/android-developer/answer/16569691?hl=en)) [Fact]:
  - Report a **significant change** without publishing a new version.
  - See a **report of parental revocations**.
  - Add **age ratings to in-app products** (SKUs).
- **Play doesn't revoke access** when a parent denies a significant change. The developer reads the approval status and acts on it [Fact, same page].
- **Play does not mandate** the API. Compliance is the developer's responsibility, and API data must follow Play's data-handling rules [Fact, same page].
- **Beta and regions.** The plugin docs say Google's status banner names only **Brazil and Texas** as live ([age_range_signals](https://pub.dev/packages/age_range_signals)) [Est., third-party; **Uncertain**]. Requires `minSdk ≥ 23` (SpotVibe is 26 ✓) and an install from Play [Fact, plugin docs].

## 5. What SpotVibe should do [Opinion, based on §2–4]

**Product stance.** Recommended, pending Blake and counsel:
- Keep a **13+ minimum**. Don't block teens outright: run clubs, markets and game nights are legitimate teen activities.
- Apply **minor-safe defaults** to anyone the store reports as under 18.
  - Alternative: a simpler 18+ minimum (drop teens). That avoids most minor flows but loses an audience and still needs the age check to enforce it.
  - **Blake decides.**
- For users the store reports as **under 13**:
  - block account creation and posting;
  - sign out;
  - delete any personal data already collected (COPPA).

**Minor-safe defaults (13–17)** [Opinion]:
- Can browse events, save, RSVP and comment.
- Can't post public events. Alternative: posts go to a moderation queue.
- Can't receive DMs from adults they don't follow. This applies once DMs (PR #16) land.
- No AI promo image.
- No personalized ads (AdMob: set `tagForUnderAgeOfConsent`/max ad content rating; check the AdMob docs during the build).
- Profile hidden from search.
- Can't buy Premium, since hosts are businesses. Alternatively, buying it requires the store's parental purchase consent, which the stores handle for in-app purchases.

**Data handling** (Texas §121.055):
- Use the age band only for gating and defaults.
- Don't send it to analytics or ads.
- Store only a derived flag (`ageBand` and `verifiedAt`) server-side, or nothing at all if a per-session check is enough.
- Delete the raw API response right after verification. The exact retention needs counsel (§9).

**Significant changes** (§121.053):
- Keep a checklist in `RELEASE_TODO_BLAKE.md`. Any release that changes data collected, the rating, monetization (ads, new purchases) or major functionality → notify Apple (Significant Change API) and Google (Play Console) **before** release.
- Examples already in the pipeline: **DMs (#8/#16)**, **AdMob ads**, the **ratings/reviews prompt (#9)** and attendee messaging.

**Revocation.**
- Subscribe to the App Store Server Notification. Read the Play Console report (and/or the API status).
- On revocation: lock the minor's account to read-only, sign out, and hide their public content until re-consent.

## 6. Order of implementation (iOS launch is the deadline for Apple; Texas Play users are covered now)

**0. Decide before any code (Blake + counsel).**
- Minimum age: 13+ with teen defaults, or 18+.
- Make the Terms, privacy policy, Play target audience and App Store age rating all say the same thing. Today they don't: Terms say 13+, the Play plan says 18+.

**1. Store questionnaires (no code).**
- Re-answer Play IARC and Apple's age-rating questionnaire honestly: UGC, user interaction, messaging when it lands, ads, AI image generation. **Expect Teen / 13+ or higher.**
- If minimum age = 18, override Apple to 18+ and set Play's target audience to 18+.
- Assign age ratings to the Premium SKUs in Play Console and App Store Connect.

**2. Age signal plumbing (build).**
- One Dart service backed by a plugin. Candidate: `age_range_signals` 0.10.x, which bridges Play Age Signals and Apple's Declared Age Range, including eligibility and the significant-update sheet ([pub.dev](https://pub.dev/packages/age_range_signals)). It's third-party and young, so evaluate it or write a thin platform channel [Opinion].
- iOS needs the entitlement, the capability on the App ID, and a fallback for iOS < 26.
- Android needs nothing extra (minSdk 26).

**3. Gating and defaults (build).**
- Map the band to the minor-safe defaults in §5.
- Enforce them **server-side** too (Cloud Functions: `saveUserEvent`, comments, DMs). **No Firestore rules changes** until Blake OKs a rules deploy.

**4. Revocation and significant change (build + console).**
- iOS: App Store Server Notification endpoint (a new HTTPS function, which needs a deploy), PermissionKit significant-change flow, StoreKit rating-change check.
- Android: Play Console significant-change notices; read `significantChangeApprovalDate`.

**5. Privacy policy and Terms update.**
- Describe age-band processing, its purpose and deletion.
- Minor-contract language (Texas: terms are unenforceable against minors without parental consent).

**6. Sandbox and QA (§8). Then submit the iOS build.**

**7. Monthly re-check of the litigation and dates.**
- Fifth Circuit ruling; Alabama preliminary injunction (before Jan 1, 2027); California Jan 1, 2027; Utah May 6, 2027; Louisiana Jul 1, 2027.

**Rough effort [Opinion]:** steps 1 + 5 take about a day of Blake/counsel time. Steps 2–4 are about 4–6 agent days, and the iOS server notification and PermissionKit parts need a Mac/Xcode build (Codemagic). Step 6 takes about 1–2 days.

## 7. Store listing and privacy-label impact

**Apple App Privacy label.**
- An age band derived from Apple is still data the app processes. Whether it must be declared (e.g. "Other data", linked to the user, for app functionality) depends on whether it's stored with the account. **Uncertain → §9.**
- If SpotVibe keeps only an ephemeral, on-device gate, it may not count as "collected".

**Google Play Data safety.**
- Same question. Play's rules for Age Signals data also apply ([Play Help](https://support.google.com/googleplay/android-developer/answer/16569691?hl=en)).
- Update the Data safety form if a band is stored server-side.

**Age ratings.**
- Apple: likely **13+ or 16+** given UGC, user interaction and planned messaging (the calculated result depends on the questionnaire answers) [**Uncertain**].
- Play IARC: likely **Teen**.
- If the minimum is 18, both go to **18+** and the listing says so.

**Listing copy.**
- Don't call SpotVibe "for teens" unless the 13+ path is chosen.
- If it is chosen, add a line on safety defaults for under-18s.
- Keep screenshots adult-oriented per `PLAY_APP_CONTENT.md`.

**Play target audience.** Must match the decision in step 0. Including 13–17 adds Play's teen-related policy expectations [**Uncertain**; check the Families/target-audience policy at build time].

**Every future listing change that adds ads, purchases or messaging is a significant change** that needs a store notice first (§5).

## 8. Test cases (sandbox / mock; pass = expected behavior)

| # | Setup | Expected |
|---|---|---|
| T1 | iOS sandbox, Texas new account, adult (18+) shared | Full access. Band used, then raw data discarded. Nothing sent to analytics |
| T2 | iOS sandbox, Texas teen 13–15 with parental consent | Minor-safe defaults on. Can't post public events. Premium purchase triggers the store parent flow |
| T3 | iOS sandbox, Texas child < 13 | Account creation blocked; existing account locked; data deletion job queued |
| T4 | iOS sandbox, teen, parent **revokes** consent | Server notification received; account read-only/signed out within one sync; content hidden |
| T5 | iOS, Significant Change API called after a rating change | Teen sees the system consent dialog; features gated until approved |
| T6 | iOS < 26 device (no API) | Fallback: the existing 13+ Terms acceptance; no crash; no fake "verified" state |
| T7 | Non-regulated region, user declines sharing | App works as today (13+ Terms); no repeated nagging |
| T8 | Android, `FakeAgeSignalsManager`: `VERIFICATION_REQUIRED` | User sent to the Play Store to verify; app explains why; no crash |
| T9 | Android, `SHARED` 16–17 | Teen defaults. `significantChangeApprovalDate` older than the last significant change → gated feature stays off |
| T10 | Android, `NOT_SHARED` outside regulated states | Normal 13+ path |
| T11 | Server-side: a teen calls `saveUserEvent` directly (bypassing the UI) | Function rejects. Defense in depth |
| T12 | Data audit | Age band absent from analytics, logs, ads requests and Firestore except the agreed derived flag |
| T13 | Release checklist | A build adding DMs or ads is blocked until both store significant-change notices are recorded |

## 9. Open legal questions for a lawyer

1. Under SB 2420, is a **free** app with optional host subscriptions and UGC covered in full? Are any exemptions relevant? [Uncertain]
2. Is **13+ with teen defaults** defensible, or should SpotVibe go **18+** given UGC, messaging and nightlife-adjacent events?
3. **§121.055 deletion.** Must the age band be deleted immediately after each check, or may a derived "minor/adult" flag be kept to enforce defaults? For how long?
4. Does storing a derived flag need to be declared on the Apple privacy label and Play Data safety form?
5. What counts as a **significant change** for SpotVibe's roadmap: DMs, AdMob ads, reviews, AI promo images, a price change? Notice timing: how long before release?
6. With store data giving **actual knowledge** of a user under 13: what's the COPPA deletion scope and timeline? Also how this interacts with Texas SCOPE Act/HB 18 duties for minors, which this plan didn't research. [Uncertain]
7. **Contracts with minors.** Without parental consent, which Terms provisions (moderation, bans, licensing of posted content) can SpotVibe still enforce?
8. **Users on older iOS or outside the store signal.** Is relying on the store "good faith" enough, or is a self-declared birthdate gate expected?
9. Utah and Alabama "lowest age category" rule: if SpotVibe later collects a birthdate, does that override the store signal?
10. California AB 1043 (Jan 1, 2027): does requesting the signal "at download and launch" mean every launch? How do the CCPA teen opt-in rules apply?
11. If the Fifth Circuit strikes SB 2420, should SpotVibe keep the age features anyway (multi-state laws, App Store 1.2 UGC expectations)?

## 10. Not done / unverified

- Apple's Texas Q&A ("Age assurance frameworks Q&A") and the PermissionKit and server-notification reference pages weren't read in full. Re-read them at build time.
- The Alabama, Louisiana, Utah and California dates come from one law-firm summary (Nov 19, 2026) plus the Texas statute and tracker. They weren't checked against every bill text.
- The `age_range_signals` plugin hasn't been evaluated in code.
- The AdMob teen settings weren't researched.
- The Texas SCOPE Act (HB 18) and COPPA 2025 amendments are out of scope here and flagged for counsel.
