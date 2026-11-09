const fs = require('fs');
const os = require('os');
const path = require('path');

const VIDEO_NAME = /^(promo|video_\d+_.+)\.(mp4|mov|m4v|webm)$/i;

/**
 * Event promo clips live at events/{uid}/{eventId}/promo.mp4 and
 * events/{uid}/{eventId}/video_{n}_{stamp}.mp4. Photos in the same folder
 * are ignored.
 */
function isEventVideoPath(name, contentType) {
  if (!name || typeof name !== 'string') return false;
  const parts = name.split('/');
  if (parts.length !== 4 || parts[0] !== 'events') return false;
  const base = parts[3];
  if (VIDEO_NAME.test(base)) return true;
  const type = (contentType || '').toLowerCase();
  return type.startsWith('video/') && /\.(mp4|mov|m4v|webm)$/i.test(base);
}

function bufferIncludes(bytes, ascii) {
  if (!bytes || !bytes.length) return false;
  return bytes.indexOf(Buffer.from(ascii)) !== -1;
}

/**
 * True when a just-uploaded event video should be replaced with H.264 MP4.
 *
 * Already-compatible uploads (H.264 `avc1` in an mp4, or a file this function
 * already rewrote) are left untouched so existing playback URLs keep working.
 * HEVC (`hvc1` / `hev1`), QuickTime, and unknown video codecs are converted.
 * The download token is preserved by the caller, so the URL stored on the
 * event document does not change.
 */
function needsH264Transcode({ name, contentType, metadata, bytes }) {
  const meta = metadata || {};
  if (meta.transcoded === 'h264') return false;
  if (!isEventVideoPath(name, contentType)) return false;

  const lowerName = name.toLowerCase();
  const type = (contentType || '').toLowerCase();
  const quicktime =
    lowerName.endsWith('.mov') ||
    lowerName.endsWith('.m4v') ||
    type.includes('quicktime');

  const hevc = bufferIncludes(bytes, 'hvc1') || bufferIncludes(bytes, 'hev1');
  const avc = bufferIncludes(bytes, 'avc1') || bufferIncludes(bytes, 'avc3');
  if (hevc) return true;
  if (quicktime) return true;
  if (avc) return false;
  // mp4/webm with no recognized codec box: convert so Chrome can play it.
  return lowerName.endsWith('.mp4') || lowerName.endsWith('.webm') || type.startsWith('video/');
}

function transcodeToH264(inputPath, outputPath) {
  return new Promise((resolve, reject) => {
    let ffmpegPath;
    let ffmpeg;
    try {
      ffmpegPath = require('ffmpeg-static');
      ffmpeg = require('fluent-ffmpeg');
    } catch (err) {
      reject(err);
      return;
    }
    if (!ffmpegPath) {
      reject(new Error('ffmpeg-static did not provide a binary'));
      return;
    }
    ffmpeg.setFfmpegPath(ffmpegPath);
    ffmpeg(inputPath)
      .outputOptions([
        '-c:v libx264',
        '-profile:v main',
        '-pix_fmt yuv420p',
        '-movflags +faststart',
        '-c:a aac',
        '-b:a 128k',
      ])
      .on('end', () => resolve(outputPath))
      .on('error', reject)
      .save(outputPath);
  });
}

/**
 * Downloads [objectName], converts it when needed, and overwrites the same
 * object so the Firebase download URL (token) stays valid.
 */
async function transcodeStorageObject(bucket, object) {
  const name = object.name;
  const metadata = object.metadata || {};
  if (metadata.transcoded === 'h264') return { skipped: 'already-h264' };
  if (!isEventVideoPath(name, object.contentType)) return { skipped: 'not-event-video' };

  const tmpIn = path.join(os.tmpdir(), `sv-in-${Date.now()}-${path.basename(name)}`);
  const tmpOut = path.join(os.tmpdir(), `sv-out-${Date.now()}.mp4`);
  await bucket.file(name).download({ destination: tmpIn });
  let bytes;
  try {
    bytes = fs.readFileSync(tmpIn);
    if (!needsH264Transcode({
      name,
      contentType: object.contentType,
      metadata,
      bytes,
    })) {
      return { skipped: 'already-playable' };
    }
    await transcodeToH264(tmpIn, tmpOut);
    const token = metadata.firebaseStorageDownloadTokens;
    await bucket.upload(tmpOut, {
      destination: name,
      metadata: {
        contentType: 'video/mp4',
        metadata: {
          ...metadata,
          transcoded: 'h264',
          ...(token ? { firebaseStorageDownloadTokens: token } : {}),
        },
      },
    });
    return { transcoded: true };
  } finally {
    fs.rmSync(tmpIn, { force: true });
    fs.rmSync(tmpOut, { force: true });
  }
}

module.exports = {
  isEventVideoPath,
  needsH264Transcode,
  transcodeToH264,
  transcodeStorageObject,
};
