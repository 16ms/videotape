#!/bin/bash

# Abort the mission if any command fails
set -e
set -x

defaults write ~/Library/Preferences/com.apple.iphonesimulator SimulatorWindowLastScale-com.apple.CoreSimulator.SimDeviceType.iPhone-SE "0.5"

E2E_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

npm run build

./e2e/test_movie.sh
./e2e/test_ios.sh
