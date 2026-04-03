#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BUILD_NUMBER="${1:-1}"

cd "$ROOT_DIR"

if [[ ! -f .env ]]; then
  echo "Missing .env"
  exit 1
fi

flutter pub get
(cd ios && pod install)
flutter build ipa \
  --release \
  --build-number "$BUILD_NUMBER" \
  --dart-define-from-file=.env \
  --export-options-plist=ios/ExportOptions.plist

echo "Created build/ios/ipa/*.ipa"
