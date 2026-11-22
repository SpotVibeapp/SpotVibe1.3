'use strict';

const { maskContactInfo } = require('./piiMask');
const {
  REVIEWS_COLLECTION,
  STATS_SCAN_MAX,
  SCOPE_FIELDS,
  REVIEW_NOTE_MAX,
  REVIEW_REPLY_MAX,
  isValidId,
  reviewDocId,
  publicReview,
  buildListing,
  isEventEnded,
  normalizeStars,
} = require('./eventReviews');

/**
 * Event reviews and the Play rating prompt. Every read and write goes
 * through these callables against server-only collections, so no Firestore
 * rules change is needed:
 *  - event_reviews/{eventId}_{uid}            (top-level, Admin SDK only)
 *  - users/{uid}/ended_rsvps/{eventId}         (falls under the deny-all)
 *  - users/{uid}/play_review_prompt/state      (falls under the deny-all)
 * Queries are single-field equality on a top-level collection, so they use
 * Firestore's automatic indexes; no firestore.indexes.json change either.
 */
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
    timeoutSeconds: 60,
    invoker: 'private',
  };
  const readOpts = {
    timeoutSeconds: 30,
    invoker: 'private',
  };

  const db = () => admin.firestore();
  const reviews = () => db().collection(REVIEWS_COLLECTION);

  function requireEventId(data) {
    const eventId = data && data.eventId;
    if (!isValidId(eventId)) throw new HttpsError('invalid-argument', 'eventId is required.');
    return eventId;
  }

  async function loadEvent(eventId) {
    const snap = await db().collection('events').doc(eventId).get();
    if (snap.exists) return { id: snap.id, ...(snap.data() || {}) };
    const fallback = await db().collection('user_events').doc(eventId).get();
    if (fallback.exists) return { id: fallback.id, ...(fallback.data() || {}) };
    return null;
  }

  async function hasRsvp(eventId, uid) {
    const rsvp = await db().collection('events').doc(eventId).collection('rsvps').doc(uid).get();
    if (rsvp.exists) return true;
    const alt = await db().collection('user_events').doc(eventId).collection('rsvps').doc(uid).get();
    return alt.exists;
  }

  fns.submitEventReview = onCall(callOpts, async (request) => {
    const uid = request.auth && request.auth.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Sign in.');
    const data = request.data || {};
    const eventId = requireEventId(data);
    const stars = normalizeStars(data.stars);
    const rawNote = String(data.note || '').trim();
    const authorName = String(data.authorName || '').trim().slice(0, 80);
    if (stars == null) throw new HttpsError('invalid-argument', 'Choose a star rating from 1 to 5.');
    if (rawNote.length > REVIEW_NOTE_MAX) {
      throw new HttpsError('invalid-argument', 'Review notes can be at most 300 characters.');
    }
    if (rawNote && containsBanned(rawNote)) {
      throw new HttpsError('failed-precondition', 'That review cannot be posted.');
    }
    const event = await loadEvent(eventId);
    if (!event) throw new HttpsError('not-found', 'Event not found.');
    if (!isEventEnded(event)) {
      throw new HttpsError('failed-precondition', 'You can review an event only after it has ended.');
    }
    if (!(await hasRsvp(eventId, uid))) {
      throw new HttpsError('permission-denied', 'Only people who RSVP\'d can review this event.');
    }
    const hostId = event.creatorId || '';
    if (hostId && hostId === uid) {
      throw new HttpsError('permission-denied', 'Hosts cannot review their own events.');
    }
    const gemId = isValidId(event.gemId) ? event.gemId : '';
    let businessId = '';
    if (hostId) {
      const status = await verifiedEntitlement(hostId);
      if (status && status.pro) businessId = hostId;
    }
    const note = rawNote ? maskContactInfo(rawNote) : '';
    const ref = reviews().doc(reviewDocId(eventId, uid));
    const existing = await ref.get();
    const now = Date.now();
    const payload = {
      authorId: uid,
      authorName: authorName || (existing.exists ? existing.get('authorName') || '' : ''),
      stars,
      note,
      hidden: existing.exists ? existing.get('hidden') === true : false,
      eventId,
      eventTitle: event.title || '',
      hostId,
      businessId: businessId || null,
      gemId: gemId || null,
      createdAtMs: existing.exists ? (existing.get('createdAtMs') || now) : now,
      updatedAtMs: now,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    if (!existing.exists) payload.createdAt = admin.firestore.FieldValue.serverTimestamp();
    // merge keeps a previous host reply when the reviewer edits.
    await ref.set(payload, { merge: true });
    await runParallelModeration({ text: note, authorId: uid, targetPath: ref.path });
    return { ok: true, review: publicReview(ref.id, { ...(existing.data() || {}), ...payload }), edited: existing.exists };
  });

  fns.replyToEventReview = onCall(callOpts, async (request) => {
    const uid = request.auth && request.auth.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Sign in.');
    const data = request.data || {};
    const eventId = requireEventId(data);
    const reviewerId = data.reviewerId;
    if (!isValidId(reviewerId)) throw new HttpsError('invalid-argument', 'reviewerId is required.');
    const raw = String(data.reply || '').trim();
    if (!raw) throw new HttpsError('invalid-argument', 'Reply cannot be empty.');
    if (raw.length > REVIEW_REPLY_MAX) {
      throw new HttpsError('invalid-argument', 'Replies can be at most 300 characters.');
    }
    if (containsBanned(raw)) throw new HttpsError('failed-precondition', 'That reply cannot be posted.');
    const event = await loadEvent(eventId);
    if (!event) throw new HttpsError('not-found', 'Event not found.');
    if (event.creatorId !== uid) {
      throw new HttpsError('permission-denied', 'Only the host can reply to reviews.');
    }
    const status = await verifiedEntitlement(uid);
    if (!status || !status.pro) {
      throw new HttpsError('permission-denied', 'Replying to reviews is a Premium perk.', { reason: 'premium-required' });
    }
    const ref = reviews().doc(reviewDocId(eventId, reviewerId));
    const existing = await ref.get();
    if (!existing.exists) throw new HttpsError('not-found', 'Review not found.');
    const reply = maskContactInfo(raw);
    await ref.update({
      reply,
      replyAtMs: Date.now(),
      replyAuthorId: uid,
      replyUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    await runParallelModeration({ text: reply, authorId: uid, targetPath: `${ref.path}#reply` });
    return { ok: true, reply };
  });

  /**
   * Public read path for reviews. scope is event | host | business | gem.
   * Returns visible reviews (newest first, at most `limit`, default 20)
   * plus stats over every visible review for that scope.
   */
  fns.listEventReviews = onCall(readOpts, async (request) => {
    const data = request.data || {};
    const field = SCOPE_FIELDS[data.scope];
    if (!field) throw new HttpsError('invalid-argument', 'scope must be event, host, business, or gem.');
    if (!isValidId(data.id)) throw new HttpsError('invalid-argument', 'id is required.');
    const snap = await reviews().where(field, '==', data.id).limit(STATS_SCAN_MAX).get();
    const docs = snap.docs.map((d) => ({ id: d.id, data: d.data() }));
    return { ok: true, ...buildListing(docs, data.limit == null ? 20 : data.limit) };
  });

  fns.recordEndedRsvp = onCall(callOpts, async (request) => {
    const uid = request.auth && request.auth.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Sign in.');
    const eventId = requireEventId(request.data);
    const event = await loadEvent(eventId);
    if (!event) throw new HttpsError('not-found', 'Event not found.');
    if (!isEventEnded(event)) {
      throw new HttpsError('failed-precondition', 'This event has not ended yet.');
    }
    if (!(await hasRsvp(eventId, uid))) {
      throw new HttpsError('permission-denied', 'Only people who RSVP\'d can record this event.');
    }
    const userRef = db().collection('users').doc(uid);
    const ref = userRef.collection('ended_rsvps').doc(eventId);
    const snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        eventId,
        endedAtMs: Date.now(),
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
    const all = await userRef.collection('ended_rsvps').count().get();
    const count = (all.data() && all.data().count) || 0;
    const prompted = await userRef.collection('play_review_prompt').doc('state').get();
    return { ok: true, count, alreadyPrompted: prompted.exists };
  });

  fns.markPlayReviewPrompted = onCall(callOpts, async (request) => {
    const uid = request.auth && request.auth.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Sign in.');
    const ref = db().collection('users').doc(uid).collection('play_review_prompt').doc('state');
    const snap = await ref.get();
    if (snap.exists) return { ok: true, already: true };
    await ref.set({
      requestedAtMs: Date.now(),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return { ok: true, already: false };
  });

  return fns;
}

module.exports = { install };
