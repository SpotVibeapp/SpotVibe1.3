/**
 * SpotVibe Cloud Functions.
 *
 * Deploy:
 *   cd functions && npm install
 *   firebase deploy --only functions
 *
 * What's here:
 *  - deleteUser          callable — authoritative account deletion (auth + data)
 *  - bannedUserCleanup   Firestore trigger — purges a banned user's content
 *  - moderateComment     Firestore trigger — hides comments containing banned words
 *  - moderateUserEvent   Firestore trigger — hides user events containing banned words
 *  - promoteAdmin        callable — adds a user to the `admins/{uid}` roster
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

  await commitDeletions(await collectUserDeletions(uid));

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
 * Authoritative cleanup when a user is banned. Fires whenever a `bans/{uid}`
 * document is created (the in-app admin "Ban user" action), and deletes the
 * banned user's events, comments, RSVPs, claims, reports, saved events,
 * profile, and blocks — so their content is gone from the feed even for
 * readers that don't filter on the ban list.
 *
 * NOTE: this is destructive and is NOT undone by "unban" (unban restores the
 * account but the deleted content does not come back). The in-app readers
 * already hide banned users' content via the `bans/{uid}` list, which IS
 * reversible; this function is the hard, authoritative cleanup on top.
 */
exports.bannedUserCleanup = onDocumentCreated('bans/{uid}', async (event) => {
  const uid = event.params.uid;
  if (!uid) return;
  const refs = await collectUserDeletions(uid);
  await commitDeletions(refs);
  return { ok: true, deleted: refs.length };
});

/**
 * Collects every Firestore document reference owned by `uid` (or mentioning
 * them) so it can be deleted. Deduplicates; the caller commits in chunks.
 */
async function collectUserDeletions(uid) {
  const db = admin.firestore();
  const refs = [];

  const push = (snap) => snap.docs.forEach((d) => refs.push(d.ref));

  refs.push(db.collection('users').doc(uid));
  refs.push(db.collection('blocks').doc(uid));

  push(await db.collection('users').doc(uid).collection('saved_events').get());
  push(await db.collection('blocks').doc(uid).collection('blocked').get());

  // Events they created (mirrored across `events/{id}` and `user_events/{id}`).
  const userEvents = await db
    .collection('user_events')
    .where('creatorId', '==', uid)
    .get();
  userEvents.docs.forEach((d) => {
    refs.push(d.ref);
    refs.push(db.collection('events').doc(d.id));
  });
  const events = await db
    .collection('events')
    .where('creatorId', '==', uid)
    .get();
  events.docs.forEach((d) => {
    refs.push(d.ref);
    refs.push(db.collection('user_events').doc(d.id));
  });

  // Collection-group queries (indexes in firestore.indexes.json).
  push(await db.collectionGroup('rsvps').where('userId', '==', uid).get());
  push(await db.collectionGroup('comments').where('authorId', '==', uid).get());

  push(await db.collection('event_claims').where('userId', '==', uid).get());
  push(await db.collection('user_reports').where('reportedById', '==', uid).get());
  push(await db.collection('user_reports').where('reportedUserId', '==', uid).get());

  // Dedupe (mirrored event docs can collide).
  const seen = new Set();
  return refs.filter((ref) => {
    const key = ref.path;
    if (seen.has(key)) return false;
    seen.add(key);
    return true;
  });
}

/**
 * Commits a list of deletions in chunks (Firestore batches cap at 500 ops).
 */
async function commitDeletions(refs) {
  const db = admin.firestore();
  for (let i = 0; i < refs.length; i += 400) {
    const batch = db.batch();
    refs.slice(i, i + 400).forEach((ref) => batch.delete(ref));
    await batch.commit();
  }
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
 * Promotes a Firebase Auth user to administrator.
 *
 * Security: only an EXISTING admin may call this (checked against the
 * `admins/{uid}` collection). Bootstrap your first admin via the Firebase
 * console: Firestore → Start collection → `admins` → doc id = the user's UID
 * from Authentication → Users, with fields {role:"admin", email:...}.
 * After that, an admin can promote more admins from anywhere:
 *
 *   firebase functions:call promoteAdmin --data '{"uid":"<uid>","email":"you@example.com"}'
 */
exports.promoteAdmin = onCall(async (request) => {
  if (!request.auth || !request.auth.uid) {
    throw new HttpsError('unauthenticated', 'You must be signed in to promote an admin.');
  }
  // Only an existing admin may promote new admins.
  const caller = await admin
    .firestore()
    .collection('admins')
    .doc(request.auth.uid)
    .get();
  if (!caller.exists) {
    throw new HttpsError(
      'permission-denied',
      'Only an existing admin can promote new admins.'
    );
  }
  const uid = request.data.uid;
  const email = request.data.email || '';
  if (!uid) {
    throw new HttpsError('invalid-argument', 'uid is required.');
  }
  await admin.firestore().collection('admins').doc(uid).set({
    role: 'admin',
    email: email,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  return { ok: true };
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
