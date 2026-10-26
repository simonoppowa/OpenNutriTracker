# rt.sh — the driver for the unattended 2.5.0 run

The adb driver for the 2.5.0 release run on the Pixel 6 ([#1432](https://github.com/simonoppowa/OpenNutriTracker/issues/1432), map [#1425](https://github.com/simonoppowa/OpenNutriTracker/issues/1425)). It started as `st.sh`/`ui.py` from the settings run (`research/settings-pixel-test`) and was rebuilt for a run of several hours with nobody watching. Everything the settings run learnt the hard way is enforced in the driver itself, so no caller has to remember it.

```bash
RT=docs/release-tests/2.5.0/tools/rt.sh
bash $RT init
bash $RT launch
bash $RT preflight 2.5.0        # 0 = go, 4 = refuse, 5 = charge first
bash $RT prep
bash $RT step_begin 07-favourites; rc=$?    # 3 = done in an earlier session: skip it
bash $RT tap id=nav-diary
bash $RT step_end pass "starred food listed under Favourites"
```

The phone is pinned to the USB serial `18101FDF60010M`, which can't be overridden. The package is `com.opennutritracker.ont.opennutritracker` (`full`). Evidence goes to `~/Documents/ont-release-2.5.0-evidence/` (`RT_ROOT`). Only stdlib Python 3, `flock` and `timeout` are needed on the laptop.

**One action per call, and read every exit code.** A call that exits 99 or 97 has done its own clean-up, and the caller's job is to stop (99) or to record the step and recover (97). Looping past either is safe now, because every later call refuses without touching adb, but a loop that does that still wastes the run.

## Exit codes

| Code | Meaning | What the caller does |
|---|---|---|
| 0 | done | carry on |
| 1 | soft miss: selector not on screen, `wait` timed out, `prep` incomplete, key found by the audit | the step decides (retry, or record *fail* / *inconclusive*) |
| 2 | usage error, or no run pinned (`init`) | fix the script |
| 3 | `step_begin`: this step already has a final status in this run | skip the step (this is how a resumed run moves past finished work) |
| 4 | `preflight` refused (wrong serial, model, version, focus, key file, settings, storage) | don't start; the table says which row |
| 5 | battery below the floor and not recovering (not charging, or still low after `RT_CHARGE_WAIT_MAX`) | pause the run, try again later |
| 6 | the phone stopped answering on its USB serial (after waiting `RT_USB_WAIT` s) | pause; once it's back, `step_begin` re-checks everything |
| 97 | **HALT**: the app crashed, hit an ANR, or showed a red ErrorWidget. `$RUN/HALT` holds the reason | `step_end fail "…"`, then `recover`. Until then only `recover`, `step_end`, `errors`, `status`, `resume` and the read-only system queries run |
| 98 | **refused**, nothing sent: HOME or another key off the allowlist, BACK with nothing to go back from, a swipe with a dialog or the keyboard open, a target under the FAB or the nav bar, key-like text in `type`, a bad key file or `show_password` ≠ 0 for `type_secret`, a screenshot while the secret window is open | change the script |
| 99 | **ABORT**: focus left the app. `$RT_ROOT/ABORT` holds the time, the window and the step, and the window was screenshotted | **stop the run for good.** Every later call exits 99 without an adb call. Only a person who has looked at the phone deletes the file |

## Actions

Selectors (`ui.py`): `id=RESOURCE_ID`, `text=LABEL`, `text^=PREFIX`, `text~=FRAGMENT`, `edit=N` (the N-th text field, top to bottom), each optionally `@K` for the K-th match. Labels are `text` or `content-desc`. There's no coordinate tap: every tap resolves a selector against a dump taken in the same call, and the node must belong to an allowed package.

**Input.** Each one reads focus right before the event and again after it, then saves evidence and runs the fault checks:

| Action | Notes |
|---|---|
| `tap SEL` | refused (98) if the centre falls under `fab-add-item` or a `nav-*` item |
| `longpress SEL` | 900 ms |
| `slider SEL FRACTION [bottom]` | taps the track at FRACTION of its usable width (inset `RT_SLIDER_INSET`, 63 px). Read the value back afterwards |
| `type TEXT` | into the focused field; logged in full, so refused if TEXT contains the key or looks like an API key |
| `type_secret [SEL]` | the AI key, see below. SEL defaults to `id=ai-assist-key-field` |
| `clear [N]` / `field SEL VALUE` | N deletes (default 64) / tap + clear + type |
| `done` | ENTER |
| `key KEYCODE` | allowlist only: ENTER, DEL, MOVE_END, MOVE_HOME (cursor), TAB, DPAD_LEFT/RIGHT |
| `kb_hide` | BACK, but only while the keyboard is up |
| `back` | only with the keyboard, a dialog or sheet, a Back/Close button in the app bar, or DocumentsUI in a picker step on screen. On the main screen, or on one whose nav bar an ErrorWidget has hidden, it is refused |
| `swipe up\|down` | refused with a dialog or sheet open (it moved the per-meal sliders last time) and with the keyboard up |
| `swipe_in SEL up\|down` | swipes inside SEL's bounds only: the deliberate way to scroll a dialog's list |
| `scroll_to SEL [max]` | swipes until SEL sits between y 300 and 2000, clear of the FAB |

**Reading** (no input): `ls`, `get SEL`, `has SEL` (exit 0/1), `state` (nav / modal / back / focused-edit flags), `wait SEL [s]`, `save NAME` (screenshot + dump + listing as named evidence), `shot NAME`, `guard` (the focus check on its own; it aborts like any other), `where` (prints focus and pid, doesn't abort), `version`, `alarms`, `notif`, `clock`, `errors`, `mark TEXT`.

**App lifecycle**

| Action | Notes |
|---|---|
| `launch` | `am start -W`, without a force-stop, so reminder alarms survive |
| `restart` | force-stop + start. **Cancels the app's reminder alarm**, which the run log notes |
| `recover` | after a HALT: `am start` after a crash, force-stop + start after an ANR or an ErrorWidget. More than `RT_MAX_RECOVER` (5) in one run turns into an ABORT |
| `prep [--check]` | idempotent per-path prep: `pm grant` POST_NOTIFICATIONS, health.READ_EXERCISE, health.READ_TOTAL_CALORIES_BURNED and CAMERA (`RT_GRANTS`), each checked first and re-checked after. `--check` only reports (exit 1 if any are missing). Device settings are checked by `preflight` and never changed by the driver |
| `pm_clear` | `pm clear`, then `prep`. A cleared app has lost its grants, so the two always go together |
| `install APK` | `adb install -r`, then `prep` |

**Run and steps**

| Action | Notes |
|---|---|
| `init [--new]` | pins the run folder in `$RT_ROOT/current-run`. Re-uses the pinned one unless `--new` |
| `preflight [VERSION]` | serial (USB, `ro.serialno`), model `oriole`, installed versionName = VERSION (or `RT_EXPECT_VERSION`), the app in focus, charging, battery ≥ `RT_BATTERY_START` (40 %), ≥ 2 GB free on the phone and ≥ 4 GB on the laptop, the key file (present, one line of `[A-Za-z0-9_-]`, mode 600, **not** `PASTE_YOUR_KEY_HERE`), the provider file, stay-awake, the three animation scales 0, `show_password` 0, no screen lock, no HALT. Read-only. It prints a table, appends it to `preflight.txt` and exits 0, 4 or 5 |
| `step_begin ID [export\|import]` | exits 3 if ID already has a final status. Otherwise: starts logcat if it isn't running, wakes the screen if it's asleep, **pauses for charge** below `RT_BATTERY_FLOOR` (25 %) until `RT_BATTERY_RESUME` (40 %), runs the guard, logs `started` (or `resumed`) and takes a `begin` screenshot. `export`/`import` allows DocumentsUI in focus for this step only |
| `step_end pass\|fail\|skip\|inconclusive [NOTE]` | takes an `end` screenshot, scans the log, records the status. If the step used `type_secret`, it also audits the whole run folder for the key |
| `charge_wait [LEVEL] [MAX_S]` | screen off (`RT_PAUSE_SCREEN_OFF=1`), polls every 5 min, wakes and re-checks focus |
| `resume` / `status` / `step_status ID` | where the pinned run stands. These work even after an ABORT |
| `logcat_start` / `logcat_stop` | `logcat_start` is idempotent. Each start writes a new `logcat/logcat-NNN.txt` and never runs `logcat -c`, so nothing is overwritten. `logcat_stop` kills by recorded pid after checking that pid's command line, never with `pkill -f` |
| `secret_audit` | lists the files under the run folder that contain the key, by name. Exit 1 if there are any |

## The focus guard and the abort flag

- **The check.** `mCurrentFocus`, the app's pid and the phone's clock are read in a single adb round trip. A `null` focus (an activity transition) is read again for up to 3 s, and a foreign window gets one more look 0.7 s later.
- **When it runs.** Right before every input event and right after it. It also runs whenever a dump has no content from an allowed package, so a foreign window always produces an ABORT and never just a "selector not found" that a loop would retry.
- **Allowed in focus.** The app always. `com.google.android.documentsui` only while the open step was begun with `export` or `import`. Anything else aborts, inside a picker step too.
- **What the abort does.** `ABORT` is written *first*, before the screenshot and the log lines, so the stop holds even if the rest fails. It lives in `$RT_ROOT`, not in the run folder, so `init --new` doesn't get past it. Every action except `status` and `resume` checks it before the run lock and again after it, and so before any adb call.
- **What isn't an abort.** A crash or ANR of the app is a HALT, not an ABORT. That needs one of: the system's crash or ANR dialog naming the package; or the app's process gone (or restarted under a new pid) **and** `logcat -b crash` since the last good check showing `FATAL EXCEPTION` with `Process: <pkg>` or a native `>>> <pkg> <<<`. A focus loss without that evidence is always an ABORT. A lost USB link exits 6, not 99.
- **The logcat filter.** uiautomator, `am` and `input` run as `app_process`. Every dump logs `AndroidRuntime: START … RuntimeInit`, `Calling main entry …uiautomator…` and `Shutting down VM`, and now and then a `FATAL EXCEPTION` of their own. Findings count only when the `Process:` line names the app. Over the settings run's 113 k-line logcat (551 dumps) this gives zero false positives.
- **The ErrorWidget.** It's detected from the screenshot, not from logcat. The settings run's red "Duplicate keys" screens left **no** `EXCEPTION CAUGHT` line in logcat, so a log check alone would have missed every one. After every input action the raw `screencap` is sampled for Flutter's debug ErrorWidget red, (137,2,1) on the dark theme. Above 2 % of the screen, the driver halts. Measured on the settings run's evidence, the four ErrorWidget screenshots score 0.32–0.70 and every other screenshot (~130) scores ≤ 0.0003. `EXCEPTION CAUGHT BY …`, `Another exception was thrown` and `Unhandled Exception` lines are still collected per step as warnings in `errors.txt`.

## type_secret

1. **Checks.** It refuses (98) unless the key file passes `keycheck`: present, exactly one line (`\r` and second lines are refused), `[A-Za-z0-9_-]{16,}`, mode 600, no placeholder. It also refuses unless `settings get system show_password` reads `0`. That setting is checked, never set.
2. **Focus the field.** It taps SEL, then requires that the focused EditText in a fresh dump is a password field (`password="true"`). Otherwise nothing is typed.
3. **Open the secret window.** It writes `$RUN/.secret`. While that file exists, no screenshot or dump is kept: `shot` and `save` refuse, and the automatic evidence is skipped.
4. **Type.** It clears the field and runs `adb shell 'read -r k; input text "$k"' < keyfile`. The key goes over stdin, so no host argv, no run log line and no device shell line carries it.
5. **Verify.** It checks that the field shows exactly one bullet per key character, then deletes the dump.
6. **Close.** The next `tap` (Save) closes the window, and that tap's own evidence is skipped. `step_end` then runs `secret_audit` over the whole run folder, logcat included.

## Evidence layout

```
~/Documents/ont-release-2.5.0-evidence/      (RT_ROOT)
  ABORT                    only after a focus loss; never deleted by the driver
  current-run              path of the pinned run folder
  run-YYYYMMDD-HHMM/
    run.log                every action, timestamped, tagged with the step
    steps.tsv              id, status, started, ended, note (append-only; the last row per id wins)
    preflight.txt          every preflight table
    HALT                   while halted (moved into the step folder by recover)
    logcat/logcat-NNN.txt  one file per capture; never overwritten
    steps/<id>/
      NNN-<action>.png     a screenshot after every input action
      NNN-<action>.xml     the dump (RT_EVIDENCE=all, the default)
      NNN-<action>.txt     the dump as `x,y  id | label  {flags}`
      errors.txt           crash / ANR / Flutter-error lines seen during the step
      crash-buffer.txt     `logcat -b crash` at a HALT
      ABORT-focus-lost.png / HALT-<reason>.png / HALT-HHMMSS.txt
```

Statuses in `steps.tsv`: `started`, `resumed`, `interrupted` (another step began while this one was open), `halted`, `aborted`, and the final ones `pass`, `fail`, `skip`, `inconclusive`.

## Resuming a paused run

The run folder stays pinned until `init --new`, so a new session picks up where the last one stopped:

1. Run `bash $RT resume`. It shows the counts per status, an open step (if any), and any HALT or ABORT.
2. ABORT present: don't resume. A person looks at the phone first.
3. HALT present: run `step_end fail "…"` if the step isn't recorded yet, then `recover`.
4. Run `preflight` again, then `prep` (it's idempotent).
5. Run the script from the top. Every finished step's `step_begin` exits 3 and is skipped. The step that was open re-runs from its start (logged `resumed`), so **write each step so that it can run twice**: check the state before creating anything.

## Lessons the driver now enforces (from the settings and 2.4.0 runs)

| Lesson | Where it's handled |
|---|---|
| A guard exited 99 while the caller's loop kept swiping on the launcher (~30 swipes) | the ABORT flag and its check before any adb call |
| A stray HOME opened Gmail | `key` allowlist; no `press_home` and no coordinate taps |
| Swipes with a dialog open moved sliders | `swipe` refuses when `modal=1`; `swipe_in` for dialog lists |
| The FAB covers the bottom row | `find` exit 3, so `tap` refuses (98) |
| A red ErrorWidget hid `nav-home`, so BACK left the app | `back` needs positive evidence of a back target; the ErrorWidget halts first |
| The first `uiautomator dump` is bare | `_dump` retries until an allowed package shows content |
| Bounds go stale after a swipe | every tap dumps and resolves its selector in the same call |
| `logcat_start` overwrote the old log | numbered files, no `logcat -c` |
| `am force-stop` cancels the reminder alarm | `launch` never force-stops; `restart` and `recover` log it |
| `pkill -f` matched its own shell | pid files, checked against `/proc/<pid>/cmdline` |
| `st.sh type` logs its text | `type` refuses key-like text; `type_secret` reads stdin |
| Two callers at once | every action holds `$RT_ROOT/.lock` (`flock`) |

## Tests

`bash docs/release-tests/2.5.0/tools/selftest/run.sh` runs 129 checks against `selftest/fake-adb`, a stand-in that logs every call and every input event. No phone is involved. The checks cover:

- the abort, and that after it **no adb call at all** reaches the phone from 19 different actions;
- the pre-input guard, a `null` focus, and the DocumentsUI allowlist;
- crash, ANR and ErrorWidget halts and recovery, and uiautomator's own FATAL not counting as the app's crash;
- every `type_secret` refusal, the key arriving on stdin only, and the audit;
- resume, preflight, idempotent prep and prep after `pm clear`, the battery pause and USB loss;
- the log scanner.

## Knobs

| Variable | Default | |
|---|---|---|
| `RT_ROOT` | `~/Documents/ont-release-2.5.0-evidence` | evidence root, home of the ABORT flag |
| `RT_EXPECT_VERSION` | — | versionName `preflight` expects when not given one |
| `RT_KEY_FILE` / `RT_PROVIDER_FILE` | `~/.config/ont-run/ai-key` / `ai-provider` | |
| `RT_BATTERY_START` / `_FLOOR` / `_RESUME` | 40 / 25 / 40 | % |
| `RT_CHARGE_WAIT_MAX` | 14400 | s per pause |
| `RT_PAUSE_SCREEN_OFF` | 1 | screen off while charging (no lock is set, and the guard re-checks after waking) |
| `RT_USB_WAIT` | 120 | s to wait for the USB serial to come back |
| `RT_GRANTS` | the four permissions above | |
| `RT_EVIDENCE` | `all` | `shots` keeps only screenshots |
| `RT_MAX_RECOVER` | 5 | recoveries per run before an ABORT |
| `RT_SETTLE`, `RT_LAUNCH_SETTLE`, `RT_SLIDER_INSET`, `RT_CLEAR` | 0.8 s, 3 s, 63 px, 64 | |
| `ADB_BIN` | `~/Android/Sdk/platform-tools/adb` | the self-test points it at `fake-adb` |
