'use strict';

/**
 * Same week key as lib/data/pricing.dart `isoWeekKey` (kept byte-for-byte
 * compatible, including its handling of the first days of January, so the
 * app's `isFeaturedInCurrentWeek` check agrees with the server). Uses the
 * UTC calendar date of [date].
 */
function isoWeekKey(date) {
  const utc = Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate());
  const weekday = new Date(utc).getUTCDay() || 7; // Monday=1 … Sunday=7
  const thursday = new Date(utc + (4 - weekday) * 86400000);
  const firstThursday = Date.UTC(thursday.getUTCFullYear(), 0, 4);
  const days = Math.round((thursday.getTime() - firstThursday) / 86400000);
  const week = 1 + Math.floor(days / 7);
  return `${thursday.getUTCFullYear()}-W${String(week).padStart(2, '0')}`;
}

/** Max founding slots — mirrors kFoundingMemberLimit in lib/data/pricing.dart. */
const FOUNDING_MEMBER_LIMIT = 25;

/**
 * Pure transition for the founding roster doc (meta/founding).
 * @returns {{changed: boolean, memberIds: string[], count: number, userIsMember: boolean}}
 */
function claimFoundingSlotIn(data, uid, limit = FOUNDING_MEMBER_LIMIT) {
  const memberIds = Array.isArray(data && data.memberIds)
    ? data.memberIds.filter((id) => typeof id === 'string')
    : [];
  if (memberIds.includes(uid)) {
    return { changed: false, memberIds, count: memberIds.length, userIsMember: true };
  }
  if (memberIds.length >= limit) {
    return { changed: false, memberIds, count: memberIds.length, userIsMember: false };
  }
  const next = [...memberIds, uid];
  return { changed: true, memberIds: next, count: next.length, userIsMember: true };
}

module.exports = { FOUNDING_MEMBER_LIMIT, claimFoundingSlotIn, isoWeekKey };
