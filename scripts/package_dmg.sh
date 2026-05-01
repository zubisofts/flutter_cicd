#!/usr/bin/env bash
# Builds FlutterCI.app in release mode and packages it as a distributable DMG.
# Usage: ./scripts/package_dmg.sh [version]
# Example: ./scripts/package_dmg.sh 1.2.0
set -euo pipefail

# ── Config ────────────────────────────────────────────────────────────────────
APP_NAME="FlutterCI"
VERSION="${1:-1.0.0}"
DMG_FILENAME="${APP_NAME}-${VERSION}.dmg"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
RELEASE_APP="$PROJECT_DIR/build/macos/Build/Products/Release/${APP_NAME}.app"
DIST_DIR="$PROJECT_DIR/dist"
DMG_OUT="$DIST_DIR/$DMG_FILENAME"
STAGING="$(mktemp -d)/dmg_staging"

# ── 1. Build ──────────────────────────────────────────────────────────────────
echo "▶ Building $APP_NAME $VERSION (release)..."
cd "$PROJECT_DIR"
flutter build macos --release
echo "  ✓ Build complete"

# ── 2. Ad-hoc sign ────────────────────────────────────────────────────────────
# Removes the quarantine "damaged app" Gatekeeper block for sideloaded apps.
# Teammates still need to right-click → Open on first launch if they see a
# "cannot verify developer" warning — this is expected without a Developer ID cert.
echo "▶ Signing ad-hoc..."
codesign --force --deep --sign - "$RELEASE_APP"
echo "  ✓ Signed"

# ── 3. Stage ──────────────────────────────────────────────────────────────────
echo "▶ Staging..."
mkdir -p "$STAGING"
cp -r "$RELEASE_APP" "$STAGING/"

# ── 4. Create DMG ─────────────────────────────────────────────────────────────
echo "▶ Creating DMG → $DMG_OUT"
mkdir -p "$DIST_DIR"
rm -f "$DMG_OUT"

create-dmg \
  --volname "$APP_NAME $VERSION" \
  --volicon "$PROJECT_DIR/macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_512.png" \
  --window-pos 200 120 \
  --window-size 540 380 \
  --icon-size 96 \
  --icon "${APP_NAME}.app" 140 190 \
  --hide-extension "${APP_NAME}.app" \
  --app-drop-link 400 190 \
  --no-internet-enable \
  "$DMG_OUT" \
  "$STAGING"

# ── 5. Cleanup ────────────────────────────────────────────────────────────────
rm -rf "$(dirname "$STAGING")"

echo ""
echo "✅  Done: $DMG_OUT"
echo ""
echo "📋  Distribution note:"
echo "    Teammates should drag $APP_NAME to Applications, then on first launch"
echo "    right-click the app → Open (to bypass the Gatekeeper 'unverified developer'"
echo "    prompt). This is only needed once per machine."
echo ""
echo "    If they see 'app is damaged', run:"
echo "    xattr -cr /Applications/${APP_NAME}.app"
