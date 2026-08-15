/**
 * SpotVibe Cloud Functions.
 *
 * Deploy:
 *   cd functions && npm install
 *   firebase deploy --only functions
 *
 * What's here:
 *  - deleteUser          callable — authoritative account deletion (auth + data)
 *  - moderateComment     Firestore trigger — hides comments containing banned words
 *  - moderateUserEvent   Firestore trigger — hides user events containing banned words
 *  - seedCuratedEvents   callable — seeds the El Paso curated feed (Admin SDK)
 */
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const admin = require('firebase-admin');

admin.initializeApp();

// Minimal starter blocklist — expand this (or swap in an ML provider) before a
// broad launch. This is a last-line-of-defense behind the client-side filter.
const BANNED_WORDS = ['hatefulplaceholder'];

function containsBanned(text) {
  const lower = (text || '').toLowerCase();
  return BANNED_WORDS.some((w) => lower.includes(w));
}

/**
 * Authoritative account deletion. The in-app flow deletes the user's own data
 * first and then the auth record; this function does the same server-side with
 * Admin SDK so nothing is missed (e.g. if the client was interrupted).
 *
 * Usage from a client:
 *   final fn = FirebaseFunctions.instance.httpsCallable('deleteUser');
 *   await fn.call();
 */
exports.deleteUser = onCall(async (request) => {
  if (!request.auth || !request.auth.uid) {
    throw new HttpsError(
      'unauthenticated',
      'You must be signed in to delete your account.'
    );
  }
  const uid = request.auth.uid;

  await purgeUserData(uid);

  try {
    await admin.auth().deleteUser(uid);
  } catch (e) {
    if (e.code === 'auth/user-not-found') {
      // Already deleted — nothing to do.
    } else {
      throw new HttpsError('internal', `Could not delete auth record: ${e.message}`);
    }
  }

  return { ok: true };
});

/**
 * Deletes every Firestore document owned by `uid`. Best-effort; runs in a
 * single batch (Firestore batches cap at 500 ops — a single user is far
 * below that).
 */
async function purgeUserData(uid) {
  const db = admin.firestore();
  const batch = db.batch();

  batch.delete(db.collection('users').doc(uid));
  batch.delete(db.collection('blocks').doc(uid));

  const del = (snap) => snap.docs.forEach((d) => batch.delete(d.ref));

  del(await db.collection('users').doc(uid).collection('saved_events').get());
  del(await db.collection('blocks').doc(uid).collection('blocked').get());

  const userEvents = await db
    .collection('user_events')
    .where('creatorId', '==', uid)
    .get();
  userEvents.docs.forEach((d) => {
    batch.delete(d.ref);
    batch.delete(db.collection('events').doc(d.id));
  });

  del(await db.collectionGroup('rsvps').where('userId', '==', uid).get());
  del(await db.collectionGroup('comments').where('authorId', '==', uid).get());
  del(await db.collection('event_claims').where('userId', '==', uid).get());

  await batch.commit();
}

/**
 * Server-side moderation for comments. Client-side filtering can be bypassed;
 * this flags/hides content that matches the blocklist.
 */
exports.moderateComment = onDocumentCreated(
  'events/{eventId}/comments/{commentId}',
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const text = snap.get('text') || '';
    if (containsBanned(text)) {
      await snap.ref.update({
        hidden: true,
        flaggedReason: 'banned-word',
        moderatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  }
);

/**
 * Server-side moderation for user-created events (both mirrors are checked —
 * the event is written to `events/{id}` and `user_events/{id}`).
 */
exports.moderateUserEvent = onDocumentCreated('events/{eventId}', async (event) => {
  const snap = event.data;
  if (!snap) return;
  const text = `${snap.get('title') || ''} ${snap.get('description') || ''}`;
  if (containsBanned(text)) {
    await snap.ref.update({
      hidden: true,
      flaggedReason: 'banned-word',
      moderatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    // Mirror to the creator's user_events doc when present.
    const mirrorId = snap.id;
    const db = admin.firestore();
    await db.collection('user_events').doc(mirrorId).update({
      hidden: true,
      flaggedReason: 'banned-word',
      moderatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
});

/**
 * Seeds the curated El Paso events into `events/{id}`. Clients can no longer
 * write arbitrary feed docs (security rules require a creatorId), so seeding
 * happens here with the Admin SDK. Run once via:
 *   firebase functions:shell   →   seedCuratedEvents()
 */
exports.seedCuratedEvents = onCall(async () => {
  // Curated seed lives in lib/data/el_paso_events.dart. This function is a
  // stub: wire it to your seed source (e.g. export the list to JSON and
  // import it here) before relying on server-side seeding. The client already
  // falls back to the bundled curated list, so this is optional for v1.
  return { ok: true, seeded: 0 };
});
