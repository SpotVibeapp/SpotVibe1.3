'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const { validateSubmission, submissionToEvent } = require('../lib/webSubmission');

const now = Date.UTC(2026, 9, 28);
const good = {
  title: 'Sunday Market', location: 'Mesa Plaza', organizerName: 'UV Market',
  contactEmail: 'Org@Example.com', startMs: now + 86400000, consent: true,
};

test('valid submission passes and is normalized', () => {
  const r = validateSubmission(good, now);
  assert.equal(r.ok, true);
  assert.equal(r.value.contactEmail, 'org@example.com');
  assert.equal(r.value.city, 'El Paso');
});

test('honeypot marks spam', () => {
  assert.equal(validateSubmission({ ...good, website2: 'x' }, now).spam, true);
});

test('bad dates, email and consent are rejected', () => {
  const r = validateSubmission({ ...good, startMs: now - 86400000 * 2,
    contactEmail: 'nope', consent: false }, now);
  assert.deepEqual(r.errors.sort(), ['consent', 'contactEmail', 'startMs']);
  const e = validateSubmission({ ...good, endMs: good.startMs - 1 }, now);
  assert.deepEqual(e.errors, ['endMs']);
});

test('approved submission maps to feed keys', () => {
  const v = validateSubmission({ ...good, endMs: good.startMs + 3600000 }, now).value;
  const ev = submissionToEvent(v, { reviewerUid: 'admin1', nowMs: now });
  assert.equal(ev.visibleUntilMs, v.endMs);
  assert.equal(ev.dateTimeMs, v.startMs);
  assert.equal(ev.kind, 'web_submission');
  assert.equal(ev.claimStatus, 'unclaimed');
});
