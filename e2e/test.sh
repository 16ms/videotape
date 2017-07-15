#!/bin/bash

# Abort the mission if any command fails
set -e
set -x

E2E_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

npm run build

./e2e/test_movie.sh
./e2e/test_ios.sh
