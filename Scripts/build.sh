#!/bin/bash
set -euo pipefail

echo "Generating Xcode project..."
xcodegen generate

echo "Building ClipFlow..."
xcodebuild archive \
    -project ClipFlow.xcodeproj \
    -scheme ClipFlow \
    -configuration Release \
    -archivePath /tmp/ClipFlow.xcarchive \
    -sdk iphoneos \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO

echo "Packaging IPA..."
mkdir -p /tmp/ipa/Payload
cp -r /tmp/ClipFlow.xcarchive/Products/Applications/ClipFlow.app /tmp/ipa/Payload/

EXTENSIONS_DIR="/tmp/ClipFlow.xcarchive/Products/Applications/ClipFlow.app/PlugIns"
if [ -d "$EXTENSIONS_DIR" ]; then
    mkdir -p /tmp/ipa/Payload/ClipFlow.app/PlugIns
    cp -r "$EXTENSIONS_DIR"/* /tmp/ipa/Payload/ClipFlow.app/PlugIns/ 2>/dev/null || true
fi

cd /tmp/ipa
zip -r ClipFlow.ipa Payload/ -y

echo "IPA ready: /tmp/ipa/ClipFlow.ipa"
echo "Install with: ideviceinstaller -i /tmp/ipa/ClipFlow.ipa"
