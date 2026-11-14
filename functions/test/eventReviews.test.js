'use strict';

const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const {
  isEventEnded,
  eventEndMs,
  normalizeStars,
  aggregateFromReviews,
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
