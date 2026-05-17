#!/usr/bin/env bash
# tools/adb/adb-driver.sh
#
# ADB UI driver for OpenNutriTracker.
#
# Finds Flutter widgets via the `resource-id` attribute (set by
# `Semantics(identifier:)` in the app) and drives them with
# `adb shell input tap` / `input text`.
#
# Source this from other scripts:
#   source "$(dirname "$0")/adb-driver.sh"
#   tap_id 'nav-profile'
#   enter_text_at 'onboarding-height-field' '170'
#
# Required env (set by sourcing script, or uses default):
#   DEVICE — adb device serial (default: first connected device)
#
# Dependencies: adb, python3 (stdlib only)
# ---------------------------------------------------------------------------

DEVICE="${DEVICE:-$(adb devices | awk '/device$/{print $1; exit}')}"
DUMP_PATH="/sdcard/window_dump.xml"
LOCAL_DUMP="/tmp/ont-window-dump.xml"

# Dump the current UI tree to /tmp/ont-window-dump.xml and echo the local path.
dump_ui() {
  adb -s "$DEVICE" shell uiautomator dump "$DUMP_PATH" > /dev/null 2>&1
  adb -s "$DEVICE" pull "$DUMP_PATH" "$LOCAL_DUMP" > /dev/null 2>&1
  echo "$LOCAL_DUMP"
}

# Print the center (x y) coordinates of the widget with the given resource-id,
# or empty string if not found.
_center_of_id() {
  local id="$1"
  local dump_file
  dump_file=$(dump_ui)

  python3 <<EOF
import re, sys, xml.etree.ElementTree as ET
try:
    tree = ET.parse("$dump_file")
except Exception:
    sys.exit(0)
for n in tree.getroot().iter():
    if n.attrib.get('resource-id', '') == "$id":
        m = re.match(r'\[(\d+),(\d+)\]\[(\d+),(\d+)\]', n.attrib.get('bounds', ''))
        if m:
            x1, y1, x2, y2 = (int(g) for g in m.groups())
            print(f"{(x1+x2)//2} {(y1+y2)//2}")
        sys.exit(0)
EOF
}

# Tap the widget with the given resource-id. Returns 1 if not found.
# Usage: tap_id 'nav-profile'
tap_id() {
  local id="$1"
  local coords
  coords=$(_center_of_id "$id")
  if [[ -z "$coords" ]]; then
    echo "tap_id: '$id' not found in current UI tree" >&2
    return 1
  fi
  adb -s "$DEVICE" shell input tap $coords
}

# Wait up to N seconds for a widget with the given resource-id to appear.
# Re-dumps the UI tree every second.
# Usage: wait_for_id 'nav-home' 20
wait_for_id() {
  local id="$1"
  local timeout="${2:-15}"
  local start=$SECONDS
  while (( SECONDS - start < timeout )); do
    local coords
    coords=$(_center_of_id "$id")
    if [[ -n "$coords" ]]; then
      return 0
    fi
    sleep 1
  done
  echo "wait_for_id: timed out waiting for '$id' after ${timeout}s" >&2
  return 1
}

# Tap a widget and type text into it (assumes it's a text field).
# Spaces in text must be escaped as %s — adb shell input text limitation.
# Usage: enter_text_at 'onboarding-height-field' '170'
enter_text_at() {
  local id="$1"
  local text="$2"
  tap_id "$id" || return 1
  sleep 0.5
  adb -s "$DEVICE" shell input text "${text// /%s}"
}

# Tap a widget by its visible text or content-desc.
# Flutter widgets expose labels via content-desc; system dialogs use text.
# Checks both so this works for native dialogs (DatePicker OK) and Flutter.
# Usage: _tap_text 'OK'
_tap_text() {
  local needle="$1"
  local dump_file
  dump_file=$(dump_ui)
  local coords
  coords=$(python3 <<EOF
import re, sys, xml.etree.ElementTree as ET
tree = ET.parse("$dump_file")
for n in tree.getroot().iter():
    if n.attrib.get('text', '') == "$needle" or n.attrib.get('content-desc', '') == "$needle":
        m = re.match(r'\[(\d+),(\d+)\]\[(\d+),(\d+)\]', n.attrib.get('bounds', ''))
        if m:
            x1, y1, x2, y2 = (int(g) for g in m.groups())
            print(f"{(x1+x2)//2} {(y1+y2)//2}")
            sys.exit(0)
EOF
)
  if [[ -z "$coords" ]]; then
    return 1
  fi
  adb -s "$DEVICE" shell input tap $coords
}

# Press the device back button.
press_back() {
  adb -s "$DEVICE" shell input keyevent 4
}

# Press the home button.
press_home() {
  adb -s "$DEVICE" shell input keyevent 3
}

# Take a screenshot. Prints the output path.
# Usage: screenshot /tmp/foo.png
screenshot() {
  local out="${1:-/tmp/ont-screenshot-$(date +%s).png}"
  adb -s "$DEVICE" exec-out screencap -p > "$out"
  echo "$out"
}

# Return 0 if a widget with the given resource-id is visible.
# Usage: id_exists 'nav-profile' && echo "on main screen"
id_exists() {
  local coords
  coords=$(_center_of_id "$1")
  [[ -n "$coords" ]]
}

# Print all resource-ids currently visible (useful for debugging).
list_ids() {
  local dump_file
  dump_file=$(dump_ui)
  python3 <<EOF
import xml.etree.ElementTree as ET
tree = ET.parse("$dump_file")
for n in tree.getroot().iter():
    rid = n.attrib.get('resource-id', '')
    if rid:
        print(rid)
EOF
}

# Print the on-screen centre coords of the first EditText whose `hint`
# attribute equals the needle. Flutter's TextField / TextFormField
# widgets don't typically carry a `resource-id`, but uiautomator dumps
# their placeholder text as `hint`, so this is the most reliable way to
# locate a form field without sprinkling Semantics identifiers across
# every input. Returns nothing (and exits non-zero) when not found.
_center_of_hint() {
  local needle="$1"
  local dump_file
  dump_file=$(dump_ui)
  python3 <<EOF
import re, sys, xml.etree.ElementTree as ET
tree = ET.parse("$dump_file")
for n in tree.getroot().iter():
    if 'EditText' not in n.attrib.get('class', ''):
        continue
    if n.attrib.get('hint', '') != "$needle":
        continue
    m = re.match(r'\[(\d+),(\d+)\]\[(\d+),(\d+)\]', n.attrib.get('bounds', ''))
    if m:
        x1, y1, x2, y2 = (int(g) for g in m.groups())
        print(f"{(x1+x2)//2} {(y1+y2)//2}")
        sys.exit(0)
sys.exit(1)
EOF
}

# Tap an EditText by its placeholder hint, re-dumping the UI first.
# Use this for Flutter form fields whose bounds shift between taps
# (a keyboard popping up rearranges the layout under the field you're
# about to tap, so cached coordinates from an earlier dump go stale).
#
# If the field isn't in the current viewport, the helper scrolls the
# form down (up to `max_scrolls` times) looking for it. Forms longer
# than one screen — custom meal create, recipe builder, settings —
# regularly hide fields below the fold after a keyboard close, and
# uiautomator's dump only includes nodes that are actually rendered.
#
# Usage: tap_field_by_hint 'Meal name'
tap_field_by_hint() {
  local needle="$1"
  local max_scrolls="${2:-5}"
  local coords
  for ((attempt=0; attempt<=max_scrolls; attempt++)); do
    coords=$(_center_of_hint "$needle")
    if [[ -n "$coords" ]]; then
      adb -s "$DEVICE" shell input tap $coords
      return 0
    fi
    # Scroll the form upward (drag the screen contents up so lower
    # fields rise into view). Anchor near the bottom of the safe
    # area for the from-coord and stop above the soft-nav region for
    # the to-coord so the swipe doesn't get intercepted.
    adb -s "$DEVICE" shell input swipe 720 2400 720 1200 200
    sleep 0.4
  done
  echo "tap_field_by_hint: no EditText with hint '$needle' after $max_scrolls scrolls" >&2
  return 1
}

# Hide the on-screen keyboard. KEYCODE_BACK (4) is the only reliable way
# to close a soft keyboard on modern Android — KEYCODE_ESCAPE (111) is
# documented as "close keyboard" but several stock IMEs (including the
# Pixel keyboard the test rig uses) ignore it, leaving the keyboard up
# and turning subsequent scroll gestures into spurious taps on the
# suggestion bar. BACK doubles as "navigate up" when the keyboard isn't
# up, so only call this immediately after typing — never as a generic
# screen reset.
hide_keyboard() {
  adb -s "$DEVICE" shell input keyevent 4
}

# Erase the contents of the currently-focused text field. Moves the
# cursor to the end of the line then sends `max_chars` deletes. The
# default of 200 is enough for any sane form input — empty fields are a
# no-op so over-deleting costs nothing.
clear_focused_field() {
  local max_chars="${1:-200}"
  adb -s "$DEVICE" shell input keyevent KEYCODE_MOVE_END
  for ((i=0; i<max_chars; i++)); do
    adb -s "$DEVICE" shell input keyevent 67 > /dev/null 2>&1
  done
}

# Enter `text` into the EditText with the given `hint`. Re-dumps the UI
# before locating the field (so coordinates are fresh), taps the field,
# optionally clears any existing content, types, and hides the keyboard
# so the next field's coordinates aren't shifted by an open IME.
#
# Spaces in `text` should be passed as %s — same convention as
# `enter_text_at` and the underlying `adb shell input text`.
#
# Usage:
#   enter_text_in_field 'Meal name' 'Greek%syoghurt'
#   enter_text_in_field 'Energy (kcal)' '100' clear
enter_text_in_field() {
  local hint="$1"
  local text="$2"
  local mode="${3:-keep}"  # keep | clear
  tap_field_by_hint "$hint" || return 1
  sleep 0.4
  if [[ "$mode" == "clear" ]]; then
    clear_focused_field
    sleep 0.2
  fi
  adb -s "$DEVICE" shell input text "$text"
  sleep 0.2
  hide_keyboard
  sleep 0.4
}

# Fill an arbitrary sequence of (hint, value) pairs in one call. Re-dumps
# before each field, taps, types, and hides the keyboard between them so
# the next field's hit-target isn't sitting under a stale layout. The
# pairs are positional: hint1 val1 hint2 val2 hint3 val3 ...
#
# Usage:
#   fill_fields_by_hint \
#     'Meal name'       'Greek%syoghurt' \
#     'Energy (kcal)'   '100' \
#     'Carbohydrates'   '4' \
#     'Fat'             '5' \
#     'Protein'         '10'
fill_fields_by_hint() {
  while (( $# >= 2 )); do
    local hint="$1"
    local value="$2"
    shift 2
    if ! enter_text_in_field "$hint" "$value"; then
      echo "fill_fields_by_hint: failed on field '$hint'" >&2
      return 1
    fi
  done
}
