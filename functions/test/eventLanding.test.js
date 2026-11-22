'use strict';
const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const {
  buildEventJsonLd,
  eventIdFromPath,
  indexability,
  isSafeEventId,
  jsonForScript,
  landingResponse,
} = require('../lib/eventLanding');

const now = Date.UTC(2026, 10, 22, 12);
const base = 'https://spotvibeapp.com';
const event = {
  title: 'Thursday Board Game Night',
  description: 'Bring a friend.\nNew players welcome.',
  dateTimeMs: Date.UTC(2026, 11, 4, 2), // Thu Dec 3, 7 PM MST
  endDateTimeMs: Date.UTC(2026, 11, 4, 5),
  visibleUntilMs: Date.UTC(2026, 11, 4, 5),
  location: 'Cafe Ludo',
  address: '1 Main St',
  city: 'El Paso',
  state: 'TX',
  zipCode: '79901',
  cost: null,
  imageUrl: 'https://cdn.example.com/a.jpg',
  imageUrls: ['https://cdn.example.com/a.jpg', 'http://insecure.example.com/b.jpg'],
  organizerName: 'Game Night Crew',
  source: 'local',
  kind: 'user',
  creatorId: 'host1',
};

describe('indexability', () => {
  it('organizer-posted upcoming events are indexable', () => {
    assert.deepEqual(indexability(event, now), { ok: true });
    assert.deepEqual(indexability({ ...event, kind: 'web_submission', creatorId: '' }, now), { ok: true });
  });

  it('never indexes backfill, curated, samples, hidden or ended events', () => {
    assert.equal(indexability({ ...event, source: 'ticketmaster' }, now).reason, 'provider');
    assert.equal(indexability({ ...event, source: 'jambase' }, now).reason, 'provider');
    assert.equal(indexability({ ...event, kind: 'curated', creatorId: '' }, now).reason, 'not_first_party');
    assert.equal(indexability({ ...event, isSample: true }, now).reason, 'sample');
    assert.equal(indexability({ ...event, hidden: true }, now).reason, 'hidden');
    assert.equal(indexability({ ...event, visibleUntilMs: now - 1 }, now).reason, 'ended');
    assert.equal(indexability({ ...event, location: '' }, now).reason, 'incomplete');
    assert.equal(indexability(null, now).reason, 'missing');
  });
});

describe('buildEventJsonLd', () => {
  it('produces a Google-eligible Event with a Place and UTC dates', () => {
    const ld = buildEventJsonLd('evt42', event, { baseUrl: base });
    assert.equal(ld['@type'], 'Event');
    assert.equal(ld.name, 'Thursday Board Game Night');
    assert.equal(ld.startDate, '2026-12-04T02:00:00.000Z');
    assert.equal(ld.endDate, '2026-12-04T05:00:00.000Z');
    assert.equal(ld.location['@type'], 'Place');
    assert.equal(ld.location.name, 'Cafe Ludo');
    assert.equal(ld.location.address.addressLocality, 'El Paso');
    assert.equal(ld.eventAttendanceMode, 'https://schema.org/OfflineEventAttendanceMode');
    assert.equal(ld.url, 'https://spotvibeapp.com/e/evt42');
    assert.deepEqual(ld.image, ['https://cdn.example.com/a.jpg']); // https only, deduped
    assert.equal(ld.organizer.name, 'Game Night Crew');
    assert.equal(ld.isAccessibleForFree, true);
    assert.equal(ld.offers, undefined);
  });

  it('adds an Offer when there is a price', () => {
    const ld = buildEventJsonLd('evt42', { ...event, cost: 12, sourceUrl: 'https://tix.example.com/x' }, { baseUrl: base });
    assert.equal(ld.offers.price, '12.00');
    assert.equal(ld.offers.priceCurrency, 'USD');
    assert.equal(ld.offers.url, 'https://tix.example.com/x');
    assert.equal(ld.isAccessibleForFree, undefined);
  });

  it('omits an endDate that is not after the start', () => {
    const ld = buildEventJsonLd('e', { ...event, endDateTimeMs: event.dateTimeMs }, { baseUrl: base });
    assert.equal(ld.endDate, undefined);
  });
});

describe('landingResponse', () => {
  it('renders an indexable page with JSON-LD and OG tags', () => {
    const r = landingResponse('evt42', event, { baseUrl: base, playUrl: 'https://play.google.com/store/apps/details?id=app.spotvibe', nowMs: now });
    assert.equal(r.status, 200);
    assert.equal(r.headers['X-Robots-Tag'], undefined);
    assert.match(r.body, /<script type="application\/ld\+json">/);
    assert.match(r.body, /<meta property="og:title" content="Thursday Board Game Night">/);
    assert.match(r.body, /<link rel="canonical" href="https:\/\/spotvibeapp.com\/e\/evt42">/);
    assert.match(r.body, /href="https:\/\/spotvibeapp.com\/app\/event\/evt42"/);
    assert.match(r.body, /Dec 3/); // shown in the launch metro's time zone
  });

  it('escapes hostile text in HTML and in the JSON-LD block', () => {
    const evil = { ...event, title: 'Night </script><script>alert(1)</script>', description: '<img src=x onerror=alert(1)>' };
    const r = landingResponse('evt42', evil, { baseUrl: base, nowMs: now });
    assert.equal(r.body.includes('</script><script>alert(1)'), false);
    assert.equal(r.body.includes('<img src=x'), false);
    assert.match(r.body, /\\u003c\/script\\u003e/);
  });

  it('noindexes events that must not be in search, 404s hidden or missing ones', () => {
    const provider = landingResponse('t1', { ...event, source: 'seatgeek' }, { baseUrl: base, nowMs: now });
    assert.equal(provider.status, 200);
    assert.equal(provider.headers['X-Robots-Tag'], 'noindex');
    assert.equal(provider.body.includes('ld+json'), false);
    assert.equal(landingResponse('h1', { ...event, hidden: true }, { baseUrl: base, nowMs: now }).status, 404);
    assert.equal(landingResponse('m1', null, { baseUrl: base, nowMs: now }).status, 404);
    assert.equal(landingResponse('../etc', event, { baseUrl: base, nowMs: now }).status, 404);
  });
});

describe('helpers', () => {
  it('eventIdFromPath and isSafeEventId', () => {
    assert.equal(eventIdFromPath('/e/abc123'), 'abc123');
    assert.equal(eventIdFromPath('/e/abc123/'), 'abc123');
    assert.equal(eventIdFromPath('/x/abc'), '');
    assert.equal(isSafeEventId('abc_DEF-9'), true);
    assert.equal(isSafeEventId('a/b'), false);
    assert.equal(isSafeEventId(''), false);
  });

  it('jsonForScript neutralizes script breakouts', () => {
    assert.equal(jsonForScript({ a: '</script>' }), '{"a":"\\u003c/script\\u003e"}');
  });
});
