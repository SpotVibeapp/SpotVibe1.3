#!/usr/bin/env node
/**
 * ONE-OFF BACKFILL — writes `visibleUntilMs` and `geoCells` (the new feed
 * query keys) onto every existing `events/{id}` doc. NOT run automatically
 * and NOT deployed. Without it, events created before the release are
 * invisible to the new feed query (`visibleUntilMs >= now`).
 *
 * Run after the functions deploy (normalizeEventFeedFields then keeps new
 * writes correct) and before the new app build reaches users.
 * Safe to re-run; only docs whose values differ are written. Dry run by default.
 *
 *   cd functions && npm install
 *   gcloud auth application-default login
 *   GOOGLE_CLOUD_PROJECT=spotvibe-cfa08 node scripts/backfill_event_feed_fields.js          # dry run
 *   GOOGLE_CLOUD_PROJECT=spotvibe-cfa08 node scripts/backfill_event_feed_fields.js --apply  # write
 */
'use strict';

const admin = require('firebase-admin');
const { planFeedFields } = require('../lib/feedFields');

async function main() {
  const apply = process.argv.includes('--apply');
  admin.initializeApp();
  const db = admin.firestore();

  let scanned = 0;
  let needing = 0;
  let last = null;
  const pageSize = 400;

  for (;;) {
    let query = db
      .collection('events')
      .orderBy(admin.firestore.FieldPath.documentId())
      .limit(pageSize);
    if (last) query = query.startAfter(last);
    const page = await query.get();
    if (page.empty) break;

    const batch = db.batch();
    let writes = 0;
    for (const doc of page.docs) {
      scanned++;
      const patch = planFeedFields(doc.data());
      if (!patch) continue;
      needing++;
      if (apply) {
        batch.update(doc.ref, patch);
        writes++;
      }
    }
    if (writes > 0) await batch.commit();
    last = page.docs[page.docs.length - 1];
  }

  console.log(
    `${apply ? 'APPLIED' : 'DRY RUN'}: scanned ${scanned} events, ${needing} needed feed fields` +
      (apply ? ' (written).' : '. Re-run with --apply to write.')
  );
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
