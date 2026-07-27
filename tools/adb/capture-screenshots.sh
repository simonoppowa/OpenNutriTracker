#!/usr/bin/env bash
# tools/adb/capture-screenshots.sh
#
# Shoots the README / Play Store screenshot set against a seeded build.
#
# Prerequisites:
#   1. The screenshots build installed and launched at least once, so the
#      demo fixture is seeded:
#        fvm flutter build apk --flavor develop --debug \
#          -t lib/dev/main_screenshots.dart
#        adb -s <serial> install -r build/app/outputs/flutter-apk/app-develop-debug.apk
#      or simply `just screenshots` with one device attached.
#   2. Network access — the demo food photos hotlink the Unsplash CDN
#      (see lib/core/utils/demo/unsplash_attribution.dart). Without it the
#      meal shots render grey placeholders.
#
# Usage:
#   DEVICE='<serial>' tools/adb/capture-screenshots.sh [outdir]
#
# Output: <outdir>/NN-name.png at native resolution (default /tmp/ont-shots).
# ---------------------------------------------------------------------------
set -uo pipefail

OUT_DIR="${1:-/tmp/ont-shots}"
PKG="com.opennutritracker.ont.opennutritracker.develop"
ACTIVITY="com.opennutritracker.ont.opennutritracker.MainActivity"

source "$(dirname "$0")/adb-driver.sh"
mkdir -p "$OUT_DIR"

_adb() { adb -s "$DEVICE" "$@"; }

# Running against a real phone is fine and is in fact what the shipped set was
# shot on: the develop flavour carries an applicationIdSuffix, so $PKG is a
# second app that cannot see — let alone reseed — the production install's
# data. What *is* destructive is running it against a device where $PKG is
# someone's actual tracker, so refuse if the seeded demo profile isn't there.
if ! _adb shell pm list packages | grep -q "^package:$PKG$"; then
  echo "$PKG is not installed on '$DEVICE'." >&2
  echo "build and install it first (see the header), or run 'just screenshots'." >&2
  exit 1
fi

# Screen geometry, so the swipe distances below work on any panel. The Pixel 6
# used for the shipped set is 1080x2400; the Pixel_10_Pro AVD is 1280x2856.
read -r SCREEN_W SCREEN_H < <(
  _adb shell wm size | sed -n 's/.*: \([0-9]*\)x\([0-9]*\).*/\1 \2/p' | tail -1
)
: "${SCREEN_W:=1080}" "${SCREEN_H:=2400}"
MID_X=$((SCREEN_W / 2))

# --- status bar ------------------------------------------------------------
# Pin the clock, battery and signal so all shots match and carry no
# notification clutter. Restored by demo_exit on exit.
demo_enter() {
  _adb shell settings put global sysui_demo_allowed 1
  local c="am broadcast -a com.android.systemui.demo"
  _adb shell $c -e command clock -e hhmm 0930 >/dev/null
  _adb shell $c -e command battery -e level 100 -e plugged false >/dev/null
  _adb shell $c -e command network -e wifi show -e level 4 >/dev/null
  _adb shell $c -e command network -e mobile show -e level 4 -e datatype none >/dev/null
  _adb shell $c -e command notifications -e visible false >/dev/null
}
demo_exit() {
  _adb shell am broadcast -a com.android.systemui.demo -e command exit >/dev/null 2>&1
}
trap demo_exit EXIT

# --- helpers ---------------------------------------------------------------
# A mistyped anchor makes tap_id fall back to coordinates that may land on the
# navigation bar, and a stray tap can throw the app to the launcher — after
# which every later "tap" quietly drives whatever is on screen instead. Check
# we are still in our own app before trusting anything that follows.
guard() {
  local top
  top=$(_adb shell dumpsys activity activities | grep -m1 topResumedActivity)
  if [[ "$top" != *"$PKG"* ]]; then
    echo "FOCUS LOST — expected $PKG, got:" >&2
    echo "  $top" >&2
    exit 1
  fi
}

shot() {
  local name="$1"
  sleep 1.2                       # let animations settle before the grab
  guard
  screenshot "$OUT_DIR/$name.png" >/dev/null
  printf '  captured %s\n' "$name"
}

# Swipe up (content scrolls down) by roughly a third of screen height.
scroll_down() {
  local times="${1:-1}"
  for ((i = 0; i < times; i++)); do
    _adb shell input swipe "$MID_X" $((SCREEN_H * 80 / 100)) "$MID_X" $((SCREEN_H * 45 / 100)) 320
    sleep 0.6
  done
  guard
}

scroll_up() {
  local times="${1:-1}"
  for ((i = 0; i < times; i++)); do
    _adb shell input swipe "$MID_X" $((SCREEN_H * 45 / 100)) "$MID_X" $((SCREEN_H * 80 / 100)) 320
    sleep 0.6
  done
  guard
}

relaunch() {
  _adb shell am force-stop "$PKG"
  sleep 1
  _adb shell am start -n "$PKG/$ACTIVITY" >/dev/null
  sleep 6                         # splash + seed read
  guard
}

echo "capturing to $OUT_DIR (device $DEVICE, ${SCREEN_W}x${SCREEN_H})"
demo_enter
relaunch

# 1 — Home: the ring part-consumed, macros part-filled, a real breakfast
tap_id 'nav-home' 2>/dev/null
shot '01-home'

# 2 — Add food: the recently-added quick-log list (needs no search backend)
tap_id 'fab-add-item'; sleep 1.5; guard
tap_id 'add-item-lunch' 2>/dev/null; sleep 2.5
shot '02-add-food'

# 3 — Meal detail, scrolled to the expanded micronutrient block
_tap_text 'Salmon fillet' 2>/dev/null || _tap_text 'Greek yogurt' 2>/dev/null
sleep 2.5; guard
scroll_down 2
shot '03-meal-detail'

# Back out by relaunching rather than counting press_back calls: the detail
# page and the add sheet do not always take the same number of pops, and one
# back too many lands on the launcher, after which every later "tap" drives
# whatever is on screen instead of the app.
relaunch

# 4 — Diary: a month coloured by rating, a logged day selected
tap_id 'nav-diary'; sleep 2
shot '04-diary'

# 5 — Trends: streak, calorie curve against the dashed goal, weight trending
tap_id 'nav-trends'; sleep 2.5
shot '05-trends'

# 6 — You: profile header, BMI ring, goal and weight cards
tap_id 'nav-you'; sleep 2
shot '06-you'

echo
echo "done — $(ls -1 "$OUT_DIR"/*.png 2>/dev/null | wc -l) files in $OUT_DIR"
echo "open each one and check it against the table in the plan before shipping."
