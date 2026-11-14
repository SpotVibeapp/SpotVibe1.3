'use strict';

const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const {
  searchTokensFor,
  derivedSearchFields,
  isBusinessPromoGem,
  visibleToFreeAtForGem,
} = require('../lib/gemSearch');

describe('gem search index', () => {
  it('indexes name, place, category, business type and offer text', () => {
    const tokens = searchTokensFor({
      name: 'Cafe Luz',
      summary: 'Patio tacos',
      address: 'El Paso, TX',
      city: 'El Paso',
      category: 'foodDrink',
      businessType: 'restaurant',
      offerTitle: 'Happy hour',
      offerText: '2-for-1 tacos 5-7',
    });
    for (const word of ['cafe', 'luz', 'el', 'paso', 'fooddrink', 'restaurant', 'happy', 'hour', 'tacos']) {
      assert.ok(tokens.includes(word), `missing ${word}`);
    }
  });

  it('writes geoCells and offer flags, and treats only business listings as promo', () => {
    const richUntilMs = Date.now() + 30 * 24 * 60 * 60 * 1000;
    const fields = derivedSearchFields({
      name: 'Cafe Luz',
      latitude: 31.7619,
      longitude: -106.485,
      listingKind: 'business',
      offerTitle: 'Happy hour',
      richUntilMs,
    });
    assert.ok(fields.geoCells.length >= 3);
    assert.equal(fields.hasOffer, true);
    assert.equal(fields.listingTier, 'promoted');
    assert.equal(fields.promoUntilMs, richUntilMs);
    assert.equal(isBusinessPromoGem({ listingKind: 'community' }), false);
    assert.equal(isBusinessPromoGem({ listingKind: 'business' }), true);
  });

  it('delays free visibility only for business promo gems', () => {
    const approved = Date.UTC(2026, 10, 14, 20);
    assert.equal(visibleToFreeAtForGem({ listingKind: 'community' }, approved, 48), approved);
    assert.equal(
      visibleToFreeAtForGem({ listingKind: 'business' }, approved, 48),
      approved + 48 * 60 * 60 * 1000,
    );
  });
});
