#!/usr/bin/env bash
set -euo pipefail
apk="$1"
portrait_width="${2:-720}"
portrait_height="${3:-1280}"
mode="${4:-Story}"
package=com.comicspidey.nativegame
# The expanded 720-high logical viewport fills wide landscape screens.
# Menu controls are centered; gameplay buttons are anchored to the edges.
tap_center() { adb shell input tap "$(( portrait_height / 2 ))" "$(( $1 * portrait_width / 720 ))"; }
tap_right() { adb shell input tap "$(( portrait_height - $1 * portrait_width / 720 ))" "$(( $2 * portrait_width / 720 ))"; }
swipe_left() { adb shell input swipe "$(( $1 * portrait_width / 720 ))" "$(( $2 * portrait_width / 720 ))" "$(( $3 * portrait_width / 720 ))" "$(( $4 * portrait_width / 720 ))" "$5"; }
swipe_right() { adb shell input swipe "$(( portrait_height - $1 * portrait_width / 720 ))" "$(( $2 * portrait_width / 720 ))" "$(( portrait_height - $3 * portrait_width / 720 ))" "$(( $4 * portrait_width / 720 ))" "$5"; }
on_error() {
  local code=$? line=$1
  trap - ERR
  set +e
  echo "::error::Android smoke command failed at line $line (exit $code)"
  adb shell pidof "$package" | while IFS= read -r text; do echo "::notice::App PID: $text"; done
  adb shell dumpsys activity activities | grep -iE 'mResumedActivity|topResumedActivity|comicspidey' | tail -8 | while IFS= read -r text; do echo "::notice::$text"; done
  adb logcat -b crash -d > /tmp/android-smoke-crash.txt
  python3 - <<'PYCRASH'
from pathlib import Path
s = Path('/tmp/android-smoke-crash.txt').read_text(errors='replace')[:3400]
print('::error::Android crash details: ' + s.replace('%', '%25').replace('\r', '%0D').replace('\n', '%0A'))
PYCRASH
  adb logcat -d | grep -iE 'fatal exception|androidruntime|godot|comicspidey|lowmemorykiller|lmkd' | tail -25 | while IFS= read -r text; do echo "::notice::$text"; done
  exit "$code"
}
trap 'on_error "$LINENO"' ERR
adb install -r "$apk"
adb shell pm clear "$package" >/dev/null
adb shell wm size "${portrait_width}x${portrait_height}"
# Avoid the OS first-use immersive-mode education dialog covering the game.
adb shell settings put secure immersive_mode_confirmations confirmed
adb logcat -c
adb shell monkey -p "$package" -c android.intent.category.LAUNCHER 1
# Slow software emulators sometimes need more than a fixed startup delay.
# Wait for the game to finish initialization, with a bounded timeout.
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
  echo '::error::Native menu did not become ready within 90 seconds'
  false
fi
sleep 2
# Open credits from the actual Android menu, then return and choose the mode.
adb exec-out screencap -p > /tmp/android-menu.png
# Check the actual graphics menu on Android; restore defaults after exercising it.
tap_center 513
sleep 2
tap_center 210
sleep 1
tap_center 268
sleep 1
tap_center 326
sleep 1
tap_center 384
sleep 2
tap_center 210
sleep 1
tap_center 210
sleep 1
tap_center 268
sleep 1
tap_center 326
sleep 1
tap_center 384
sleep 2
# Exercise and restore the city mood, then leave graphics settings.
tap_center 442
sleep 2
tap_center 442
sleep 2
tap_center 500
sleep 2
tap_center 225
sleep 3
tap_center 47
sleep 3
if [ "$mode" = "Free Roam" ]; then tap_center 397; else tap_center 339; fi
sleep 20
# Exercise the touch buttons and movement joystick through Android, not injected Godot events.
tap_right 177 645
swipe_left 100 620 100 550 1500
swipe_right 68 515 68 515 1800
sleep 3
# Pause and resume through the touch UI.
tap_right 48 50
sleep 2
tap_center 165
sleep 5
adb shell pidof "$package" >/dev/null
adb shell dumpsys activity activities | grep -q "$package"
adb logcat -d > /tmp/native-android-log.txt
if ! grep -q "Native mode started: $mode" /tmp/native-android-log.txt; then
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
  for marker in 'Native mode started:' 'Native attack input received' 'Native movement input received' 'Native web attached' 'Native credits opened' 'Native game resumed'; do
    if grep -q "$marker" /tmp/native-android-log.txt; then echo "::notice::$mode ${portrait_height}x${portrait_width}: received $marker"; else echo "::error::$mode ${portrait_height}x${portrait_width}: missing $marker"; fi
  done
  adb exec-out screencap -p > /tmp/android-input.png
  python3 - <<'PYSCREEN'
from PIL import Image
from io import BytesIO
import base64
im = Image.open('/tmp/android-input.png').convert('RGB'); im.thumbnail((384,216))
b = BytesIO(); im.save(b, 'JPEG', quality=20)
s = base64.b64encode(b.getvalue()).decode()
for i in range(0,len(s),3500): print('::notice::ANDROID_INPUT_SCREENSHOT_%d=%s' % (i//3500,s[i:i+3500]))
PYSCREEN
  echo '::error::Touch attack, movement or swinging input did not reach native gameplay'
  exit 1
fi
for option in scale msaa shadows fps city; do
  if ! grep -q "Native graphics changed: $option" /tmp/native-android-log.txt; then
    echo "::error::Graphics setting $option did not respond to Android touch"
    exit 1
  fi
done
if ! grep -q 'Native credits opened' /tmp/native-android-log.txt || ! grep -q 'Native game resumed' /tmp/native-android-log.txt; then
  echo '::error::Credits or pause/resume did not respond to Android touch'
  exit 1
fi
if grep -E 'FATAL EXCEPTION|SCRIPT ERROR|AndroidRuntime.*FATAL' /tmp/native-android-log.txt; then
  echo '::error::Android emulator reported a fatal or GDScript error'
  exit 1
fi
echo 'Android emulator installed and kept the native game running.'
