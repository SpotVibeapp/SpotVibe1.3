/**
 * Users' contact details live in the owner-only doc
 * `users/{uid}/private/profile`; the public `users/{uid}` doc (readable by
 * every signed-in user) must never carry them. This module holds the pure
 * planning logic shared by the `scrubPublicUserPii` trigger and the one-off
 * `scripts/migrate_user_private_fields.js` admin script.
 */
'use strict';

const PRIVATE_PROFILE_FIELDS = ['email', 'phone', 'phoneNumber'];

function text(value) {
  return typeof value === 'string' ? value.trim() : '';
}

/**
 * Decides how to move private fields off a public profile doc.
 *
 * @param {object|undefined} publicData  current users/{uid} data
 * @param {object|undefined} privateData current users/{uid}/private/profile data
 * @returns {{privateFields: object, removeFromPublic: string[]}}
 *   privateFields: values to merge into the private doc (never overwrites a
 *   non-blank private value, never writes a blank one);
 *   removeFromPublic: keys to delete from the public doc (every private key
 *   present, including blank ones).
 */
function planPublicPiiScrub(publicData, privateData) {
  const privateFields = {};
  const removeFromPublic = [];
  if (!publicData) return { privateFields, removeFromPublic };
  for (const field of PRIVATE_PROFILE_FIELDS) {
    if (!Object.prototype.hasOwnProperty.call(publicData, field)) continue;
    removeFromPublic.push(field);
    const value = text(publicData[field]);
    if (value && !text(privateData && privateData[field])) {
      privateFields[field] = value;
    }
  }
  return { privateFields, removeFromPublic };
}

module.exports = { PRIVATE_PROFILE_FIELDS, planPublicPiiScrub };
