#!/bin/bash

param="false"
# Check if the parameter is passed
if [ -z "$1" ]; then
    echo "run without parameters.. default don't rebuild if exists"
else
    param=$(echo "$1" | tr '[:upper:]' '[:lower:]')
fi

# If the parameter is false, check if IOWalletCIE.xcframework exists
if [ "$param" == "false" ]; then

  if [ -d ".archives/IOWalletCIE.xcframework" ]; then
    echo "IOWalletCIE.xcframework exists."
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
    -scheme IOWalletCIE \
    -destination "generic/platform=iOS Simulator" \
    -archivePath ".archives/IOWalletCIE-iOS-simulator.xcarchive" \
    -configuration Release \
    -sdk iphonesimulator

# iOS Devices
xcodebuild archive \
    -scheme IOWalletCIE \
    -archivePath ".archives/IOWalletCIE-iOS.xcarchive" \
    -destination "generic/platform=iOS" \
    -configuration Release \
    -sdk iphoneos 
    
# Build IOWalletCIE.xcframework
xcodebuild -create-xcframework \
    -framework ".archives/IOWalletCIE-iOS.xcarchive/Products/Library/Frameworks/IOWalletCIE.framework" \
    -framework ".archives/IOWalletCIE-iOS-simulator.xcarchive/Products/Library/Frameworks/IOWalletCIE.framework" \
    -output ".archives/IOWalletCIE.xcframework"