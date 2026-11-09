const test = require('node:test');
const assert = require('node:assert/strict');
const { isEventVideoPath, needsH264Transcode } = require('../lib/videoTranscode');

test('only event promo and extra videos are candidates', () => {
  assert.equal(isEventVideoPath('events/uid/evt/promo.mp4', 'video/mp4'), true);
  assert.equal(isEventVideoPath('events/uid/evt/video_2_123.mp4', 'video/mp4'), true);
  assert.equal(isEventVideoPath('events/uid/evt/video_2_123.mov', 'video/quicktime'), true);
  assert.equal(isEventVideoPath('events/uid/evt/cover.jpg', 'image/jpeg'), false);
  assert.equal(isEventVideoPath('users/uid/avatar.jpg', 'image/jpeg'), false);
  assert.equal(isEventVideoPath('gems/uid/gem/photo_1_1.jpg', 'image/jpeg'), false);
});

test('HEVC and QuickTime are transcoded; H.264 mp4 is left alone', () => {
  const hevc = Buffer.from('....hvc1....');
  const avc = Buffer.from('....avc1....');
  assert.equal(needsH264Transcode({
    name: 'events/u/e/promo.mp4',
    contentType: 'video/mp4',
    metadata: {},
    bytes: hevc,
  }), true);
  assert.equal(needsH264Transcode({
    name: 'events/u/e/promo.mov',
    contentType: 'video/quicktime',
    metadata: {},
    bytes: avc,
  }), true);
  assert.equal(needsH264Transcode({
    name: 'events/u/e/promo.mp4',
    contentType: 'video/mp4',
    metadata: {},
    bytes: avc,
  }), false);
  assert.equal(needsH264Transcode({
    name: 'events/u/e/promo.mp4',
    contentType: 'video/mp4',
    metadata: { transcoded: 'h264' },
    bytes: hevc,
  }), false);
  assert.equal(needsH264Transcode({
    name: 'events/u/e/cover.jpg',
    contentType: 'image/jpeg',
    metadata: {},
    bytes: hevc,
  }), false);
});
