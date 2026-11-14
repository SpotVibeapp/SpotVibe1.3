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
  rateOk,
};
