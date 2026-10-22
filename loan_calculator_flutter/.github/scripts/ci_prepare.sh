#!/usr/bin/env bash
# CI-only fixes so the Flutter app can build on the runner.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

# Use CocoaPods for iOS plugins (avoid SPM half-migration on CI).
flutter config --no-enable-swift-package-manager

# Deployment target is already 15. Podfile leaves the platform line commented.
if grep -q "^# platform :ios, '15.0'" ios/Podfile; then
  sed -i.bak "s/^# platform :ios, '15.0'/platform :ios, '15.0'/" ios/Podfile
  rm -f ios/Podfile.bak
fi
