'use strict';

const { aggregateFromReviews } = require('./eventReviews');

async function collectReviewArtifacts(db, uid) {
  const refs = [];
  const targets = [];
  try {
    const snap = await db.collectionGroup('reviews').where('authorId', '==', uid).get();
    snap.docs.forEach((d) => {
      refs.push(d.ref);
      const data = d.data() || {};
      targets.push({
        eventId: data.eventId || (d.ref.parent && d.ref.parent.parent && d.ref.parent.parent.id) || '',
        hostId: data.hostId || '',
        gemId: data.gemId || '',
        businessId: data.businessId || '',
      });
    });
  } catch (e) {
    console.warn('reviews purge skipped:', e && e.message);
  }
  try {
    const copies = await db.collectionGroup('event_reviews').where('authorId', '==', uid).get();
    copies.docs.forEach((d) => refs.push(d.ref));
  } catch (e) {
    console.warn('event_reviews purge skipped:', e && e.message);
  }
  try {
    const ended = await db.collection('users').doc(uid).collection('ended_rsvps').get();
    ended.docs.forEach((d) => refs.push(d.ref));
    refs.push(db.collection('users').doc(uid).collection('play_review_prompt').doc('state'));
    refs.push(db.collection('users').doc(uid).collection('review_stats').doc('aggregate'));
    refs.push(db.collection('users').doc(uid).collection('business_review_stats').doc('aggregate'));
  } catch (e) {
    console.warn('review personal docs purge skipped:', e && e.message);
  }
  return { refs, targets };
}

async function writeAggregate(db, admin, ref, rows) {
  const agg = aggregateFromReviews(rows);
  await ref.set({
    ...agg,
    updatedAtMs: Date.now(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  return agg;
}

async function reviewsFor(db, field, value) {
  if (!value) return [];
  const snap = await db.collectionGroup('reviews').where(field, '==', value).get();
  return snap.docs.map((d) => d.data() || {});
}

async function recomputeReviewTargets(db, admin, targets) {
  const seen = new Set();
  for (const t of targets || []) {
    const key = `${t.eventId}|${t.hostId}|${t.gemId}|${t.businessId}`;
    if (seen.has(key)) continue;
    seen.add(key);
    if (t.eventId) {
      const snap = await db.collection('events').doc(t.eventId).collection('reviews').get();
      await writeAggregate(
        db,
        admin,
        db.collection('events').doc(t.eventId).collection('review_stats').doc('aggregate'),
        snap.docs.map((d) => d.data() || {}),
      );
    }
    if (t.hostId) {
      await writeAggregate(
        db,
        admin,
        db.collection('users').doc(t.hostId).collection('review_stats').doc('aggregate'),
        await reviewsFor(db, 'hostId', t.hostId),
      );
    }
    if (t.businessId) {
      await writeAggregate(
        db,
        admin,
        db.collection('users').doc(t.businessId).collection('business_review_stats').doc('aggregate'),
        await reviewsFor(db, 'businessId', t.businessId),
      );
    }
    if (t.gemId) {
      await writeAggregate(
        db,
        admin,
        db.collection('gems').doc(t.gemId).collection('review_stats').doc('aggregate'),
        await reviewsFor(db, 'gemId', t.gemId),
      );
    }
  }
}

module.exports = { collectReviewArtifacts, recomputeReviewTargets };
