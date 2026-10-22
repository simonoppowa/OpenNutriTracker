#!/usr/bin/env bash
# Offline self-test for rt.sh: drives it against fake-adb (no phone, no adb).
#   bash docs/release-tests/2.5.0/tools/selftest/run.sh
# Every scenario gets its own RT_ROOT and fake device under a temp dir.
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RT="$HERE/../rt.sh"
UI="$HERE/../ui.py"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/rt-selftest.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT   # fake logcat captures exit once their dir is gone
PKG=com.opennutritracker.ont.opennutritracker
APPWIN="Window{1 u0 $PKG/$PKG.MainActivity}"
pass=0 fail=0

ok() { pass=$((pass + 1)); printf '  ok    %s\n' "$1"; }
bad() { fail=$((fail + 1)); printf '  FAIL  %s\n' "$1"; }
expect() {  # expect CODE "label" cmd…
  local want="$1" label="$2"; shift 2
  "$@" > "$TMP/out" 2>&1
  local got=$?
  if [[ "$got" == "$want" ]]; then ok "$label (exit $got)"; else bad "$label: exit $got, wanted $want"; sed 's/^/        /' "$TMP/out" | tail -5; fi
}
inputs() { [[ -f "$FAKE/input.log" ]] && wc -l < "$FAKE/input.log" || echo 0; }
calls() { wc -l < "$FAKE/calls.log" 2>/dev/null || echo 0; }

node() {  # id text desc bounds [class] [pkg] [focused] [password]
  printf '<node index="0" text="%s" resource-id="%s" class="%s" package="%s" content-desc="%s" checkable="false" checked="false" clickable="true" enabled="true" focusable="true" focused="%s" scrollable="false" long-clickable="false" password="%s" selected="false" bounds="%s" />' \
    "$2" "$1" "${5:-android.view.View}" "${6:-$PKG}" "$3" "${7:-false}" "${8:-false}" "$4"
}
dump() {  # dump PKG nodes…
  local p="$1"; shift
  printf '<?xml version="1.0" encoding="UTF-8" standalone="yes" ?><hierarchy rotation="0"><node index="0" text="" resource-id="" class="android.widget.FrameLayout" package="%s" content-desc="" bounds="[0,0][1080,2400]">%s</node></hierarchy>' "$p" "$*"
}
HOME_XML="$(dump $PKG \
  "$(node home-kcal-gauge '' '1654 kcal left' '[100,800][980,1200]')" \
  "$(node add-activity-placeholder '' '' '[36,2040][1044,2146]')" \
  "$(node fab-add-item '' '' '[466,2059][614,2206]')" \
  "$(node nav-home '' Home '[0,2140][228,2328]')" \
  "$(node nav-you '' You '[852,2140][1080,2328]')")"
DIALOG_XML="$(dump $PKG \
  "$(node '' '' '' '[105,553][975,1912]')" \
  "$(node '' '' 'Per-meal split' '[168,616][912,778]')" \
  "$(node dlg-list '' '' '[168,820][912,1660]')" \
  "$(node '' '' CANCEL '[447,1723][666,1849]' android.widget.Button)" \
  "$(node '' '' OK '[687,1723][912,1849]' android.widget.Button)")"
KEYLEN=40
BULLETS="$(python3 -c "print('•' * $KEYLEN)")"
SECRET_XML="$(dump $PKG \
  "$(node '' '' Back '[0,140][148,264]')" \
  "$(node ai-assist-key-field "$BULLETS" '' '[60,900][1020,1040]' android.widget.EditText $PKG true true)" \
  "$(node ai-assist-save-key '' Save '[700,1700][1000,1820]' android.widget.Button)")"
PLAIN_FIELD_XML="$(dump $PKG \
  "$(node '' '' Back '[0,140][148,264]')" \
  "$(node ai-assist-key-field '' '' '[60,900][1020,1040]' android.widget.EditText $PKG true false)")"
PICKER_XML="$(dump com.google.android.documentsui \
  "$(node android:id/title backup.zip '' '[60,300][1020,420]' android.widget.EditText com.google.android.documentsui)" \
  "$(node android:id/button1 SPEICHERN '' '[700,2100][1000,2220]' android.widget.Button com.google.android.documentsui)")"
LAUNCHER_XML="$(dump app.lawnchair "$(node '' Gmail '' '[100,100][300,300]' android.widget.TextView app.lawnchair)")"

raw() {  # raw FILE dark|red
  python3 -I - "$1" "$2" <<'EOF'
import sys
w, h = 54, 120
px = bytes([30, 30, 30, 255]) * (w * h)
if sys.argv[2] == "red":
    half = bytes([137, 2, 1, 255]) * (w * h // 2)
    px = px[: len(px) - len(half)] + half
hdr = w.to_bytes(4, "little") + h.to_bytes(4, "little") + (1).to_bytes(4, "little") + (0).to_bytes(4, "little")
open(sys.argv[1], "wb").write(hdr + px)
EOF
}

KEY="sk-or-v1-$(python3 -c "print('a1' * 15 + 'b')")"   # 40 chars, fake
fresh() {  # fresh NAME — new fake phone, new evidence root, app in focus
  export FAKE="$TMP/$1/phone" RT_ROOT="$TMP/$1/evidence"
  mkdir -p "$FAKE" "$TMP/$1/cfg"
  : > "$FAKE/calls.log"
  echo "$APPWIN" > "$FAKE/focus"
  echo 4242 > "$FAKE/pid"
  printf '%s\n' "$HOME_XML" > "$FAKE/dump.xml"
  raw "$FAKE/screen.raw" dark
  export RT_KEY_FILE="$TMP/$1/cfg/ai-key" RT_PROVIDER_FILE="$TMP/$1/cfg/ai-provider"
  printf '%s\n' "$KEY" > "$RT_KEY_FILE"; chmod 600 "$RT_KEY_FILE"
  echo openrouter > "$RT_PROVIDER_FILE"
  bash "$RT" init >/dev/null
}
rt() { bash "$RT" "$@"; }
export ADB_BIN="$HERE/fake-adb" RT_SETTLE=0 RT_LAUNCH_SETTLE=0 RT_USB_WAIT=1 RT_HOST_FREE_MB=1

echo "1. ordinary input"
fresh basic
expect 0 "tap a selector" rt tap id=home-kcal-gauge
[[ "$(tail -1 "$FAKE/input.log")" == "tap 540 1000" ]] && ok "tap sent at the node centre" || bad "tap coordinates: $(tail -1 "$FAKE/input.log")"
ls "$RT_ROOT"/run-*/steps/_nostep/001-tap_id=home-kcal-gauge.png >/dev/null 2>&1 && ok "evidence png kept" || bad "no evidence png"
ls "$RT_ROOT"/run-*/steps/_nostep/001-tap_id=home-kcal-gauge.xml >/dev/null 2>&1 && ok "evidence dump kept" || bad "no evidence dump"
n=$(inputs)
expect 98 "tap under the FAB refused" rt tap id=add-activity-placeholder
expect 98 "KEYCODE_HOME refused" rt key KEYCODE_HOME
expect 98 "keycode 3 refused" rt key 3
expect 98 "KEYCODE_APP_SWITCH refused" rt key KEYCODE_APP_SWITCH
expect 98 "BACK on the main screen refused" rt back
expect 98 "type of an API-key-looking text refused" rt type "sk-ant-abcdefghijklmnopqrstuvwxyz"
expect 98 "type of the key itself refused" rt type "x${KEY}x"
expect 1 "tap of an absent selector" rt tap id=nope
[[ "$(inputs)" == "$n" ]] && ok "none of the refusals sent input" || bad "a refusal sent input"
expect 2 "tapxy does not exist" rt tapxy 10 10

echo "2. dialogs"
printf '%s\n' "$DIALOG_XML" > "$FAKE/dump.xml"
n=$(inputs)
expect 98 "swipe with a dialog open refused" rt swipe up
[[ "$(inputs)" == "$n" ]] && ok "no swipe sent" || bad "swipe went out"
expect 0 "swipe_in the dialog's own list" rt swipe_in id=dlg-list up
expect 0 "BACK with a dialog open" rt back
echo true > "$FAKE/kb"
printf '%s\n' "$HOME_XML" > "$FAKE/dump.xml"
expect 98 "swipe with the keyboard up refused" rt swipe up
rm "$FAKE/kb"
expect 0 "swipe on the main screen" rt swipe up

echo "3. focus loss after an input -> ABORT"
fresh abort
echo "Window{9 u0 app.lawnchair/app.lawnchair.LawnchairLauncher}" > "$FAKE/focus_after_input"
expect 99 "tap whose result leaves the app" rt tap id=home-kcal-gauge
[[ -f "$RT_ROOT/ABORT" ]] && ok "ABORT flag written" || bad "no ABORT flag"
grep -q 'lawnchair' "$RT_ROOT/ABORT" && ok "flag names the focused window" || bad "flag lacks focus"
grep -q $'\taborted\t' "$RT_ROOT"/run-*/steps.tsv && ok "step log records the abort" || bad "step log silent"
[[ "$(inputs)" == 1 ]] && ok "exactly one input event went out" || bad "inputs: $(inputs)"
c=$(calls)
for a in "tap id=home-kcal-gauge" "swipe up" "back" "key KEYCODE_ENTER" "type hello" "type_secret" "launch" "restart" "recover" "prep" "pm_clear" "ls" "guard" "where" "preflight 2.4.0" "init --new" "step_begin x" "logcat_start" "charge_wait"; do
  # shellcheck disable=SC2086
  expect 99 "after abort: $a" rt $a
done
[[ "$(calls)" == "$c" ]] && ok "no adb call at all after the abort" || bad "adb was called after the abort ($(calls) vs $c)"
expect 0 "status still answers" rt status
grep -q ABORTED "$TMP/out" && ok "status shows ABORTED" || bad "status silent"

echo "4. foreign focus before an input -> ABORT, nothing sent"
fresh prefocus
echo "Window{9 u0 com.google.android.gm/com.google.android.gm.ConversationListActivityGmail}" > "$FAKE/focus"
printf '%s\n' "$LAUNCHER_XML" > "$FAKE/dump.xml"
expect 99 "tap while another app is in front" rt tap id=home-kcal-gauge
[[ "$(inputs)" == 0 ]] && ok "no input sent" || bad "input was sent"
fresh prefocus2
echo "Window{9 u0 com.google.android.gm/x}" > "$FAKE/focus"
expect 99 "dump looked like the app, focus did not: pre-input guard" rt tap id=home-kcal-gauge
[[ "$(inputs)" == 0 ]] && ok "no input sent" || bad "input was sent"
fresh nullfocus
echo "null" > "$FAKE/focus"
expect 99 "focus null for good" rt tap id=home-kcal-gauge
[[ "$(inputs)" == 0 ]] && ok "no input sent" || bad "input was sent"

echo "5. DocumentsUI only inside export/import steps"
fresh picker
echo "Window{5 u0 com.google.android.documentsui/com.android.documentsui.picker.PickActivity}" > "$FAKE/focus_after_input"
expect 0 "plain step begins" rt step_begin 10-settings
expect 99 "picker opened outside an export step aborts" rt tap id=home-kcal-gauge
fresh picker2
expect 0 "export step begins" rt step_begin 12-export export
echo "Window{5 u0 com.google.android.documentsui/com.android.documentsui.picker.PickActivity}" > "$FAKE/focus_after_input"
expect 0 "tap that opens the picker" rt tap id=home-kcal-gauge
printf '%s\n' "$PICKER_XML" > "$FAKE/dump.xml"
expect 0 "tap Save inside DocumentsUI" rt tap id=android:id/button1
echo "Window{9 u0 com.android.chrome/x}" > "$FAKE/focus_after_input"
expect 99 "a third app aborts even in an export step" rt tap id=android:id/button1

echo "6. crash, ANR, ErrorWidget -> HALT, then recover"
fresh crash
printf '%s\n' \
  "10-22 14:00:01.000  4242  4242 E AndroidRuntime: FATAL EXCEPTION: main" \
  "10-22 14:00:01.000  4242  4242 E AndroidRuntime: Process: $PKG, PID: 4242" \
  "10-22 14:00:01.000  4242  4242 E AndroidRuntime: java.lang.IllegalStateException: boom" > "$FAKE/crash_after_input"
echo "Window{9 u0 app.lawnchair/app.lawnchair.LawnchairLauncher}" > "$FAKE/focus_after_input"
expect 0 "step begins" rt step_begin 20-crash
expect 97 "tap that crashes the app halts" rt tap id=home-kcal-gauge
[[ ! -f "$RT_ROOT/ABORT" ]] && ok "a crash is not an abort" || bad "crash wrote ABORT"
n=$(inputs)
expect 97 "tap refused while halted" rt tap id=home-kcal-gauge
expect 97 "ls refused while halted" rt ls
[[ "$(inputs)" == "$n" ]] && ok "nothing sent while halted" || bad "input while halted"
expect 0 "step_end records the failure" rt step_end fail "crash on tap"
expect 0 "recover relaunches" rt recover
expect 0 "input works again" rt tap id=home-kcal-gauge
fresh uiautomator
printf '%s\n' \
  "10-22 14:00:01.000  7777  7777 D AndroidRuntime: >>>>>> START com.android.internal.os.RuntimeInit uid 2000 <<<<<<" \
  "10-22 14:00:01.000  7777  7777 E AndroidRuntime: FATAL EXCEPTION: main" \
  "10-22 14:00:01.000  7777  7777 E AndroidRuntime: Process: uiautomator, PID: 7777" > "$FAKE/crash_after_input"
echo "Window{9 u0 app.lawnchair/app.lawnchair.LawnchairLauncher}" > "$FAKE/focus_after_input"
expect 99 "uiautomator's own FATAL is not the app's crash: abort" rt tap id=home-kcal-gauge
fresh anr
echo "Window{9 u0 Application Not Responding: $PKG}" > "$FAKE/focus_after_input"
expect 97 "ANR dialog halts" rt tap id=home-kcal-gauge
grep -q 'reason=anr' "$RT_ROOT"/run-*/HALT && ok "halt reason anr" || bad "halt reason"
expect 0 "recover after ANR (force-stop + start)" rt recover
grep -q 'am force-stop' "$FAKE/calls.log" && ok "ANR recovery force-stopped" || bad "no force-stop"
fresh errorwidget
raw "$FAKE/screen_after_input" red
expect 97 "red ErrorWidget after a tap halts" rt tap id=home-kcal-gauge
grep -q 'reason=errorwidget' "$RT_ROOT"/run-*/HALT && ok "halt reason errorwidget" || bad "halt reason"
expect 97 "BACK refused after the ErrorWidget" rt back

echo "7. type_secret"
fresh secret
printf 'PASTE_YOUR_KEY_HERE\n' > "$RT_KEY_FILE"
printf '%s\n' "$SECRET_XML" > "$FAKE/dump.xml"
expect 0 "step begins" rt step_begin 30-ai
expect 98 "placeholder key refused" rt type_secret
printf '%s\r\n' "$KEY" > "$RT_KEY_FILE"
expect 98 "key with CRLF refused" rt type_secret
printf '%s\n' "$KEY" > "$RT_KEY_FILE"; chmod 644 "$RT_KEY_FILE"
expect 98 "world-readable key refused" rt type_secret
chmod 600 "$RT_KEY_FILE"
echo 1 > "$FAKE/show_password"
expect 98 "show_password=1 refused" rt type_secret
rm "$FAKE/show_password"
printf '%s\n' "$PLAIN_FIELD_XML" > "$FAKE/dump.xml"
expect 98 "a non-password field refused" rt type_secret
[[ ! -f "$FAKE/typed.txt" ]] && ok "nothing typed into it" || bad "typed into a plain field"
printf '%s\n' "$SECRET_XML" > "$FAKE/dump.xml"
expect 0 "type_secret into the key field" rt type_secret
[[ "$(cat "$FAKE/typed.txt")" == "$KEY" ]] && ok "the key reached the phone on stdin" || bad "stdin mismatch"
grep -qF "$KEY" "$FAKE/calls.log" && bad "key in an adb argv" || ok "key in no adb argv"
expect 98 "shot refused in the secret window" rt shot after-typing
expect 98 "save refused in the secret window" rt save after-typing
expect 0 "tap Save" rt tap id=ai-assist-save-key
expect 0 "shot allowed again" rt shot after-save
expect 0 "step_end runs the key audit" rt step_end pass
grep -rqF "$KEY" "$RT_ROOT" && bad "key found under the evidence root" || ok "key nowhere under the evidence root"
run_dir=("$RT_ROOT"/run-*)
cp "$RT_KEY_FILE" "${run_dir[0]}/steps/30-ai/leak.txt"
expect 1 "secret_audit catches a planted copy" rt secret_audit
grep -qF "$KEY" "$TMP/out" && bad "audit printed the key" || ok "audit names files, not the key"

echo "8. resumable step log"
fresh resume
expect 0 "step a" rt step_begin a
expect 0 "a passes" rt step_end pass
expect 3 "step a again: done already" rt step_begin a
expect 0 "step b begins" rt step_begin b
expect 0 "step b re-entered after an interruption" rt step_begin b
grep -q $'^b\tresumed' "$RT_ROOT"/run-*/steps.tsv && ok "b logged as resumed" || bad "no resumed row"
expect 0 "init re-uses the pinned run" rt init
grep -q 're-used' "$TMP/out" && ok "same run folder" || bad "new folder"
expect 0 "resume summary" rt resume
grep -q 'open step.*b' "$TMP/out" && ok "resume names the open step" || bad "resume output: $(cat "$TMP/out")"
expect 0 "step c supersedes b" rt step_begin c
grep -q $'^b\tinterrupted' "$RT_ROOT"/run-*/steps.tsv && ok "b marked interrupted" || bad "b not interrupted"
expect 2 "bad step id refused" rt step_begin "a b"

echo "9. preflight, prep, battery"
fresh preflight
expect 0 "preflight passes on a ready phone" rt preflight 2.4.0
expect 4 "wrong version" rt preflight 2.5.0
expect 4 "no expected version" rt preflight
printf 'PASTE_YOUR_KEY_HERE\n' > "$RT_KEY_FILE"
expect 4 "placeholder key refuses to start" rt preflight 2.4.0
grep -q 'PASTE_YOUR_KEY_HERE' "$TMP/out" && ok "says why" || bad "reason missing"
printf '%s\n' "$KEY" > "$RT_KEY_FILE"
echo 22 > "$FAKE/battery"
expect 5 "battery 22 % is below the start floor" rt preflight 2.4.0
echo 80 > "$FAKE/battery"
echo "Window{9 u0 app.lawnchair/x}" > "$FAKE/focus"
expect 4 "app not in focus" rt preflight 2.4.0
[[ ! -f "$RT_ROOT/ABORT" ]] && ok "preflight reports, it does not abort" || bad "preflight aborted"
echo "$APPWIN" > "$FAKE/focus"
echo "ABCDEF" > "$FAKE/serial"
expect 4 "another serial" rt preflight 2.4.0
rm "$FAKE/serial"
expect 1 "prep --check finds missing grants" rt prep --check
grep -q 'pm grant' "$FAKE/calls.log" && bad "--check granted" || ok "--check changes nothing"
expect 0 "prep grants" rt prep
c=$(grep -c 'pm grant' "$FAKE/calls.log")
expect 0 "prep again is a no-op" rt prep
[[ "$(grep -c 'pm grant' "$FAKE/calls.log")" == "$c" ]] && ok "no second grant" || bad "re-granted"
expect 0 "pm_clear re-runs prep" rt pm_clear
[[ "$(grep -c 'pm grant' "$FAKE/calls.log")" -gt "$c" ]] && ok "grants re-applied after pm clear" || bad "grants not re-applied"
echo 20 > "$FAKE/battery"; echo false > "$FAKE/usb"
expect 5 "step_begin below the floor, not charging: pause code" rt step_begin low
echo true > "$FAKE/usb"; echo 80 > "$FAKE/battery"

echo "10. USB gone"
fresh usb
touch "$FAKE/offline"
expect 6 "phone not answering" rt tap id=home-kcal-gauge
[[ ! -f "$RT_ROOT/ABORT" ]] && ok "a lost USB link is not an abort" || bad "USB loss wrote ABORT"

echo "11. log scanning"
L="$TMP/logcat.txt"
printf '%s\n' \
  "10-22 14:00:01.000  7777  7777 D AndroidRuntime: >>>>>> START com.android.internal.os.RuntimeInit uid 2000 <<<<<<" \
  "10-22 14:00:01.000  7777  7777 D AndroidRuntime: Calling main entry com.android.commands.uiautomator.Launcher" \
  "10-22 14:00:01.000  7777  7777 D AndroidRuntime: Shutting down VM" \
  "10-22 14:00:02.000  4242  4242 I flutter : FINE: IntakeDataSource: Adding new intake items to db" > "$L"
out="$(python3 -I "$UI" logscan "$L" 0 $PKG)"
[[ "$(grep -vc '^offset=' <<< "$out")" == 0 ]] && ok "uiautomator noise is not a finding" || bad "false positive: $out"
printf '%s\n' \
  "10-22 14:00:03.000  4242  4242 I flutter : ══╡ EXCEPTION CAUGHT BY WIDGETS LIBRARY ╞══" \
  "10-22 14:00:04.000  1000  1100 E ActivityManager: ANR in $PKG ($PKG/.MainActivity)" \
  "10-22 14:00:05.000  4242  4242 E AndroidRuntime: FATAL EXCEPTION: main" >> "$L"
off="$(sed -n 's/^offset=//p' <<< "$out")"
out="$(python3 -I "$UI" logscan "$L" "$off" $PKG)"
grep -q '^FLUTTER' <<< "$out" && grep -q '^ANR' <<< "$out" && ok "Flutter error and ANR found" || bad "missed: $out"
off2="$(sed -n 's/^offset=//p' <<< "$out")"
echo "10-22 14:00:05.000  4242  4242 E AndroidRuntime: Process: $PKG, PID: 4242" >> "$L"
out="$(python3 -I "$UI" logscan "$L" "$off2" $PKG)"
grep -q '^CRASH' <<< "$out" && ok "a FATAL split across two scans is still found" || bad "split FATAL missed: $out"

echo
echo "selftest: $pass passed, $fail failed"
(( fail == 0 ))
