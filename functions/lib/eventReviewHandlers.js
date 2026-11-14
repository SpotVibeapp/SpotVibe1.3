'use strict';

const { maskContactInfo } = require('./piiMask');
const {
  REVIEW_NOTE_MAX,
  REVIEW_REPLY_MAX,
  isEventEnded,
  normalizeStars,
  aggregateFromReviews,
} = require('./eventReviews');

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

  const db = () => admin.firestore();

  async function loadEvent(eventId) {
    const snap = await db().collection('events').doc(eventId).get();
    if (snap.exists) return { id: snap.id, ...(snap.data() || {}) };
    const fallback = await db().collection('user_events').doc(eventId).get();
    if (fallback.exists) return { id: fallback.id, ...(fallback.data() || {}) };
    return null;
  }

  async function requireRsvp(eventId, uid) {
    const rsvp = await db().collection('events').doc(eventId).collection('rsvps').doc(uid).get();
    if (rsvp.exists) return true;
    const alt = await db().collection('user_events').doc(eventId).collection('rsvps').doc(uid).get();
    return alt.exists;
  }

  function statsRef(col, id) {
    return db().collection(col).doc(id).collection('review_stats').doc('aggregate');
  }

  async function writeAggregate(ref, rows) {
    const agg = aggregateFromReviews(rows);
    await ref.set({
      ...agg,
      updatedAtMs: Date.now(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return agg;
  }

  async function reviewsFor(field, value) {
    if (!value) return [];
    const snap = await db().collectionGroup('reviews').where(field, '==', value).get();
    return snap.docs.map((d) => d.data() || {});
  }

  async function recomputeTargets({ eventId, hostId, gemId, businessId }) {
    if (eventId) {
      const snap = await db().collection('events').doc(eventId).collection('reviews').get();
      await writeAggregate(statsRef('events', eventId), snap.docs.map((d) => d.data() || {}));
    }
    if (hostId) {
      await writeAggregate(statsRef('users', hostId), await reviewsFor('hostId', hostId));
    }
    if (businessId) {
      await writeAggregate(
        db().collection('users').doc(businessId).collection('business_review_stats').doc('aggregate'),
        await reviewsFor('businessId', businessId),
      );
    }
    if (gemId) {
      await writeAggregate(statsRef('gems', gemId), await reviewsFor('gemId', gemId));
    }
  }

  async function upsertGemCopy(reviewId, data, remove) {
    const gemId = data.gemId;
    if (!gemId) return;
    const copyRef = db().collection('gems').doc(gemId).collection('event_reviews').doc(reviewId);
    if (remove) {
      await copyRef.delete().catch(() => {});
      return;
    }
    await copyRef.set({
      reviewId,
      eventId: data.eventId || '',
      authorId: data.authorId || '',
      authorName: data.authorName || '',
      stars: data.stars,
      note: data.note || '',
      hidden: data.hidden === true,
      createdAtMs: data.createdAtMs || Date.now(),
      updatedAtMs: data.updatedAtMs || Date.now(),
    }, { merge: true });
  }

  fns.submitEventReview = onCall(callOpts, async (request) => {
    const uid = request.auth && request.auth.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Sign in.');
    const eventId = request.data && request.data.eventId;
    const stars = normalizeStars(request.data && request.data.stars);
    const rawNote = String((request.data && request.data.note) || '').trim();
    const authorName = String((request.data && request.data.authorName) || '').trim().slice(0, 80);
    if (!eventId) throw new HttpsError('invalid-argument', 'eventId is required.');
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
    const rsvped = await requireRsvp(eventId, uid);
    if (!rsvped) {
      throw new HttpsError('permission-denied', 'Only people who RSVP\'d can review this event.');
    }
    const hostId = event.creatorId || '';
    const gemId = typeof event.gemId === 'string' ? event.gemId : '';
    let businessId = '';
    if (hostId) {
      const status = await verifiedEntitlement(hostId);
      if (status && status.pro) businessId = hostId;
    }
    const note = rawNote ? maskContactInfo(rawNote) : '';
    const ref = db().collection('events').doc(eventId).collection('reviews').doc(uid);
    const existing = await ref.get();
    const now = Date.now();
    const payload = {
      authorId: uid,
      authorName,
      stars,
      note,
      hidden: false,
      eventId,
      eventTitle: event.title || '',
      hostId,
      businessId: businessId || null,
      gemId: gemId || null,
      createdAtMs: existing.exists ? (existing.get('createdAtMs') || now) : now,
      updatedAtMs: now,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    if (!existing.exists) {
      payload.createdAt = admin.firestore.FieldValue.serverTimestamp();
    }
    // Preserve a previous host reply when the reviewer edits their review.
    if (existing.exists && existing.get('reply')) {
      payload.reply = existing.get('reply');
      payload.replyAtMs = existing.get('replyAtMs') || null;
      payload.replyAuthorId = existing.get('replyAuthorId') || null;
    }
    await ref.set(payload, { merge: true });
    await upsertGemCopy(`${eventId}_${uid}`, payload, false);
    await runParallelModeration({
      text: note,
      authorId: uid,
      targetPath: ref.path,
    });
    const agg = await recomputeTargets({ eventId, hostId, gemId, businessId });
    return { ok: true, stars, note, edited: existing.exists, aggregate: agg || null };
  });

  fns.replyToEventReview = onCall(callOpts, async (request) => {
    const uid = request.auth && request.auth.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Sign in.');
    const eventId = request.data && request.data.eventId;
    const reviewerId = request.data && request.data.reviewerId;
    const raw = String((request.data && request.data.reply) || '').trim();
    if (!eventId || !reviewerId) {
      throw new HttpsError('invalid-argument', 'eventId and reviewerId are required.');
    }
    if (!raw) throw new HttpsError('invalid-argument', 'Reply cannot be empty.');
    if (raw.length > REVIEW_REPLY_MAX) {
      throw new HttpsError('invalid-argument', 'Replies can be at most 300 characters.');
    }
    if (containsBanned(raw)) {
      throw new HttpsError('failed-precondition', 'That reply cannot be posted.');
    }
    const event = await loadEvent(eventId);
    if (!event) throw new HttpsError('not-found', 'Event not found.');
    if (event.creatorId !== uid) {
      throw new HttpsError('permission-denied', 'Only the host can reply to reviews.');
    }
    const status = await verifiedEntitlement(uid);
    if (!status || !status.pro) {
      throw new HttpsError('permission-denied', 'Replying to reviews is a Premium perk.', { reason: 'premium-required' });
    }
    const ref = db().collection('events').doc(eventId).collection('reviews').doc(reviewerId);
    const existing = await ref.get();
    if (!existing.exists) throw new HttpsError('not-found', 'Review not found.');
    const reply = maskContactInfo(raw);
    await ref.update({
      reply,
      replyAtMs: Date.now(),
      replyAuthorId: uid,
      replyUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    await runParallelModeration({
      text: reply,
      authorId: uid,
      targetPath: `${ref.path}#reply`,
    });
    return { ok: true, reply };
  });

  fns.recordEndedRsvp = onCall(callOpts, async (request) => {
    const uid = request.auth && request.auth.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Sign in.');
    const eventId = request.data && request.data.eventId;
    if (!eventId) throw new HttpsError('invalid-argument', 'eventId is required.');
    const event = await loadEvent(eventId);
    if (!event) throw new HttpsError('not-found', 'Event not found.');
    if (!isEventEnded(event)) {
      throw new HttpsError('failed-precondition', 'This event has not ended yet.');
    }
    const rsvped = await requireRsvp(eventId, uid);
    if (!rsvped) {
      throw new HttpsError('permission-denied', 'Only people who RSVP\'d can record this event.');
    }
    const ref = db().collection('users').doc(uid).collection('ended_rsvps').doc(eventId);
    if (!ref.exists) {
      // exists check needs get
    }
    const snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        eventId,
        endedAtMs: Date.now(),
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
    const all = await db().collection('users').doc(uid).collection('ended_rsvps').count().get();
    const count = (all.data() && all.data().count) || 0;
    const prompted = await db().collection('users').doc(uid).collection('play_review_prompt').doc('state').get();
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
