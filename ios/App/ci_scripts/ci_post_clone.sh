#!/bin/sh
# Xcode Cloud post-clone hook for the DTGF Social Capacitor shell.
# Xcode Cloud clones the repo with no node_modules and no Pods; the
# Xcode project alone cannot build. Prepare the JS side and sync the
# iOS project (cap sync also runs pod install) before xcodebuild runs.
set -e
cd "$(dirname "$0")/../../.."
echo "Preparing Capacitor project at $(pwd)"
if ! command -v node >/dev/null 2>&1; then
  brew install node
fi
npm ci
npx cap sync ios
