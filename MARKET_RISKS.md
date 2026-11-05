# Market-risk mitigations

What this branch changes, and what it cannot fix. No Firebase deploy, no
store upload, and no new secrets.

## 1. Empty feed / cold start

**Changed**

- A successful feed read that comes back empty stays empty. It is no longer
  filled with unlabeled El Paso rows.
- The empty states explain that Ticketmaster, SeatGeek, and JamBase rows
  appear only when those sources respond, and they offer **Browse sample
  events**. That is an explicit opt-in. The samples are the bundled El Paso
  list with `isSample: true`, a "Sample" chip, and a banner. They are not
  written to Firestore. Bookmark and Interested do nothing on them.
- If Firestore itself throws, the existing offline fallback still shows that
  bundled list, now labeled as samples, so an outage is not a blank screen
  and not a fake live feed.
- Provider failures were already isolated in `EventService` (one bad source
  cannot wipe the others). That behavior is unchanged.

**Not fixed**

- This does not create real events in cities that have none, and it does not
  put provider keys in the app. Live rows still depend on
  `liveEventsProxy` plus Secret Manager, which Blake deploys.
- The client still *attempts* `ensureSeeded()` (the old upsert). Current
  rules reject that write. This branch does not remove the call and does
  not run it against production.

## 2. Rules deploy vs the v14 beta

**Changed**

- `firestore.rules` is not modified.
- `RULES_DEPLOY_GUARD.md` is the deploy order: functions and the new app
  build first, rules last. `RELEASE_TODO_BLAKE.md` points at it.
- This build retries a permission-denied profile create and event
  write with the other legal shape (`email: ''` first, real email only if
  that was denied; `featuredWeekKey` omitted, then `null`). It never sends
  a featured week from the client. Turn the retry off with
  `--dart-define=RULES_COMPAT_RETRIES=false`.

**Not fixed**

- The installed v14 binary still breaks if these rules are deployed first
  (sign-up, Premium create, founding slot, `user_events.interestedCount`,
  stale counter edits). A new build cannot patch an old binary. The
  one-line "allow email on create" soften is documented and was not applied,
  because this branch does not ship new production rules.

## 3. Name collision

**Changed**

- Store and home-screen display name is `SpotVibe - Find Your Vibe`
  (`STORE_NAME.md`, Play listing notes, Apple checklist, Android label, iOS
  `CFBundleDisplayName`).
- Package / bundle id stays `app.spotvibe`.

**Not fixed**

- The store record itself is created in App Store Connect and Play Console.
  Nothing here uploads a listing or files a trademark.

## 4. Almost no users

**Changed (in the product, user-initiated only)**

- Onboarding says a quiet feed is normal and that sharing waits until the
  person taps it.
- Profile (guest and signed-in) and the empty home feed open the OS share
  sheet with an invite. Nothing is sent automatically and there is no
  outreach job.

**Still Blake**

- Promote the Play beta to production, and any outreach outside the app.
  The code cannot buy or message users.
