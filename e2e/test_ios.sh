#!/bin/bash

MACOS_LOAD=$(ps -A -o %cpu | awk '{s+=$1} END {print s "%"}')
echo "CPU load: $MACOS_LOAD"
# run videotape with http server
node cli/videotape.js --target=Simulator --http=true &

# TODO: move to xcbuild + xctool as soon it will be ready
xcodebuild \
  -scheme VideoTapeTester \
  -configuration Release \
  -project e2e/VideoTapeTester/ios/VideoTapeTester.xcodeproj \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone SE,OS=10.3.1' \
   test | xcpretty && exit ${PIPESTATUS[0]}
