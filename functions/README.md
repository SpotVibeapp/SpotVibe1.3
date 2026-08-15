# SpotVibe Cloud Functions

Optional but recommended backend helpers. Deploy after `firebase deploy --only hosting`
and after publishing the Firestore rules.

## Deploy

```bash
cd functions
npm install
firebase deploy --only functions
```

## What's here

| Function | Type | Purpose |
|---|---|---|
| `deleteUser` | callable | Authoritative account deletion (Firestore purge + auth delete). The in-app flow already does this client-side; this is the reliable fallback. |
| `moderateComment` | Firestore trigger | Flags/hides comments matching a banned-word list. |
| `moderateUserEvent` | Firestore trigger | Flags/hides user events matching a banned-word list. |
| `seedCuratedEvents` | callable (stub) | Seeds curated events server-side. The client already bundles the curated list, so this is optional for v1. |

## Notes

- The `BANNED_WORDS` list is a starter. Swap in a real moderation provider
  (e.g. perspective API, OpenAI moderation, or a stricter blocklist) before a
  broad launch.
- `deleteUser` runs within a single batch (500-op cap). One user's data is far
  below that; if you ever expect more, chunk the deletes.
- To call `deleteUser` from Flutter you'd use `cloud_functions` package; the
  in-app flow currently deletes directly via firebase_auth/firestore, so this
  is a fallback only.
