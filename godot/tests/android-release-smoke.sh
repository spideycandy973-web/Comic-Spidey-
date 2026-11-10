#!/usr/bin/env bash
# CI-only: this APK is signed with a temporary key, not the release key.
set -euo pipefail
apk="$1"
package=com.comicspidey.nativegame
on_error() {
  local code=$? line=$1
  trap - ERR
  set +e
  echo "::error::Release-template emulator check failed at line $line (exit $code)"
  crash=$(adb logcat -b crash -d | head -35 | sed -e 's/%/%25/g' -e 's//%0D/g' | awk '{printf "%s%%0A", $0}')
  echo "::error::Crash details: $crash"
  adb logcat -d | grep -iE 'godot|comicspidey|fatal exception' | tail -20 | while IFS= read -r text; do echo "::notice::$text"; done
  exit "$code"
}
trap 'on_error "$LINENO"' ERR
# Debug and release test builds use different keys; start from a clean install.
adb uninstall "$package" || true
adb install "$apk"
adb shell wm size 720x1280
adb shell settings put secure immersive_mode_confirmations confirmed
adb logcat -c
adb shell monkey -p "$package" -c android.intent.category.LAUNCHER 1
ready=false
for _ in $(seq 1 45); do
  if adb shell pidof "$package" >/dev/null; then
    adb logcat -d > /tmp/native-startup.log
    if grep -q 'Native menu ready' /tmp/native-startup.log; then
      ready=true
      break
    fi
  fi
  sleep 2
done
if [ "$ready" != true ]; then
  echo '::error::Release-template menu did not become ready within 90 seconds'
  false
fi
sleep 2
# New Story from the menu; exercise a jump and movement on the release template.
adb shell input tap 640 339
sleep 20
adb shell input tap 1208 635
adb shell input swipe 100 620 100 550 1500
sleep 3
adb shell pidof "$package" >/dev/null
adb shell dumpsys activity activities | grep -q "$package"
adb logcat -d > /tmp/release-template-log.txt
if ! grep -q 'Native mode started: Story' /tmp/release-template-log.txt; then
  echo '::error::Release-template Story did not start after touch'
  exit 1
fi
if grep -E 'FATAL EXCEPTION|SCRIPT ERROR|AndroidRuntime.*FATAL' /tmp/release-template-log.txt; then
  echo '::error::Release-template app reported an error'
  exit 1
fi
echo 'Release-template CI build installed and launched; temporary key only.'
