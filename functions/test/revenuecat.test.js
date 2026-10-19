'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const { entitlementStatus, fetchSubscriber } = require('../lib/revenuecat');

const NOW = Date.parse('2026-10-19T10:00:00Z');
const future = '2026-11-19T10:00:00Z';
const past = '2026-09-19T10:00:00Z';

test('no subscriber or no entitlement means no access', () => {
  assert.deepEqual(entitlementStatus(null, NOW), { pro: false, founding: false, productId: null });
  assert.equal(entitlementStatus({ entitlements: {} }, NOW).pro, false);
});

test('an expired entitlement grants nothing', () => {
  const s = { entitlements: { pro: { expires_date: past, product_identifier: 'spotvibe_premium_founding_monthly' } } };
  assert.deepEqual(entitlementStatus(s, NOW), { pro: false, founding: false, productId: null });
});

test('grace period keeps access', () => {
  const s = { entitlements: { pro: { expires_date: past, grace_period_expires_date: future, product_identifier: 'spotvibe_premium_monthly' } } };
  assert.equal(entitlementStatus(s, NOW).pro, true);
});

test('active standard premium is pro but not founding', () => {
  const s = { entitlements: { pro: { expires_date: future, product_identifier: 'spotvibe_premium_monthly' } } };
  assert.deepEqual(entitlementStatus(s, NOW), { pro: true, founding: false, productId: 'spotvibe_premium_monthly' });
});

test('active founding product is founding (Play base-plan ids included)', () => {
  const s = { entitlements: { pro: { expires_date: future, product_identifier: 'spotvibe_premium_founding_monthly:monthly' } } };
  assert.equal(entitlementStatus(s, NOW).founding, true);
});

test('an active founding subscription counts even if the entitlement points elsewhere', () => {
  const s = {
    entitlements: { pro: { expires_date: future, product_identifier: 'spotvibe_premium_monthly' } },
    subscriptions: { spotvibe_premium_founding_monthly: { expires_date: future } },
  };
  assert.equal(entitlementStatus(s, NOW).founding, true);
  s.subscriptions.spotvibe_premium_founding_monthly.refunded_at = past;
  assert.equal(entitlementStatus(s, NOW).founding, false);
});

test('fetchSubscriber fails closed on HTTP errors and missing key', async () => {
  await assert.rejects(fetchSubscriber('u', ''), /not configured/);
  const fake = async () => ({ ok: false, status: 401 });
  await assert.rejects(fetchSubscriber('u', 'sk_test', fake), /401/);
  const ok = async (url, init) => {
    assert.match(url, /\/v1\/subscribers\/u%2F1$/);
    assert.equal(init.headers.Authorization, 'Bearer sk_test');
    return { ok: true, json: async () => ({ subscriber: { entitlements: {} } }) };
  };
  assert.deepEqual(await fetchSubscriber('u/1', 'sk_test', ok), { entitlements: {} });
});
