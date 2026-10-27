# Release blockers — what only Blake can do

This branch (`release-blockers`, stacked on `ios-appstore-fixes`) contains
**code and config only**. Nothing has been deployed, uploaded, migrated or
rotated. Every step below needs you. Run them **in this order**: the new
functions and data migrations must be live before the new rules, because the
rules expect data the functions and scripts create.

iOS-only steps (GoogleService-Info.plist, Apple sign-in, signing, App Store
Connect) are still in `IOS_RELEASE_TODO_BLAKE.md`.

---

## 0. Prerequisites

- **Blaze (pay-as-you-go) plan** on `spotvibe-cfa08`. Secret Manager, scheduled
  functions (`archivePastEvents`) and outbound network calls from functions
  (`liveEventsProxy`, RevenueCat checks) all require it. Firebase console →
  ⚙ → Usage and billing.
- `firebase-tools` logged in to the project, and `gcloud` with access to it.
- Node 22 for `functions/`.

## 1. Rotate keys, then put them in Secret Manager

The old Ticketmaster key is in public git history (and compiled into the live
v14 build). **Confirm you have revoked it and created a new one** before you
store it. SeatGeek/JamBase keys have also been build-time values, so
rotate them too if they ever went into a shipped build.

```bash
firebase functions:secrets:set REVENUECAT_SECRET_API_KEY --project spotvibe-cfa08   # RevenueCat → API keys → Secret key (sk_...)
firebase functions:secrets:set TICKETMASTER_API_KEY      --project spotvibe-cfa08
firebase functions:secrets:set SEATGEEK_CLIENT_ID        --project spotvibe-cfa08
firebase functions:secrets:set JAMBASE_API_KEY           --project spotvibe-cfa08
# already exists (AI functions):  OPENAI_API_KEY
```

The app no longer accepts provider keys. Delete them from your local
`secrets.json` and from any CI variables (RevenueCat *public* SDK keys and
AdMob ids stay as dart-defines).

## 2. Deploy the functions (first)

```bash
cd functions
npm ci
npm run lint && npm test          # also runs automatically as predeploy
cd ..
firebase deploy --only functions --project spotvibe-cfa08
```

New functions: `scrubPublicUserPii`, `claimFoundingSlot`, `featureEvent`,
`normalizeEventFeedFields`, `archivePastEvents` (daily 04:00 MT),
`liveEventsProxy`.

Workspace Domain Restricted Sharing blocks `allUsers`, so open the new
callables the same way as the AI ones:

```bash
for svc in claimfoundingslot featureevent liveeventsproxy; do
  gcloud run services update $svc --region=us-central1 \
    --project=spotvibe-cfa08 --no-invoker-iam-check
done
```

Check that each URL matches the default in `lib/config/app_config.dart`
(`https://<name>-kfzltbt5ja-uc.a.run.app`). If one differs, pass it with
`--dart-define=CLAIM_FOUNDING_SLOT_FUNCTION_URL=...`,
`FEATURE_EVENT_FUNCTION_URL=...` or `LIVE_EVENTS_PROXY_FUNCTION_URL=...`:

```bash
gcloud run services describe liveeventsproxy --region=us-central1 \
  --project=spotvibe-cfa08 --format='value(status.url)'
```

## 3. Deploy the indexes and wait for them to build

```bash
firebase deploy --only firestore:indexes --project spotvibe-cfa08
```

Wait until all three new `events` indexes show **Enabled** (Firebase console
→ Firestore → Indexes). Until then the new app quietly falls back to its
old bounded scan.

Optional: auto-delete old provider cache docs:

```bash
gcloud firestore fields ttls update expireAt \
  --collection-group=provider_cache --enable-ttl --project=spotvibe-cfa08
```

## 4. Run the one-off data scripts (dry run first)

```bash
cd functions
gcloud auth application-default login
export GOOGLE_CLOUD_PROJECT=spotvibe-cfa08

node scripts/migrate_user_private_fields.js          # dry run: counts users with email/phone on the public doc
node scripts/migrate_user_private_fields.js --apply  # moves them to users/{uid}/private/profile

node scripts/backfill_event_feed_fields.js           # dry run: counts events missing visibleUntilMs/geoCells
node scripts/backfill_event_feed_fields.js --apply
```

Both are safe to re-run. Without the backfill, existing events do not appear
in the new feed query.

## 5. Build the new app (versionCode must be ≥ 15)

`pubspec.yaml` is `1.0.15+15`. Play rejects anything ≤ 14 (v14 is live in
beta). Bump to `+16` or higher if 15 is ever uploaded and rejected.

Release builds now **fail** unless real AdMob ids are supplied (debug still
uses Google's test ids):

```bash
# AdMob App ID: admobAppId=ca-app-pub-…~… in android/gradle.properties
# (or export ORG_GRADLE_PROJECT_admobAppId=ca-app-pub-…~…). See ADMOB_SETUP_GUIDE.md.
flutter build appbundle --release \
  --dart-define-from-file=secrets.json      # REVENUECAT_*, ADMOB_BANNER_ANDROID, ...
```

The iOS build (Mac) needs the steps in `IOS_RELEASE_TODO_BLAKE.md`.

## 6. Deploy the rules (last)

Deploy once steps 2–4 are done, and ideally after testers are on the new
build (see the v14 notes below):

```bash
firebase deploy --only firestore:rules --project spotvibe-cfa08
```

To check the rules locally first (Java 21 required):

```bash
cd firestore-tests && npm ci && npm test
```

## 7. Upload to Play / App Store

Your call. Nothing has been uploaded.

---

## What changes for the live v14 Play beta once the new rules are live

| v14 behaviour | Under the new rules | Effect |
| --- | --- | --- |
| New sign-up writes `email` (and phone) on `users/{uid}` | Denied (only blank is allowed) | **v14 sign-ups get no profile doc.** Existing v14 users keep working; their edits that change email are denied. |
| Pro creator creates an event with `featuredWeekKey` set | Whole create denied | **v14 Premium creators can't post** until they update. Free creators are unaffected (they send `null`). |
| Founding purchase claims its slot with a client transaction on `meta/founding` | Denied | The purchase still goes through in RevenueCat, but the slot is not recorded. The new app records it through `claimFoundingSlot`. |
| "Interested" bumps `user_events.interestedCount` | Denied (silently) | Creator dashboard counts stop moving for v14 taps. |
| Creator edit resends a stale copy of the public counters | Denied if a counter changed since the event was loaded | Some v14 edits fail. Reloading the event and editing again works. |
| Analytics +1 per field, save/unsave transaction | Allowed | No change. |
| Feed reads (`limit(400)`) | Allowed | No change. Past events disappear once `archivePastEvents` runs. |
| Calls Ticketmaster directly with its compiled key | Not affected by rules | Stops working when you revoke the old key. v14 then shows no Ticketmaster rows. |

**Recommendation:** ship the new build to the beta track and get testers onto
it (or require the update) before step 6. If you have to deploy the rules
while v14 is still in use, the v14 sign-up break is the one to avoid. It can
be softened by allowing a non-blank email on create (the `scrubPublicUserPii`
trigger moves it within seconds). That is a one-line rules change; ask for it
if you want it.
