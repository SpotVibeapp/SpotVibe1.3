'use strict';

const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const {
  quotaKeyForEvent,
  countQuotaPostsInCalendarMonth,
  seriesCountedThisMonth,
  resolveSeriesId,
  collectOwnedSeriesIds,
  shouldChargeMonthlyQuota,
} = require('../lib/postQuota');

const nov = Date.parse('2026-11-16T17:00:00-07:00');
const oct = Date.parse('2026-10-31T17:00:00-07:00');

describe('quotaKeyForEvent', () => {
  it('prefers seriesId and falls back to the event id', () => {
    assert.equal(quotaKeyForEvent({ id: 'evt-1', seriesId: 'series-a' }), 'series-a');
    assert.equal(quotaKeyForEvent({ id: 'evt-1', seriesId: '  ' }), 'evt-1');
    assert.equal(quotaKeyForEvent({ id: 'evt-1' }), 'evt-1');
    assert.equal(quotaKeyForEvent({}, 'evt-2'), 'evt-2');
  });
});

describe('countQuotaPostsInCalendarMonth', () => {
  it('counts a weekly series as one post even with several instances this month', () => {
    const events = [
      { id: 'game-1', seriesId: 'game-night', createdAtMs: Date.parse('2026-11-05T18:00:00-07:00') },
      { id: 'game-2', seriesId: 'game-night', createdAtMs: Date.parse('2026-11-12T18:00:00-07:00') },
      { id: 'game-3', seriesId: 'game-night', createdAtMs: Date.parse('2026-11-19T18:00:00-07:00') },
      { id: 'one-off', createdAtMs: Date.parse('2026-11-08T18:00:00-07:00') },
      { id: 'last-month', seriesId: 'old', createdAtMs: oct },
    ];
    assert.equal(countQuotaPostsInCalendarMonth(events, nov), 2);
  });

  it('treats a missing seriesId as its own series', () => {
    const events = [
      { id: 'a', createdAtMs: Date.parse('2026-11-01T12:00:00-07:00') },
      { id: 'b', createdAtMs: Date.parse('2026-11-02T12:00:00-07:00') },
    ];
    assert.equal(countQuotaPostsInCalendarMonth(events, nov), 2);
  });
});

describe('seriesCountedThisMonth and resolveSeriesId', () => {
  it('detects an already-counted series and rejects a guessed seriesId', () => {
    const events = [
      { id: 'game-1', seriesId: 'game-night', createdAtMs: Date.parse('2026-11-05T18:00:00-07:00') },
    ];
    assert.equal(seriesCountedThisMonth(events, 'game-night', nov), true);
    assert.equal(seriesCountedThisMonth(events, 'other', nov), false);
    assert.equal(seriesCountedThisMonth(events, 'game-night', oct), false);

    const owned = collectOwnedSeriesIds([
      { id: 'game-1', data: { seriesId: 'game-night' } },
    ], ['new-evt']);
    assert.equal(resolveSeriesId({
      incomingSeriesId: 'game-night',
      eventId: 'new-evt',
      ownedSeriesIds: owned,
    }), 'game-night');
    assert.equal(resolveSeriesId({
      incomingSeriesId: 'not-mine',
      eventId: 'new-evt',
      ownedSeriesIds: owned,
    }), 'new-evt');
    assert.equal(resolveSeriesId({
      incomingSeriesId: '',
      eventId: 'new-evt',
      ownedSeriesIds: owned,
    }), 'new-evt');
  });
});

describe('shouldChargeMonthlyQuota', () => {
  it('charges only a new free-tier series in the current month', () => {
    assert.equal(shouldChargeMonthlyQuota({
      isCreate: true, pro: false, isAdmin: false, seriesAlreadyCounted: false,
    }), true);
    assert.equal(shouldChargeMonthlyQuota({
      isCreate: true, pro: false, isAdmin: false, seriesAlreadyCounted: true,
    }), false);
    assert.equal(shouldChargeMonthlyQuota({
      isCreate: false, pro: false, isAdmin: false, seriesAlreadyCounted: false,
    }), false);
    assert.equal(shouldChargeMonthlyQuota({
      isCreate: true, pro: true, isAdmin: false, seriesAlreadyCounted: false,
    }), false);
    assert.equal(shouldChargeMonthlyQuota({
      isCreate: true, pro: false, isAdmin: true, seriesAlreadyCounted: false,
    }), false);
  });
});
