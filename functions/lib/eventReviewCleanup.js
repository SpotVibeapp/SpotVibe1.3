'use strict';

const { REVIEWS_COLLECTION } = require('./eventReviews');

/**
 * Review data to delete with an account: reviews the user wrote, reviews
 * of events they hosted (those events are deleted too), and their private
 * Play-prompt bookkeeping. Stats are computed on read, so nothing needs
 * recomputing afterwards.
 */
async function collectReviewRefs(db, uid) {
  const refs = [];
  const reviews = db.collection(REVIEWS_COLLECTION);
  for (const field of ['authorId', 'hostId']) {
    const snap = await reviews.where(field, '==', uid).get();
    snap.docs.forEach((d) => refs.push(d.ref));
  }
  const userRef = db.collection('users').doc(uid);
  const ended = await userRef.collection('ended_rsvps').get();
  ended.docs.forEach((d) => refs.push(d.ref));
  refs.push(userRef.collection('play_review_prompt').doc('state'));
  return refs;
}

module.exports = { collectReviewRefs };
