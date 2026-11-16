# SpotVibe messaging

Status: v1 in review. Do not merge, deploy rules, or deploy functions without
Blake's OK. Rules stay staged until 1.0.15 is the installed beta
(`STAGED_RULES_DEPLOY.md`).

## What exists

| Surface | Who | Free / Premium | Where |
|---|---|---|---|
| Event thread (group) | Host + people who RSVP'd | Free | Event page > Event thread (PR #8) |
| Read receipts in the event thread | Readers with Premium | Premium | PR #8 |
| 1:1 conversation, attendee starts | An RSVP'd attendee and the host | Free | Event thread sheet > "Message the host" |
| 1:1 conversation, host starts | Host and an RSVP'd attendee | Premium to start | Event thread sheet > message menu > "Message privately" |
| Replies in an existing 1:1 conversation | Both sides | Free | Messages inbox / conversation screen |
| Messages inbox with unread badges | Any signed-in user | Free | Profile > Messages (`/messages`) |

## Rules of the road (server-enforced in `functions/lib/eventMessaging.js` `dmSendDecision`)

- Conversations are always between one event's host and one attendee.
  The id is deterministic: `event_dms/{eventId}_{hostId}_{attendeeId}`.
- To start a conversation the attendee must have RSVP'd. Once a
  conversation exists, it stays usable if the RSVP is later removed.
- A host needs Premium to start a conversation. Replies are free for both
  sides, so a free host can always answer an attendee's question.
- An attendee can opt out of host messages (event thread sheet). Opt-out
  stops host-started conversations; the host can still answer one the
  attendee started.
- A block in either direction stops all sends, and the blocked person's
  conversations are hidden from the inbox.
- Text: 1-1000 characters, banned-term check, phone/email/handle masking,
  10 DMs per rolling hour per sender, then the parallel AI moderator
  (`runParallelModeration` plus the `parallelModerateDirectMessage` trigger).
- Report (conversation or single message) writes a `user_reports` doc with
  `contentType` `direct_conversation` / `direct_message`.

## Data

`event_dms/{threadId}` (written only by Cloud Functions):
`eventId, eventTitle, hostId, attendeeId, participants[2], startedBy,
createdAtMs, lastMessageAtMs, lastPreview, lastAuthorId, unread{uid:int},
readAtMs{uid:ms}, names{uid:string}`

`event_dms/{threadId}/dm_messages/{id}`: `authorId, text, createdAtMs, hidden`.

Callables: `sendEventDirectMessage` (send/start), `markEventDirectRead`
(zero my unread). The inbox query is
`where participants array-contains uid orderBy lastMessageAtMs desc`
(index in `firestore.indexes.json`).

Rules (`firestore.rules`): participants-only reads; list only when the
query is filtered to the caller; a not-yet-started conversation reads as
empty only for a caller whose uid is in the id; all client writes denied,
so `authorId`/sender cannot be spoofed. Covered by
`firestore-tests/rules.test.mjs` ("event_dms 1:1 conversations").

## Not in v1 (follow-ups)

- Push notifications: the app has no FCM (only local
  `awesome_notifications`), so unread is in-app only. Adding FCM is a
  separate change (APNs key, token storage, a send trigger).
- Event group threads are not listed in the inbox yet (they stay on the
  event page with their own badge).
- General user-to-user DMs outside an event (for example mutual follows)
  and Hidden Gems owner contact.
- Images/attachments, typing indicators, message edit/delete by the author.
