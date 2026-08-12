#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# SpotVibe — development environment setup
#
# Installs the Flutter SDK (if missing), fetches dependencies, and verifies
# the project. Works on Linux/macOS sandboxes and local machines alike.
#
# Usage:
#   ./tool/setup.sh          # full setup: SDK + pub get + analyze + tests
#   ./tool/setup.sh quick    # just SDK check + pub get
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

FLUTTER_VERSION="3.44.9"
# Where the SDK gets installed. Override with FLUTTER_HOME if you prefer.
FLUTTER_HOME="${FLUTTER_HOME:-$HOME/flutter}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Large temp dir — some sandboxes have a tiny /tmp.
export TMPDIR="${TMPDIR:-$REPO_ROOT/.tmp}"
mkdir -p "$TMPDIR"

info()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
error() { printf '\033[1;31m!!\033[0m  %s\n' "$*" >&2; }

# ── 1. Flutter SDK ──────────────────────────────────────────────────────────
install_flutter() {
  info "Installing Flutter $FLUTTER_VERSION to $FLUTTER_HOME ..."
  rm -rf "$FLUTTER_HOME"
  case "$(uname -s)" in
    Linux)  OS=linux;  ARCHIVE="flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" ;;
    Darwin) OS=macos;  ARCHIVE="flutter_macos_${FLUTTER_VERSION}-stable.tar.xz" ;;
    *) error "Unsupported OS for auto-install. Install Flutter manually: https://docs.flutter.dev/get-started/install"; exit 1 ;;
  esac
  URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/$OS/$ARCHIVE"
  curl -fL --retry 2 -o "$TMPDIR/$ARCHIVE" "$URL"
  tar xf "$TMPDIR/$ARCHIVE" -C "$(dirname "$FLUTTER_HOME")"
  rm -f "$TMPDIR/$ARCHIVE"
  # git safe.directory avoids "dubious ownership" errors in containers
  git config --global --add safe.directory "$FLUTTER_HOME" 2>/dev/null || true
}

if [ -x "$FLUTTER_HOME/bin/flutter" ]; then
  info "Flutter SDK found at $FLUTTER_HOME — verifying..."
  # Snapshots/zip-copies can strip the SDK's .git dir or truncate files,
  # which breaks the tool. Verify it works; reinstall if it doesn't.
  if "$FLUTTER_HOME/bin/flutter" --version >/dev/null 2>&1; then
    info "SDK OK"
  else
    error "Existing SDK is broken (missing .git or truncated files) — reinstalling"
    install_flutter
  fi
else
  install_flutter
fi
export PATH="$FLUTTER_HOME/bin:$PATH"
flutter --version

# ── 2. Dependencies ─────────────────────────────────────────────────────────
cd "$REPO_ROOT"
info "Fetching dependencies (flutter pub get)..."
flutter pub get

if [ "${1:-}" = "quick" ]; then
  info "Quick setup complete. Run: flutter run -d chrome   (or: flutter test)"
  exit 0
fi

# ── 3. Verify ───────────────────────────────────────────────────────────────
info "Running static analysis (flutter analyze)..."
flutter analyze || error "analyze reported issues (see above)"

info "Running tests (flutter test)..."
flutter test

info "✅ Setup complete!

Useful commands (from the repo root):
  flutter run -d chrome                          # run in Chrome
  flutter run -d web-server --web-port 8080 \
      --web-hostname 0.0.0.0                     # serve over HTTP (remote/sandbox)
  flutter test                                   # run unit tests
  flutter analyze                                # static analysis
  flutter build apk / ios / web                  # release builds

VS Code: open the repo root and use the Run & Debug panel (F5) —
configurations for Chrome, web server, Android, and iOS are provided."
