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
  adb logcat -b crash -d > /tmp/engine-crash.log
  python3 - <<'PYLOG'
from pathlib import Path
lines=Path('/tmp/engine-check.log').read_text(errors='replace').splitlines()
selected=[x for x in lines if any(s in x.lower() for s in ['enginecheck', 'androidharness', 'com.jme3', 'fatal exception'])]
text='\n'.join(selected[-40:])+'\nCrash buffer:\n'+Path('/tmp/engine-crash.log').read_text(errors='replace')[-5000:]
print('::notice::'+text.replace('%','%25').replace('\r','%0D').replace('\n','%0A'))
PYLOG
  echo '::error::Engine did not initialize on emulator'
  exit 1
fi
echo '::notice::jMonkeyEngine 3D initialized on Android emulator'
