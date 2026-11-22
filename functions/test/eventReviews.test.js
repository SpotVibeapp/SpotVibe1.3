'use strict';

const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const {
  isEventEnded,
  eventEndMs,
  normalizeStars,
  aggregateFromReviews,
  reviewDocId,
  isValidId,
  publicReview,
  clampLimit,
  buildListing,
  SCOPE_FIELDS,
  REVIEWS_COLLECTION,
} = require('../lib/eventReviews');

describe('event review helpers', () => {
  it('treats an event as ended only after its end time, with start as a legacy fallback', () => {
    const now = 1_000_000;
    assert.equal(isEventEnded({ endDateTimeMs: now, dateTimeMs: now - 10 }, now), true);
    assert.equal(isEventEnded({ endDateTimeMs: now + 1, dateTimeMs: now - 10 }, now), false);
    assert.equal(isEventEnded({ dateTimeMs: now }, now), true);
    assert.equal(isEventEnded({ dateTimeMs: now + 1 }, now), false);
    assert.equal(isEventEnded({}, now), false);
    assert.equal(eventEndMs({ endDateTimeMs: 50, dateTimeMs: 10 }), 50);
  });

  it('accepts only whole stars from 1 to 5 and ignores hidden reviews in aggregates', () => {
    assert.equal(normalizeStars(5), 5);
    assert.equal(normalizeStars(1), 1);
    assert.equal(normalizeStars(0), null);
    assert.equal(normalizeStars(6), null);
    assert.equal(normalizeStars(3.5), null);
    const agg = aggregateFromReviews([
      { stars: 5 },
      { stars: 3 },
      { stars: 4, hidden: true },
      { stars: 99 },
    ]);
    assert.deepEqual(agg, { count: 2, sumStars: 8, avgStars: 4 });
  });
});

describe('server-only review storage', () => {
  it('uses one top-level doc per person per event and validates ids', () => {
    assert.equal(REVIEWS_COLLECTION, 'event_reviews');
    assert.equal(reviewDocId('evt1', 'uidA'), 'evt1_uidA');
    assert.equal(isValidId('abc_DEF-123'), true);
    assert.equal(isValidId(''), false);
    assert.equal(isValidId('a/b'), false);
    assert.equal(isValidId(42), false);
    assert.deepEqual(Object.keys(SCOPE_FIELDS).sort(), ['business', 'event', 'gem', 'host']);
  });

  it('returns only public fields, never moderation or reply-author internals', () => {
    const row = publicReview('evt1_uidA', {
      eventId: 'evt1', authorId: 'uidA', authorName: 'Maya', stars: 4, note: 'Fun',
      hostId: 'h1', reply: 'Thanks', replyAuthorId: 'h1', hidden: false,
      createdAtMs: 10, updatedAt: { secret: true },
    });
    assert.equal(row.stars, 4);
    assert.equal(row.reply, 'Thanks');
    assert.equal('replyAuthorId' in row, false);
    assert.equal('hidden' in row, false);
    assert.equal('updatedAt' in row, false);
  });

  it('clamps list limits to 0..50 with a default of 20', () => {
    assert.equal(clampLimit(undefined), 20);
    assert.equal(clampLimit(-3), 0);
    assert.equal(clampLimit(500), 50);
    assert.equal(clampLimit(7.9), 7);
  });

  it('builds a newest-first listing whose stats skip hidden and invalid reviews', () => {
    const out = buildListing([
      { id: 'a', data: { stars: 5, createdAtMs: 1 } },
      { id: 'b', data: { stars: 2, createdAtMs: 3 } },
      { id: 'c', data: { stars: 1, createdAtMs: 2, hidden: true } },
      { id: 'd', data: { stars: 0, createdAtMs: 4 } },
      { id: 'e', data: null },
    ], 1);
    assert.deepEqual(out.stats, { count: 2, avgStars: 3.5 });
    assert.equal(out.reviews.length, 1);
    assert.equal(out.reviews[0].id, 'b');
    assert.deepEqual(buildListing([], 0), { stats: { count: 0, avgStars: 0 }, reviews: [] });
  });
});
