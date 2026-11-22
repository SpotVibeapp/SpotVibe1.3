'use strict';

const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const {
  addMonths,
  nextOccurrence,
  shouldSpawn,
  buildSpawnedEvent,
} = require('../lib/recurringSpawn');

describe('nextOccurrence', () => {
  const monday = Date.parse('2026-11-09T19:00:00-07:00');

  it('does not spawn while the current start is still in the future', () => {
    assert.equal(nextOccurrence(monday, monday + 3600000, 'weekly', monday - 1000), null);
  });

  it('advances a weekly event by seven days after it has started', () => {
    const next = nextOccurrence(monday, monday + 2 * 3600000, 'weekly', monday + 1000);
    assert.equal(next.startMs, monday + 7 * 24 * 60 * 60 * 1000);
    assert.equal(next.endMs, next.startMs + 2 * 3600000);
  });

  it('skips missed weeks so a stale series jumps to the next future date', () => {
    const threeWeeksLater = monday + 21 * 24 * 60 * 60 * 1000 + 1000;
    const next = nextOccurrence(monday, null, 'weekly', threeWeeksLater);
    assert.equal(next.startMs, monday + 28 * 24 * 60 * 60 * 1000);
    assert.equal(next.endMs, null);
  });

  it('keeps the day of month when possible, otherwise uses the last day', () => {
    const jan31 = Date.parse('2026-01-31T18:00:00-07:00');
    const feb = addMonths(jan31, 1);
    const febDate = new Date(feb);
    assert.equal(febDate.getMonth(), 1); // February
    assert.equal(febDate.getDate(), 28);
  });

  it('returns null for a non-recurring type', () => {
    assert.equal(nextOccurrence(monday, null, 'none', monday + 1000), null);
  });

  it('keeps the Denver wall-clock time across the fall DST change', () => {
    const before = Date.parse('2026-10-25T19:00:00-06:00'); // MDT
    const now = before + 1000;
    const next = nextOccurrence(before, null, 'weekly', now);
    // Next Sunday is Nov 1, standard time, still 7:00 PM Denver.
    assert.equal(next.startMs, Date.parse('2026-11-01T19:00:00-07:00'));
  });
});

describe('shouldSpawn and buildSpawnedEvent', () => {
  const now = Date.parse('2026-11-16T12:00:00-07:00');
  const start = Date.parse('2026-11-15T19:00:00-07:00');
  const parent = {
    id: 'evt-1',
    title: 'Game night',
    creatorId: 'u1',
    recurringType: 'weekly',
    dateTimeMs: start,
    endDateTimeMs: start + 3600000,
    imageUrls: ['https://x.test/a.jpg'],
    chatLink: 'https://discord.gg/club',
    analyticsViews: 12,
    interestedCount: 4,
    featuredWeekKey: '2026-W46',
    occurrenceIndex: 0,
  };

  it('spawns once the current occurrence has started and has no child', () => {
    assert.equal(shouldSpawn(parent, now), true);
    assert.equal(shouldSpawn({ ...parent, nextSpawnedEventId: 'evt-2' }, now), false);
    assert.equal(shouldSpawn({ ...parent, spawnStopped: true }, now), false);
    assert.equal(shouldSpawn({ ...parent, dateTimeMs: now + 10000 }, now), false);
  });

  it('copies listing fields, advances the date, and resets counts', () => {
    const next = nextOccurrence(parent.dateTimeMs, parent.endDateTimeMs, 'weekly', now);
    const spawned = buildSpawnedEvent(parent, {
      newId: 'evt-2',
      startMs: next.startMs,
      endMs: next.endMs,
      nowMs: now,
      seriesId: 'evt-1',
    });
    assert.equal(spawned.id, 'evt-2');
    assert.equal(spawned.title, 'Game night');
    assert.equal(spawned.chatLink, 'https://discord.gg/club');
    assert.deepEqual(spawned.imageUrls, ['https://x.test/a.jpg']);
    assert.equal(spawned.seriesId, 'evt-1');
    assert.equal(spawned.parentEventId, 'evt-1');
    assert.equal(spawned.occurrenceIndex, 1);
    assert.equal(spawned.dateTimeMs, next.startMs);
    assert.equal(spawned.analyticsViews, 0);
    assert.equal(spawned.interestedCount, 0);
    assert.equal(spawned.featuredWeekKey, null);
    assert.equal(spawned.nextSpawnedEventId, null);
  });
});
