'use strict';

const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const {
  counterFieldFor,
  isValidEventId,
  shouldSkipSelf,
  isRateLimited,
  RATE_WINDOW_MS,
} = require('../lib/eventAnalytics');

describe('eventAnalytics helpers', () => {
  it('maps known metrics and rejects unknown ones', () => {
    assert.equal(counterFieldFor('views'), 'analyticsViews');
    assert.equal(counterFieldFor('impressions'), 'analyticsSearchImpressions');
    assert.equal(counterFieldFor('saves'), 'analyticsSaves');
    assert.equal(counterFieldFor('clicks'), 'analyticsClicks');
    assert.equal(counterFieldFor('shares'), 'analyticsShares');
    assert.equal(counterFieldFor('likes'), null);
  });

  it('accepts only safe event ids', () => {
    assert.equal(isValidEventId('abc-123_X'), true);
    assert.equal(isValidEventId(''), false);
    assert.equal(isValidEventId('bad id'), false);
    assert.equal(isValidEventId('x'.repeat(129)), false);
  });

  it('skips the host\'s own views and impressions, but not clicks', () => {
    assert.equal(shouldSkipSelf('views', 'u1', 'u1'), true);
    assert.equal(shouldSkipSelf('impressions', 'u1', 'u1'), true);
    assert.equal(shouldSkipSelf('views', 'u1', 'u2'), false);
    assert.equal(shouldSkipSelf('clicks', 'u1', 'u1'), false);
  });

  it('rate-limits inside the window and allows the first bump', () => {
    const now = 1_000_000;
    assert.equal(isRateLimited(null, now, RATE_WINDOW_MS.views), false);
    assert.equal(isRateLimited(now - 1000, now, RATE_WINDOW_MS.views), true);
    assert.equal(isRateLimited(now - RATE_WINDOW_MS.views, now, RATE_WINDOW_MS.views), false);
    assert.equal(isRateLimited(now - 30 * 1000, now, RATE_WINDOW_MS.clicks), true);
    assert.equal(isRateLimited(now - 61 * 1000, now, RATE_WINDOW_MS.clicks), false);
  });
});
