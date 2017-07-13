#!/bin/bash

vlc --noaudio --width=300 --no-repeat --quiet --play-and-exit ./e2e/60fps_test.mov &
sleep 0.5s # give time VLC to open, would be better to handle this inside the app
SCORE=$(videotape --target=VLC --autorun=true | node e2e/extractScores.js)
echo "Score tests comparison result: $SCORE"
if [ "0.9" == "$SCORE" ]; then
    exit 0;
fi
exit 1;
