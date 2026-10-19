#!/usr/bin/env node
/**
 * ONE-OFF MIGRATION — moves `email` / `phone` / `phoneNumber` off every
 * public `users/{uid}` doc into the owner-only `users/{uid}/private/profile`
 * doc. NOT run automatically and NOT deployed. Blake runs it once, after the
 * functions deploy and BEFORE (or right after) the rules deploy.
 *
 * Safe to re-run: it never overwrites a non-blank private value and skips
 * docs that are already clean. Dry run by default.
 *
 *   cd functions && npm install
 *   gcloud auth application-default login         # an account with Firestore access
 *   GOOGLE_CLOUD_PROJECT=spotvibe-cfa08 node scripts/migrate_user_private_fields.js          # dry run
 *   GOOGLE_CLOUD_PROJECT=spotvibe-cfa08 node scripts/migrate_user_private_fields.js --apply  # write
 */
'use strict';

const admin = require('firebase-admin');
const { planPublicPiiScrub } = require('../lib/userPrivacy');

async function main() {
  const apply = process.argv.includes('--apply');
  admin.initializeApp();
  const db = admin.firestore();

  let scanned = 0;
  let needing = 0;
  let migrated = 0;
  let last = null;
  const pageSize = 300;

  for (;;) {
    let query = db
      .collection('users')
      .orderBy(admin.firestore.FieldPath.documentId())
      .limit(pageSize);
    if (last) query = query.startAfter(last);
    const page = await query.get();
    if (page.empty) break;

    for (const doc of page.docs) {
      scanned++;
      if (planPublicPiiScrub(doc.data(), undefined).removeFromPublic.length === 0) {
        continue;
      }
      needing++;
      if (!apply) continue;
      const privateRef = doc.ref.collection('private').doc('profile');
      await db.runTransaction(async (tx) => {
        const [pub, priv] = await Promise.all([tx.get(doc.ref), tx.get(privateRef)]);
        if (!pub.exists) return;
        const plan = planPublicPiiScrub(pub.data(), priv.data());
        if (plan.removeFromPublic.length === 0) return;
        if (Object.keys(plan.privateFields).length > 0) {
          tx.set(
            privateRef,
            {
              ...plan.privateFields,
              migratedAt: admin.firestore.FieldValue.serverTimestamp(),
            },
            { merge: true }
          );
        }
        const removal = {};
        for (const field of plan.removeFromPublic) {
          removal[field] = admin.firestore.FieldValue.delete();
        }
        tx.update(pub.ref, removal);
      });
      migrated++;
    }
    last = page.docs[page.docs.length - 1];
  }

  console.log(
    `${apply ? 'APPLIED' : 'DRY RUN'}: scanned ${scanned} users, ` +
      `${needing} had contact fields on the public doc` +
      (apply ? `, migrated ${migrated}.` : '. Re-run with --apply to migrate.')
  );
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
