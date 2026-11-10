#!/usr/bin/env bash
# Exercises a CI-only APK through repeated cold starts and background/return.
# This helps expose native lifecycle crashes which a single smoke run can miss.
set -euo pipefail
apk="$1"
package=com.comicspidey.nativegame
cycles="${2:-5}"
report_crash() {
  adb logcat -b crash -d > /tmp/native-lifecycle-crash.txt || true
  adb logcat -d | grep -iE 'godot|comicspidey|fatal exception' | tail -30 > /tmp/native-lifecycle-relevant.txt || true
  python3 - <<'PY'
from pathlib import Path
s = (Path('/tmp/native-lifecycle-crash.txt').read_text(errors='replace') + '\nRecent Godot logs:\n' + Path('/tmp/native-lifecycle-relevant.txt').read_text(errors='replace'))[:3600]
print('::error::Android lifecycle crash details: ' + s.replace('%', '%25').replace('\r', '%0D').replace('\n', '%0A'))
PY
}
trap 'status=$?; if [ "$status" -ne 0 ]; then report_crash; fi' EXIT
adb uninstall "$package" >/dev/null 2>&1 || true
adb install "$apk"
adb shell wm size 720x1280
adb shell settings put secure immersive_mode_confirmations confirmed
for cycle in $(seq 1 "$cycles"); do
  adb shell am force-stop "$package"
  adb logcat -c
  adb shell monkey -p "$package" -c android.intent.category.LAUNCHER 1 >/dev/null
  ready=false
  for _ in $(seq 1 45); do
    if adb shell pidof "$package" >/dev/null; then
      adb logcat -d > /tmp/native-lifecycle-startup.txt
      if grep -q 'Native menu ready' /tmp/native-lifecycle-startup.txt; then
        ready=true
        break
      fi
    fi
    sleep 2
  done
  if [ "$ready" != true ]; then
    echo "::error::Cold launch $cycle did not reach the menu"
    exit 1
  fi
  adb shell input keyevent KEYCODE_HOME
  sleep 2
  adb shell monkey -p "$package" -c android.intent.category.LAUNCHER 1 >/dev/null
  sleep 5
  if ! adb shell pidof "$package" >/dev/null; then
    echo "::error::Application died after background/return in cycle $cycle"
    exit 1
  fi
  adb logcat -b crash -d > /tmp/native-lifecycle-check.txt
  if grep -q "$package" /tmp/native-lifecycle-check.txt; then
    echo "::error::Native crash occurred in lifecycle cycle $cycle"
    exit 1
  fi
  echo "Lifecycle cycle $cycle passed"
done
