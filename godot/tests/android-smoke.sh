#!/usr/bin/env bash
set -euo pipefail
apk="$1"
package=com.comicspidey.nativegame
adb install -r "$apk"
adb logcat -c
adb shell am start -n "$package/org.godotengine.godot.GodotApp"
# Allow engine startup and model import to finish on software rendering.
sleep 20
adb shell pidof "$package" >/dev/null
# Default emulator runs landscape after Godot starts; choose New Story.
adb shell input tap 640 300
sleep 20
adb shell pidof "$package" >/dev/null
adb shell dumpsys activity activities | grep -q "$package"
adb logcat -d > /tmp/native-android-log.txt
if grep -E 'FATAL EXCEPTION|SCRIPT ERROR|AndroidRuntime.*FATAL' /tmp/native-android-log.txt; then
  echo '::error::Android emulator reported a fatal or GDScript error'
  exit 1
fi
echo 'Android emulator installed and kept the native game running.'
