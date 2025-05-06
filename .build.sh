#!/bin/bash

param="false"
# Check if the parameter is passed
if [ -z "$1" ]; then
    echo "run without parameters.. default don't rebuild if exists"
else
    param=$(echo "$1" | tr '[:upper:]' '[:lower:]')
fi

# If the parameter is false, check if CieSDK.xcframework exists
if [ "$param" == "false" ]; then

  if [ -d ".archives/CieSDK.xcframework" ]; then
    echo "CieSDK.xcframework exists."
    exit 0
  else
    echo "no exists"
  fi
fi

echo "building xcframework"

# Remove the old /archives folder
rm -rf .archives


# iOS Simulators
xcodebuild archive \
    -scheme CieSDK \
    -destination "generic/platform=iOS Simulator" \
    -archivePath ".archives/CieSDK-iOS-simulator.xcarchive" \
    -configuration Release \
    -sdk iphonesimulator

# iOS Devices
xcodebuild archive \
    -scheme CieSDK \
    -archivePath ".archives/CieSDK-iOS.xcarchive" \
    -destination "generic/platform=iOS" \
    -configuration Release \
    -sdk iphoneos 
    
# Build CieSDK.xcframework
xcodebuild -create-xcframework \
    -framework ".archives/CieSDK-iOS.xcarchive/Products/Library/Frameworks/CieSDK.framework" \
    -framework ".archives/CieSDK-iOS-simulator.xcarchive/Products/Library/Frameworks/CieSDK.framework" \
    -output ".archives/CieSDK.xcframework"