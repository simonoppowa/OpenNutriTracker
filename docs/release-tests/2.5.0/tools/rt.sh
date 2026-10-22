#!/usr/bin/env bash
# docs/release-tests/2.5.0/tools/rt.sh — the hardened adb driver for the
# unattended 2.5.0 release run on the Pixel 6 (#1432, map #1425).
#
#   RT=docs/release-tests/2.5.0/tools/rt.sh
#   bash $RT init                      # pin (or re-use) the run's evidence folder
#   bash $RT preflight 2.5.0           # refuse to start unless the phone is ready
#   bash $RT step_begin 12-export export || [ $? = 3 ]   # 3 = done already
#   bash $RT tap id=settings-export
#   bash $RT step_end pass "zip pulled, 4 files"
#
# One action per call. README.md next to this file is the reference: every
# action, every exit code, the evidence layout and how to resume.
#
# The rules this file enforces, whoever calls it:
#   * ABORT. The first time focus is found outside the app (or outside
#     DocumentsUI during a step marked export/import), $RT_ROOT/ABORT is
#     written *before anything else happens*, and every later call exits 99
#     without touching adb. Nothing here deletes that file.
#   * Focus is read right before every input event and again after it.
#     Taps take a selector, never coordinates, and the selector must match a
#     node of an allowed package in a dump made in the same call.
#   * A crash, an ANR or a red ErrorWidget writes $RUN/HALT; only `recover`,
#     `step_end`, `errors`, `status` and `resume` run until `recover` clears it.
#   * HOME, APP_SWITCH, POWER and anything off the key allowlist are refused;
#     BACK only goes out when the screen shows something to go back from.
#   * The AI key is only ever read by `type_secret`, from the key file, on the
#     phone's stdin. No log line, dump, screenshot or argv carries it.
# ---------------------------------------------------------------------------

set -u -o pipefail

RT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UI_PY="$RT_DIR/ui.py"

ADB_BIN="${ADB_BIN:-$HOME/Android/Sdk/platform-tools/adb}"
# The USB serial, pinned. The phone also lists over adb-tls under another name;
# never "the first device", never the wireless alias.
SERIAL="18101FDF60010M"
PKG="com.opennutritracker.ont.opennutritracker"
ACT="$PKG/.MainActivity"
PICKER_PKG="com.google.android.documentsui"
KEY_FILE="${RT_KEY_FILE:-$HOME/.config/ont-run/ai-key}"
PROVIDER_FILE="${RT_PROVIDER_FILE:-$HOME/.config/ont-run/ai-provider}"
RT_ROOT="${RT_ROOT:-$HOME/Documents/ont-release-2.5.0-evidence}"
ABORT_FILE="$RT_ROOT/ABORT"

GRANTS="${RT_GRANTS:-android.permission.POST_NOTIFICATIONS android.permission.health.READ_EXERCISE android.permission.health.READ_TOTAL_CALORIES_BURNED android.permission.CAMERA}"
BATTERY_START="${RT_BATTERY_START:-40}"     # preflight refuses below this
BATTERY_FLOOR="${RT_BATTERY_FLOOR:-25}"     # step_begin pauses below this ...
BATTERY_RESUME="${RT_BATTERY_RESUME:-40}"   # ... until the level is back here
CHARGE_WAIT_MAX="${RT_CHARGE_WAIT_MAX:-14400}"
PAUSE_SCREEN_OFF="${RT_PAUSE_SCREEN_OFF:-1}"
USB_WAIT="${RT_USB_WAIT:-120}"
DEVICE_FREE_MB="${RT_DEVICE_FREE_MB:-2048}"
HOST_FREE_MB="${RT_HOST_FREE_MB:-4096}"
EVIDENCE="${RT_EVIDENCE:-all}"              # all | shots

RUN=""
ACTION="${1:-}"
STEP_ID="_nostep"
STEP_KIND=""
P_FOCUS="" P_PKG="" P_PID="" P_NOW=""

# --- plumbing ---------------------------------------------------------------

_adb() { "$ADB_BIN" -s "$SERIAL" "$@"; }

_ui() { RT_ALLOW_PKGS="$(_allowed_pkgs)" python3 -I "$UI_PY" "$@"; }

_ts() { date '+%F %T'; }

_log() { [[ -n "$RUN" ]] && printf '%s  [%s] %s\n' "$(_ts)" "$STEP_ID" "$*" >> "$RUN/run.log"; return 0; }

_die() { local code="$1"; shift; echo "rt: $*" >&2; _log "exit $code: $*"; exit "$code"; }

_load_run() {
  [[ -f "$RT_ROOT/current-run" ]] || return 1
  RUN="$(cat "$RT_ROOT/current-run")"
  [[ -d "$RUN" ]] || { RUN=""; return 1; }
  if [[ -f "$RUN/.step" ]]; then
    IFS=$'\t' read -r STEP_ID STEP_KIND _ < "$RUN/.step"
  fi
  return 0
}

_need_run() { [[ -n "$RUN" ]] || _die 2 "no run pinned: call 'init' first"; }

_allowed_pkgs() {
  if [[ "$STEP_KIND" == export || "$STEP_KIND" == import ]]; then
    echo "$PKG $PICKER_PKG"
  else
    echo "$PKG"
  fi
}

_step_dir() { local d="$RUN/steps/$STEP_ID"; mkdir -p "$d"; echo "$d"; }

_next_n() {  # evidence counter for the open step
  local f="$RUN/steps/$STEP_ID/.n" n=0
  mkdir -p "$RUN/steps/$STEP_ID"
  [[ -f "$f" ]] && n="$(cat "$f")"
  n=$((n + 1)); echo "$n" > "$f"; printf '%03d' "$n"
}

_slug() { tr -c 'A-Za-z0-9._=-' '_' <<< "$*" | cut -c1-48 | sed 's/_*$//'; }

_steplog() {  # id status note
  [[ -n "$RUN" ]] || return 0
  local start=""
  [[ -f "$RUN/.step" ]] && start="$(cut -f3 "$RUN/.step")"
  printf '%s\t%s\t%s\t%s\t%s\n' "$1" "$2" "$start" "$(_ts)" "${3//$'\t'/ }" >> "$RUN/steps.tsv"
}

# --- stop states -------------------------------------------------------------

_check_abort() {
  if [[ -e "$ABORT_FILE" ]]; then
    echo "rt: ABORTED earlier — refusing '$ACTION'. Nothing was sent to the phone." >&2
    sed 's/^/rt:   /' "$ABORT_FILE" >&2
    echo "rt: Only a person who has looked at the phone deletes $ABORT_FILE." >&2
    exit 99
  fi
}

_check_halt() {
  if [[ -n "$RUN" && -e "$RUN/HALT" ]]; then
    echo "rt: HALTED ($(grep -m1 '^reason=' "$RUN/HALT" | cut -d= -f2-)) — refusing '$ACTION'." >&2
    echo "rt: record the step with step_end, then call recover." >&2
    exit 97
  fi
}

_shot_raw() {  # PNG path -> red check; never during the secret window
  local out="$1" raw="$RUN/.screen.raw" rc
  [[ -n "$RUN" ]] || return 0
  _adb exec-out screencap > "$raw" 2>/dev/null || return 0
  _ui screen "$raw" "$out" >/dev/null; rc=$?
  rm -f "$raw"
  return $rc
}

_abort() {  # reason
  # The flag goes first: if anything below hangs or fails, the stop holds.
  mkdir -p "$RT_ROOT"
  {
    echo "time=$(_ts)"
    echo "reason=$1"
    echo "focus=$P_FOCUS"
    echo "step=$STEP_ID"
    echo "action=$ACTION"
    echo "run=$RUN"
  } > "$ABORT_FILE"
  echo "rt: FOCUS LEFT THE APP: $P_FOCUS" >&2
  echo "rt: ABORT written to $ABORT_FILE. Every later call refuses. Stop the run." >&2
  _log "ABORT: $1 | $P_FOCUS"
  _steplog "$STEP_ID" aborted "$1 | $P_FOCUS"
  if [[ -n "$RUN" && ! -e "$RUN/.secret" ]]; then
    _shot_raw "$(_step_dir)/ABORT-focus-lost.png"
  fi
  exit 99
}

_halt() {  # reason detail
  {
    echo "time=$(_ts)"
    echo "reason=$1"
    echo "detail=$2"
    echo "focus=$P_FOCUS"
    echo "step=$STEP_ID"
    echo "action=$ACTION"
  } > "$RUN/HALT"
  local d; d="$(_step_dir)"
  echo "rt: HALT: $1 — $2" >&2
  _log "HALT: $1 | $2 | $P_FOCUS"
  [[ -f "$RUN/.t0" ]] && _adb logcat -b crash -d -v threadtime -T "$(cat "$RUN/.t0")" > "$d/crash-buffer.txt" 2>/dev/null
  [[ -e "$RUN/.secret" ]] || _shot_raw "$d/HALT-$1.png"
  _steplog "$STEP_ID" halted "$1: $2"
  exit 97
}

# --- the device --------------------------------------------------------------

_device_wait() {
  _log "device not answering; waiting up to ${USB_WAIT}s on $SERIAL"
  timeout "$USB_WAIT" "$ADB_BIN" -s "$SERIAL" wait-for-device >/dev/null 2>&1
}

_probe() {  # one round trip: focus, the app's pid, the phone's clock
  local out i
  for i in 1 2; do
    out="$(_adb shell "dumpsys window 2>/dev/null | grep -m1 mCurrentFocus; echo PID=\$(pidof $PKG); echo NOW=\$(date '+%m-%d %H:%M:%S.000')" 2>/dev/null)"
    if [[ "$out" == *NOW=* ]]; then
      P_FOCUS="$(grep -m1 mCurrentFocus <<< "$out" | sed 's/^ *//')"
      P_PID="$(sed -n 's/^PID=//p' <<< "$out" | awk '{print $1}')"
      P_NOW="$(sed -n 's/^NOW=//p' <<< "$out")"
      P_PKG="$(sed -n 's/.* u[0-9]* \([^/ }]*\).*/\1/p' <<< "$P_FOCUS")"
      return 0
    fi
    (( i == 1 )) && _device_wait
  done
  _die 6 "phone $SERIAL is not answering over USB (waited ${USB_WAIT}s)"
}

_crashed_since() {  # exit 0 if the crash buffer shows the app dying since .t0
  local since=""
  [[ -f "$RUN/.t0" ]] && since="$(cat "$RUN/.t0")"
  [[ -n "$since" ]] || return 1
  _adb logcat -b crash -d -v threadtime -T "$since" 2>/dev/null | _ui crashscan "$PKG" >/dev/null
}

_focus_ok() {
  [[ "$P_PKG" == "$PKG" ]] && return 0
  [[ "$P_PKG" == "$PICKER_PKG" && ( "$STEP_KIND" == export || "$STEP_KIND" == import ) ]]
}

_guard() {  # pre|post — returns only if focus is allowed
  local i
  for i in 1 2 3 4 5; do
    _probe
    case "$P_FOCUS" in
      *"Application Not Responding"*"$PKG"*) _halt anr "ANR dialog in focus" ;;
      *"Application Error"*"$PKG"*) _halt crash "crash dialog in focus" ;;
    esac
    if _focus_ok; then
      if [[ "$P_PKG" == "$PKG" && -s "$RUN/.pid" && -n "$P_PID" && "$P_PID" != "$(cat "$RUN/.pid")" ]]; then
        _crashed_since && _halt crash "app restarted under a new pid ($P_PID)"
        _log "WARN app pid changed $(cat "$RUN/.pid") -> $P_PID without a crash record"
      fi
      [[ "$P_PKG" == "$PKG" && -n "$P_PID" ]] && echo "$P_PID" > "$RUN/.pid"
      echo "$P_NOW" > "$RUN/.t0"
      return 0
    fi
    # null focus is an activity transition; a foreign window gets one more look.
    if [[ -z "$P_PKG" || "$P_FOCUS" == *"=null"* ]] || (( i < 2 )); then
      sleep 0.7
      continue
    fi
    break
  done
  if [[ -z "$P_PID" ]] && _crashed_since; then
    _halt crash "app process gone, crash buffer names $PKG"
  fi
  _abort "focus not on the app ($1-input check)"
}

_dump() {  # [noguard] — fresh dump into $RUN/.dump.xml; retries the bare first dump
  local i
  for i in 1 2 3; do
    _adb exec-out uiautomator dump /dev/tty > "$RUN/.dump.xml" 2>/dev/null
    _ui usable "$RUN/.dump.xml" && return 0
    sleep 1
  done
  # No content from an allowed package: maybe focus has gone. Find out now,
  # in this shell, so a foreign window writes ABORT instead of reading as
  # "selector not found" to a caller that would carry on.
  [[ "${1:-}" == noguard ]] || _guard post
  return 1
}

_kb_shown() { _adb shell dumpsys input_method 2>/dev/null | grep -q 'mInputShown=true'; }

_state() {  # sets S_NAV S_MODAL S_BACK S_EDIT S_PASSWORD from the last dump
  local line
  S_NAV=0 S_MODAL=0 S_BACK=0 S_EDIT=0 S_PASSWORD=0
  while IFS='=' read -r k v; do
    case "$k" in
      nav) S_NAV="$v" ;; modal) S_MODAL="$v" ;; back) S_BACK="$v" ;;
      edit) S_EDIT="$v" ;; password) S_PASSWORD="$v" ;;
    esac
  done < <(_ui state "$RUN/.dump.xml")
}

# --- evidence ----------------------------------------------------------------

_logscan() {  # new crash / ANR / Flutter-error lines since the last scan
  local cur file off out
  [[ -f "$RUN/.logcat" ]] || return 0
  file="$(cut -f1 "$RUN/.logcat")"
  [[ -f "$file" ]] || return 0
  off=0
  [[ -f "$RUN/.logoff" ]] && [[ "$(cut -f1 "$RUN/.logoff")" == "$file" ]] && off="$(cut -f2 "$RUN/.logoff")"
  out="$(_ui logscan "$file" "$off" "$PKG")"
  printf '%s\t%s\n' "$file" "$(sed -n 's/^offset=//p' <<< "$out" | tail -1)" > "$RUN/.logoff"
  cur="$(grep -v '^offset=' <<< "$out")"
  [[ -n "$cur" ]] || return 0
  printf '%s\n' "$cur" >> "$(_step_dir)/errors.txt"
  grep '^FLUTTER' <<< "$cur" | head -3 | sed 's/^/rt: WARN /' >&2
  if grep -q '^CRASH' <<< "$cur"; then _halt crash "$(grep -m1 '^CRASH' <<< "$cur" | cut -c1-160)"; fi
  if grep -q '^ANR' <<< "$cur"; then _halt anr "$(grep -m1 '^ANR' <<< "$cur" | cut -c1-160)"; fi
}

_evidence() {  # label — screenshot (+ dump), red ErrorWidget check, log scan
  local base rc
  if [[ -e "$RUN/.secret" ]]; then
    _log "evidence skipped ($1): secret window open"
    return 0
  fi
  base="$(_step_dir)/$(_next_n)-$(_slug "$1")"
  _shot_raw "$base.png"; rc=$?
  if [[ "$EVIDENCE" == all ]] && _dump; then
    cp "$RUN/.dump.xml" "$base.xml"
    _ui ls "$RUN/.dump.xml" > "$base.txt" 2>/dev/null
  fi
  (( rc == 4 )) && _halt errorwidget "red ErrorWidget on screen ($base.png)"
  _logscan
}

# --- input: the only ways anything reaches the phone's input -----------------

_send() {  # input ARGS… — focus checked right before, and after
  _check_abort
  _check_halt
  _guard pre
  _adb shell input "$@"
  sleep "${RT_SETTLE:-0.8}"
  _guard post
}

_secret_close() {
  if [[ -e "$RUN/.secret" ]]; then
    rm -f "$RUN/.secret"
    _log "secret window closed"
  fi
}

_center() {  # SELECTOR -> CENTER="x y" from a fresh dump; 1 absent, 3 occluded, 5 foreign
  # Not called in $(…): the guard inside _dump must be able to exit this shell.
  CENTER=""
  _dump || { echo "rt: no usable dump" >&2; return 1; }
  CENTER="$(_ui find "$RUN/.dump.xml" "$1")"
}

_tap_like() {  # verb SELECTOR [hold-ms]
  local verb="$1" sel="$2" hold="${3:-}" xy rc
  _center "$sel"; rc=$?; xy="$CENTER"
  case $rc in
    0) ;;
    3) _die 98 "$verb: '$sel' is under the FAB or the nav bar; scroll it clear first" ;;
    5) _die 98 "$verb: '$sel' belongs to another package" ;;
    *) echo "rt: $verb: '$sel' not on screen" >&2; return 1 ;;
  esac
  local x="${xy% *}" y="${xy#* }"
  if [[ -n "$hold" ]]; then
    _send swipe "$x" "$y" "$x" "$y" "$hold"
  else
    _send tap "$x" "$y"
  fi
  _log "$verb $sel @ $x,$y"
  local was_secret=0
  [[ -e "$RUN/.secret" ]] && was_secret=1
  _evidence "$verb $sel"
  # The tap after type_secret (Save) closes the window, after its own
  # evidence was skipped.
  (( was_secret )) && _secret_close
  return 0
}

cmd_tap() { [[ $# -eq 1 ]] || _die 2 "tap SELECTOR"; _tap_like tap "$1"; }

cmd_longpress() { [[ $# -eq 1 ]] || _die 2 "longpress SELECTOR"; _tap_like longpress "$1" 900; }

# slider SELECTOR FRACTION [bottom] — taps the track at FRACTION (0..1) of its
# usable width (inset 24 dp = 63 px on the Pixel 6, RT_SLIDER_INSET). `bottom`
# aims 24 dp above the node's lower edge, for ids that wrap a label and the
# slider. Read the value back afterwards.
cmd_slider() {
  [[ $# -ge 2 ]] || _die 2 "slider SELECTOR FRACTION [bottom]"
  local sel="$1" frac="$2" mode="${3:-}" inset="${RT_SLIDER_INSET:-63}" b rc x y
  [[ "$frac" =~ ^(0|1|0?\.[0-9]+|1\.0+)$ ]] || _die 2 "slider: FRACTION is 0..1"
  _dump || return 1
  b="$(_ui bounds "$RUN/.dump.xml" "$sel")"; rc=$?
  (( rc == 0 )) || { (( rc == 1 )) && { echo "rt: slider: '$sel' not on screen" >&2; return 1; }; _die 98 "slider: '$sel' refused (code $rc)"; }
  read -r x1 y1 x2 y2 <<< "$b"
  x="$(python3 -I -c "print(round($x1 + $inset + float('$frac') * (($x2 - $x1) - 2 * $inset)))")" || _die 2 "slider: bad fraction"
  if [[ "$mode" == bottom ]]; then y=$(( y2 - 63 )); else y=$(( (y1 + y2) / 2 )); fi
  _send tap "$x" "$y"
  _log "slider $sel frac=$frac @ $x,$y"
  _evidence "slider $sel $frac"
}

cmd_type() {  # type TEXT — into the focused field; logged, so never a secret
  [[ $# -eq 1 ]] || _die 2 "type TEXT"
  if ! python3 -I "$UI_PY" textcheck "$KEY_FILE" "$1"; then
    _die 98 "type: refused, that text is (or looks like) an API key — use type_secret"
  fi
  [[ "$1" != *%* ]] || _die 98 "type: '%' would be read as an input escape"
  _send text "${1// /%s}"
  _log "type '$1'"
  _evidence "type"
}

cmd_clear() {  # clear [N] — N deletes before the cursor (default 64)
  local n="${1:-64}" keys="" i
  [[ "$n" =~ ^[0-9]+$ ]] || _die 2 "clear [N]"
  for ((i = 0; i < n; i++)); do keys+=" 67"; done
  _send keyevent KEYCODE_MOVE_END
  # shellcheck disable=SC2086
  _send keyevent $keys
  _log "clear $n"
}

cmd_field() {  # field SELECTOR VALUE — focus, clear, type. No Done.
  [[ $# -eq 2 ]] || _die 2 "field SELECTOR VALUE"
  cmd_tap "$1" || return 1
  cmd_clear "${RT_CLEAR:-64}"
  cmd_type "$2"
}

cmd_done() { _send keyevent KEYCODE_ENTER; _log "done (ENTER)"; _evidence "done"; }

cmd_key() {  # key KEYCODE — allowlist only
  case "${1:-}" in
    KEYCODE_ENTER|66|KEYCODE_DEL|67|KEYCODE_MOVE_END|123|KEYCODE_MOVE_HOME|122|KEYCODE_TAB|61|KEYCODE_DPAD_LEFT|21|KEYCODE_DPAD_RIGHT|22) ;;
    *) _die 98 "key: '${1:-}' is not on the allowlist (HOME, APP_SWITCH, POWER and the rest are never sent)" ;;
  esac
  _send keyevent "$1"
  _log "key $1"
  _evidence "key $1"
}

cmd_kb_hide() {  # BACK only while the keyboard is up, so it never closes a page
  if _kb_shown; then
    _send keyevent KEYCODE_BACK
    _log "kb_hide"
  else
    _check_abort; _check_halt; _guard post
  fi
}

# back — only when there is something to go back from: the keyboard, a dialog
# or sheet, an app bar with a Back/Close button, or DocumentsUI in a picker
# step. On the main screen (or a screen whose nav bar a red ErrorWidget has
# hidden) BACK would leave the app, so it is refused.
cmd_back() {
  _check_abort; _check_halt
  _guard pre
  if [[ "$P_PKG" != "$PICKER_PKG" ]] && ! _kb_shown; then
    _dump || _die 98 "back: no usable dump, refusing blind BACK"
    _state
    if (( S_MODAL == 0 && S_BACK == 0 )); then
      _die 98 "back: refused — no dialog, sheet or Back button on screen (BACK would leave the app)"
    fi
  fi
  _send keyevent KEYCODE_BACK
  _log "back"
  _evidence "back"
}

_swipe_ok() {  # refuse the cases that moved sliders or tapped suggestions last time
  _kb_shown && _die 98 "swipe: refused while the keyboard is up (kb_hide first)"
  _dump || _die 98 "swipe: no usable dump"
}

cmd_swipe() {  # swipe up|down — "up" reveals what is below
  _check_abort; _check_halt
  local dir="${1:-}"
  [[ "$dir" == up || "$dir" == down ]] || _die 2 "swipe up|down"
  _swipe_ok
  _state
  (( S_MODAL == 0 )) || _die 98 "swipe: refused with a dialog or sheet open (use swipe_in on its list)"
  if [[ "$dir" == up ]]; then _send swipe 540 1700 540 1000 400; else _send swipe 540 1000 540 1700 400; fi
  _log "swipe $dir"
  _evidence "swipe $dir"
}

cmd_swipe_in() {  # swipe_in SELECTOR up|down — inside that node only (dialog lists)
  _check_abort; _check_halt
  [[ $# -eq 2 && ( "$2" == up || "$2" == down ) ]] || _die 2 "swipe_in SELECTOR up|down"
  local b rc x ya yb
  _swipe_ok
  b="$(_ui bounds "$RUN/.dump.xml" "$1")"; rc=$?
  (( rc == 0 )) || { (( rc == 1 )) && { echo "rt: swipe_in: '$1' not on screen" >&2; return 1; }; _die 98 "swipe_in: '$1' refused (code $rc)"; }
  read -r x1 y1 x2 y2 <<< "$b"
  x=$(( (x1 + x2) / 2 )); ya=$(( y1 + (y2 - y1) * 3 / 4 )); yb=$(( y1 + (y2 - y1) / 4 ))
  if [[ "$2" == up ]]; then _send swipe "$x" "$ya" "$x" "$yb" 400; else _send swipe "$x" "$yb" "$x" "$ya" 400; fi
  _log "swipe_in $1 $2"
  _evidence "swipe_in $2"
}

# scroll_to SELECTOR [max=14] — swipe up until the match sits between y=300
# and y=2000 (clear of the FAB), then as many swipes back down.
cmd_scroll_to() {
  [[ $# -ge 1 ]] || _die 2 "scroll_to SELECTOR [max]"
  local sel="$1" max="${2:-14}" xy rc y dir i
  for dir in up down; do
    for ((i = 0; i <= max; i++)); do
      _center "$sel"; rc=$?; xy="$CENTER"
      if (( rc == 0 )); then
        y="${xy#* }"
        if (( y > 300 && y < 2000 )); then echo "$xy"; return 0; fi
      fi
      cmd_swipe "$dir" >/dev/null
    done
  done
  echo "rt: scroll_to: '$sel' not found" >&2
  return 1
}

# type_secret [SELECTOR] — the AI key, from the key file, over the phone's
# stdin. Checks first: key file sane, show_password off, the target is a
# focused password field. No screenshot or dump is kept from here until the
# next tap (Save) has gone out.
cmd_type_secret() {
  _check_abort; _check_halt; _need_run
  local sel="${1:-id=ai-assist-key-field}" rc sp
  python3 -I "$UI_PY" keycheck "$KEY_FILE"; rc=$?
  (( rc == 0 )) || _die 98 "type_secret: key file not usable (keycheck code $rc; see README)"
  sp="$(_adb shell settings get system show_password 2>/dev/null | tr -d '\r')"
  [[ "$sp" == 0 ]] || _die 98 "type_secret: show_password is '$sp', not 0 — a typed character would flash on screen"
  cmd_tap "$sel" || _die 1 "type_secret: '$sel' not on screen"
  mkdir -p "$RUN/steps/$STEP_ID"
  touch "$RUN/.secret" "$RUN/steps/$STEP_ID/.used-secret"
  _log "secret window open"
  _dump || { _secret_close; _die 98 "type_secret: no usable dump, nothing typed"; }
  _state
  (( S_EDIT == 1 && S_PASSWORD == 1 )) || { _secret_close; _die 98 "type_secret: the focused field is not a password field, nothing typed"; }
  cmd_clear "${RT_CLEAR:-64}"
  _check_abort; _check_halt
  _guard pre
  # The key travels on stdin; the shell line names only $k.
  _adb shell 'read -r k; input text "$k"' < "$KEY_FILE"
  sleep 0.8
  _guard post
  _dump || _die 98 "type_secret: no usable dump after typing"
  if python3 -I "$UI_PY" secretlen "$KEY_FILE" "$RUN/.dump.xml"; then
    _log "type_secret: typed from the key file; field shows the right number of bullets"
  else
    _log "type_secret: typed from the key file; bullet count does NOT match"
    echo "rt: type_secret: the field does not show one bullet per key character" >&2
  fi
  rm -f "$RUN/.dump.xml"
  echo "typed (not shown); next: tap the Save button"
}

# --- reading the screen (no input) -------------------------------------------

_reader() { _check_abort; _check_halt; _need_run; }

cmd_ls() { _reader; _dump || return 1; _ui ls "$RUN/.dump.xml"; }
cmd_get() { _reader; _dump || return 1; _ui get "$RUN/.dump.xml" "$1"; }
cmd_has() {  # exit 0 if the selector is on screen (occluded counts as shown)
  _reader; _dump || return 1
  _ui find "$RUN/.dump.xml" "$1" >/dev/null 2>&1
  case $? in 0|3) return 0 ;; *) return 1 ;; esac
}
cmd_state() { _reader; _dump || return 1; _ui state "$RUN/.dump.xml"; }

cmd_wait() {  # wait SELECTOR [seconds=15]
  _reader
  local sel="$1" t="${2:-15}" start=$SECONDS
  while (( SECONDS - start < t )); do
    if _dump; then
      _ui find "$RUN/.dump.xml" "$sel" >/dev/null 2>&1
      case $? in 0|3) return 0 ;; esac
    fi
    sleep 1
  done
  echo "rt: wait: '$sel' not on screen after ${t}s" >&2
  return 1
}

cmd_save() {  # save NAME — keep this screen (png + dump + listing) as named evidence
  _reader
  [[ -e "$RUN/.secret" ]] && _die 98 "save: refused while the secret window is open"
  local base rc; base="$(_step_dir)/$(_next_n)-$(_slug "${1:-save}")"
  _guard post
  _shot_raw "$base.png"; rc=$?
  _dump && { cp "$RUN/.dump.xml" "$base.xml"; _ui ls "$RUN/.dump.xml" > "$base.txt"; }
  (( rc == 4 )) && _halt errorwidget "red ErrorWidget on screen ($base.png)"
  echo "$base"
}

cmd_shot() {  # shot NAME
  _reader
  [[ -e "$RUN/.secret" ]] && _die 98 "shot: refused while the secret window is open"
  local f rc; f="$(_step_dir)/$(_next_n)-$(_slug "${1:-shot}").png"
  _shot_raw "$f"; rc=$?
  echo "$f"
  (( rc == 4 )) && _halt errorwidget "red ErrorWidget on screen ($f)"
  return 0
}

cmd_guard() { _reader; _guard post; echo "focus ok: $P_FOCUS"; }
cmd_where() { _check_abort; _probe; echo "$P_FOCUS"; echo "pid=$P_PID"; }

# --- app lifecycle -----------------------------------------------------------

_after_launch() {
  sleep "${RT_LAUNCH_SETTLE:-3}"
  _dump noguard; sleep 1; _dump noguard   # warms the semantics tree
  _guard post
  echo "$P_PID" > "$RUN/.pid"
}

cmd_launch() {  # bring the app up without stopping it (keeps reminder alarms)
  _check_abort; _check_halt; _need_run
  _adb shell am start -W -n "$ACT" >/dev/null 2>&1
  _log "launch"
  _after_launch
  _evidence "launch"
}

cmd_restart() {  # cold start: force-stop (cancels the reminder alarm!) + launch
  _check_abort; _check_halt; _need_run
  _adb shell am force-stop "$PKG"
  _log "restart (force-stop: reminder alarms are cancelled until the app re-arms them)"
  echo "rt: note: force-stop cancelled the app's reminder alarm" >&2
  rm -f "$RUN/.pid"
  sleep 1
  _adb shell am start -W -n "$ACT" >/dev/null 2>&1
  _after_launch
  _evidence "restart"
}

cmd_recover() {  # after a HALT: bring the app back, then carry on
  _check_abort; _need_run
  [[ -e "$RUN/HALT" ]] || { echo "nothing to recover"; return 0; }
  local reason n=0
  reason="$(grep -m1 '^reason=' "$RUN/HALT" | cut -d= -f2-)"
  [[ -f "$RUN/.recoveries" ]] && n="$(cat "$RUN/.recoveries")"
  n=$((n + 1)); echo "$n" > "$RUN/.recoveries"
  if (( n > ${RT_MAX_RECOVER:-5} )); then
    P_FOCUS="(recover #$n)"
    _abort "more than ${RT_MAX_RECOVER:-5} recoveries in one run"
  fi
  mv "$RUN/HALT" "$RUN/steps/$STEP_ID/HALT-$(date +%H%M%S).txt" 2>/dev/null || rm -f "$RUN/HALT"
  if [[ "$reason" == crash ]]; then
    _log "recover after crash: am start"
  else
    _adb shell am force-stop "$PKG"
    _log "recover after $reason: force-stop + am start (reminder alarms cancelled)"
  fi
  rm -f "$RUN/.pid" "$RUN/.secret"
  _adb shell am start -W -n "$ACT" >/dev/null 2>&1
  _after_launch
  _evidence "recover"
  echo "recovered from $reason (recovery $n of ${RT_MAX_RECOVER:-5})"
}

# prep [--check] — idempotent per-path preparation. Grants the runtime
# permissions that would otherwise raise a system dialog (which the guard
# treats as focus loss). Re-run after every pm clear and fresh install; the
# install and pm_clear actions call it themselves. Device settings are only
# checked (preflight), never changed here.
cmd_prep() {
  _check_abort; _check_halt
  local check=0 perm dump bad=0
  [[ "${1:-}" == --check ]] && check=1
  dump="$(_adb shell dumpsys package "$PKG" 2>/dev/null)"
  [[ -n "$dump" ]] || _die 6 "prep: dumpsys package failed"
  grep -q "versionName=" <<< "$dump" || _die 1 "prep: $PKG is not installed"
  for perm in $GRANTS; do
    if grep -qE "^ +$perm: granted=true" <<< "$dump"; then
      echo "ok     $perm"
    elif (( check )); then
      echo "MISS   $perm"; bad=1
    else
      _adb shell pm grant "$PKG" "$perm" 2>&1 | sed 's/^/rt: /'
      if _adb shell dumpsys package "$PKG" 2>/dev/null | grep -qE "^ +$perm: granted=true"; then
        echo "grant  $perm"; _log "prep: granted $perm"
      else
        echo "FAIL   $perm"; bad=1
      fi
    fi
  done
  _log "prep$([[ $check == 1 ]] && echo ' --check'): $([[ $bad == 0 ]] && echo ok || echo incomplete)"
  return $bad
}

cmd_pm_clear() {  # wipe the app's data, then prep again (grants are lost too)
  _check_abort; _check_halt; _need_run
  _adb shell pm clear "$PKG" | tr -d '\r'
  rm -f "$RUN/.pid"
  _log "pm clear"
  cmd_prep
}

cmd_install() {  # install APK — `install -r` (upgrade in place), then prep
  _check_abort; _check_halt; _need_run
  [[ -f "${1:-}" ]] || _die 2 "install APK"
  _adb install -r "$1" || _die 1 "install failed"
  rm -f "$RUN/.pid"
  _log "install -r $(basename "$1")"
  cmd_prep
}

# --- preflight ---------------------------------------------------------------

cmd_preflight() {  # preflight [EXPECTED_VERSION_NAME]
  _check_abort
  local want="${1:-${RT_EXPECT_VERSION:-}}" fail=0 low=0 out="" v lvl usb ac temp free hostfree rc
  _row() { out+="$(printf '%-5s %-14s %s' "$1" "$2" "$3")"$'\n'; [[ "$1" == FAIL ]] && fail=1; return 0; }

  if "$ADB_BIN" devices 2>/dev/null | awk -F'\t' -v s="$SERIAL" '$1 == s && $2 == "device" {f=1} END {exit !f}'; then
    _row ok serial "$SERIAL attached over USB"
  else
    _row FAIL serial "$SERIAL not attached as 'device'"
    printf '%s' "$out"; return 4
  fi
  [[ "$(_adb shell getprop ro.serialno | tr -d '\r')" == "$SERIAL" ]] && _row ok serialno "matches" || _row FAIL serialno "ro.serialno differs"
  v="$(_adb shell getprop ro.product.device | tr -d '\r')"
  [[ "$v" == oriole ]] && _row ok model "oriole (Pixel 6), SDK $(_adb shell getprop ro.build.version.sdk | tr -d '\r')" || _row FAIL model "'$v', expected oriole"

  v="$(_adb shell dumpsys package "$PKG" 2>/dev/null | sed -n 's/^ *versionName=//p' | head -1 | tr -d '\r')"
  local code; code="$(_adb shell dumpsys package "$PKG" 2>/dev/null | sed -n 's/^ *versionCode=\([0-9]*\).*/\1/p' | head -1)"
  if [[ -z "$v" ]]; then _row FAIL version "$PKG not installed"
  elif [[ -z "$want" ]]; then _row FAIL version "installed $v ($code); no expected version given"
  elif [[ "$v" == "$want" ]]; then _row ok version "$v ($code)"
  else _row FAIL version "installed $v ($code), expected $want"; fi

  _probe
  if [[ "$P_PKG" == "$PKG" ]]; then _row ok focus "$PKG in focus (pid $P_PID)"
  else _row FAIL focus "not the app: $P_FOCUS (call launch)"; fi

  local bat; bat="$(_adb shell dumpsys battery 2>/dev/null | tr -d '\r')"
  lvl="$(sed -n 's/^ *level: //p' <<< "$bat")"
  usb="$(sed -n 's/^ *USB powered: //p' <<< "$bat")"; ac="$(sed -n 's/^ *AC powered: //p' <<< "$bat")"
  temp="$(sed -n 's/^ *temperature: //p' <<< "$bat")"
  if [[ "$usb" != true && "$ac" != true ]]; then _row FAIL power "not charging"
  else _row ok power "$([[ $ac == true ]] && echo AC || echo USB)"; fi
  if [[ -z "$lvl" ]]; then _row FAIL battery "unreadable"
  elif (( lvl < BATTERY_START )); then _row LOW battery "$lvl % < start floor $BATTERY_START % (wait: charge_wait)"; low=1
  else _row ok battery "$lvl % (start floor $BATTERY_START %, pause below $BATTERY_FLOOR %)"; fi
  [[ -n "$temp" ]] && (( temp > 420 )) && _row warn temperature "$((temp / 10)) °C"

  free="$(_adb shell df -k /data 2>/dev/null | awk 'NR==2 {print int($4/1024)}')"
  if [[ -n "$free" ]] && (( free >= DEVICE_FREE_MB )); then _row ok phone-storage "${free} MB free"
  else _row FAIL phone-storage "${free:-?} MB free < $DEVICE_FREE_MB MB"; fi
  mkdir -p "$RT_ROOT"
  hostfree="$(df -Pm "$RT_ROOT" | awk 'NR==2 {print $4}')"
  if (( hostfree >= HOST_FREE_MB )); then _row ok host-storage "${hostfree} MB free under $RT_ROOT"
  else _row FAIL host-storage "${hostfree} MB free < $HOST_FREE_MB MB"; fi

  python3 -I "$UI_PY" keycheck "$KEY_FILE"; rc=$?
  case $rc in
    0) _row ok ai-key "present, one line, mode 600 (not shown)" ;;
    10) _row FAIL ai-key "missing or empty: $KEY_FILE" ;;
    11) _row FAIL ai-key "still reads PASTE_YOUR_KEY_HERE — refusing to start" ;;
    12) _row FAIL ai-key "not one line of [A-Za-z0-9_-]" ;;
    13) _row FAIL ai-key "mode is not 600" ;;
    *) _row FAIL ai-key "keycheck code $rc" ;;
  esac
  v="$(tr -d ' \n' < "$PROVIDER_FILE" 2>/dev/null)"
  case "$v" in anthropic|openrouter|openai) _row ok ai-provider "$v" ;; *) _row FAIL ai-provider "'$v' in $PROVIDER_FILE" ;; esac

  v="$(_adb shell settings get global stay_on_while_plugged_in | tr -d '\r')"
  [[ "$v" =~ ^[1-9][0-9]*$ ]] && _row ok stay-awake "stay_on_while_plugged_in=$v" || _row FAIL stay-awake "stay_on_while_plugged_in=$v"
  local s bad=""
  for s in window_animation_scale transition_animation_scale animator_duration_scale; do
    v="$(_adb shell settings get global $s | tr -d '\r')"
    [[ "$v" == 0 || "$v" == 0.0 ]] || bad+=" $s=$v"
  done
  [[ -z "$bad" ]] && _row ok animations "all three scales 0" || _row FAIL animations "${bad# }"
  v="$(_adb shell settings get system show_password | tr -d '\r')"
  [[ "$v" == 0 ]] && _row ok show-password "0" || _row FAIL show-password "'$v' (type_secret needs 0)"
  v="$(_adb shell locksettings get-disabled 2>/dev/null | tr -d '\r')"
  [[ "$v" == true ]] && _row ok screen-lock "none" || _row FAIL screen-lock "get-disabled=$v"
  v="$(_adb shell settings get global adb_allowed_connection_time | tr -d '\r')"
  [[ "$v" == 0 ]] && _row ok adb-auth "no timeout" || _row warn adb-auth "adb_allowed_connection_time=$v (USB key re-auth after that many ms idle)"
  if [[ -n "$RUN" && -e "$RUN/HALT" ]]; then _row FAIL halt "run is halted: recover first"; fi
  for v in python3 flock timeout; do command -v $v >/dev/null || _row FAIL host-tool "$v missing"; done

  printf '%s' "$out"
  if [[ -n "$RUN" ]]; then printf '# %s preflight %s\n%s' "$(_ts)" "$want" "$out" >> "$RUN/preflight.txt"; fi
  if (( fail )); then _log "preflight: FAIL"; return 4; fi
  if (( low )); then _log "preflight: battery low"; return 5; fi
  _log "preflight: ok"
  return 0
}

# --- battery pause -----------------------------------------------------------

_battery() { _adb shell dumpsys battery 2>/dev/null | tr -d '\r' | sed -n 's/^ *level: //p'; }
_charging() { _adb shell dumpsys battery 2>/dev/null | tr -d '\r' | grep -qE '(USB|AC) powered: true'; }
_awake() { _adb shell dumpsys power 2>/dev/null | grep -q 'mWakefulness=Awake'; }

cmd_charge_wait() {  # charge_wait [resume-level] [max-seconds] — pause, screen off
  _check_abort; _check_halt
  local want="${1:-$BATTERY_RESUME}" max="${2:-$CHARGE_WAIT_MAX}" start=$SECONDS lvl
  lvl="$(_battery)"
  [[ -n "$lvl" ]] || _die 6 "charge_wait: battery unreadable"
  (( lvl >= want )) && { echo "battery $lvl %"; return 0; }
  _charging || _die 5 "charge_wait: battery $lvl % and not charging"
  _log "PAUSE: battery $lvl % < $want %, waiting up to ${max}s"
  echo "rt: pausing for charge: $lvl % -> $want %" >&2
  # Screen off charges several times faster. No lock is set, so WAKEUP lands
  # back in the app, and the guard checks that before anything else is sent.
  (( PAUSE_SCREEN_OFF )) && _adb shell input keyevent KEYCODE_SLEEP
  while (( SECONDS - start < max )); do
    sleep 300
    lvl="$(_battery)"
    _log "PAUSE: battery ${lvl:-?} %"
    [[ -n "$lvl" ]] && (( lvl >= want )) && break
  done
  _awake || _adb shell input keyevent KEYCODE_WAKEUP
  sleep 2
  [[ -n "$RUN" ]] && _guard post
  lvl="$(_battery)"
  (( ${lvl:-0} >= want )) || _die 5 "charge_wait: battery still ${lvl:-?} % after ${max}s"
  _log "RESUME: battery $lvl %"
  echo "battery $lvl %"
}

# --- run, steps, resume ------------------------------------------------------

cmd_init() {  # init [--new] — pin the evidence folder (re-used unless --new)
  _check_abort
  mkdir -p "$RT_ROOT"
  if [[ "${1:-}" != --new ]] && _load_run; then
    echo "run (re-used): $RUN"; return 0
  fi
  local dir="$RT_ROOT/run-$(date +%Y%m%d-%H%M)" k=1
  while [[ -e "$dir" ]]; do dir="$RT_ROOT/run-$(date +%Y%m%d-%H%M)-$k"; k=$((k + 1)); done
  mkdir -p "$dir/steps" "$dir/logcat"
  printf 'id\tstatus\tstarted\tended\tnote\n' > "$dir/steps.tsv"
  echo "$dir" > "$RT_ROOT/current-run"
  RUN="$dir"
  _log "init (driver $(git -C "$RT_DIR" rev-parse --short HEAD 2>/dev/null || echo '?'))"
  echo "run: $RUN"
}

_last_status() { awk -F'\t' -v id="$1" 'NR > 1 && $1 == id {s = $2} END {print s}' "$RUN/steps.tsv"; }

cmd_step_begin() {  # step_begin ID [export|import]
  _check_abort; _check_halt; _need_run
  local id="${1:-}" kind="${2:-}" st lvl
  [[ "$id" =~ ^[A-Za-z0-9._-]+$ ]] || _die 2 "step_begin ID [export|import] (ID: letters, digits, . _ -)"
  [[ -z "$kind" || "$kind" == export || "$kind" == import ]] || _die 2 "step kind must be export or import"
  st="$(_last_status "$id")"
  case "$st" in
    pass|fail|skip|inconclusive) echo "done already: $id = $st"; return 3 ;;
  esac
  if [[ -f "$RUN/.step" && "$STEP_ID" != "$id" ]]; then
    _steplog "$STEP_ID" interrupted "superseded by $id"
  fi
  STEP_ID="$id" STEP_KIND="$kind"
  printf '%s\t%s\t%s\n' "$id" "$kind" "$(_ts)" > "$RUN/.step"
  mkdir -p "$RUN/steps/$id"
  cmd_logcat_start >/dev/null
  _awake || { _adb shell input keyevent KEYCODE_WAKEUP; sleep 1; }
  lvl="$(_battery)"
  if [[ -n "$lvl" ]] && (( lvl < BATTERY_FLOOR )); then
    cmd_charge_wait "$BATTERY_RESUME" || exit $?
  fi
  _guard post
  _adb shell log -t ONT-RT "STEP_BEGIN_$id" >/dev/null 2>&1
  _steplog "$id" "$([[ "$st" == started || "$st" == interrupted || "$st" == halted ]] && echo resumed || echo started)" "${kind:+picker:$kind}"
  _log "step_begin $id ${kind}"
  _evidence "begin"
  echo "step $id$([[ -n "$kind" ]] && echo " ($kind: DocumentsUI allowed)") -> $RUN/steps/$id"
}

cmd_step_end() {  # step_end pass|fail|skip|inconclusive [NOTE…]
  _check_abort; _need_run
  local status="${1:-}"; shift || true
  case "$status" in pass|fail|skip|inconclusive) ;; *) _die 2 "step_end pass|fail|skip|inconclusive [note]" ;; esac
  [[ -f "$RUN/.step" ]] || _die 2 "step_end: no step open"
  local note="$*"
  # Subshells: a fault found here writes HALT but must not stop the step
  # from being recorded.
  if [[ ! -e "$RUN/HALT" && ! -e "$RUN/.secret" ]]; then
    ( _evidence "end" ) || true
  fi
  ( _logscan ) 2>/dev/null || true
  if [[ -e "$RUN/HALT" ]]; then
    note+=" [halt at step end: $(grep -m1 '^reason=' "$RUN/HALT" | cut -d= -f2-)]"
  fi
  _steplog "$STEP_ID" "$status" "$note"
  _adb shell log -t ONT-RT "STEP_END_${STEP_ID}_$status" >/dev/null 2>&1
  _log "step_end $STEP_ID $status $*"
  local leak=0
  if [[ -e "$RUN/steps/$STEP_ID/.used-secret" ]]; then
    python3 -I "$UI_PY" audit "$KEY_FILE" "$RUN" >&2 || leak=1
  fi
  rm -f "$RUN/.step" "$RUN/.secret"
  echo "$STEP_ID: $status"
  (( leak )) && _die 1 "the AI key was found in the evidence (file names above): stop and scrub"
  return 0
}

cmd_resume() {  # where the pinned run stands
  _load_run || { echo "no run pinned"; return 1; }
  echo "run: $RUN"
  [[ -e "$ABORT_FILE" ]] && { echo "ABORTED:"; sed 's/^/  /' "$ABORT_FILE"; }
  [[ -e "$RUN/HALT" ]] && { echo "HALTED (call recover):"; sed 's/^/  /' "$RUN/HALT"; }
  awk -F'\t' 'NR > 1 {s[$1] = $2; if (!($1 in o)) {o[$1] = ++n; id[n] = $1}}
    END {for (i = 1; i <= n; i++) c[s[id[i]]]++; for (k in c) printf "  %-12s %d\n", k, c[k]}' "$RUN/steps.tsv"
  if [[ -f "$RUN/.step" ]]; then
    echo "open step (re-runs from its start on step_begin): $STEP_ID ${STEP_KIND}"
  fi
}

cmd_step_status() { _need_run; local s; s="$(_last_status "${1:-}")"; echo "${s:-none}"; [[ -n "$s" ]]; }

cmd_secret_audit() { _need_run; python3 -I "$UI_PY" audit "$KEY_FILE" "$RUN"; }

cmd_status() {
  [[ -e "$ABORT_FILE" ]] && { echo "ABORTED"; sed 's/^/  /' "$ABORT_FILE"; } || echo "no abort flag"
  if [[ -n "$RUN" ]]; then cmd_resume; else echo "no run pinned"; fi
  return 0
}

# --- logs ---------------------------------------------------------------------

_logcat_alive() {
  local pid
  [[ -f "$RUN/.logcat" ]] || return 1
  pid="$(cut -f2 "$RUN/.logcat")"
  [[ -n "$pid" && -r "/proc/$pid/cmdline" ]] || return 1
  tr '\0' ' ' < "/proc/$pid/cmdline" | grep -q -- "-s $SERIAL logcat"
}

cmd_logcat_start() {  # idempotent; a new numbered file each time, never `logcat -c`
  _check_abort; _need_run
  if _logcat_alive; then echo "logcat running -> $(cut -f1 "$RUN/.logcat")"; return 0; fi
  local n file
  n="$(find "$RUN/logcat" -name 'logcat-*.txt' 2>/dev/null | wc -l)"
  file="$RUN/logcat/logcat-$(printf '%03d' $((n + 1))).txt"
  # 9>&- : the background logcat must not inherit (and so hold) the run lock.
  nohup "$ADB_BIN" -s "$SERIAL" logcat -v threadtime -T 1 > "$file" 2>&1 < /dev/null 9>&- &
  printf '%s\t%s\n' "$file" "$!" > "$RUN/.logcat"
  disown 2>/dev/null || true
  _log "logcat -> $file (pid $!)"
  echo "logcat -> $file"
}

cmd_logcat_stop() {  # by recorded pid only, after checking it is our logcat
  _need_run
  if _logcat_alive; then kill "$(cut -f2 "$RUN/.logcat")"; _log "logcat stopped"; fi
  rm -f "$RUN/.logcat"
}

cmd_errors() {  # crash / ANR / Flutter-error lines recorded for the open step
  _need_run
  ( _logscan ) 2>/dev/null || true
  cat "$RUN/steps/$STEP_ID/errors.txt" 2>/dev/null || echo "none"
}

cmd_mark() {  # mark TEXT — a line in logcat and run.log
  _reader
  local m; m="$(_slug "$*")"
  _adb shell log -t ONT-RT "MARK_$m" >/dev/null 2>&1
  _log "MARK $*"
}

# --- system state (read only) ------------------------------------------------

cmd_version() { _check_abort; _adb shell dumpsys package "$PKG" | grep -m2 -E 'versionName|versionCode'; }
cmd_alarms() { _check_abort; _adb shell dumpsys alarm | grep -B2 -A6 "$PKG" | grep -E "$PKG|when|origWhen|type=" | head -20; }
cmd_notif() { _check_abort; _adb shell dumpsys notification --noredact | grep -A40 "pkg=$PKG" | grep -E "pkg=|android.title|android.text|postTime" | head -12; }
cmd_clock() { _check_abort; _adb shell "date '+%F %T %Z'"; }

cmd_help() { sed -n '2,30p' "${BASH_SOURCE[0]}"; echo; echo "Actions: see README.md"; }

# ---------------------------------------------------------------------------
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  shift || true
  case "$ACTION" in
    ""|help|-h|--help) cmd_help; exit 2 ;;
  esac
  declare -F "cmd_$ACTION" >/dev/null || { echo "rt: unknown action '$ACTION'" >&2; cmd_help >&2; exit 2; }
  # Refuse before anything else, the lock included; a call that waited on
  # the lock reads the flag again.
  case "$ACTION" in status|resume) ;; *) _check_abort ;; esac
  mkdir -p "$RT_ROOT"
  exec 9>"$RT_ROOT/.lock"
  flock -w 900 9 || { echo "rt: another rt.sh call holds the lock" >&2; exit 2; }
  case "$ACTION" in status|resume) ;; *) _check_abort ;; esac
  _load_run || true
  case "$ACTION" in
    recover|step_end|errors|status|resume|step_status|secret_audit|logcat_stop|init|preflight|where|version|clock) ;;
    *) _check_halt ;;
  esac
  "cmd_$ACTION" "$@"
fi
