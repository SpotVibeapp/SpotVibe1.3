/**
 * Geohash cells for the public feed's geo query.
 *
 * Every `events/{id}` doc with real coordinates carries
 *   geoCells: [<2-char>, <3-char>, <4-char> geohash]
 * and the app asks for `geoCells array-contains-any <cover>` together with
 * `visibleUntilMs >= now` ordered by `visibleUntilMs` — one composite index
 * (geoCells CONTAINS, visibleUntilMs ASC) serves every radius, and the time
 * ordering/pagination stays exact (a plain geohash range query would force
 * ordering by geohash instead of by end time).
 *
 * The cover picks the finest precision whose cells fit Firestore's 30-value
 * `array-contains-any` limit. The app then trims to the exact radius with
 * haversine. lib/data/geo_cells.dart is the Dart twin of this file; both are
 * tested against the same vectors.
 */
const BASE32 = '0123456789bcdefghjkmnpqrstuvwxyz';
const CELL_PRECISIONS = [2, 3, 4];
const MAX_COVER_CELLS = 30;
const MILES_PER_DEGREE_LAT = 69.0;

function hasCoordinates(lat, lng) {
  return (
    typeof lat === 'number' &&
    typeof lng === 'number' &&
    Number.isFinite(lat) &&
    Number.isFinite(lng) &&
    !(lat === 0 && lng === 0) &&
    lat >= -90 &&
    lat <= 90 &&
    lng >= -180 &&
    lng <= 180
  );
}

function encodeGeohash(lat, lng, precision) {
  let latLo = -90;
  let latHi = 90;
  let lngLo = -180;
  let lngHi = 180;
  let hash = '';
  let bits = 0;
  let value = 0;
  let evenBit = true; // longitude first
  while (hash.length < precision) {
    if (evenBit) {
      const mid = (lngLo + lngHi) / 2;
      if (lng >= mid) {
        value = value * 2 + 1;
        lngLo = mid;
      } else {
        value *= 2;
        lngHi = mid;
      }
    } else {
      const mid = (latLo + latHi) / 2;
      if (lat >= mid) {
        value = value * 2 + 1;
        latLo = mid;
      } else {
        value *= 2;
        latHi = mid;
      }
    }
    evenBit = !evenBit;
    bits += 1;
    if (bits === 5) {
      hash += BASE32[value];
      bits = 0;
      value = 0;
    }
  }
  return hash;
}

/** Cell size in degrees for a geohash precision: [latDeg, lngDeg]. */
function cellSize(precision) {
  const totalBits = precision * 5;
  const lngBits = Math.ceil(totalBits / 2);
  const latBits = Math.floor(totalBits / 2);
  return [180 / 2 ** latBits, 360 / 2 ** lngBits];
}

/** The geoCells array stored on an event doc ([] without coordinates). */
function geoCellsFor(lat, lng) {
  if (!hasCoordinates(lat, lng)) return [];
  return CELL_PRECISIONS.map((p) => encodeGeohash(lat, lng, p));
}

function cellsAt(precision, minLat, maxLat, minLng, maxLng) {
  const [dLat, dLng] = cellSize(precision);
  const i0 = Math.floor((minLat + 90) / dLat);
  const i1 = Math.floor((Math.min(maxLat, 89.999999) + 90) / dLat);
  const j0 = Math.floor((minLng + 180) / dLng);
  const j1 = Math.floor((Math.min(maxLng, 179.999999) + 180) / dLng);
  const count = (i1 - i0 + 1) * (j1 - j0 + 1);
  if (count > MAX_COVER_CELLS) return null;
  const cells = new Set();
  for (let i = i0; i <= i1; i++) {
    for (let j = j0; j <= j1; j++) {
      const lat = -90 + (i + 0.5) * dLat;
      const lng = -180 + (j + 0.5) * dLng;
      cells.add(encodeGeohash(lat, lng, precision));
    }
  }
  return [...cells].sort();
}

/**
 * Cells covering a circle of [radiusMiles] around (lat, lng), at the finest
 * precision that fits in [MAX_COVER_CELLS]. Returns { precision, cells } or
 * null when no precision fits (the caller then queries by time only).
 */
function coverCells(lat, lng, radiusMiles) {
  if (!hasCoordinates(lat, lng) || !(radiusMiles > 0)) return null;
  const dLat = radiusMiles / MILES_PER_DEGREE_LAT;
  const cosLat = Math.max(Math.cos((lat * Math.PI) / 180), 0.01);
  const dLng = radiusMiles / (MILES_PER_DEGREE_LAT * cosLat);
  const minLat = Math.max(lat - dLat, -90);
  const maxLat = Math.min(lat + dLat, 90);
  const minLng = Math.max(lng - dLng, -180);
  const maxLng = Math.min(lng + dLng, 180);
  for (const precision of [...CELL_PRECISIONS].reverse()) {
    const cells = cellsAt(precision, minLat, maxLat, minLng, maxLng);
    if (cells) return { precision, cells };
  }
  return null;
}

module.exports = {
  CELL_PRECISIONS,
  MAX_COVER_CELLS,
  cellSize,
  coverCells,
  encodeGeohash,
  geoCellsFor,
  hasCoordinates,
};
