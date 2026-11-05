# Parallel moderation

SpotVibe already moderates in two places, and both stay on:

- **Client:** `AiModerationService` blocks or warns before a post is saved.
- **Server:** `moderateComment`, `moderateUserEvent`, `moderateGem`, and
  `moderateGemComment` hide text that contains the `BANNED_WORDS` list.

The parallel path is a **second** reviewer. It does not replace either of
those, and it does not hide or delete content.

## When it fires

A Firestore `onDocumentCreated` trigger, one per surface, after the write
has already succeeded:

| Function | Document |
|---|---|
| `parallelModerateUserEvent` | `events/{eventId}` (user-created and any other new event doc) |
| `parallelModerateComment` | `events/{eventId}/comments/{commentId}` |
| `parallelModerateGem` | `gems/{gemId}` |
| `parallelModerateGemComment` | `gems/{gemId}/comments/{commentId}` |

Docs with no `creatorId` / `authorId` (curated rows) are skipped.

The Flutter app also runs `ParallelModerationService` in the same submit
flow as `AiModerationService` (`ModerationPipeline`). That pass only sees
the current session. It cannot block the submit: the primary result is what
the screen uses, and a throw from the parallel service is ignored.

## Inputs

For each new document:

- text (title + description, comment body, or gem name/summary/description)
- author id
- `createdAt` on `users/{authorId}`, when that read works
- the last 40 rows in `moderation_activity` (this function's own log)

No OpenAI call and no new API key. The scorer is
`functions/lib/parallelModeration.js` (`assessParallelModeration`). The
device copy is `lib/services/parallel_moderation_service.dart` and only
covers what one phone can see.

## What it looks for

| Code | Meaning |
|---|---|
| `limit_probe` | Zero-width characters, "ignore previous rules", "bypass the filter", "is this banned", or the blocklist token with letters split by dots or spaces |
| `rate_abuse` | 4 earlier posts by the same author in 10 minutes (this post is the 5th) |
| `near_duplicate` | Very similar to that author's own recent post |
| `coordinated_spam` | Two or more other accounts posted nearly the same text in 30 minutes |
| `multi_account` | This account and another account were both created in the last 48 hours and posted nearly the same text |

## Outputs

When at least one signal fires, the function adds `moderation_flags/{autoId}`:

```text
source: "parallel"
status: "open"
targetPath: "events/abc"
authorId: "<uid>"
signals: [{ code, score, detail }]
createdAt, createdAtMs
```

Every reviewed post (flagged or not) also adds a short
`moderation_activity` row so the next post can be compared. Text there is
truncated to 500 characters.

Both collections are written with the Admin SDK. This branch does not add
client rules for them, so the app cannot read or write them. The default
deny at the bottom of `firestore.rules` already covers that.

## How operators see flags

Firebase console → Firestore → `moderation_flags`, `status == open`.

The primary hide (`hidden: true`, `flaggedReason: banned-word`) is a
different field on the content doc and is unchanged.

## Failures

`runParallelModeration` catches every error, logs
`parallel moderation failed (primary path unaffected)`, and returns. It
does not rethrow, so the trigger does not retry into the user's flow, and
the banned-word trigger is a separate function that already ran on its own.

Deploy with the other functions when you are ready
(`firebase deploy --only functions`). Nothing in this branch deploys it.
