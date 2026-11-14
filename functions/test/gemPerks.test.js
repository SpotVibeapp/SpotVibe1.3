'use strict';

const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const {
  RICH_DURATION_MS,
  applyEntitlementToGem,
  downgradeGemData,
  isRich,
  looksLikeBusinessPromo,
  shouldRemindRichExpiry,
} = require('../lib/gemPerks');

describe('applyEntitlementToGem', () => {
  const now = Date.UTC(2026, 10, 14, 20);
  const rich = {
    name: 'Cafe Luz',
    listingKind: 'business',
    description: 'Full menu and patio',
    imageUrls: ['https://x.test/a.jpg'],
    contactPhone: '+1 555 0100',
    promoTitle: 'Happy hour',
    promoDetails: '2-for-1 tacos',
  };

  it('rejects a business listing from a free user', () => {
    const result = applyEntitlementToGem(rich, { pro: false, activateRich: true, nowMs: now });
    assert.equal(result.ok, false);
    assert.equal(result.reason, 'premium-required');
  });

  it('starts a 30-day rich window for Premium and ignores client richUntil', () => {
    const result = applyEntitlementToGem(
      { ...rich, richUntilMs: now + 99 },
      { pro: true, activateRich: true, nowMs: now },
    );
    assert.equal(result.ok, true);
    assert.equal(result.gem.listingKind, 'business');
    assert.equal(result.gem.richUntilMs, now + RICH_DURATION_MS);
    assert.equal(result.gem.promoTitle, 'Happy hour');
  });

  it('rejects a business-shaped listing from a free user even without activateRich', () => {
    const result = applyEntitlementToGem(rich, { pro: false, activateRich: false, nowMs: now });
    assert.equal(result.ok, false);
    assert.equal(result.reason, 'premium-required');
  });

  it('strips promo, contact and photos from a free community post', () => {
    const result = applyEntitlementToGem(
      { ...rich, listingKind: 'community' },
      { pro: false, activateRich: false, nowMs: now },
    );
    assert.equal(result.ok, true);
    assert.equal(result.gem.listingKind, 'community');
    assert.equal(result.gem.description, '');
    assert.deepEqual(result.gem.imageUrls, []);
    assert.equal(result.gem.contactPhone, null);
    assert.equal(result.gem.promoTitle, null);
    assert.equal(result.gem.richUntilMs, null);
  });

  it('keeps the existing expiry when a Premium owner edits a live listing', () => {
    const existing = { richUntilMs: now + 5 * 24 * 60 * 60 * 1000, listingKind: 'business' };
    const result = applyEntitlementToGem(
      { ...rich, listingKind: 'business' },
      { pro: true, activateRich: false, existing, nowMs: now },
    );
    assert.equal(result.gem.richUntilMs, existing.richUntilMs);
  });
});

describe('downgrade and promo detection', () => {
  const now = Date.UTC(2026, 10, 14, 20);
  it('hides public rich fields but archives them, without requiring media deletion', () => {
    const { patch, changed } = downgradeGemData({
      name: 'Cafe Luz',
      listingKind: 'business',
      description: 'Patio',
      imageUrls: ['https://x.test/a.jpg'],
      promoTitle: 'Happy hour',
      richUntilMs: now + 1000,
    }, now);
    assert.equal(changed, true);
    assert.equal(patch.listingKind, 'community');
    assert.deepEqual(patch.imageUrls, []);
    assert.equal(patch.promoTitle, null);
    assert.equal(patch.archivedRich.promoTitle, 'Happy hour');
    assert.deepEqual(patch.archivedRich.imageUrls, ['https://x.test/a.jpg']);
  });

  it('flags promotional language and contact details on a basic post', () => {
    assert.equal(looksLikeBusinessPromo({ summary: 'Quiet trail at sunrise' }).flagged, false);
    assert.equal(looksLikeBusinessPromo({ summary: 'Happy hour 5-7, 20% off tacos' }).flagged, true);
    assert.equal(looksLikeBusinessPromo({ contactPhone: '+1 555 0100' }).flagged, true);
    assert.equal(looksLikeBusinessPromo({ summary: 'Visit https://cantina.test' }).flagged, true);
  });

  it('reminds a few days before richUntil and not after it lapses', () => {
    assert.equal(isRich({ richUntilMs: now + 1000 }, now), true);
    assert.equal(shouldRemindRichExpiry({ richUntilMs: now + 2 * 24 * 60 * 60 * 1000 }, now), true);
    assert.equal(shouldRemindRichExpiry({ richUntilMs: now + 20 * 24 * 60 * 60 * 1000 }, now), false);
    assert.equal(shouldRemindRichExpiry({ richUntilMs: now - 1000 }, now), false);
  });
});
