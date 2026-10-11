#!/usr/bin/env bash
# docs/settings-test/tools/st.sh — guarded adb driver for the settings run (#1343).
#
# Run it as a command, one action per call (no `source` needed):
#
#   ST=docs/settings-test/tools/st.sh
#   bash $ST tap id=settings-food-units
#   bash $ST tap text=OK
#   bash $ST ls
#
# Every action that touches the screen (tap, tapxy, slider, type, key, done,
# back, swipe, scroll_to, restart) re-reads `mCurrentFocus` afterwards and
# exits 99 if the focused window is not the app. Exit 99 means STOP: write
# down what was on screen, do not press anything, ask the maintainer.
# During a HAND-OFF, call `ST_HANDOFF=1 bash $ST focus` to look without
# aborting.
#
# It reuses tools/adb/adb-driver.sh from the repo (tap_id, wait_for_id,
# screenshot, list_ids) with two overrides:
#   * dump_ui streams the hierarchy over `exec-out ... /dev/tty`, so nothing is
#     written to the phone's shared storage;
#   * press_home refuses. HOME is never sent in this run.
# `key` takes only an allowlist (ENTER, DEL, MOVE_END/HOME, TAB, DPAD left/right),
# and `back` refuses while the main screen itself is showing.
#
# Selectors (see ui.py): id=RID | text=EXACT | text^=PREFIX | text~=PART |
# edit=N (N-th text field top to bottom), optionally suffixed @K for the K-th
# match.
# ---------------------------------------------------------------------------

ST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ST_REPO="$(cd "$ST_DIR/../../.." && pwd)"
UI_PY="$ST_DIR/ui.py"

ADB_BIN="${ADB_BIN:-$HOME/Android/Sdk/platform-tools/adb}"
# Always the USB serial. The same phone also lists over adb-tls under a
# different name; the driver must never pick "the first device".
DEVICE="18101FDF60010M"
PKG="com.opennutritracker.ont.opennutritracker"
ACT="$PKG/.MainActivity"
# The evidence folder is pinned once in preflight (`init`) so a run that
# crosses midnight keeps writing to the same place.
ST_CURRENT="$HOME/Documents/ont-settings-test-evidence/current-run"
if [[ -z "${EVID:-}" ]]; then
  if [[ -f "$ST_CURRENT" ]]; then EVID="$(cat "$ST_CURRENT")"
  else EVID="$HOME/Documents/ont-settings-test-evidence/run-$(date +%F)"; fi
fi
LOCAL_DUMP="$EVID/.dump.xml"
[[ -d "$EVID" ]] && mkdir -p "$EVID/shots" "$EVID/dumps"

adb() { "$ADB_BIN" "$@"; }

# shellcheck source=../../../tools/adb/adb-driver.sh
. "$ST_REPO/tools/adb/adb-driver.sh"
DEVICE="18101FDF60010M"          # the driver may have set its own default
LOCAL_DUMP="$EVID/.dump.xml"

# Override: stream the dump instead of writing /sdcard/window_dump.xml.
dump_ui() {
  adb -s "$DEVICE" exec-out uiautomator dump /dev/tty > "$LOCAL_DUMP" 2>/dev/null
  if ! grep -q "</hierarchy>" "$LOCAL_DUMP"; then
    # Rare "null root node" while an animation runs: wait and retry once.
    sleep 1
    adb -s "$DEVICE" exec-out uiautomator dump /dev/tty > "$LOCAL_DUMP" 2>/dev/null
  fi
  echo "$LOCAL_DUMP"
}

press_home() {
  echo "st.sh: HOME is never sent in this run (refused)." >&2
  return 98
}

_log() { printf '%s  %s\n' "$(date +%T)" "$*" >> "$EVID/run.log"; }

# --- focus guard ------------------------------------------------------------

focus_window() {
  adb -s "$DEVICE" shell dumpsys window 2>/dev/null | grep -m1 'mCurrentFocus' | sed 's/^ *//'
}

guard() {
  local win
  for _ in 1 2 3 4; do
    win="$(focus_window)"
    case "$win" in
      *" $PKG/"*|*"{"*" $PKG/"*) return 0 ;;
      *"=null"*|"") sleep 0.7 ;;      # activity transition; look again
      *) break ;;
    esac
  done
  if [[ "${ST_HANDOFF:-0}" == 1 ]]; then
    echo "focus (hand-off, not aborting): $win"
    return 0
  fi
  echo "FOCUS LEFT THE APP: $win" >&2
  echo "STOP. Do not press anything. Screenshot follows; ask the maintainer." >&2
  adb -s "$DEVICE" exec-out screencap -p > "$EVID/shots/focus-lost-$(date +%H%M%S).png"
  _log "FOCUS LOST: $win"
  exit 99
}

# --- reading the screen -----------------------------------------------------

cmd_focus() { focus_window; guard; }

cmd_ls() { dump_ui >/dev/null; python3 -I "$UI_PY" ls "$LOCAL_DUMP"; }

cmd_get() { dump_ui >/dev/null; python3 -I "$UI_PY" get "$LOCAL_DUMP" "$1"; }

cmd_has() {   # exit 0 if the selector is on screen now
  dump_ui >/dev/null
  python3 -I "$UI_PY" find "$LOCAL_DUMP" "$1" >/dev/null
}

cmd_wait() {  # wait SELECTOR [seconds]
  local sel="$1" t="${2:-15}" start=$SECONDS
  while (( SECONDS - start < t )); do
    cmd_has "$sel" && return 0
    sleep 1
  done
  echo "wait: '$sel' not on screen after ${t}s" >&2
  return 1
}

cmd_save() {  # save NAME: keep the current dump and its listing as evidence
  dump_ui >/dev/null
  cp "$LOCAL_DUMP" "$EVID/dumps/$1.xml"
  python3 -I "$UI_PY" ls "$LOCAL_DUMP" > "$EVID/dumps/$1.txt"
  echo "$EVID/dumps/$1.txt"
}

cmd_shot() {  # shot NAME
  adb -s "$DEVICE" exec-out screencap -p > "$EVID/shots/$1.png"
  echo "$EVID/shots/$1.png"
}

cmd_pixel() { # pixel SHOTNAME X Y   (reads a screenshot taken with `shot`)
  python3 -I "$UI_PY" pixel "$EVID/shots/$1.png" "$2" "$3"
}

# --- acting on the screen ---------------------------------------------------

_center() {
  dump_ui >/dev/null
  python3 -I "$UI_PY" find "$LOCAL_DUMP" "$1"
}

cmd_tap() {   # tap SELECTOR
  local xy
  xy="$(_center "$1")" || { echo "tap: '$1' not on screen" >&2; return 1; }
  adb -s "$DEVICE" shell input tap $xy
  _log "tap $1 @ $xy"
  sleep 0.8
  guard
}

cmd_tapxy() {
  adb -s "$DEVICE" shell input tap "$1" "$2"
  _log "tapxy $1 $2"
  sleep 0.8
  guard
}

# slider SELECTOR FRACTION [bottom]
# Taps the track at FRACTION (0..1) of its usable width. Flutter insets the
# track by the overlay radius, 24 dp = 63 px on the Pixel 6 (2.625 dpr);
# override with ST_SLIDER_INSET. `bottom` aims 24 dp above the node's lower
# edge, for ids that wrap a label *and* the slider (the day-boundary ones).
# Always read the value back afterwards and re-tap with a corrected fraction
# if it is a step off.
cmd_slider() {
  local sel="$1" frac="$2" mode="${3:-}" inset="${ST_SLIDER_INSET:-63}" b
  dump_ui >/dev/null
  b="$(python3 -I "$UI_PY" bounds "$LOCAL_DUMP" "$sel")" || { echo "slider: '$sel' not on screen" >&2; return 1; }
  read -r x1 y1 x2 y2 <<< "$b"
  local x y
  x="$(python3 -I -c "print(round($x1 + $inset + $frac * (($x2 - $x1) - 2 * $inset)))")"
  if [[ "$mode" == bottom ]]; then y=$(( y2 - 63 )); else y=$(( (y1 + y2) / 2 )); fi
  adb -s "$DEVICE" shell input tap "$x" "$y"
  _log "slider $sel frac=$frac @ $x,$y"
  sleep 0.8
  guard
}

cmd_type() {  # type TEXT  (into the focused field; spaces allowed)
  adb -s "$DEVICE" shell input text "${1// /%s}"
  _log "type '$1'"
  sleep 0.5
  guard
}

cmd_clear() { # clear [N]: delete N characters before the cursor (default 12)
  local n="${1:-12}" keys=""
  for ((i = 0; i < n; i++)); do keys+=" 67"; done
  adb -s "$DEVICE" shell input keyevent KEYCODE_MOVE_END
  adb -s "$DEVICE" shell input keyevent $keys
  sleep 0.3
  guard
}

cmd_field() { # field SELECTOR VALUE: focus, clear, type. No Done.
  cmd_tap "$1" || return 1
  cmd_clear "${ST_CLEAR:-64}"   # long enough for a prefilled URL
  cmd_type "$2"
}

cmd_done() {  # the keyboard's Done / Enter on a single-line field
  adb -s "$DEVICE" shell input keyevent KEYCODE_ENTER
  _log "done (ENTER)"
  sleep 0.6
  guard
}

kb_shown() {
  adb -s "$DEVICE" shell dumpsys input_method 2>/dev/null | grep -q 'mInputShown=true'
}

cmd_kb_hide() {  # BACK only while the keyboard is up, so it never closes a dialog
  if kb_shown; then
    adb -s "$DEVICE" shell input keyevent KEYCODE_BACK
    _log "kb_hide"
    sleep 0.5
  fi
  guard
}

# back — refused on the main screen itself: there one BACK too many leaves the
# app for the launcher (main_screen.dart has no PopScope). A dialog or sheet
# blocks the semantics below it, so `nav-home` in the dump means "at the root".
cmd_back() {
  if ! kb_shown && cmd_has id=nav-home; then
    echo "back: refused, the main screen is showing (BACK would leave the app)" >&2
    return 98
  fi
  adb -s "$DEVICE" shell input keyevent KEYCODE_BACK
  _log "back"
  sleep 0.8
  guard
}

cmd_key() {   # key KEYCODE — an allowlist; HOME, APP_SWITCH, POWER and the rest are refused
  case "$1" in
    KEYCODE_ENTER|66|KEYCODE_DEL|67|KEYCODE_MOVE_END|123|KEYCODE_MOVE_HOME|122|KEYCODE_TAB|61|KEYCODE_DPAD_LEFT|21|KEYCODE_DPAD_RIGHT|22) ;;
    *) echo "key: $1 is not on the allowlist for this run" >&2; return 98 ;;
  esac
  adb -s "$DEVICE" shell input keyevent "$1"
  _log "key $1"
  sleep 0.6
  guard
}

cmd_swipe() { # swipe up|down  — "up" moves the content up (reveals what is below)
  case "$1" in
    up)   adb -s "$DEVICE" shell input swipe 540 1700 540 1000 400 ;;
    down) adb -s "$DEVICE" shell input swipe 540 1000 540 1700 400 ;;
    *)    echo "swipe up|down" >&2; return 1 ;;
  esac
  _log "swipe $1"
  sleep 0.8
  guard
}

# scroll_to SELECTOR [max=14] — swipe up until the match sits between y=300 and
# y=2050, then (if it never shows) the same number of swipes back down.
cmd_scroll_to() {
  local sel="$1" max="${2:-14}" xy y
  for dir in up down; do
    for ((i = 0; i <= max; i++)); do
      if xy="$(_center "$sel")"; then
        y="${xy#* }"
        if (( y > 300 && y < 2050 )); then echo "$xy"; return 0; fi
      fi
      cmd_swipe "$dir" >/dev/null
    done
  done
  echo "scroll_to: '$sel' not found" >&2
  return 1
}

# open_settings — You tab, scroll to the collapsed Settings card, expand it.
# The label is "Settings" with the app in English, "Einstellungen" in German.
cmd_open_settings() {
  local label="${ST_SETTINGS_LABEL:-Settings}"
  cmd_tap id=nav-you || return 1
  cmd_has id=settings-food-units && return 0
  cmd_scroll_to "text^=$label" || return 1
  cmd_has id=settings-food-units || cmd_tap "text^=$label"
  cmd_wait id=settings-food-units 5
}

# restart — the run's "cold restart": force-stop, launch, warm the tree.
cmd_restart() {
  adb -s "$DEVICE" shell am force-stop "$PKG"
  sleep 1
  adb -s "$DEVICE" shell am start -W -n "$ACT" >/dev/null
  _log "restart"
  sleep 4
  dump_ui >/dev/null; sleep 1; dump_ui >/dev/null
  guard
  cmd_wait id=nav-home 20 || cmd_wait id=onboarding-checkbox-privacy 5
}

cmd_launch() {
  adb -s "$DEVICE" shell am start -W -n "$ACT" >/dev/null
  sleep 4
  dump_ui >/dev/null; sleep 1; dump_ui >/dev/null
  guard
}

# --- system state (read only) -----------------------------------------------

cmd_version() { adb -s "$DEVICE" shell dumpsys package "$PKG" | grep -m2 -E 'versionName|versionCode'; }
cmd_locale()  { adb -s "$DEVICE" shell cmd locale get-app-locales "$PKG"; }
cmd_alarms()  { adb -s "$DEVICE" shell dumpsys alarm | grep -B2 -A6 "$PKG" | grep -E "$PKG|when|origWhen|type=" | head -20; }
cmd_notif()   { adb -s "$DEVICE" shell dumpsys notification --noredact | grep -A40 "pkg=$PKG" | grep -E "pkg=|android.title|android.text|postTime" | head -12; }
cmd_clock()   { adb -s "$DEVICE" shell date '+%F %T %Z'; }

# --- run log ----------------------------------------------------------------

cmd_init() {  # init: pin a fresh evidence folder for this run (laptop only)
  local dir="$HOME/Documents/ont-settings-test-evidence/run-$(date +%Y%m%d-%H%M)"
  mkdir -p "$dir/shots" "$dir/dumps"
  echo "$dir" > "$ST_CURRENT"
  echo "evidence -> $dir"
}

cmd_longpress() {  # longpress SELECTOR
  local xy
  xy="$(_center "$1")" || { echo "longpress: '$1' not on screen" >&2; return 1; }
  read -r x y <<< "$xy"
  adb -s "$DEVICE" shell input swipe "$x" "$y" "$x" "$y" 900
  _log "longpress $1 @ $xy"
  sleep 0.8
  guard
}

cmd_mark() {  # mark TEXT — a line in logcat and in run.log to slice evidence by
  local m="$*"
  adb -s "$DEVICE" shell log -t ONT-SETTINGS-RUN "MARK_${m// /_}"
  _log "MARK $*"
}

cmd_logcat_start() {
  adb -s "$DEVICE" logcat -c
  nohup "$ADB_BIN" -s "$DEVICE" logcat -v threadtime > "$EVID/logcat.txt" 2>&1 &
  echo $! > "$EVID/logcat.pid"
  echo "logcat -> $EVID/logcat.txt (pid $(cat "$EVID/logcat.pid"))"
}

cmd_logcat_stop() { [[ -f "$EVID/logcat.pid" ]] && kill "$(cat "$EVID/logcat.pid")" 2>/dev/null; rm -f "$EVID/logcat.pid"; }

# errors [MARK] — Flutter exceptions, assertion failures and crashes logged
# since the last `mark` exactly equal to MARK (or since the start).
cmd_errors() {
  local from=1
  if [[ -n "${1:-}" ]]; then
    local m="$1"
    from="$(grep -nE "ONT-SETTINGS-RUN.*MARK_${m// /_}[[:space:]]*$" "$EVID/logcat.txt" | tail -1 | cut -d: -f1)"
    from="${from:-1}"
  fi
  tail -n "+$from" "$EVID/logcat.txt" \
    | grep -E "E flutter|EXCEPTION CAUGHT|Failed assertion|Unhandled Exception|FATAL EXCEPTION|AndroidRuntime" \
    | grep -E "$PKG|flutter|AndroidRuntime" | head -40
}

# handoff MESSAGE — print the hand-off banner. Then wait for the maintainer to
# say "done" in chat; then `ST_HANDOFF=1 bash st.sh focus` and carry on only
# when focus is back in the app.
cmd_handoff() {
  _log "HAND-OFF: $*"
  printf '\n==== HAND-OFF TO THE MAINTAINER ====\n%s\n====================================\n' "$*"
}

# ---------------------------------------------------------------------------
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  sub="${1:-}"; shift || true
  if declare -F "cmd_$sub" >/dev/null; then
    "cmd_$sub" "$@"
  else
    sed -n '2,25p' "$0"
    exit 2
  fi
fi
