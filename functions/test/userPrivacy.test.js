'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const { planPublicPiiScrub } = require('../lib/userPrivacy');

test('no public doc means nothing to do', () => {
  assert.deepEqual(planPublicPiiScrub(undefined, undefined), {
    privateFields: {},
    removeFromPublic: [],
  });
});

test('legacy email and phone are copied privately and removed publicly', () => {
  const plan = planPublicPiiScrub(
    { name: 'Ana', email: ' ana@example.com ', phone: '+19155550100' },
    undefined
  );
  assert.deepEqual(plan.privateFields, {
    email: 'ana@example.com',
    phone: '+19155550100',
  });
  assert.deepEqual(plan.removeFromPublic, ['email', 'phone']);
});

test('an existing private value is never overwritten', () => {
  const plan = planPublicPiiScrub(
    { email: 'old@example.com' },
    { email: 'new@example.com' }
  );
  assert.deepEqual(plan.privateFields, {});
  assert.deepEqual(plan.removeFromPublic, ['email']);
});

test('blank legacy keys are removed without a private write', () => {
  const plan = planPublicPiiScrub({ name: 'Ana', email: '' }, undefined);
  assert.deepEqual(plan.privateFields, {});
  assert.deepEqual(plan.removeFromPublic, ['email']);
});

test('a clean public doc needs nothing', () => {
  const plan = planPublicPiiScrub({ name: 'Ana', avatarUrl: 'x' }, {});
  assert.deepEqual(plan, { privateFields: {}, removeFromPublic: [] });
});
