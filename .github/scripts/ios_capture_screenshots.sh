#!/usr/bin/env bash
#
# Capture one device class's raw store screenshots on an iOS simulator.
#
#   ios_capture_screenshots.sh <slot> <out-dir>
#
#     <slot>     iphone | ipad — only used for the expected native size and
#                for log text.
#     <out-dir>  where the raw PNGs are copied to.
#
# Environment:
#
#     CANDIDATES  '|'-separated simulator device names, in preference order.
#     BUNDLE_ID   the app's bundle identifier (must match the built flavor).
#     SCREENSHOT_FIXTURE  optional: dev (default) or onboarding.
#
# Called twice by .github/workflows/ios-screenshots.yml. Extracted into a
# script rather than inlined because the two device classes run exactly the
# same twelve steps and an inlined copy of them would drift.
#
# The two things here that are not obvious:
#
#   1. The device type is chosen from a preference list, not hardcoded.
#      Runner images add and drop simulator device types between updates, and
#      a hardcoded name turns an image refresh into a mystery failure. When
#      none of the candidates is present, this prints every device the runner
#      *does* have, which is the only thing that makes that diagnosable from
#      a log.
#
#   2. The captures are read out of the simulator's app container rather than
#      handed back over a `flutter drive` channel. That keeps the run a plain
#      `flutter test -d <udid>` — the exact command shape
#      ios-integration-attempt.yml already runs green on this image — instead
#      of adding flutter_driver and a second, unproven tool path on top of
#      everything else here that has never executed.

set -euo pipefail

SLOT="${1:?usage: ios_capture_screenshots.sh <iphone|ipad> <out-dir>}"
OUT_DIR="${2:?usage: ios_capture_screenshots.sh <iphone|ipad> <out-dir>}"
: "${CANDIDATES:?CANDIDATES must list simulator device names, '|'-separated}"
: "${BUNDLE_ID:?BUNDLE_ID must be set}"
FIXTURE="${SCREENSHOT_FIXTURE:-dev}"

case "$SLOT" in
  iphone) EXPECT_W=1290; EXPECT_H=2796; LABEL='6.9" iPhone' ;;
  ipad)   EXPECT_W=2064; EXPECT_H=2752; LABEL='13" iPad' ;;
  *) echo "Unknown slot '$SLOT' (want iphone or ipad)" >&2; exit 2 ;;
esac

echo "==> $LABEL: choosing a simulator"
UDID=$(
  CANDIDATES="$CANDIDATES" python3 -c "
import json, os, subprocess, sys

wanted = [n.strip() for n in os.environ['CANDIDATES'].split('|') if n.strip()]
data = json.loads(
    subprocess.run(
        ['xcrun', 'simctl', 'list', 'devices', 'available', '-j'],
        capture_output=True, text=True, check=True,
    ).stdout
)
available = [
    d for runtime in data['devices'].values()
    for d in runtime if d.get('isAvailable')
]
by_name = {}
for d in available:
    by_name.setdefault(d['name'], d)

for name in wanted:
    if name in by_name:
        print(by_name[name]['udid'])
        sys.exit(0)

sys.stderr.write(
    'None of the candidate device types is available on this runner.\n'
    'Wanted, in order: ' + ', '.join(wanted) + '\n'
    'Available:\n'
)
for name in sorted(by_name):
    sys.stderr.write(f'  {name}\n')
sys.exit(1)
"
)
NAME=$(xcrun simctl list devices -j | python3 -c "
import json, sys
udid = '$UDID'
data = json.load(sys.stdin)
for runtime in data['devices'].values():
    for d in runtime:
        if d['udid'] == udid:
            print(d['name'])
")
echo "    $NAME ($UDID)"

cleanup() {
  xcrun simctl shutdown "$UDID" >/dev/null 2>&1 || true
}
trap cleanup EXIT

xcrun simctl boot "$UDID"
xcrun simctl bootstatus "$UDID"

# Apple's canonical status bar. Two of the live iPhone assets show the
# simulator's `Carrier` placeholder (#1072); this is what stops that coming
# back, and it costs one command. Best-effort: if a future simulator drops
# `status_bar override` the run should still produce screenshots.
xcrun simctl status_bar "$UDID" override \
  --time '9:41' \
  --dataNetwork wifi --wifiMode active --wifiBars 3 \
  --cellularMode active --cellularBars 4 \
  --batteryState charged --batteryLevel 100 \
  || echo "::warning::simctl status_bar override failed; the status bar will be whatever the simulator felt like"

echo "==> $LABEL: running the capture test"
# --flavor full so the app carries the production bundle id and display name.
# A screenshot of a build whose app bar reads "[Alpha]" is the defect this
# whole lane replaces.
flutter test integration_test/store_screenshots_test.dart \
  -d "$UDID" \
  --flavor full \
  --dart-define=STORE_SCREENSHOTS=true \
  --dart-define="SCREENSHOT_FIXTURE=$FIXTURE" \
  --reporter expanded

echo "==> $LABEL: reading the captures out of the simulator"
SRC=""
if CONTAINER=$(xcrun simctl get_app_container "$UDID" "$BUNDLE_ID" data 2>/dev/null); then
  SRC="$CONTAINER/Documents/store_screenshots"
fi
# Fallback for the case `get_app_container` cannot resolve the bundle id —
# a flavor mismatch, or flutter_tools having uninstalled the app after the
# run. The data container survives either way, so find it by name.
if [ -z "$SRC" ] || [ ! -d "$SRC" ]; then
  echo "    app container lookup failed for $BUNDLE_ID; searching the device's data dir"
  SRC=$(find "$HOME/Library/Developer/CoreSimulator/Devices/$UDID/data/Containers/Data/Application" \
        -maxdepth 3 -type d -name store_screenshots 2>/dev/null | head -n 1 || true)
fi
if [ -z "$SRC" ] || [ ! -d "$SRC" ]; then
  echo "No captures were written. The test reported success but nothing reached" >&2
  echo "the app's Documents directory, which means the capture step never ran." >&2
  exit 1
fi

mkdir -p "$OUT_DIR"
cp "$SRC"/*.png "$OUT_DIR/"

# The compositor forces its output to the target size whatever it is handed,
# so a capture taken on the wrong device would be silently up- or downscaled
# and would still pass the Apple spec guard afterwards. That is precisely how
# a listing ends up with soft, wrong-sized assets, so check the *native*
# capture here where the device that produced it is still known.
EXPECT_W="$EXPECT_W" EXPECT_H="$EXPECT_H" OUT_DIR="$OUT_DIR" \
LABEL="$LABEL" NAME="$NAME" python3 -c "
import glob, os, struct, sys

want_w = int(os.environ['EXPECT_W'])
want_h = int(os.environ['EXPECT_H'])
files = sorted(glob.glob(os.path.join(os.environ['OUT_DIR'], '*.png')))
label = os.environ['LABEL']
name = os.environ['NAME']

if not files:
    sys.exit(f'{label}: no PNGs copied out')

bad = []
for f in files:
    head = open(f, 'rb').read(26)
    if len(head) < 26 or head[:8] != b'\x89PNG\r\n\x1a\n':
        bad.append(f'{os.path.basename(f)}: not a readable PNG')
        continue
    w, h = struct.unpack('>II', head[16:24])
    print(f'  {os.path.basename(f):24s} {w}x{h}')
    if w < want_w or h < want_h:
        bad.append(
            f'{os.path.basename(f)}: {w}x{h} is smaller than the {want_w}x{want_h} '
            f'{label} slot. Compositing would upscale it into a soft asset. '
            f'The simulator that produced this was \"{name}\".'
        )
    elif (w, h) != (want_w, want_h):
        print(f'::warning::{os.path.basename(f)} is {w}x{h}, not {want_w}x{want_h}; '
              f'it will be downscaled to fit the {label} slot')

if bad:
    sys.exit(f'{label} captures rejected:\n  ' + '\n  '.join(bad))
print(f'{len(files)} raw capture(s) OK for {label}.')
"

echo "==> $LABEL: done"
