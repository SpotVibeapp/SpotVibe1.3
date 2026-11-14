'use strict';

const { geoCellsFor, hasCoordinates } = require('./geo');

/**
 * Search / geo helpers for Hidden Gems. searchTokens are written on the
 * document so the app can keyword-filter after a geoCells query — Firestore
 * cannot combine two array-contains clauses in one query.
 */
function tokenize(...parts) {
  const tokens = new Set();
  for (const part of parts) {
    const text = String(part || '')
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, ' ')
      .trim();
    if (!text) continue;
    for (const word of text.split(' ')) {
      if (word.length >= 2) tokens.add(word);
    }
  }
  return [...tokens].slice(0, 80);
}

function searchTokensFor(data) {
  const src = data && typeof data === 'object' ? data : {};
  return tokenize(
    src.name,
    src.summary,
    src.address,
    src.city,
    src.category,
    src.businessType,
    src.offerTitle || src.promoTitle,
    src.offerText || src.promoDetails
  );
}

function derivedSearchFields(data) {
  const src = data && typeof data === 'object' ? data : {};
  const lat = typeof src.latitude === 'number' ? src.latitude : Number(src.latitude);
  const lng = typeof src.longitude === 'number' ? src.longitude : Number(src.longitude);
  const offerTitle = src.offerTitle || src.promoTitle || null;
  const offerText = src.offerText || src.promoDetails || null;
  const offerUntilMs = typeof src.offerUntilMs === 'number'
    ? src.offerUntilMs
    : (typeof src.promoEndsAtMs === 'number' ? src.promoEndsAtMs : null);
  const hasOffer = !!(offerTitle || offerText);
  const stillRich = typeof src.richUntilMs === 'number' && src.richUntilMs > Date.now();
  const listingTier = (src.listingKind === 'business' || src.listingTier === 'promoted') && stillRich
    ? 'promoted'
    : 'basic';
  return {
    geoCells: hasCoordinates(lat, lng) ? geoCellsFor(lat, lng) : [],
    searchTokens: searchTokensFor(src),
    offerTitle,
    offerText,
    offerUntilMs,
    hasOffer,
    listingTier,
    promoUntilMs: typeof src.richUntilMs === 'number' ? src.richUntilMs : (src.promoUntilMs || null),
  };
}

function isBusinessPromoGem(data) {
  const src = data && typeof data === 'object' ? data : {};
  return src.listingKind === 'business' || src.listingTier === 'promoted';
}

/**
 * Early access is only for new business promo listings. Casual "share a
 * spot" gems become visible to everyone immediately.
 */
function visibleToFreeAtForGem(data, approvedAtMs, delayHours) {
  if (!isBusinessPromoGem(data)) return approvedAtMs;
  const delay = Number.isFinite(delayHours) ? delayHours : 48;
  return approvedAtMs + delay * 60 * 60 * 1000;
}

module.exports = {
  tokenize,
  searchTokensFor,
  derivedSearchFields,
  isBusinessPromoGem,
  visibleToFreeAtForGem,
};
