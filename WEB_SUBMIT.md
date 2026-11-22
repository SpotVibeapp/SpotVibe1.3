# No-app web event submission form (DRAFT)

Status: ready for Blake's review. **Do not merge and do not deploy** (functions, hosting, or rules) until Blake explicitly OKs.

The form lives in the Flutter web app at **`https://spotvibeapp.com/app/submit`**. Coordinators do not need an app install or an account. A link was also added on the login screen.

## What happens to a submission

1. The form calls the `submitWebEvent` callable (App Check required once that is set up).
2. The function validates the fields, drops honeypot hits, rate-limits 5 posts per IP hash per day, and writes `event_submissions/{id}` with `status: pending`.
3. Nothing appears in the public feed until an admin calls `reviewWebSubmission` with `approve`. That writes `events/{id}` as an **unclaimed** listing (`kind: 'web_submission'`, `creatorId: ''`).
4. The organizer's email is stored only on the submission doc and on `events/{id}/private/contact`. It is **not** copied onto the public event document.

Banned-word flagging uses the existing `containsBanned` helper. After approval, the existing `moderateUserEvent` / `parallelModerateUserEvent` triggers also run on the new `events/{id}` document. There is no separate new moderation stack.

## Firestore rules

**No rules deploy is required**, including while the v14 beta is live.

`event_submissions/*`, `submission_rate/*`, and `events/{id}/private/*` have no client rules, so the existing deny-all at the bottom of `firestore.rules` already covers them. All writes go through the Admin SDK in the callables. This PR does not change `firestore.rules`.

## Still needed before a deploy (Blake)

None of these were run.

1. **reCAPTCHA Enterprise + App Check** for the existing web app (`1:626183324233:web:db73096904c2fc41d8f598`). The callable is defined with `enforceAppCheck: true`.
2. **Functions deploy** of `submitWebEvent` and `reviewWebSubmission` only, after Blake OKs. The org policy that blocks `allUsers` invoker will likely need the same Cloud Run invoker-IAM workaround used for the other callables, because this form is used while signed out.
3. Confirm the Cloud Run URL and, if it differs from `https://submitwebevent-kfzltbt5ja-uc.a.run.app`, rebuild the web app with `--dart-define=SUBMIT_WEB_EVENT_FUNCTION_URL=...`.
4. **Hosting deploy** of the Flutter web app (`firebase.spotvibeapp.json`, site `spotvibeapp`, **not** `spotvibe-cfa08`) so `/app/submit` is reachable on spotvibeapp.com. The web app itself is also still undeployed (PR #6).
5. Optional later: an in-app admin review queue, and a "you're live, claim it" email. Not built. Do not send email without Blake's OK.

## Local proof

```bash
flutter build web --release --base-href /app/
# Then serve build/web with a rewrite of /app/** to /app/index.html
```

The form renders at `/app/submit`. Submitting will not write to production until the functions are deployed.
