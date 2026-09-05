# SpotVibe Cloud Functions

Optional but recommended backend helpers. Deploy after `firebase deploy --only hosting`
and after publishing the Firestore rules.

## Deploy

```bash
cd functions
npm install
firebase deploy --only functions
```

To promote admins, bootstrap the **first** admin via the Firebase console
(create `admins/{uid}` — see below); after that an admin can promote more
admins with the `promoteAdmin` callable.

## AI promo-image setup

`generatePromoImage` uses an OpenAI image-generation key stored in Firebase
Cloud Secret Manager — never in Flutter or source control:

```bash
firebase functions:secrets:set OPENAI_API_KEY
firebase deploy --only functions
```

The function provides a conservative daily quota (3 per signed-in user; 20 per
admin), provider-side standard moderation, and a first-line prompt safety check.
Creators may add up to 280 characters of optional visual art direction; it is
validated server-side and is used only to guide the background artwork. Generated
backgrounds are written to the event owner's Firebase Storage path.
Cloud Functions and the image provider both require a billed account; set a
budget alert before enabling this in production.

### Google Workspace domain-restricted sharing

This project’s Google Workspace organization blocks the `allUsers` IAM binding
that Firebase normally adds to an HTTPS callable Gen 2 function. The function
therefore declares `invoker: 'private'`, and the mobile app calls the backing
Cloud Run service URL configured in `AppConfig.aiPromoFunctionUrl`; that URL is
public routing information, never a secret. The callable handler still requires
Firebase Authentication before it can generate an image.

After every deployment of `generatePromoImage`, make sure its backing service
allows the callable request without a Cloud Run IAM identity check:

```bash
gcloud run services update generatepromoimage \
  --region=us-central1 \
  --project=spotvibe-cfa08 \
  --no-invoker-iam-check
```

Do not add `allUsers` to the service IAM policy while Domain Restricted Sharing
is enforced; Google Cloud rejects that binding.

## What's here

| Function | Type | Purpose |
|---|---|---|
| `deleteUser` | callable | Authoritative account deletion (Firestore purge + auth delete). The in-app flow already does this client-side; this is the reliable fallback. |
| `bannedUserCleanup` | Firestore trigger (`bans/{uid}`) | Runs the moment an admin bans a user and deletes all their events, comments, RSVPs, claims, reports, saved events, profile, and blocks. |
| `moderateComment` | Firestore trigger | Flags/hides comments matching a banned-word list. |
| `moderateUserEvent` | Firestore trigger | Flags/hides user events matching a banned-word list. |
| `promoteAdmin` | callable | Adds a user to the `admins/{uid}` roster. Only an **existing** admin may call it (the first admin is created in the Firebase console). |
| `seedCuratedEvents` | callable (stub) | Seeds curated events server-side. The client already bundles the curated list, so this is optional for v1. |
| `generatePromoImage` | callable | Generates a rate-limited, moderated AI event-promo background with the provider key kept in Cloud Secret Manager. |

## Notes

- **`bannedUserCleanup` is destructive.** It deletes content, and deleting is
  not undone by "unban" (unban restores the account, not the removed content).
  The in-app readers already hide a banned user's content via the `bans/{uid}`
  list — that layer IS reversible. This function is the hard, authoritative
  cleanup on top of it.
- `deleteUser` and `bannedUserCleanup` both delete via chunked batches
  (Firestore caps batches at 500 ops).
- `bannedUserCleanup` needs the single-field collection-group index controls
  in `firestore.indexes.json` (`rsvps.userId`, `comments.authorId`). Deploy
  them with `firebase deploy --only firestore:indexes`.
- The `BANNED_WORDS` list is a starter. Swap in a real moderation provider
  (e.g. Perspective API, OpenAI moderation, or a stricter blocklist) before a
  broad launch.
