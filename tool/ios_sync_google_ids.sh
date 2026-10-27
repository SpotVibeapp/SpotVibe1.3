#!/bin/sh
# Copies CLIENT_ID / REVERSED_CLIENT_ID from ios/Runner/GoogleService-Info.plist
# into ios/Flutter/AppIds.local.xcconfig (gitignored) for Google Sign-In on iOS.
# Run on a Mac from the repo root after `flutterfire configure`. Prints no values.
set -e
PLIST="ios/Runner/GoogleService-Info.plist"
LOCAL="ios/Flutter/AppIds.local.xcconfig"
[ -f "$PLIST" ] || { echo "Missing $PLIST (run: flutterfire configure --project=spotvibe-cfa08)"; exit 1; }
CLIENT_ID=$(/usr/libexec/PlistBuddy -c "Print :CLIENT_ID" "$PLIST")
REVERSED=$(/usr/libexec/PlistBuddy -c "Print :REVERSED_CLIENT_ID" "$PLIST")
touch "$LOCAL"
grep -v '^GOOGLE_IOS_CLIENT_ID\|^GOOGLE_REVERSED_CLIENT_ID' "$LOCAL" > "$LOCAL.tmp" || true
printf 'GOOGLE_IOS_CLIENT_ID = %s\nGOOGLE_REVERSED_CLIENT_ID = %s\n' "$CLIENT_ID" "$REVERSED" >> "$LOCAL.tmp"
mv "$LOCAL.tmp" "$LOCAL"
echo "Updated $LOCAL with Google Sign-In ids."
