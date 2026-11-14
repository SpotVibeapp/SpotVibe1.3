'use strict';

const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const { isHost, dmThreadId, rateOk, DM_RATE_LIMIT, DM_RATE_WINDOW_MS } = require('../lib/eventMessaging');

describe('event messaging helpers', () => {
  it('identifies the host and builds a stable DM thread id', () => {
    assert.equal(isHost({ creatorId: 'h1' }, 'h1'), true);
    assert.equal(isHost({ creatorId: 'h1' }, 'a1'), false);
    assert.equal(dmThreadId('e1', 'h1', 'a1'), 'e1_h1_a1');
  });

  it('rate-limits DMs to 10 per rolling hour', () => {
    const now = 1_000_000;
    const full = Array.from({ length: 10 }, (_, i) => now - i * 1000);
    assert.equal(rateOk(full, DM_RATE_LIMIT, DM_RATE_WINDOW_MS, now).ok, false);
    assert.equal(rateOk(full.slice(1), DM_RATE_LIMIT, DM_RATE_WINDOW_MS, now).ok, true);
    assert.equal(rateOk([now - DM_RATE_WINDOW_MS - 1], DM_RATE_LIMIT, DM_RATE_WINDOW_MS, now).ok, true);
  });
});
