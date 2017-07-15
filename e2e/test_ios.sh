#!/bin/bash

# run videotape with http server
node cli/videotape.js --target=Simulator --http=true &

# TODO: move to xcbuild + xctool
xcodebuild \
  -scheme VideoTapeTester \
  -configuration Release \
  -project e2e/VideoTapeTester/ios/VideoTapeTester.xcodeproj \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone SE,OS=10.3.1' \
  build test
