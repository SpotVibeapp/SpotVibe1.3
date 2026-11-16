'use strict';

const THREAD_MESSAGE_MAX = 1000;
const THREAD_RATE_LIMIT = 30;
const THREAD_RATE_WINDOW_MS = 10 * 60 * 1000;
const DM_RATE_LIMIT = 10;
const DM_RATE_WINDOW_MS = 60 * 60 * 1000;

function isHost(event, uid) {
  return !!(event && uid && event.creatorId === uid);
}

async function isThreadParticipant(db, eventId, uid) {
  if (!uid || !eventId) return { ok: false, host: false, event: null };
  const eventSnap = await db.collection('events').doc(eventId).get();
  if (!eventSnap.exists) return { ok: false, host: false, event: null };
  const event = eventSnap.data() || {};
  if (isHost(event, uid)) return { ok: true, host: true, event };
  const rsvp = await db.collection('events').doc(eventId).collection('rsvps').doc(uid).get();
  return { ok: rsvp.exists, host: false, event };
}

function dmThreadId(eventId, hostId, attendeeId) {
  return `${eventId}_${hostId}_${attendeeId}`;
}

/**
 * Decide whether a 1:1 event conversation message may be sent.
 *
 * Model (see MESSAGING.md):
 *  - Conversations are always between an event's host and one attendee.
 *  - An RSVP'd attendee may start a conversation with the host (free).
 *  - A host may start a conversation only with an RSVP'd attendee and only
 *    with Premium. Replies inside an existing conversation are free for both.
 *  - An attendee who opted out of host messages cannot be cold-messaged by
 *    the host, but the host may still answer a conversation the attendee
 *    started.
 *  - A block in either direction stops all sends.
 */
function dmSendDecision({
  senderIsHost = false,
  senderIsAttendee = false,
  threadExists = false,
  startedBy = '',
  attendeeId = '',
  senderIsPro = false,
  attendeeRsvpd = false,
  attendeeOptedOut = false,
  blocked = false,
} = {}) {
  const deny = (code, message, reason) => ({ ok: false, code, message, reason });
  if (!senderIsHost && !senderIsAttendee) {
    return deny('permission-denied', 'Only the host and that attendee can use this conversation.', 'not-participant');
  }
  if (blocked) {
    return deny('permission-denied', 'You cannot message this person.', 'blocked');
  }
  if (!threadExists && !attendeeRsvpd) {
    return deny('permission-denied', 'Conversations start from an RSVP to the event.', 'rsvp-required');
  }
  if (senderIsHost && !threadExists && !senderIsPro) {
    return deny('permission-denied', 'Starting a private message with an attendee is a Premium perk.', 'premium-required');
  }
  const attendeeStarted = threadExists && startedBy && startedBy === attendeeId;
  if (senderIsHost && attendeeOptedOut && !attendeeStarted) {
    return deny('permission-denied', 'This attendee has opted out of private messages from hosts.', 'opted-out');
  }
  return { ok: true, starts: !threadExists };
}

/** The other participant in a host/attendee conversation. */
function dmRecipient(senderId, hostId, attendeeId) {
  return senderId === hostId ? attendeeId : hostId;
}

/** True when uid may read or act on the conversation doc. */
function isDmParticipant(thread, uid) {
  if (!thread || !uid) return false;
  const parts = Array.isArray(thread.participants) ? thread.participants : [];
  return parts.includes(uid) || thread.hostId === uid || thread.attendeeId === uid;
}

function rateOk(stamps, limit, windowMs, nowMs) {
  const recent = (stamps || []).filter((t) => typeof t === 'number' && nowMs - t < windowMs);
  return { ok: recent.length < limit, recent };
}

module.exports = {
  THREAD_MESSAGE_MAX,
  THREAD_RATE_LIMIT,
  THREAD_RATE_WINDOW_MS,
  DM_RATE_LIMIT,
  DM_RATE_WINDOW_MS,
  isHost,
  isThreadParticipant,
  dmThreadId,
  dmSendDecision,
  dmRecipient,
  isDmParticipant,
  rateOk,
};
