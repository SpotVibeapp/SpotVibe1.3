'use strict';

/**
 * One-off backfill: write geoCells, searchTokens, hasOffer, listingTier and
 * visibleToFreeAtMs on existing gems/{id} docs.
 *
 *   cd functions && node scripts/backfill_gem_geo.js
 *
 * Safe to re-run. Does not change listing content. Casual gems get
 * visibleToFreeAtMs = approvedAtMs so they stay visible immediately.
 */
const admin = require('firebase-admin');
const { derivedSearchFields, visibleToFreeAtForGem } = require('../lib/gemSearch');

if (!admin.apps.length) {
  admin.initializeApp();
}

async function main() {
  const db = admin.firestore();
  const snap = await db.collection('gems').get();
  let updated = 0;
  for (const doc of snap.docs) {
    const data = doc.data() || {};
    const createdAtMs = typeof data.createdAtMs === 'number'
      ? data.createdAtMs
      : Date.now();
    const approvedAtMs = typeof data.approvedAtMs === 'number' ? data.approvedAtMs : createdAtMs;
    const derived = derivedSearchFields(data);
    const visible = visibleToFreeAtForGem(data, approvedAtMs, 48);
    await doc.ref.set(
      {
        approvedAtMs,
        visibleToFreeAtMs: visible,
        geoCells: derived.geoCells,
        searchTokens: derived.searchTokens,
        hasOffer: derived.hasOffer,
        listingTier: derived.listingTier,
        promoUntilMs: derived.promoUntilMs,
      },
      { merge: true }
    );
    updated += 1;
  }
  console.log(`backfill_gem_geo: updated ${updated} gem(s)`);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
