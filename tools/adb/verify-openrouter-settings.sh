#!/usr/bin/env bash
# tools/adb/verify-openrouter-settings.sh
#
# Drives the provider picker on a real handset.
#
# What this can check: that the surface exists, that switching provider
# really swaps the disclosure and the model list, that a key saved for one
# provider is not offered for the other, and whether the dialog is usable at
# the height it has grown to. Widget tests assert all of that against a
# fixed 800x600 viewport; only a phone shows what it feels like.
#
# What this deliberately does NOT do: type an API key. Entering a credential
# is the user's job, not an automated driver's.
#
#   DEVICE=<serial> bash tools/adb/verify-openrouter-settings.sh
#
# Reads exact bounds from the accessibility tree for every tap. Never taps a
# remembered coordinate: the layout shifts between screens and once, doing
# that, this driver opened somebody's mail app.
#
# KNOWN LIMITATION — this script cannot navigate to the dialog on its own.
# Two things defeat it, both in the You tab rather than in this feature:
#
#   * `uiautomator dump` truncates the tree. Scrolling the settings list
#     never reports past `settings-day-boundary`, so `settings-ai-assist` is
#     unfindable by resource-id even while it is on screen and tappable.
#   * The nested scroll has no usable middle gear. A swipe fast enough to
#     register flings past the whole band; a slower drag does not move the
#     list at all; DPAD focus traversal is inert.
#
# So the dialog has to be opened by hand, and this script run against it.
# Everything below assumes it is already on screen.

set -uo pipefail
cd "$(dirname "$0")/../.."
source tools/adb/adb-driver.sh

PKG="com.opennutritracker.ont.opennutritracker.develop"
SHOTS="${SHOTS:-/tmp/ont-openrouter-shots}"
mkdir -p "$SHOTS"
pass=0
fail=0

say() { printf '%s\n' "$*"; }

# The safety rule that matters on a real device: after every tap, confirm the
# app is still the thing in front. A tap that misses can land anywhere.
assert_focused() {
  local focus
  focus=$(adb -s "$DEVICE" shell dumpsys window 2>/dev/null |
    grep -m1 -E 'mCurrentFocus|mFocusedApp' || true)
  if [[ "$focus" != *"$PKG"* ]]; then
    say "  ABORT: focus left the app -> $focus"
    exit 1
  fi
}

shot() {
  adb -s "$DEVICE" exec-out screencap -p > "$SHOTS/$1.png" 2>/dev/null
  say "  shot: $SHOTS/$1.png"
}

# Does the current UI tree contain this resource-id?
has_id() {
  local dump
  dump=$(dump_ui)
  python3 - "$dump" "$1" <<'EOF'
import sys, xml.etree.ElementTree as ET
try:
    tree = ET.parse(sys.argv[1])
except Exception:
    sys.exit(1)
sys.exit(0 if any(n.attrib.get('resource-id','') == sys.argv[2]
                  for n in tree.getroot().iter()) else 1)
EOF
}

# Does any visible text contain this substring?
has_text() {
  local dump
  dump=$(dump_ui)
  python3 - "$dump" "$1" <<'EOF'
import sys, xml.etree.ElementTree as ET
try:
    tree = ET.parse(sys.argv[1])
except Exception:
    sys.exit(1)
needle = sys.argv[2].lower()
# Flutter surfaces its strings as content-desc, not text. Checking only
# `text` silently matches nothing and every assertion "passes" as a
# negative — which is how this script first reported a clean run against a
# screen it had never reached.
def blob(n):
    return ((n.attrib.get('text','') or '') + ' ' +
            (n.attrib.get('content-desc','') or '')).lower()
sys.exit(0 if any(needle in blob(n) for n in tree.getroot().iter()) else 1)
EOF
}

check() {
  local label="$1"; shift
  if "$@"; then
    say "  ok   $label"; ((pass++))
  else
    say "  FAIL $label"; ((fail++))
  fi
}

say "=== launching $PKG"
adb -s "$DEVICE" shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
sleep 6

if ! wait_for_id 'nav-you' 25 2>/dev/null; then
  say "=== onboarding needed"
  source tools/adb/walk-onboarding.sh
  walk_onboarding || { say "onboarding failed"; exit 1; }
  wait_for_id 'nav-you' 25 || exit 1
fi
assert_focused

say "=== opening Settings -> AI meal assistance"
tap_id 'nav-you' || exit 1
sleep 2
assert_focused
wait_for_id 'settings-ai-assist' 15 || { say "settings tile not found"; exit 1; }
tap_id 'settings-ai-assist' || exit 1
sleep 3
assert_focused
shot 01-dialog-anthropic

say "=== the provider picker exists"
check "Anthropic option present"  has_id 'ai-assist-provider-anthropic'
check "OpenRouter option present" has_id 'ai-assist-provider-openrouter'
check "key field labelled for Anthropic" has_text 'Anthropic API-Schlüssel'
check "Anthropic disclosure shown"  has_text 'an Anthropic gesendet'
check "shared sentences shown"      has_text 'Dein Tagebuch wird nie gesendet'
check "no OpenRouter wording yet"   ! has_text 'kontobezogene Kennung'
check "direct model stated"         has_text 'claude-haiku-4-5'
check "no model radios for direct"  ! has_id 'ai-assist-model-anthropic/claude-sonnet-5'

say "=== switching to OpenRouter"
tap_id 'ai-assist-provider-openrouter' || exit 1
sleep 3
assert_focused
shot 02-dialog-openrouter

check "OpenRouter disclosure shown"   has_text 'kontobezogene Kennung'
check "carve-out stated"              has_text 'rechtlicher Pflichten'
check "shared sentences still shown"  has_text 'Dein Tagebuch wird nie gesendet'
check "Anthropic-direct wording gone" ! has_text 'an Anthropic gesendet.'
check "key field relabelled"          has_text 'OpenRouter API-Schlüssel'
check "no key for this provider"      has_text 'kein Schlüssel gespeichert'
check "sonnet offered"  has_id 'ai-assist-model-anthropic/claude-sonnet-5'
check "haiku offered"   has_id 'ai-assist-model-anthropic/claude-haiku-4.5'
check "vendor named"    has_text 'Bereitgestellt von Anthropic'

say "=== choosing the cheaper model"
tap_id 'ai-assist-model-anthropic/claude-haiku-4.5' || exit 1
sleep 2
assert_focused
shot 03-model-haiku

say "=== switching back to Anthropic"
tap_id 'ai-assist-provider-anthropic' || exit 1
sleep 3
assert_focused
shot 04-back-to-anthropic
check "disclosure swapped back" has_text 'an Anthropic gesendet'
check "OpenRouter wording gone" ! has_text 'kontobezogene Kennung'

say "=== how much of the dialog fits on screen"
python3 - "$(dump_ui)" <<'EOF'
import re, sys, xml.etree.ElementTree as ET
tree = ET.parse(sys.argv[1])
root = tree.getroot()
screen = 0
for n in root.iter():
    m = re.match(r'\[(\d+),(\d+)\]\[(\d+),(\d+)\]', n.attrib.get('bounds',''))
    if m:
        screen = max(screen, int(m.group(4)))
ids = [n.attrib.get('resource-id','') for n in root.iter()]
print(f"  screen height: {screen}px")
print(f"  widgets in tree: {sum(1 for i in ids if i.startswith('ai-assist'))} ai-assist nodes")
EOF

say ""
say "=== $pass passed, $fail failed"
say "screenshots in $SHOTS"
exit $(( fail > 0 ? 1 : 0 ))
