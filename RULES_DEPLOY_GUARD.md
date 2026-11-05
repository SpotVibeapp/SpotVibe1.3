# Rules deploy guard (v14 beta)

`firestore.rules` in this repo is the strict set: no real email or phone on
`users/{uid}`, `featuredWeekKey` only from `featureEvent` or an admin, and
`meta/founding` not writable by clients. **This branch does not change that
file.** Do not deploy it while the live Play beta (v14) is still what people
open.

## What a rules deploy does to v14

The table in `RELEASE_TODO_BLAKE.md` ("What changes for the live v14 Play
beta") is still accurate, because the rules were not softened:

| v14 behaviour | If these rules go live first |
|---|---|
| Sign-up writes `email` (and phone) on `users/{uid}` | Denied. New v14 sign-ups get no profile doc. |
| Premium creator sends a non-null `featuredWeekKey` | The whole event create is denied. |
| Founding purchase writes `meta/founding` from the client | Denied. RevenueCat still charges; the slot is not recorded. |
| "Interested" bumps `user_events.interestedCount` | Denied. |
| Creator edit resends stale public counters | Denied when a counter changed since the screen loaded. |

`scrubPublicUserPii` can move a public email within seconds, but only if the
write is allowed. The rules still deny that write. Softening them (allow a
non-blank email on create only) is a one-line change Blake can make later.
It is intentionally not in `firestore.rules` here.

## Safe order

1. Deploy functions (`scrubPublicUserPii`, `featureEvent`, `claimFoundingSlot`,
   `normalizeEventFeedFields`) and run the data scripts in `RELEASE_TODO_BLAKE.md`.
2. Ship this app build to the beta track and get testers onto it.
3. Only then `firebase deploy --only firestore:rules`.

Until step 3, leave the rules that v14 already runs against in place.

## What this build does without a rules change

`AppConfig.rulesCompatRetries` (default on,
`--dart-define=RULES_COMPAT_RETRIES=false` to disable) retries a
permission-denied profile or event write once:

- Profile create tries `email: ''`, then no email key, and only then the
  real email. The real email runs only when the stricter shapes were
  denied, which is the old rules, not the rules in this repo.
- Event create/update omits `featuredWeekKey`. If that is denied, it retries
  with `featuredWeekKey: null`. It never sends a week key from the client.
  Featuring stays on `featureEvent`.

Other errors are not retried, so an outage cannot fall through into the
looser shape.

That protects **this** build if the deployed rules are either the current
file or the older v14 rules. It does not update the binaries already
installed from the v14 beta. Those keep breaking if the new rules ship
first.
