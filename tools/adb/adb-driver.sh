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
