#!/usr/bin/env node
const RELEASE = process.env.NODE_ENV === 'production' || true;

const cliArgs = process.argv.slice(2);

const { spawn, execSync } = require('child_process');
const argv = require('./argv');
const fs = require('fs');
const path = require('path');

function getPathToBinary() {
  if (!RELEASE) {
    /*
     * run:
     * xcodebuild -showBuildSettings -configuration Debug -project macos/VideoTape.xcodeproj | grep TARGET_BUILD_DIR
     */
    return '/Users/ptmt/Library/Developer/Xcode/DerivedData/VideoTape-hldagcwzsplsyocceiosnlryfvcv/Build/Products/Debug/VideoTape.app/Contents/MacOS/VideoTape';
  }
  return path.join(
    path.dirname(fs.realpathSync(process.argv[1])),
    '..',
    'build',
    'VideoTape.app',
    'Contents',
    'MacOS',
    'VideoTape'
  );
}

const pathToBinary = getPathToBinary();

try {
  fs.accessSync(pathToBinary, fs.F_OK);
} catch (e) {
  console.error('VideoTape binary is not located in', pathToBinary);
  process.exit(1);
}

const vt = spawn(pathToBinary, [JSON.stringify(argv)]);

vt.stdout.on('data', data => {
  console.log(`${data}`);
});

vt.stderr.on('data', data => {
  if (argv.verbose) {
    console.error(`debug: ${data}`);
  }
});

vt.on('close', code => {
  if (code) {
    console.log(`VideoTape process exited with code ${code}`);
  }
  process.exit(code || 0);
});
