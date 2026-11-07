#!/usr/bin/env bash
set -euo pipefail
apk="$1"
package=com.comicspidey.nativegame
adb install -r "$apk"
adb shell wm size 720x1280
adb logcat -c
adb shell monkey -p "$package" -c android.intent.category.LAUNCHER 1
# Allow engine startup and model import to finish on software rendering.
sleep 20
adb shell pidof "$package" >/dev/null
# Record the actual menu before selecting New Story on the landscape screen.
adb exec-out screencap -p > /tmp/android-menu.png
adb shell input tap 640 230
sleep 20
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
if grep -E 'FATAL EXCEPTION|SCRIPT ERROR|AndroidRuntime.*FATAL' /tmp/native-android-log.txt; then
  echo '::error::Android emulator reported a fatal or GDScript error'
  exit 1
fi
echo 'Android emulator installed and kept the native game running.'
