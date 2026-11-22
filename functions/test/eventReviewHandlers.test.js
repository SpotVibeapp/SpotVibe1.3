'use strict';

const { describe, it, beforeEach } = require('node:test');
const assert = require('node:assert/strict');
const { install } = require('../lib/eventReviewHandlers');
const { collectReviewRefs } = require('../lib/eventReviewCleanup');

// Minimal in-memory Firestore: enough for the review handlers.
function fakeDb() {
  const docs = new Map();
  const docRef = (path) => ({
    path,
    id: path.split('/').pop(),
    collection: (name) => colRef(`${path}/${name}`),
    async get() {
      const data = docs.get(path);
      return {
        exists: data !== undefined,
        id: path.split('/').pop(),
        data: () => (data ? { ...data } : undefined),
        get: (k) => (data ? data[k] : undefined),
      };
    },
    async set(value, opts) {
      const prev = opts && opts.merge ? docs.get(path) || {} : {};
      docs.set(path, { ...prev, ...value });
    },
    async update(value) {
      if (!docs.has(path)) throw new Error('missing');
      docs.set(path, { ...docs.get(path), ...value });
    },
  });
  const children = (path) => [...docs.keys()].filter((p) => {
    const rest = p.slice(path.length + 1);
    return p.startsWith(`${path}/`) && rest && !rest.includes('/');
  });
  const query = (path, filters, max) => ({
    where: (f, op, v) => query(path, [...filters, [f, v]], max),
    limit: (n) => query(path, filters, n),
    async get() {
      let hits = children(path).filter((p) => filters.every(([f, v]) => docs.get(p)[f] === v));
      if (max != null) hits = hits.slice(0, max);
      return { docs: hits.map((p) => ({ id: p.split('/').pop(), ref: docRef(p), data: () => ({ ...docs.get(p) }) })) };
    },
    count: () => ({ get: async () => ({ data: () => ({ count: children(path).length }) }) }),
  });
  const colRef = (path) => ({ doc: (id) => docRef(`${path}/${id}`), ...query(path, [], null) });
  return { docs, collection: (name) => colRef(name) };
}

class HttpsError extends Error {
  constructor(code, message) {
    super(message);
    this.code = code;
  }
}

function setup({ pro = false } = {}) {
  const db = fakeDb();
  const fns = {};
  const moderated = [];
  install({
    exports: fns,
    onCall: (opts, handler) => Object.assign(handler, { opts }),
    HttpsError,
    admin: { firestore: Object.assign(() => db, { FieldValue: { serverTimestamp: () => 'ts' } }) },
    containsBanned: (t) => String(t).includes('badword'),
    runParallelModeration: async (spec) => { moderated.push(spec); },
    verifiedEntitlement: async () => ({ pro }),
    revenueCatSecretKey: 'secret',
  });
  return { db, fns, moderated };
}

const call = (fn, uid, data) => fn({ auth: uid ? { uid } : null, data });
const PAST = Date.now() - 3600_000;

describe('event review callables', () => {
  let ctx;
  beforeEach(async () => {
    ctx = setup();
    await ctx.db.collection('events').doc('e1').set({ title: 'Trivia', creatorId: 'host', endDateTimeMs: PAST });
    await ctx.db.collection('events').doc('e1').collection('rsvps').doc('u1').set({ userId: 'u1' });
    await ctx.db.collection('events').doc('e2').set({ title: 'Later', creatorId: 'host', endDateTimeMs: Date.now() + 3600_000 });
  });

  it('every callable is a private invoker', () => {
    for (const name of ['submitEventReview', 'replyToEventReview', 'listEventReviews', 'recordEndedRsvp', 'markPlayReviewPrompted']) {
      assert.equal(ctx.fns[name].opts.invoker, 'private', name);
    }
  });

  it('requires sign-in, an RSVP, and an ended event', async () => {
    await assert.rejects(call(ctx.fns.submitEventReview, null, { eventId: 'e1', stars: 5 }), { code: 'unauthenticated' });
    await assert.rejects(call(ctx.fns.submitEventReview, 'u2', { eventId: 'e1', stars: 5 }), { code: 'permission-denied' });
    await assert.rejects(call(ctx.fns.submitEventReview, 'u1', { eventId: 'e2', stars: 5 }), { code: 'failed-precondition' });
    await assert.rejects(call(ctx.fns.submitEventReview, 'u1', { eventId: 'e1', stars: 6 }), { code: 'invalid-argument' });
    await assert.rejects(call(ctx.fns.submitEventReview, 'u1', { eventId: 'e1', stars: 4, note: 'badword' }), { code: 'failed-precondition' });
  });

  it('stores one masked, moderated review in event_reviews and lists it publicly', async () => {
    const out = await call(ctx.fns.submitEventReview, 'u1', { eventId: 'e1', stars: 4, note: 'Great, text me 915-555-0100', authorName: 'Maya' });
    assert.equal(out.ok, true);
    const stored = ctx.db.docs.get('event_reviews/e1_u1');
    assert.equal(stored.stars, 4);
    assert.equal(stored.hostId, 'host');
    assert.equal(stored.note.includes('555-0100'), false);
    assert.equal(ctx.moderated[0].targetPath, 'event_reviews/e1_u1');
    await call(ctx.fns.submitEventReview, 'u1', { eventId: 'e1', stars: 2 });
    assert.equal([...ctx.db.docs.keys()].filter((k) => k.startsWith('event_reviews/')).length, 1);
    const listed = await call(ctx.fns.listEventReviews, null, { scope: 'event', id: 'e1' });
    assert.deepEqual(listed.stats, { count: 1, avgStars: 2 });
    assert.equal(listed.reviews[0].authorName, 'Maya');
    const host = await call(ctx.fns.listEventReviews, null, { scope: 'host', id: 'host', limit: 0 });
    assert.deepEqual(host.stats, { count: 1, avgStars: 2 });
    assert.equal(host.reviews.length, 0);
    await assert.rejects(call(ctx.fns.listEventReviews, null, { scope: 'users', id: 'x' }), { code: 'invalid-argument' });
  });

  it('keeps a moderator-hidden review hidden when the author edits it', async () => {
    await call(ctx.fns.submitEventReview, 'u1', { eventId: 'e1', stars: 1 });
    await ctx.db.collection('event_reviews').doc('e1_u1').update({ hidden: true });
    await call(ctx.fns.submitEventReview, 'u1', { eventId: 'e1', stars: 5 });
    const listed = await call(ctx.fns.listEventReviews, null, { scope: 'event', id: 'e1' });
    assert.equal(listed.stats.count, 0);
  });

  it('stops hosts reviewing their own event', async () => {
    await ctx.db.collection('events').doc('e1').collection('rsvps').doc('host').set({ userId: 'host' });
    await assert.rejects(call(ctx.fns.submitEventReview, 'host', { eventId: 'e1', stars: 5 }), { code: 'permission-denied' });
  });

  it('lets only a Premium host reply', async () => {
    await call(ctx.fns.submitEventReview, 'u1', { eventId: 'e1', stars: 5 });
    await assert.rejects(call(ctx.fns.replyToEventReview, 'host', { eventId: 'e1', reviewerId: 'u1', reply: 'Thanks' }), { code: 'permission-denied' });
    const pro = setup({ pro: true });
    await pro.db.collection('events').doc('e1').set({ creatorId: 'host', endDateTimeMs: PAST });
    await pro.db.collection('event_reviews').doc('e1_u1').set({ eventId: 'e1', authorId: 'u1', stars: 5 });
    await assert.rejects(call(pro.fns.replyToEventReview, 'other', { eventId: 'e1', reviewerId: 'u1', reply: 'Hi' }), { code: 'permission-denied' });
    const out = await call(pro.fns.replyToEventReview, 'host', { eventId: 'e1', reviewerId: 'u1', reply: 'Thanks! mail me at a@b.co' });
    assert.equal(out.reply.includes('a@b.co'), false);
    assert.equal(pro.db.docs.get('event_reviews/e1_u1').reply, out.reply);
  });

  it('counts ended RSVPs once each for the Play prompt and records the prompt once', async () => {
    const first = await call(ctx.fns.recordEndedRsvp, 'u1', { eventId: 'e1' });
    const again = await call(ctx.fns.recordEndedRsvp, 'u1', { eventId: 'e1' });
    assert.equal(first.count, 1);
    assert.equal(again.count, 1);
    assert.equal(again.alreadyPrompted, false);
    await assert.rejects(call(ctx.fns.recordEndedRsvp, 'u1', { eventId: 'e2' }), { code: 'failed-precondition' });
    assert.deepEqual(await call(ctx.fns.markPlayReviewPrompted, 'u1', {}), { ok: true, already: false });
    assert.deepEqual(await call(ctx.fns.markPlayReviewPrompted, 'u1', {}), { ok: true, already: true });
    assert.equal((await call(ctx.fns.recordEndedRsvp, 'u1', { eventId: 'e1' })).alreadyPrompted, true);
  });

  it('account deletion collects authored and hosted reviews plus prompt state', async () => {
    await call(ctx.fns.submitEventReview, 'u1', { eventId: 'e1', stars: 5 });
    await call(ctx.fns.recordEndedRsvp, 'u1', { eventId: 'e1' });
    const mine = (await collectReviewRefs(ctx.db, 'u1')).map((r) => r.path).sort();
    assert.deepEqual(mine, ['event_reviews/e1_u1', 'users/u1/ended_rsvps/e1', 'users/u1/play_review_prompt/state']);
    const hosted = (await collectReviewRefs(ctx.db, 'host')).map((r) => r.path);
    assert.equal(hosted.includes('event_reviews/e1_u1'), true);
  });
});
