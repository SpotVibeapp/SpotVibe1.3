// Security-rules tests for ../firestore.rules.
// Run: cd firestore-tests && npm install && npm test   (Java 21+ required)
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, test } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  deleteField,
  doc,
  getDoc,
  increment,
  serverTimestamp,
  setDoc,
  updateDoc,
  writeBatch,
  runTransaction,
  deleteDoc,
} from 'firebase/firestore';

let env;

before(async () => {
  const [host, port] = (process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8181').split(':');
  env = await initializeTestEnvironment({
    projectId: 'demo-spotvibe',
    firestore: {
      rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8'),
      host,
      port: Number(port),
    },
  });
});

after(async () => {
  await env?.cleanup();
});

beforeEach(async () => {
  await env.clearFirestore();
});

const db = (uid) => (uid ? env.authenticatedContext(uid).firestore() : env.unauthenticatedContext().firestore());
const seed = (fn) => env.withSecurityRulesDisabled((ctx) => fn(ctx.firestore()));
const makeAdmin = (uid) => seed((d) => setDoc(doc(d, 'admins', uid), { role: 'admin' }));

// ── Blocker 1: PII off the public profile ──────────────────────────────────
describe('users/{uid} public profile', () => {
  test('owner creates a profile without an email', async () => {
    await assertSucceeds(setDoc(doc(db('alice'), 'users/alice'), { name: 'Alice', avatarUrl: 'a' }));
  });

  test("blank email placeholder is accepted (rollout compatibility)", async () => {
    await assertSucceeds(
      setDoc(doc(db('alice'), 'users/alice'), { name: 'Alice', avatarUrl: 'a', email: '' })
    );
  });

  test('creating a public profile with a real email or phone is denied', async () => {
    await assertFails(
      setDoc(doc(db('alice'), 'users/alice'), { name: 'Alice', avatarUrl: 'a', email: 'a@x.com' })
    );
    await assertFails(
      setDoc(doc(db('alice'), 'users/alice'), { name: 'Alice', avatarUrl: 'a', phone: '+1915' })
    );
  });

  test('adding or changing an email on the public doc is denied', async () => {
    await seed((d) => setDoc(doc(d, 'users/alice'), { name: 'Alice', avatarUrl: 'a' }));
    await assertFails(updateDoc(doc(db('alice'), 'users/alice'), { email: 'a@x.com' }));
    await seed((d) => setDoc(doc(d, 'users/bob'), { name: 'Bob', avatarUrl: 'b', email: 'old@x.com' }));
    await assertFails(updateDoc(doc(db('bob'), 'users/bob'), { email: 'new@x.com' }));
  });

  test('a legacy email can be removed, and other edits still work', async () => {
    await seed((d) => setDoc(doc(d, 'users/bob'), { name: 'Bob', avatarUrl: 'b', email: 'old@x.com' }));
    await assertSucceeds(updateDoc(doc(db('bob'), 'users/bob'), { avatarUrl: 'new' }));
    await assertSucceeds(updateDoc(doc(db('bob'), 'users/bob'), { email: deleteField() }));
  });

  test('other signed-in users can read the public profile', async () => {
    await seed((d) => setDoc(doc(d, 'users/alice'), { name: 'Alice', avatarUrl: 'a' }));
    await assertSucceeds(getDoc(doc(db('bob'), 'users/alice')));
    await assertFails(getDoc(doc(db(null), 'users/alice')));
  });

  test('nobody else can write a profile', async () => {
    await assertFails(setDoc(doc(db('mallory'), 'users/alice'), { name: 'x', avatarUrl: 'a' }));
  });
});

describe('users/{uid}/private/profile', () => {
  test('owner reads and writes their private profile', async () => {
    const ref = doc(db('alice'), 'users/alice/private/profile');
    await assertSucceeds(setDoc(ref, { email: 'a@x.com', updatedAt: serverTimestamp() }, { merge: true }));
    await assertSucceeds(getDoc(ref));
  });

  test('other users cannot read or write it', async () => {
    await seed((d) => setDoc(doc(d, 'users/alice/private/profile'), { email: 'a@x.com' }));
    await assertFails(getDoc(doc(db('bob'), 'users/alice/private/profile')));
    await assertFails(setDoc(doc(db('bob'), 'users/alice/private/profile'), { email: 'evil@x.com' }));
    await assertFails(getDoc(doc(db(null), 'users/alice/private/profile')));
  });

  test('admins can read it', async () => {
    await makeAdmin('root');
    await seed((d) => setDoc(doc(d, 'users/alice/private/profile'), { email: 'a@x.com' }));
    await assertSucceeds(getDoc(doc(db('root'), 'users/alice/private/profile')));
  });

  test('only the profile doc with known keys may be written', async () => {
    await assertFails(setDoc(doc(db('alice'), 'users/alice/private/other'), { email: 'a@x.com' }));
    await assertFails(setDoc(doc(db('alice'), 'users/alice/private/profile'), { isAdmin: true }));
  });
});

// ── Blocker 2: paid perks, founding roster, counters ───────────────────────
const START = Date.UTC(2026, 10, 1, 1, 0);
const END = START + 3 * 3600 * 1000;
const eventDoc = (creatorId, extra = {}) => ({
  title: 'Open mic',
  creatorId,
  kind: 'user',
  dateTimeMs: START,
  endDateTimeMs: END,
  imageUrls: [],
  featuredWeekKey: null,
  analyticsSearchImpressions: 0,
  analyticsViews: 0,
  analyticsSaves: 0,
  analyticsClicks: 0,
  bookmarkedCount: 0,
  interestedCount: 0,
  ...extra,
});
const seedEvent = (id, data) =>
  seed(async (d) => {
    await setDoc(doc(d, `events/${id}`), data);
    await setDoc(doc(d, `user_events/${id}`), data);
  });

describe('featuredWeekKey is server-only', () => {
  for (const col of ['events', 'user_events']) {
    test(`${col}: create with featuredWeekKey null succeeds, with a week fails`, async () => {
      await assertSucceeds(setDoc(doc(db('alice'), `${col}/e1`), eventDoc('alice')));
      await assertFails(
        setDoc(doc(db('alice'), `${col}/e2`), eventDoc('alice', { featuredWeekKey: '2026-W44' }))
      );
    });

    test(`${col}: creator cannot set it on update but can edit content`, async () => {
      await seedEvent('e1', eventDoc('alice'));
      const ref = doc(db('alice'), `${col}/e1`);
      await assertFails(updateDoc(ref, { featuredWeekKey: '2026-W44' }));
      await assertFails(updateDoc(ref, { featuredAt: 1 }));
      await assertSucceeds(updateDoc(ref, { title: 'Open mic night' }));
    });

    test(`${col}: counters cannot be inflated by the creator or others`, async () => {
      await seedEvent('e1', eventDoc('alice'));
      await assertFails(updateDoc(doc(db('alice'), `${col}/e1`), { analyticsViews: 500 }));
      await assertFails(updateDoc(doc(db('bob'), `${col}/e1`), { analyticsViews: increment(2) }));
      await assertFails(
        updateDoc(doc(db('bob'), `${col}/e1`), {
          analyticsViews: increment(1),
          analyticsClicks: increment(1),
        })
      );
      await assertFails(
        updateDoc(doc(db('bob'), `${col}/e1`), { analyticsViews: increment(1), title: 'pwned' })
      );
    });

    test(`${col}: a single analytics +1 by any signed-in user succeeds`, async () => {
      await seedEvent('e1', eventDoc('alice'));
      await assertSucceeds(updateDoc(doc(db('bob'), `${col}/e1`), { analyticsViews: increment(1) }));
      await assertFails(updateDoc(doc(db(null), `${col}/e1`), { analyticsViews: increment(1) }));
    });
  }

  test('admin can feature an event', async () => {
    await makeAdmin('root');
    await seedEvent('e1', eventDoc('alice'));
    await assertSucceeds(updateDoc(doc(db('root'), 'events/e1'), { featuredWeekKey: '2026-W44' }));
  });

  test('user_events interestedCount is no longer client-writable', async () => {
    await seedEvent('e1', eventDoc('alice'));
    await assertFails(updateDoc(doc(db('bob'), 'user_events/e1'), { interestedCount: increment(1) }));
  });
});

describe('save counters follow the caller\'s own saved_events flag', () => {
  const toggle = (uid, eventId, flags) => {
    const d = db(uid);
    return runTransaction(d, async (tx) => {
      const saveRef = doc(d, `users/${uid}/saved_events/${eventId}`);
      const eventRef = doc(d, `events/${eventId}`);
      const saveSnap = await tx.get(saveRef);
      await tx.get(eventRef);
      const prevB = saveSnap.data()?.bookmarked === true;
      const prevI = saveSnap.data()?.interested === true;
      if (!flags.bookmarked && !flags.interested) {
        if (saveSnap.exists()) tx.delete(saveRef);
      } else {
        tx.set(saveRef, { ...flags, countedRemotely: true }, { merge: true });
      }
      const updates = {};
      if (prevB !== flags.bookmarked) updates.bookmarkedCount = increment(flags.bookmarked ? 1 : -1);
      if (prevI !== flags.interested) updates.interestedCount = increment(flags.interested ? 1 : -1);
      if (Object.keys(updates).length) tx.update(eventRef, updates);
    });
  };

  test('the app (and live v14) save transaction works both ways', async () => {
    await seedEvent('e1', eventDoc('alice'));
    await assertSucceeds(toggle('bob', 'e1', { bookmarked: true, interested: true }));
    await assertSucceeds(toggle('bob', 'e1', { bookmarked: false, interested: true }));
    await assertSucceeds(toggle('bob', 'e1', { bookmarked: false, interested: false }));
    let snap;
    await seed(async (d) => {
      snap = await getDoc(doc(d, 'events/e1'));
    });
    assert.equal(snap.data().bookmarkedCount, 0);
    assert.equal(snap.data().interestedCount, 0);
  });

  test('a counter bump without flipping the flag is rejected', async () => {
    await seedEvent('e1', eventDoc('alice'));
    await assertFails(updateDoc(doc(db('bob'), 'events/e1'), { bookmarkedCount: increment(1) }));
    await seed((d) => setDoc(doc(d, 'users/bob/saved_events/e1'), { bookmarked: true }));
    // Flag already set: a second +1 has no matching flip.
    await assertFails(updateDoc(doc(db('bob'), 'events/e1'), { bookmarkedCount: increment(1) }));
  });

  test('flipping the flag cannot move the counter by more than 1', async () => {
    await seedEvent('e1', eventDoc('alice'));
    const d = db('bob');
    await assertFails(
      runTransaction(d, async (tx) => {
        await tx.get(doc(d, 'users/bob/saved_events/e1'));
        tx.set(doc(d, 'users/bob/saved_events/e1'), { bookmarked: true });
        tx.update(doc(d, 'events/e1'), { bookmarkedCount: increment(5) });
      })
    );
  });
});

describe('meta/founding and featured_weeks are server-only', () => {
  test('anyone can read the founding roster, nobody can write it', async () => {
    await seed((d) => setDoc(doc(d, 'meta/founding'), { memberIds: ['x'], count: 1 }));
    await assertSucceeds(getDoc(doc(db(null), 'meta/founding')));
    await assertFails(
      setDoc(doc(db('bob'), 'meta/founding'), { memberIds: ['x', 'bob'], count: 2 })
    );
    await assertFails(updateDoc(doc(db('bob'), 'meta/founding'), { count: increment(1) }));
  });

  test('featured_weeks markers are not client-accessible', async () => {
    await assertFails(setDoc(doc(db('alice'), 'featured_weeks/alice_2026-W44'), { eventId: 'e1' }));
  });
});
