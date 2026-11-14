'use strict';

const { maskContactInfo } = require('./piiMask');
const {
  THREAD_MESSAGE_MAX,
  THREAD_RATE_LIMIT,
  THREAD_RATE_WINDOW_MS,
  DM_RATE_LIMIT,
  DM_RATE_WINDOW_MS,
  isThreadParticipant,
  dmThreadId,
  rateOk,
} = require('./eventMessaging');

function install(deps) {
  const {
    exports: fns,
    onCall,
    HttpsError,
    admin,
    containsBanned,
    runParallelModeration,
    verifiedEntitlement,
    revenueCatSecretKey,
  } = deps;

  const callOpts = {
    secrets: [revenueCatSecretKey],
    timeoutSeconds: 30,
    invoker: 'private',
  };

  async function requireParticipant(db, eventId, uid) {
    const part = await isThreadParticipant(db, eventId, uid);
    if (!part.ok) {
      throw new HttpsError(
        'permission-denied',
        'Only the host and people who RSVP\'d can use this event thread.',
      );
    }
    return part;
  }

  async function isBlocked(db, a, b) {
    const [ab, ba] = await Promise.all([
      db.collection('blocks').doc(a).collection('blocked').doc(b).get(),
      db.collection('blocks').doc(b).collection('blocked').doc(a).get(),
    ]);
    return ab.exists || ba.exists;
  }

  async function bumpRate(db, uid, key, limit, windowMs) {
    const ref = db.collection('users').doc(uid).collection('private').doc(`rate_${key}`);
    const now = Date.now();
    const snap = await ref.get();
    const stamps = (snap.exists && Array.isArray(snap.get('stamps'))) ? snap.get('stamps') : [];
    const check = rateOk(stamps, limit, windowMs, now);
    if (!check.ok) {
      throw new HttpsError('resource-exhausted', 'You are sending messages too quickly. Try again later.');
    }
    const next = [...check.recent, now];
    await ref.set({ stamps: next, updatedAtMs: now }, { merge: true });
  }

  fns.sendEventThreadMessage = onCall(callOpts, async (request) => {
    const uid = request.auth && request.auth.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Sign in to send a message.');
    const eventId = request.data && request.data.eventId;
    const raw = String((request.data && request.data.text) || '').trim();
    if (typeof eventId !== 'string' || !/^[A-Za-z0-9_-]{1,128}$/.test(eventId)) {
      throw new HttpsError('invalid-argument', 'eventId is required.');
    }
    if (!raw) throw new HttpsError('invalid-argument', 'Message cannot be empty.');
    if (raw.length > THREAD_MESSAGE_MAX) {
      throw new HttpsError('invalid-argument', 'Message is too long.');
    }
    if (containsBanned(raw)) {
      throw new HttpsError('failed-precondition', 'That message cannot be sent.');
    }
    const db = admin.firestore();
    const part = await requireParticipant(db, eventId, uid);
    await bumpRate(db, uid, 'thread', THREAD_RATE_LIMIT, THREAD_RATE_WINDOW_MS);
    const text = maskContactInfo(raw);
    const displayName = (request.data && request.data.authorName) || '';
    const ref = db.collection('events').doc(eventId).collection('thread_messages').doc();
    const createdAtMs = Date.now();
    await ref.set({
      authorId: uid,
      authorName: displayName,
      text,
      createdAtMs,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      hidden: false,
    });
    await db.collection('events').doc(eventId).collection('thread_meta').doc('state').set({
      lastMessageAtMs: createdAtMs,
      lastPreview: text.slice(0, 80),
      lastAuthorId: uid,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    await runParallelModeration({
      text,
      authorId: uid,
      targetPath: ref.path,
    });
    return { ok: true, id: ref.id, text };
  });

  fns.removeEventThreadMessage = onCall(callOpts, async (request) => {
    const uid = request.auth && request.auth.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Sign in.');
    const eventId = request.data && request.data.eventId;
    const messageId = request.data && request.data.messageId;
    if (!eventId || !messageId) throw new HttpsError('invalid-argument', 'eventId and messageId are required.');
    const db = admin.firestore();
    const part = await requireParticipant(db, eventId, uid);
    if (!part.host) {
      throw new HttpsError('permission-denied', 'Only the host can remove a thread message.');
    }
    const ref = db.collection('events').doc(eventId).collection('thread_messages').doc(messageId);
    const snap = await ref.get();
    if (!snap.exists) throw new HttpsError('not-found', 'Message not found.');
    await ref.update({
      hidden: true,
      hiddenBy: uid,
      hiddenAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return { ok: true };
  });

  fns.setEventThreadMute = onCall(callOpts, async (request) => {
    const uid = request.auth && request.auth.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Sign in.');
    const eventId = request.data && request.data.eventId;
    const muted = !!(request.data && request.data.muted);
    const optOutDms = request.data && request.data.optOutDms;
    if (!eventId) throw new HttpsError('invalid-argument', 'eventId is required.');
    const db = admin.firestore();
    await requireParticipant(db, eventId, uid);
    const patch = { muted, updatedAt: admin.firestore.FieldValue.serverTimestamp() };
    if (typeof optOutDms === 'boolean') patch.optOutDms = optOutDms;
    await db.collection('events').doc(eventId).collection('thread_mutes').doc(uid).set(patch, { merge: true });
    return { ok: true, muted, optOutDms: patch.optOutDms ?? null };
  });

  fns.markEventThreadRead = onCall(callOpts, async (request) => {
    const uid = request.auth && request.auth.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Sign in.');
    const eventId = request.data && request.data.eventId;
    const messageId = (request.data && request.data.messageId) || null;
    if (!eventId) throw new HttpsError('invalid-argument', 'eventId is required.');
    const db = admin.firestore();
    await requireParticipant(db, eventId, uid);
    const now = Date.now();
    await db.collection('users').doc(uid).collection('thread_reads').doc(eventId).set({
      lastReadAtMs: now,
      lastReadMessageId: messageId,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    const status = await verifiedEntitlement(uid);
    if (status && status.pro) {
      await db.collection('events').doc(eventId).collection('thread_receipts').doc(uid).set({
        lastReadAtMs: now,
        lastReadMessageId: messageId,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
    }
    return { ok: true, receipt: !!(status && status.pro) };
  });

  fns.sendEventDirectMessage = onCall(callOpts, async (request) => {
    const uid = request.auth && request.auth.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Sign in.');
    const eventId = request.data && request.data.eventId;
    const attendeeId = request.data && request.data.attendeeId;
    const raw = String((request.data && request.data.text) || '').trim();
    if (!eventId || !attendeeId) {
      throw new HttpsError('invalid-argument', 'eventId and attendeeId are required.');
    }
    if (!raw) throw new HttpsError('invalid-argument', 'Message cannot be empty.');
    if (raw.length > THREAD_MESSAGE_MAX) {
      throw new HttpsError('invalid-argument', 'Message is too long.');
    }
    if (containsBanned(raw)) {
      throw new HttpsError('failed-precondition', 'That message cannot be sent.');
    }
    const db = admin.firestore();
    const part = await requireParticipant(db, eventId, uid);
    const hostId = (part.event && part.event.creatorId) || '';
    if (!hostId) {
      throw new HttpsError('failed-precondition', 'This event has no host.');
    }
    if (attendeeId === hostId) {
      throw new HttpsError('invalid-argument', 'You cannot message yourself.');
    }
    const isHostSender = part.host === true;
    const isAttendeeReply = !isHostSender && uid === attendeeId;
    if (!isHostSender && !isAttendeeReply) {
      throw new HttpsError('permission-denied', 'Only the host and that attendee can use this conversation.');
    }
    const threadId = dmThreadId(eventId, hostId, attendeeId);
    const threadRef = db.collection('event_dms').doc(threadId);
    if (isHostSender) {
      const status = await verifiedEntitlement(uid);
      if (!status || !status.pro) {
        throw new HttpsError('permission-denied', 'Direct messages to attendees are a Premium perk.', { reason: 'premium-required' });
      }
      const rsvp = await db.collection('events').doc(eventId).collection('rsvps').doc(attendeeId).get();
      if (!rsvp.exists) {
        throw new HttpsError('permission-denied', 'You can only message people who RSVP\'d.');
      }
      const mute = await db.collection('events').doc(eventId).collection('thread_mutes').doc(attendeeId).get();
      if (mute.exists && mute.get('optOutDms') === true) {
        throw new HttpsError('permission-denied', 'This attendee has opted out of direct messages.');
      }
    } else {
      const existing = await threadRef.get();
      if (!existing.exists) {
        throw new HttpsError('permission-denied', 'The host has to start this conversation first.');
      }
    }
    if (await isBlocked(db, uid, isHostSender ? attendeeId : hostId)) {
      throw new HttpsError('permission-denied', 'You cannot message this person.');
    }
    await bumpRate(db, uid, 'dm', DM_RATE_LIMIT, DM_RATE_WINDOW_MS);
    const text = maskContactInfo(raw);
    const createdAtMs = Date.now();
    await threadRef.set({
      eventId,
      hostId: uid,
      attendeeId,
      lastMessageAtMs: createdAtMs,
      lastPreview: text.slice(0, 80),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    const msgRef = threadRef.collection('dm_messages').doc();
    await msgRef.set({
      authorId: uid,
      text,
      createdAtMs,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      hidden: false,
    });
    await runParallelModeration({
      text,
      authorId: uid,
      targetPath: msgRef.path,
    });
    return { ok: true, threadId, id: msgRef.id, text };
  });

  return fns;
}

module.exports = { install };
