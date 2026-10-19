// Security-rules tests for ../firestore.rules.
// Run: cd firestore-tests && npm install && npm test   (Java 21+ required)
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
