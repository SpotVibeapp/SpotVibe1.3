const test = require('node:test');
const assert = require('node:assert/strict');
const { coverCells, encodeGeohash, geoCellsFor, cellSize } = require('../lib/geo');
const { planFeedFields } = require('../lib/feedFields');

// Shared vectors with test/geo_cells_test.dart.
test('encodes known geohashes', () => {
  assert.equal(encodeGeohash(57.64911, 10.40744, 11), 'u4pruydqqvj');
  assert.equal(encodeGeohash(37.7749, -122.4194, 5), '9q8yy');
  assert.equal(encodeGeohash(31.7619, -106.485, 6), '9tsk8y');
  assert.deepEqual(geoCellsFor(31.7619, -106.485), ['9t', '9ts', '9tsk']);
});

test('no coordinates means no cells', () => {
  assert.deepEqual(geoCellsFor(0, 0), []);
  assert.deepEqual(geoCellsFor(undefined, -106), []);
  assert.equal(coverCells(0, 0, 25), null);
});

test('cover picks the finest precision within 30 cells', () => {
  const small = coverCells(31.7619, -106.485, 10);
  assert.equal(small.precision, 4);
  assert.ok(small.cells.includes('9tsk'));
  assert.ok(small.cells.length <= 30);

  const metro = coverCells(31.7619, -106.485, 40);
  assert.equal(metro.precision, 3);
  assert.deepEqual(metro.cells, ['9te', '9ts']); // same as the Dart test

  const wide = coverCells(31.7619, -106.485, 150);
  assert.ok(wide.cells.length <= 30);
  assert.ok(wide.cells.includes(encodeGeohash(31.7619, -106.485, wide.precision)));
});

test('cover contains every point inside the radius', () => {
  const center = [39.7392, -104.9903];
  const radius = 45;
  const { precision, cells } = coverCells(center[0], center[1], radius);
  for (let k = 0; k < 360; k += 15) {
    const rad = (k * Math.PI) / 180;
    const lat = center[0] + (radius / 69) * 0.99 * Math.sin(rad);
    const lng = center[1] + ((radius / 69) * 0.99 * Math.cos(rad)) / Math.cos((center[0] * Math.PI) / 180);
    assert.ok(cells.includes(encodeGeohash(lat, lng, precision)), `missing ${lat},${lng}`);
  }
});

test('cell sizes', () => {
  assert.deepEqual(cellSize(2), [180 / 32, 360 / 32]);
  assert.deepEqual(cellSize(3), [180 / 128, 360 / 256]);
});

test('feed fields: visibleUntilMs is the end, else the start', () => {
  assert.deepEqual(
    planFeedFields({ dateTimeMs: 10, endDateTimeMs: 20, latitude: 0, longitude: 0, geoCells: [] }),
    { visibleUntilMs: 20 }
  );
  assert.deepEqual(planFeedFields({ dateTimeMs: 10, endDateTimeMs: null, geoCells: [] }), {
    visibleUntilMs: 10,
  });
  assert.equal(
    planFeedFields({ dateTimeMs: 10, endDateTimeMs: 20, visibleUntilMs: 20, geoCells: [] }),
    null
  );
  assert.deepEqual(
    planFeedFields({ dateTimeMs: 10, visibleUntilMs: 10, latitude: 31.7619, longitude: -106.485 }),
    { geoCells: ['9t', '9ts', '9tsk'] }
  );
  // Firestore Timestamp-like values (legacy docs).
  assert.deepEqual(
    planFeedFields({ dateTime: { toMillis: () => 5 }, geoCells: [] }),
    { visibleUntilMs: 5 }
  );
});
