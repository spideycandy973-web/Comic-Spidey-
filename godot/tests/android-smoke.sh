#!/usr/bin/env bash
set -euo pipefail
apk="$1"
package=com.comicspidey.nativegame
adb install -r "$apk"
adb shell wm size 720x1280
# Avoid the OS first-use immersive-mode education dialog covering the game.
adb shell settings put secure immersive_mode_confirmations confirmed
adb logcat -c
adb shell monkey -p "$package" -c android.intent.category.LAUNCHER 1
# Allow engine startup and model import to finish on software rendering.
sleep 20
adb shell pidof "$package" >/dev/null
# Open credits from the actual Android menu, then return and choose Story.
adb exec-out screencap -p > /tmp/android-menu.png
adb shell input tap 640 225
sleep 3
adb shell input tap 640 47
sleep 3
adb shell input tap 640 339
sleep 20
# Exercise the touch buttons and movement joystick through Android, not injected Godot events.
adb shell input tap 1115 635
adb shell input swipe 100 620 100 550 1500
adb shell input swipe 1198 530 1198 530 1800
sleep 3
# Pause and resume through the touch UI.
adb shell input tap 1232 50
sleep 2
adb shell input tap 640 165
sleep 5
adb shell pidof "$package" >/dev/null
adb shell dumpsys activity activities | grep -q "$package"
adb logcat -d > /tmp/native-android-log.txt
if ! grep -q 'Native mode started: Story' /tmp/native-android-log.txt; then
  python3 - <<'PYSCREEN'
from PIL import Image
from io import BytesIO
import base64
im = Image.open('/tmp/android-menu.png').convert('RGB')
print('::notice::Android menu screenshot size %s' % (im.size,))
im.thumbnail((384,216))
b = BytesIO(); im.save(b, 'JPEG', quality=25)
s = base64.b64encode(b.getvalue()).decode()
for i in range(0,len(s),3500): print('::notice::ANDROID_SCREENSHOT_%d=%s' % (i//3500,s[i:i+3500]))
PYSCREEN
  grep -iE 'godot|comicspidey|fatal|exception' /tmp/native-android-log.txt | tail -20 | while IFS= read -r line; do echo "::notice::$line"; done
  echo '::error::Story mode did not start after the emulator touch'
  exit 1
fi
if ! grep -q 'Native attack input received' /tmp/native-android-log.txt || ! grep -q 'Native movement input received' /tmp/native-android-log.txt || ! grep -q 'Native web attached' /tmp/native-android-log.txt; then
  echo '::error::Touch attack, movement or swinging input did not reach native gameplay'
  exit 1
fi
if ! grep -q 'Native credits opened' /tmp/native-android-log.txt || ! grep -q 'Native game resumed' /tmp/native-android-log.txt; then
  echo '::error::Credits or pause/resume did not respond to Android touch'
  exit 1
fi
if grep -E 'FATAL EXCEPTION|SCRIPT ERROR|AndroidRuntime.*FATAL' /tmp/native-android-log.txt; then
  echo '::error::Android emulator reported a fatal or GDScript error'
  exit 1
fi
echo 'Android emulator installed and kept the native game running.'
