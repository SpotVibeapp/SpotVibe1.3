# Staged rules deploy (after 1.0.15 is the installed beta)

These repo rules are tighter than what is live. **Do not deploy
`firestore.rules` or `storage.rules` / `storage.rules.staged` until testers
are on 1.0.15 (or later).** The installed open beta is still treated as
v14. Shipping these rules first would break v14 signup-adjacent founding
writes and any Premium perk fields that the old binary still writes from
the client.

`storage.rules` in this folder stays v14-compatible on purpose. The
entitlement-gated file is `storage.rules.staged`.

## What 1.0.15 already does

- Event create/update goes through the `saveUserEvent` callable. The
  server checks the RevenueCat `pro` entitlement (or the admin roster)
  and is the only path that may write recurring events, extra media,
  branding, contact phone/website, `isCreatorPro`, or more than two
  upcoming events. Client-supplied `featuredWeekKey` / `isPremiumListing`
  are ignored; only `featureEvent` grants featuring.
- If the callable is down, the app falls back to a **free-shaped**
  direct write (1 photo, 1 video, no perk fields) so posting is not
  bricked. Premium fields are not written on that fallback.
- Public analytics bumps include `analyticsShares`.
- The paywall CTA uses store intro-offer eligibility and no longer
  always says “Start free trial.”

## Deploy order (after Blake confirms 1.0.15 is the installed beta)

1. Confirm Play testers are on 1.0.15+ (versionCode ≥ 15) and the
   functions below are live on `spotvibe-cfa08`:
   `saveUserEvent`, `featureEvent`, `claimFoundingSlot`,
   `downgradeExpiredPremium`, `enforceEventPerksOnWrite`,
   `enforceEventPerksOnFeedWrite`, `recordEventAnalytics`, and
   ideally `revenueCatWebhook`.
2. Deploy Firestore rules only:
   `firebase deploy --only firestore:rules`
   After this, client writes must stay free-shaped. Premium perk
   fields can only be written by the Admin SDK (the callables).
3. Extra media uploads: do **not** deploy `storage.rules.staged` until
   a signed-URL function (or equivalent) is wired in the 1.0.15+ app
   for `photo_*` and `video_2+`. Until then, live Storage rules still
   allow an owner to upload extra files; the server trims unpaid
   galleries on write / lapse, which closes the listing leak even if
   leftover files sit in the bucket.
4. When the signed-URL path is ready: copy `storage.rules.staged` over
   `storage.rules` and run `firebase deploy --only storage`.

## What the tightened Firestore rules enforce

- Create: 1 photo, 1 video, no recurring / contact phone or website /
  branding / `isPremiumListing` / `isCreatorPro` / `featuredWeekKey`.
- Update: clients cannot change featuring or Premium flags, cannot
  turn on perk fields, and cannot expand media past the free
  allowance. Unchanged leftover perk fields on an existing doc are
  left alone (the lapse job / write trigger still downgrades them).
- Analytics counters (`analyticsSearchImpressions`, `analyticsViews`,
  `analyticsSaves`, `analyticsClicks`, `analyticsShares`) are not
  client-writable. Only the `recordEventAnalytics` callable may bump
  them. **Deploy that callable (and 1.0.15) before these rules.**
  Shipping the rules first would break analytics on the live beta,
  which still writes `FieldValue.increment(1)` from the client. A
  runtime flag cannot help once the rules block those writes; the
  safety gate is this deploy order, not a Remote Config switch.

## Rollback

Redeploy the previously live rules from the last known-good revision
in Firebase Console → Firestore / Storage → Rules history. The 1.0.15
app keeps working: it prefers the callable and only uses direct writes
for the free-shaped fallback.

## Premium-bridge flags (added 14 Nov 2026)

Remote Config keys (also overridable in `meta/feature_flags`):

- `gate_rsvp_tickets_premium` (bool, default **true**): when on, RSVP
  confirmation and outbound "Get tickets" taps require Premium. Saving
  and following stay free. Turning this off in the console needs no
  app update. The `confirmRsvp` callable honors the same flag. A
  write-trigger that strips unpaid RSVPs is **not** shipped in the first
  deploy, so v14 testers are not cut off.
- `gem_early_access_hours` (int, default **48**): free users see a newly
  approved gem only after this delay. Premium users and the gem's
  creator see it immediately. `stampGemEarlyAccess` is safe to deploy
  anytime (it only stamps fields). The tightened gem `allow read` rule
  in this file must wait until 1.0.15 is the installed beta.
- `free_event_posts_per_month` (int, default **4**): on top of the 2
  upcoming-event cap. The `saveUserEvent` callable increments a
  server-owned `users/{uid}/private/post_quota` doc (clients can read
  it, not write it). Premium removes both caps.

Set the same keys in Firebase Console → Remote Config so the app can
change them without a store release.
