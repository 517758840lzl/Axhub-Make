#!/usr/bin/env bash
# Archive + export ipa with xcodebuild directly.
# flutter build ipa hides xcodebuild output until the process exits and also passes
# -allowProvisioningUpdates, which often sits for 30+ minutes on CI with no new log lines.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
APP="$ROOT/loan_calculator_flutter"
cd "$APP"

: "${IOS_TEAM_ID:?IOS_TEAM_ID is required}"
PROFILE_NAME="${IOS_PROVISIONING_PROFILE_NAME:?IOS_PROVISIONING_PROFILE_NAME is required}"
KEYCHAIN_PATH="$(cat "${RUNNER_TEMP}/ios_keychain_path")"
KEYCHAIN_PASSWORD="$(cat "${RUNNER_TEMP}/ios_keychain_password")"

security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH" || true

echo "Generating Flutter iOS config (no full compile)..."
flutter build ios --config-only --release

ARCHIVE="$APP/build/ios/archive/Runner.xcarchive"
EXPORT_DIR="$APP/build/ios/ipa"
mkdir -p "$(dirname "$ARCHIVE")"
rm -rf "$ARCHIVE" "$EXPORT_DIR"

export NSUnbufferedIO=YES

# Signing is already set on the Runner target in project.pbxproj.
# Do not pass PROVISIONING_PROFILE_SPECIFIER / CODE_SIGN_STYLE here: those apply to
# every Pod target, and CocoaPods frameworks reject a manual App Store profile.
echo "Archiving with xcodebuild (Runner profile: ${PROFILE_NAME})..."
xcodebuild \
  -workspace "$APP/ios/Runner.xcworkspace" \
  -scheme Runner \
  -configuration Release \
  -sdk iphoneos \
  -destination "generic/platform=iOS" \
  -archivePath "$ARCHIVE" \
  COMPILER_INDEX_STORE_ENABLE=NO \
  DEVELOPMENT_TEAM="$IOS_TEAM_ID" \
  OTHER_CODE_SIGN_FLAGS="--keychain ${KEYCHAIN_PATH}" \
  archive

echo "Exporting ipa..."
xcodebuild \
  -exportArchive \
  -archivePath "$ARCHIVE" \
  -exportPath "$EXPORT_DIR" \
  -exportOptionsPlist "$APP/ios/ExportOptions.ci.plist"

ls -lh "$EXPORT_DIR"/*.ipa
echo "IPA ready."
