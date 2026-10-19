'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const { claimFoundingSlotIn, isoWeekKey } = require('../lib/featuring');

test('isoWeekKey matches the Dart helper', () => {
  // Values printed by lib/data/pricing.dart isoWeekKey (its numbering is
  // one lower than strict ISO-8601; what matters is that both sides agree).
  assert.equal(isoWeekKey(new Date(Date.UTC(2026, 7, 13))), '2026-W32'); // Thu Aug 13
  assert.equal(isoWeekKey(new Date(Date.UTC(2026, 7, 10))), '2026-W32'); // Mon
  assert.equal(isoWeekKey(new Date(Date.UTC(2026, 7, 16))), '2026-W32'); // Sun
  assert.equal(isoWeekKey(new Date(Date.UTC(2026, 7, 17))), '2026-W33'); // Mon
  assert.equal(isoWeekKey(new Date(Date.UTC(2027, 0, 1))), '2026-W52');
  assert.equal(isoWeekKey(new Date(Date.UTC(2026, 0, 1))), '2026-W00');
});

test('a founding slot is claimed once and only while slots remain', () => {
  const first = claimFoundingSlotIn({ memberIds: ['a'], count: 1 }, 'b', 3);
  assert.deepEqual(first, { changed: true, memberIds: ['a', 'b'], count: 2, userIsMember: true });
  const again = claimFoundingSlotIn({ memberIds: ['a', 'b'] }, 'b', 3);
  assert.equal(again.changed, false);
  assert.equal(again.userIsMember, true);
  const full = claimFoundingSlotIn({ memberIds: ['a', 'b', 'c'] }, 'd', 3);
  assert.deepEqual(full, { changed: false, memberIds: ['a', 'b', 'c'], count: 3, userIsMember: false });
  assert.equal(claimFoundingSlotIn(undefined, 'z').count, 1);
});
