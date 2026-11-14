'use strict';

const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const {
  calendarMonthKey,
  canPostThisMonth,
  normalizeFlags,
  visibleToFreeAtMs,
  gemVisibleToViewer,
  shouldGateBasicRsvp,
  shouldGateTicketLink,
  DEFAULT_FLAGS,
} = require('../lib/featureFlags');

describe('feature flags and caps', () => {
  it('defaults keep the RSVP/tickets gate on, 48h gem delay, and 4 posts/month', () => {
    const flags = normalizeFlags({});
    assert.equal(flags.gate_rsvp_tickets_premium, true);
    assert.equal(flags.gem_early_access_hours, 48);
    assert.equal(flags.free_event_posts_per_month, 4);
    assert.equal(flags.free_event_description_max, 300);
    assert.equal(flags.gate_basic_rsvp_premium, null);
    assert.equal(DEFAULT_FLAGS.gate_rsvp_tickets_premium, true);
    assert.equal(DEFAULT_FLAGS.free_event_description_max, 300);
  });

  it('keeps basic RSVP free unless the split flag is on; tickets follow the master gate', () => {
    const defaults = normalizeFlags({});
    assert.equal(shouldGateBasicRsvp(defaults, { pro: false }), false);
    assert.equal(shouldGateTicketLink(defaults, { pro: false }), true);
    assert.equal(shouldGateTicketLink(defaults, { pro: true }), false);
    const basicPaid = normalizeFlags({ gate_basic_rsvp_premium: true });
    assert.equal(shouldGateBasicRsvp(basicPaid, { pro: false }), true);
    assert.equal(shouldGateBasicRsvp(basicPaid, { pro: true }), false);
    const ticketsOff = normalizeFlags({
      gate_rsvp_tickets_premium: true,
      gate_ticket_link_premium: false,
    });
    assert.equal(shouldGateTicketLink(ticketsOff, { pro: false }), false);
  });

  it('clamps the free description cap between 80 and 400', () => {
    assert.equal(normalizeFlags({ free_event_description_max: 20 }).free_event_description_max, 80);
    assert.equal(normalizeFlags({ free_event_description_max: 900 }).free_event_description_max, 400);
    assert.equal(normalizeFlags({ free_event_description_max: 300 }).free_event_description_max, 300);
  });

  it('honors an off switch and custom caps', () => {
    const flags = normalizeFlags({
      gate_rsvp_tickets_premium: false,
      gem_early_access_hours: 12,
      free_event_posts_per_month: 10,
    });
    assert.equal(flags.gate_rsvp_tickets_premium, false);
    assert.equal(flags.gem_early_access_hours, 12);
    assert.equal(flags.free_event_posts_per_month, 10);
  });

  it('enforces the monthly cap only for free organizers', () => {
    assert.equal(canPostThisMonth({ pro: false, postedThisMonth: 3, cap: 4 }).ok, true);
    assert.equal(canPostThisMonth({ pro: false, postedThisMonth: 4, cap: 4 }).reason, 'monthly-cap');
    assert.equal(canPostThisMonth({ pro: true, postedThisMonth: 40, cap: 4 }).ok, true);
    assert.equal(canPostThisMonth({ isAdmin: true, postedThisMonth: 40, cap: 4 }).ok, true);
  });

  it('builds a Denver calendar month key', () => {
    // 15 Nov 2026 08:00 UTC is 1:00 AM MST on Nov 15.
    assert.equal(calendarMonthKey(Date.UTC(2026, 10, 15, 8)), '2026-11');
  });

  it('hides new business promo gems from free viewers until the delay elapses', () => {
    const createdAtMs = Date.UTC(2026, 10, 14, 20);
    const nowMs = createdAtMs + 24 * 60 * 60 * 1000;
    const promo = { createdAtMs, hidden: false, creatorId: 'a', listingKind: 'business' };
    assert.equal(gemVisibleToViewer(promo, { isPremium: false, viewerId: 'b', nowMs, delayHours: 48 }), false);
    assert.equal(gemVisibleToViewer(promo, { isPremium: true, viewerId: 'b', nowMs, delayHours: 48 }), true);
    assert.equal(gemVisibleToViewer(promo, { isPremium: false, viewerId: 'a', nowMs, delayHours: 48 }), true);
    assert.equal(visibleToFreeAtMs(createdAtMs, 48), createdAtMs + 48 * 60 * 60 * 1000);
    assert.equal(gemVisibleToViewer(
      promo,
      { isPremium: false, viewerId: 'b', nowMs: createdAtMs + 48 * 60 * 60 * 1000, delayHours: 48 },
    ), true);
  });

  it('shows casual share-a-spot gems to everyone immediately', () => {
    const createdAtMs = Date.UTC(2026, 10, 14, 20);
    const nowMs = createdAtMs + 60 * 60 * 1000;
    assert.equal(gemVisibleToViewer(
      { createdAtMs, hidden: false, creatorId: 'a', listingKind: 'community' },
      { isPremium: false, viewerId: 'b', nowMs, delayHours: 48 },
    ), true);
  });
});
