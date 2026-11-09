#!/usr/bin/env bash
set -euo pipefail
apk=$(find "$GITHUB_WORKSPACE/engine-check/jme/build/outputs/apk/debug" -name '*.apk' -print -quit)
if [ -z "$apk" ]; then echo '::error::Probe APK not found'; exit 1; fi
adb install "$apk"
adb logcat -c
adb shell am start -n org.example.enginecheck/.MainActivity
sleep 25
adb logcat -d > /tmp/engine-check.log
if ! adb shell pidof org.example.enginecheck || ! grep -q 'jMonkeyEngine 3D initialized' /tmp/engine-check.log; then
  grep -iE 'fatal exception|androidruntime|jmonkey|enginecheck|exception|error' /tmp/engine-check.log | tail -35 | while IFS= read -r line; do echo "::notice::$line"; done
  echo '::error::Engine did not initialize on emulator'
  exit 1
fi
echo '::notice::jMonkeyEngine 3D initialized on Android emulator'
