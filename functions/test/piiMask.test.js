'use strict';

const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const { maskContactInfo, containsContactInfo, MASK } = require('../lib/piiMask');

describe('maskContactInfo', () => {
  it('masks emails, phones, handles and social URLs, leaving ordinary text', () => {
    const input = 'Bring snacks. Email maya@test.com or call (915) 555-0100, or @maya / https://instagram.com/maya';
    const out = maskContactInfo(input);
    assert.equal(out.includes('maya@test.com'), false);
    assert.equal(out.includes('555-0100'), false);
    assert.equal(out.includes('@maya'), false);
    assert.equal(out.includes('instagram.com'), false);
    assert.equal(out.includes('Bring snacks.'), true);
    assert.equal((out.match(new RegExp(MASK.replace('[', '\\[').replace(']', '\\]'), 'g')) || []).length >= 3, true);
    assert.equal(containsContactInfo('Just a game night at Maya\'s'), false);
    assert.equal(containsContactInfo('DM me @maya'), true);
  });
});
