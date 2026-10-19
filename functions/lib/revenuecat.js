/**
 * Server-side RevenueCat entitlement checks.
 *
 * The app logs RevenueCat in with the Firebase uid (`Purchases.logIn(uid)`),
 * so the uid is the RevenueCat app_user_id. The secret key (sk_...) lives in
 * Cloud Secret Manager as REVENUECAT_SECRET_API_KEY and never ships in the
 * app:
 *   firebase functions:secrets:set REVENUECAT_SECRET_API_KEY
 *
 * REST reference: GET https://api.revenuecat.com/v1/subscribers/{app_user_id}
 */
'use strict';

/** Entitlement identifier configured in the RevenueCat dashboard. */
const PRO_ENTITLEMENT_ID = 'pro';

/** Mirrors lib/data/pricing.dart `isFoundingStoreProduct`. */
const FOUNDING_PRODUCT_ID = 'spotvibe_premium_founding_monthly';
const FOUNDING_PRODUCT_HINT = 'founding';

function isFoundingProduct(productId) {
  if (typeof productId !== 'string' || !productId) return false;
  const id = productId.toLowerCase();
  return id === FOUNDING_PRODUCT_ID || id.includes(FOUNDING_PRODUCT_HINT);
}

function isUnexpired(expiresDate, graceDate, nowMs) {
  // `expires_date: null` = lifetime / non-expiring.
  if (expiresDate == null) return true;
  const expires = Date.parse(expiresDate);
  if (Number.isFinite(expires) && expires > nowMs) return true;
  if (graceDate) {
    const grace = Date.parse(graceDate);
    if (Number.isFinite(grace) && grace > nowMs) return true;
  }
  return false;
}

/**
 * Reads a RevenueCat `subscriber` object (the `subscriber` field of the REST
 * response) and reports what the user is entitled to right now.
 * Pure — unit-tested in test/revenuecat.test.js.
 *
 * @returns {{pro: boolean, founding: boolean, productId: string|null}}
 */
function entitlementStatus(subscriber, nowMs = Date.now()) {
  const result = { pro: false, founding: false, productId: null };
  if (!subscriber || typeof subscriber !== 'object') return result;

  const ent = subscriber.entitlements && subscriber.entitlements[PRO_ENTITLEMENT_ID];
  if (ent && isUnexpired(ent.expires_date, ent.grace_period_expires_date, nowMs)) {
    result.pro = true;
    result.productId = ent.product_identifier || null;
  }
  if (!result.pro) return result;

  if (isFoundingProduct(result.productId)) {
    result.founding = true;
    return result;
  }
  // The entitlement may point at a different product than the founding one
  // (e.g. after a cross-grade); accept any active founding subscription.
  const subs = subscriber.subscriptions || {};
  for (const [productId, sub] of Object.entries(subs)) {
    if (!isFoundingProduct(productId) || !sub) continue;
    if (sub.refunded_at) continue;
    if (isUnexpired(sub.expires_date, sub.grace_period_expires_date, nowMs)) {
      result.founding = true;
      break;
    }
  }
  return result;
}

/**
 * Fetches the subscriber from RevenueCat. Throws on transport/HTTP errors so
 * callers fail closed (no entitlement is ever granted on an error).
 */
async function fetchSubscriber(appUserId, secretKey, fetchImpl = fetch) {
  if (!secretKey) throw new Error('RevenueCat secret key is not configured.');
  const url = `https://api.revenuecat.com/v1/subscribers/${encodeURIComponent(appUserId)}`;
  const response = await fetchImpl(url, {
    headers: {
      Authorization: `Bearer ${secretKey}`,
      Accept: 'application/json',
    },
  });
  if (!response.ok) {
    throw new Error(`RevenueCat responded ${response.status}`);
  }
  const body = await response.json();
  return body && body.subscriber;
}

module.exports = {
  PRO_ENTITLEMENT_ID,
  entitlementStatus,
  fetchSubscriber,
  isFoundingProduct,
};
