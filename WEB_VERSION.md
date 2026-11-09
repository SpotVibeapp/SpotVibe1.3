# SpotVibe on the web

The Flutter app now builds and runs in a browser. Phone and tablet builds keep the same behavior. Web-only code is behind `kIsWeb` or a conditional import, so `dart:io` and the mobile-only plugins are not compiled into the web bundle.

The site is **not** deployed. Nothing was changed in production: no Hosting deploy, no DNS change, no `firestore.rules` or `storage.rules` deploy, no CORS update on the bucket, and no store products were created.

## Where it is served

Blake owns `spotvibeapp.com`. Do **not** use an `app.spotvibeapp.com` subdomain.

| URL | What it is |
| --- | --- |
| `https://spotvibeapp.com/` | SpotVibe LLC company site (static). Needed for Apple developer enrollment. |
| `https://spotvibeapp.com/app/` | This Flutter web app (`--base-href /app/`). |
| `https://spotvibeapp.com/app/event/<id>` | Event page. Opens the installed app when App Links / Universal Links are verified, otherwise the website. |
| `https://spotvibeapp.com/app/user-event/<id>` | Same, for a creator event. |
| `spotvibe://event/<id>` | Custom scheme. Still works. Unchanged. |

`firebase.json` in the repo root is unchanged. `firebase deploy --only hosting` still publishes `legal_site/` to the existing **spotvibe-cfa08** site (the Play listing legal pages). The web app config is a separate file so that deploy cannot pick it up by accident: [`firebase.spotvibeapp.json`](firebase.spotvibeapp.json).

## What works in the browser

- `flutter build web --release --base-href /app/` succeeds. go_router keeps the same paths as the phone app (`/`, `/login`, `/map`, `/event/:id`). The browser URL stays under `/app/` because of `<base href="/app/">` and `SpotVibePathStrategy`.
- Home feed, event detail, map, and sign-in. On a wide window the feed is a 2- or 3-column grid inside a max-width column, with a side rail (Discover / Gems / Map). The map shows the list beside the map. A phone-width window keeps the bottom bar and a single column.
- Email/password sign-in and **Google sign-in** via the Firebase Auth popup. Apple is implemented the same way but the button stays hidden until `ENABLE_APPLE_SIGN_IN_WEB=true`.
- Photo and video picks use in-memory bytes (`XFile.readAsBytes`). Uploads use `putData` to the **same** Storage paths and size limits as the phone (`users/…/avatar.jpg`, `events/{uid}/{eventId}/cover.jpg`, `photo_*`, `promo.mp4`, `video_*`, `gems/…`). Previews use `Image.memory`.
- Share cards, story cards, and Poster Studio share PNG bytes through the Web Share API, or download the file when the browser has no share sheet.
- Add to calendar: Google Calendar link, plus a **Download .ics file** button.
- Network photos (Ticketmaster, SeatGeek, JamBase, and other hosts that do not send CORS headers) render with an HTML `<img>` (`WebHtmlElementStrategy.prefer`) so CanvasKit can display them. Phone builds still use `CachedNetworkImage`.
- Location uses the browser Geolocation API (the prompt appears when someone taps location). The first-run native permission screen is skipped so the feed can open immediately.
- Notifications use the browser Notification API after the visitor allows them. There is no `awesome_notifications` channel on the web.
- Deep links: `https://spotvibeapp.com/app/event/<id>` and the older `spotvibe-cfa08.web.app` / `spotvibeapp.net` links still parse to `/event/<id>` inside the app.

## What is off, or different, on the web

| Area | Web behavior |
| --- | --- |
| Ads (`google_mobile_ads`) | Not compiled. The banner slot is empty. No web ad SDK. |
| App Tracking Transparency | Skipped. iOS only. |
| `awesome_notifications` | Not compiled. Browser notifications instead. No background push until FCM web is added. |
| `add_2_calendar` | Not compiled. Google Calendar link and `.ics` download. |
| `app_links` | Not used. go_router reads the URL under `/app/`. |
| `permission_handler` | Not used for the web location prompt. Browser geolocation instead. There is no "open system settings" page. |
| Crashlytics | Still not collected on web (same as before). |
| RevenueCat mobile SDK | Not used. Web Billing is implemented but **off** until the defines below are set. A release build will not grant Premium and will not charge anyone. |
| Sign in with Apple | Code is in place (Firebase popup). The button is hidden until `ENABLE_APPLE_SIGN_IN_WEB=true`. |
| HEVC / `.mov` playback | Chrome often cannot play the original. A Storage Cloud Function (below) rewrites new uploads to H.264 MP4 **in place**, keeping the download URL. It is not deployed. Existing files are not touched until they are uploaded again. iOS playback of already-H.264 files is unchanged. |
| Poster / share-card capture of a cross-origin photo | The on-screen photo uses an HTML image, which the browser will not draw into a canvas. The shared PNG still includes the title, date, and layout. A same-origin photo (Firebase Storage after CORS, or a picked file) is included. |
| First-run onboarding | Skipped on web so the feed is not blocked on a native permission dialog. |

## Build

```bash
flutter build web --release --base-href /app/
rm -rf spotvibeapp_site/app
mkdir -p spotvibeapp_site/app
cp -a build/web/. spotvibeapp_site/app/
```

`spotvibeapp_site/app/` is gitignored except for a placeholder. Do not commit the build output.

A plain `python -m http.server` only works for `/app/` itself. Client routes (`/app/login`, `/app/event/…`) need the rewrite in `firebase.spotvibeapp.json`. The smoke test used a local static server with that rewrite. It was not a deploy.

## One-time setup Blake still has to do

Do these in order when you are ready to replace the Squarespace "Coming Soon" page. None of them were run from this change.

### 1. Hosting site (do not touch spotvibe-cfa08)

The legal site stays `spotvibe-cfa08` / `legal_site`. Create a **second** Hosting site and attach the domain to that site only:

```bash
firebase hosting:sites:create spotvibeapp --project spotvibe-cfa08
```

In the Firebase console, add custom domains `spotvibeapp.com` and `www.spotvibeapp.com` to the **spotvibeapp** site, not to `spotvibe-cfa08`.

Stage the files (command above), then:

```bash
firebase deploy --config firebase.spotvibeapp.json --only hosting --project spotvibe-cfa08
```

That publishes `spotvibeapp_site/`: company page at `/`, Flutter app at `/app/**` → `/app/index.html`, and the association files at `/.well-known/`.

`firebase deploy --only hosting` **without** `--config firebase.spotvibeapp.json` still updates only the legal site. Keep using that for privacy/terms.

DNS, when the company site should go live: point `spotvibeapp.com` at the new Hosting site using the A and TXT records Firebase shows. Until that happens, Squarespace keeps serving the Coming Soon page. Do not change DNS before the Hosting site looks right.

The service worker is ` /app/flutter_service_worker.js`. Its default scope is the `/app/` directory. `web/manifest.json` sets `"scope": "/app/"` and `"start_url": "/app/"`.

### 2. Storage CORS (do not run until you mean to)

File: [`cors.json`](cors.json). It allows the production origins and a few localhost ports to `GET`/`PUT` the bucket. Storage rules are unchanged; CORS only lets the browser see the response.

```bash
gsutil cors set cors.json gs://spotvibe-cfa08.firebasestorage.app
```

`flutter run -d chrome` uses a random port. Cloud Storage does not accept `http://localhost:*`. Either add that exact origin to `cors.json` before the command, or for a local session only set the origin list to `["*"]`. Do not leave `*` in place if you do not want every website to be able to read public objects from a browser.

HTML `<img>` covers do not need CORS. Uploads and `<video>` do.

### 3. Google and Apple sign-in

Google (button is already shown):

1. Firebase Authentication → Settings → **Authorized domains**: add `spotvibeapp.com` and `www.spotvibeapp.com`. `localhost` is already allowed for local runs.
2. Google Cloud Console → APIs & Services → Credentials → the **Web client** that Firebase created for project `spotvibe-cfa08`.
3. Authorized JavaScript origins: `https://spotvibeapp.com`, `https://www.spotvibeapp.com`, and `http://localhost` for local work.
4. The redirect URI stays `https://spotvibe-cfa08.firebaseapp.com/__/auth/handler`. The web app uses `signInWithPopup`, which goes through that handler.

Apple (button hidden until you opt in):

1. Apple Developer → Identifiers → Services ID (for example `app.spotvibe.web`). Enable Sign in with Apple. Domain: `spotvibeapp.com`. Return URL: `https://spotvibe-cfa08.firebaseapp.com/__/auth/handler`.
2. Firebase Authentication → Sign-in method → Apple → enable, and paste the Services ID, Team ID, key id, and private key.
3. Rebuild with `--dart-define=ENABLE_APPLE_SIGN_IN_WEB=true`.

### 4. RevenueCat Web Billing (off by default)

Same RevenueCat project as the iOS and Android apps, so the `pro` entitlement is shared when the Firebase uid is the app user id.

1. RevenueCat → Apps → add a **Web Billing** app.
2. Create products with the same ids the phone app uses: `spotvibe_premium_monthly` and `spotvibe_premium_founding_monthly`. Attach them to the `pro` entitlement. Offerings: `default` and `founding` (see `lib/data/pricing.dart`).
3. Copy the public web key (`rcb_…`). It is not a secret, but it is still not committed.
4. Build with:

```bash
flutter build web --release --base-href /app/ \
  --dart-define=ENABLE_WEB_BILLING=true \
  --dart-define=REVENUECAT_WEB_API_KEY=rcb_your_key
```

`web/revenuecat_billing.js` loads `@revenuecat/purchases-js` from esm.sh only when configure() runs. With the flag off, the SDK is never called and nothing is charged. A release build without the flag tells the person to subscribe in the iOS or Android app.

### 5. HEVC → H.264 (not deployed)

`functions/lib/videoTranscode.js` runs on `onObjectFinalized` for `events/{uid}/{eventId}/promo.mp4` and `video_*.mp4` / `.mov`.

- If the file is already H.264 (`avc1` / `avc3`) it is left alone.
- HEVC (`hvc1` / `hev1`), QuickTime, and unrecognized video are transcoded with ffmpeg to H.264 Main, yuv420p, AAC, `+faststart`.
- The object **name** and `firebaseStorageDownloadTokens` are preserved, so the URL already saved on the event keeps working.
- The rewritten object is tagged `metadata.transcoded=h264`, so the function does not loop.
- A failed transcode leaves the original file in place.

Deploy only this function when you want it (it bundles `ffmpeg-static`, so the upload is large):

```bash
firebase deploy --only functions:transcodeEventVideo --project spotvibe-cfa08
```

Memory is 2 GiB, timeout 300 seconds. It does not change `storage.rules`.

### 6. App Links and Universal Links

Placeholders (the Team ID and the Play signing cert are not in the repo):

- [`spotvibeapp_site/.well-known/assetlinks.json`](spotvibeapp_site/.well-known/assetlinks.json) — replace `REPLACE_WITH_SIGNING_CERT_SHA256` with the **Play app signing** SHA-256 (Play Console → App integrity → App signing), not only the upload key.
- [`spotvibeapp_site/.well-known/apple-app-site-association`](spotvibeapp_site/.well-known/apple-app-site-association) — replace `REPLACE_WITH_TEAM_ID` with the Apple Team ID. The app id is `TEAMID.app.spotvibe`. Paths are `/app/event/*` and `/app/user-event/*`.

Android intent filters (`android:autoVerify="true"`) now include `spotvibeapp.com` and `www.spotvibeapp.com` for `/app/event` and `/app/user-event`. The older `spotvibeapp.net` and `spotvibe-cfa08.web.app` filters are still there so links that were already sent keep opening the app. `spotvibe://` is unchanged.

iOS Associated Domains now include `applinks:spotvibeapp.com` and `applinks:www.spotvibeapp.com`, plus the previous two hosts.

Share links default to `https://spotvibeapp.com/app/event/<id>`. Override with `--dart-define=SPOTVIBE_LINK_BASE=https://spotvibeapp.com/app` if you need a different host. The legal-page URLs (`privacy.html` and the rest) stay on `https://spotvibe-cfa08.web.app` until you deliberately move them.

## Domain notes (no DNS was changed)

What was already in the repo:

- `firebase.json` hosts only site `spotvibe-cfa08`, public directory `legal_site`. No `spotvibeapp.com` custom domain is configured there.
- `web/index.html` had no custom domain. Firebase web config uses `authDomain: spotvibe-cfa08.firebaseapp.com` and bucket `spotvibe-cfa08.firebasestorage.app`.
- `lib/config/app_config.dart` had no site URL.
- Legal pages and in-app legal links use `https://spotvibe-cfa08.web.app/privacy.html`, `terms.html`, and `delete_account.html`. Contact mail is `privacy@spotvibeapp.com` and `feedback@spotvibeapp.com`.
- Share links defaulted to `https://spotvibe-cfa08.web.app`. Accepted hosts were `spotvibeapp.net`, `www.spotvibeapp.net`, `spotvibe-cfa08.web.app`, and `spotvibe-cfa08.firebaseapp.com`.
- Android App Links and the iOS entitlement used `spotvibeapp.net` and `spotvibe-cfa08.web.app`. A comment mentioned `spotvibe.app`. That domain is **not** configured as a host in code. `spotvibe.app` is not Blake's domain.
- Older docs (`README.md`, `LAUNCH_ACTION_ITEMS.md`, `LAUNCH_AUDIT_2026-08-18.md`, `IOS_RELEASE_TODO_BLAKE.md`, `ANALYSIS.md`, `PRIMIO.md`) still mention `spotvibe.app` in places. Those files were not rewritten. The live share URL, intent filters, and entitlement are now `spotvibeapp.com`.
- There is no `app.spotvibeapp.com` anywhere, and this change does not add one.

`spotvibeapp.com` itself is still the Squarespace Coming Soon page until DNS is pointed at the new Hosting site.
