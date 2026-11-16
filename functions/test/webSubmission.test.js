'use strict';
const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const {
  validateSubmission,
  submissionToEvent,
  privateContactDoc,
} = require('../lib/webSubmission');

const now = Date.UTC(2026, 10, 16);
const good = {
  title: 'Sunday Market', location: 'Mesa Plaza', organizerName: 'UV Market',
  contactEmail: 'Org@Example.com', startMs: now + 86400000, consent: true,
};

describe('validateSubmission', () => {
  it('valid submission passes and is normalized', () => {
    const r = validateSubmission(good, now);
    assert.equal(r.ok, true);
    assert.equal(r.value.contactEmail, 'org@example.com');
    assert.equal(r.value.city, 'El Paso');
  });

  it('honeypot marks spam', () => {
    assert.equal(validateSubmission({ ...good, website2: 'x' }, now).spam, true);
  });

  it('bad dates, email and consent are rejected', () => {
    const r = validateSubmission({ ...good, startMs: now - 86400000 * 2,
      contactEmail: 'nope', consent: false }, now);
    assert.deepEqual(r.errors.sort(), ['consent', 'contactEmail', 'startMs']);
    const e = validateSubmission({ ...good, endMs: good.startMs - 1 }, now);
    assert.deepEqual(e.errors, ['endMs']);
  });
});

describe('submissionToEvent', () => {
  it('approved submission maps to feed keys and keeps contact email off the public doc', () => {
    const v = validateSubmission({
      ...good,
      endMs: good.startMs + 3600000,
      contactName: 'Alex',
    }, now).value;
    const ev = submissionToEvent(v, { reviewerUid: 'admin1', nowMs: now, eventId: 'evt-1' });
    assert.equal(ev.visibleUntilMs, v.endMs);
    assert.equal(ev.dateTimeMs, v.startMs);
    assert.equal(ev.kind, 'web_submission');
    assert.equal(ev.claimStatus, 'unclaimed');
    assert.equal(ev.creatorId, '');
    assert.equal('submittedByEmail' in ev, false);
    assert.equal('contactEmail' in ev, false);
    const priv = privateContactDoc(v, now);
    assert.equal(priv.contactEmail, 'org@example.com');
    assert.equal(priv.contactName, 'Alex');
  });
});
