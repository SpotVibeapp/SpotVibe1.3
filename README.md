# SpotVibe 🎶

Local events discovery app — browse upcoming events, RSVP, see who's going,
comment, and share. Built with **Flutter** (Dart 3, provider state management,
go_router navigation).

> ⚠️ **Prototype:** **auth is real (Firebase Auth + Firestore)** once the
> Firebase console steps below are done. The public feed is **real events
> only** — curated El Paso listings plus live Ticketmaster results (no
> invented "Live Music Night — City" templates). The app falls back to
> mock auth automatically when Firebase isn't configured on a platform.

---

## Getting started

### One-command setup

```bash
./tool/setup.sh          # installs Flutter SDK if missing, pub get, analyze, test
./tool/setup.sh quick    # just SDK check + pub get
```

### Manual setup

1. Install Flutter (stable ≥ 3.44): https://docs.flutter.dev/get-started/install
2. Verify: `flutter doctor`
3. Fetch dependencies: `flutter pub get`

## Running the app

| Target | Command |
|---|---|
| Chrome (web) | `flutter run -d chrome` |
| Web server (remote/sandbox) | `flutter run -d web-server --web-port 8080 --web-hostname 0.0.0.0` |
| Android device/emulator | `flutter run` (select device with `flutter devices`) |
| iOS simulator (macOS) | `flutter run -d iphone` |

**VS Code:** open the repo root, install the recommended Dart & Flutter
extensions, then press **F5** — launch configurations are provided for Chrome,
web server, Android, iOS, and release mode (`.vscode/launch.json`).

## Testing & quality

```bash
flutter test       # unit tests (test/)
flutter analyze    # static analysis — 0 errors/warnings expected
```

Test coverage currently targets:
- `AiModerationService` — approve / flag / reject behavior, all-caps spam rule
- `AuthService` — input validation (incl. no password trimming)
- `UserRepository` — mock session lifecycle

## Project structure

```
lib/
  models/         # data classes (Event, AppUser, Rsvp, …)
  repositories/   # data sources (currently mock/in-memory)
  services/       # cross-cutting services (auth, notifications, deep links,
                  # AI moderation, RevenueCat, location, …)
  providers/      # ChangeNotifier state (provider package)
  router/         # go_router route table
  screens/        # full-page UI
  widgets/        # reusable UI (events/, common/, user_events/)
  theme/          # design system
test/             # unit tests
tool/setup.sh     # reproducible environment setup
```

## Firebase authentication

Project: **spotvibe-cfa08** · Code: `lib/repositories/firebase_user_repository.dart`,
`lib/firebase_options.dart`, `firestore.rules`

Architecture: `AuthService → UserRepository` (interface) with two
implementations — `FirebaseUserRepository` (production) and
`MockUserRepository` (offline/dev/tests). Events/RSVPs follow the same
pattern (`FirebaseEventRepository`, `FirebaseRsvpRepository`,
`FirebaseUserEventRepository`). `main.dart` picks automatically:
if `Firebase.initializeApp` succeeds, real backends are used; otherwise
the app still runs on mocks.

Default feed: curated El Paso venues (County Coliseum, Southwest University
Park, Plaza Theatre, Franklin Mountains, Hueco Tanks, …) merged with live
Ticketmaster listings for that area. Searching another city uses Ticketmaster
only — the app never invents events. Duplicate title + venue + day rows are
collapsed, preferring the Ticketmaster row (official event photo + ticket
URL). Deploy `firestore.rules` so the El Paso seed can be written.

### Ticketmaster (live listings + official images)

1. Create a free API key at https://developer.ticketmaster.com/
2. Run with the key as a dart-define (never commit it):

```bash
flutter run --dart-define=TICKETMASTER_API_KEY=your_key_here
```

Without a key the feed still shows the curated El Paso seed (real venues,
Wikimedia venue photos) and stays empty for other cities instead of faking
listings.

### One-time console setup (you must do this)

1. Open https://console.firebase.google.com → project **spotvibe-cfa08**
2. **Build → Authentication → Get started** and enable:
   - **Email/Password** (required)
   - **Google / Facebook / Apple** (optional; each needs its own OAuth
     client credentials in that provider's console)
3. **Build → Firestore Database → Create database** (production mode, any
   region)
4. Publish the security rules: console → Firestore → **Rules** tab → paste
   the contents of `firestore.rules` → **Publish** (or
   `firebase deploy --only firestore:rules` with the Firebase CLI)

> Smoke test on 2026-08-10 returned `CONFIGURATION_NOT_FOUND` for sign-up:
> Authentication is **not enabled yet** in the console. Steps 1–2 fix that.

### Web
Already configured (`firebase_options.dart` ships the web app config).
Email/password sign-in works from any domain; for Google **popup** sign-in,
add your domain under **Authentication → Settings → Authorized domains**
(e.g. your deployed host — sandbox preview hosts would need adding too).

### Android / iOS (native builds)
Register the Android app with package name **`app.spotvibe`** and the iOS
app with bundle id **`app.spotvibe`** in the Firebase console, then run on
your machine:

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=spotvibe-cfa08
```

This rewrites `lib/firebase_options.dart` with the native configs and
downloads `google-services.json` / `GoogleService-Info.plist` (both are
gitignored by design — never commit them).

### Session behavior
Firebase sessions persist across restarts; `AuthProvider.restoreSession()`
signs returning users in automatically at launch.

## Platform configuration notes

- **Deep links:** `https://spotvibe.app/event/*` + custom scheme `spotvibe://`
  (AndroidManifest.xml / Info.plist). Base URL constant:
  `kDeepLinkBase` in `lib/services/deep_link_service.dart`. Legacy
  `vibely.app` / `vibely://` links still resolve.
- **Branch.io:** manifest/plist still contain `REPLACE_WITH_BRANCH_*`
  placeholders — set real keys from the Branch dashboard before testing
  deferred deep links.
- **Android signing:** create `android/key.properties` (see Flutter docs);
  release builds fall back to debug signing when it's absent. Never commit
  `key.properties` or keystores.
- **Subscriptions:** RevenueCat entitlement id `pro`
  (`lib/services/revenue_cat_service.dart`).
