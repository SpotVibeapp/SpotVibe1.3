'use strict';

const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const { dmSendDecision, dmRecipient, isDmParticipant } = require('../lib/eventMessaging');

const base = { attendeeId: 'a1', attendeeRsvpd: true };

describe('dmSendDecision', () => {
  it('lets an RSVP\'d attendee start a conversation with the host for free', () => {
    const d = dmSendDecision({ ...base, senderIsAttendee: true });
    assert.equal(d.ok, true);
    assert.equal(d.starts, true);
  });

  it('requires an RSVP to start a conversation', () => {
    const d = dmSendDecision({ ...base, senderIsAttendee: true, attendeeRsvpd: false });
    assert.equal(d.ok, false);
    assert.equal(d.reason, 'rsvp-required');
    const h = dmSendDecision({ ...base, senderIsHost: true, senderIsPro: true, attendeeRsvpd: false });
    assert.equal(h.reason, 'rsvp-required');
  });

  it('keeps an existing conversation open after the RSVP is removed', () => {
    const d = dmSendDecision({ ...base, senderIsAttendee: true, attendeeRsvpd: false, threadExists: true, startedBy: 'a1' });
    assert.equal(d.ok, true);
    assert.equal(d.starts, false);
  });

  it('requires Premium for a host to start a conversation', () => {
    const free = dmSendDecision({ ...base, senderIsHost: true });
    assert.equal(free.ok, false);
    assert.equal(free.reason, 'premium-required');
    assert.equal(dmSendDecision({ ...base, senderIsHost: true, senderIsPro: true }).ok, true);
  });

  it('lets a free host reply inside an existing conversation', () => {
    const d = dmSendDecision({ ...base, senderIsHost: true, threadExists: true, startedBy: 'a1' });
    assert.equal(d.ok, true);
  });

  it('honors attendee opt-out for host-started messages only', () => {
    const cold = dmSendDecision({ ...base, senderIsHost: true, senderIsPro: true, attendeeOptedOut: true });
    assert.equal(cold.reason, 'opted-out');
    const hostThread = dmSendDecision({
      ...base, senderIsHost: true, threadExists: true, startedBy: 'h1', attendeeOptedOut: true,
    });
    assert.equal(hostThread.reason, 'opted-out');
    const reply = dmSendDecision({
      ...base, senderIsHost: true, threadExists: true, startedBy: 'a1', attendeeOptedOut: true,
    });
    assert.equal(reply.ok, true);
  });

  it('blocks in either direction stop every send', () => {
    assert.equal(dmSendDecision({ ...base, senderIsAttendee: true, blocked: true }).reason, 'blocked');
    assert.equal(
      dmSendDecision({ ...base, senderIsHost: true, threadExists: true, blocked: true }).reason,
      'blocked',
    );
  });

  it('rejects anyone who is neither the host nor that attendee', () => {
    assert.equal(dmSendDecision({ ...base }).reason, 'not-participant');
  });
});

describe('conversation helpers', () => {
  it('finds the recipient on either side', () => {
    assert.equal(dmRecipient('h1', 'h1', 'a1'), 'a1');
    assert.equal(dmRecipient('a1', 'h1', 'a1'), 'h1');
  });

  it('recognizes participants by array or legacy fields', () => {
    assert.equal(isDmParticipant({ participants: ['h1', 'a1'] }, 'a1'), true);
    assert.equal(isDmParticipant({ hostId: 'h1', attendeeId: 'a1' }, 'h1'), true);
    assert.equal(isDmParticipant({ participants: ['h1', 'a1'] }, 'x'), false);
    assert.equal(isDmParticipant(null, 'a1'), false);
  });
});
