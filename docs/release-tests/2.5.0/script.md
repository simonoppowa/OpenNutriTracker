# Release 2.5.0: the unattended run script

The script for [#1434](https://github.com/simonoppowa/OpenNutriTracker/issues/1434), written in [#1433](https://github.com/simonoppowa/OpenNutriTracker/issues/1433) on map [#1425](https://github.com/simonoppowa/OpenNutriTracker/issues/1425). A session runs it over adb on the Pixel 6 with nobody watching, and the result is a verdict per area for the go/no-go ([#1438](https://github.com/simonoppowa/OpenNutriTracker/issues/1438)).

Every identifier, string and number below was read from the candidate `c293acff4` (or from `v2.4.0`, `680eafaa8`, for the steps that run on the old build) and from the PRs behind each change. A few delta rows, or halves of them, can't be shown on a phone. For those the step names the unit tests that cover them and is recorded as *skipped* (the table at the end lists them). A step never waits for a person: anything that would need one is *skipped* with its reason.

**What it covers, in order:**

| Part | What | Steps |
| :-- | :-- | :-- |
| 0 | Preflight and prep | P1–P8 |
| 1 | Seeding on 2.4.0, then the baseline export | S1–S16 |
| 2 | Path 1: upgrade in place to the candidate | U1–U9 |
| 3 | The delta in depth, area by area | DF, DC, DH, DD, DA, DM, DR, DS, DW, DN, DT, DAI, DL |
| 4 | Every other area at smoke depth | K1–K14 |
| 5 | The candidate's own exports (the input to path 3) | X0–X3 |
| 6 | Path 2: fresh onboarding, manual and Try Demo | N1–N14 |
| 7 | Path 3: restore into a cleared candidate | R1–R10 |
| 8 | The English pass, then back to German | E1–E12 |
| 9 | Wrap-up and the report | W1–W4 |

Plan on seven to nine hours, plus two reminder waits of about five minutes each. It is written against the driver `docs/release-tests/2.5.0/tools/rt.sh` at `abf60e40`.

---

## How to run it

### Constants

```bash
RT="bash docs/release-tests/2.5.0/tools/rt.sh"                  # the driver (#1432); run from the repo root
ADB="$HOME/Android/Sdk/platform-tools/adb -s 18101FDF60010M"   # raw adb: read-only queries, push/pull only
PKG=com.opennutritracker.ont.opennutritracker                   # the full flavour; the run never touches .develop
APKS=~/Documents/ont-release-2.5.0-evidence/apks
APK_240=$APKS/ont-full-2.4.0-66-debug.apk                       # sha256 0cbd3b31…dee6ab
APK_CAND=$APKS/ont-full-candidate-c293acff-debug.apk            # sha256 95232d69…a40df0
FX=docs/release-tests/2.5.0/fixtures                            # in this repo
CMP="python3 -I $FX/compare_exports.py"
UI="python3 -I docs/release-tests/2.5.0/tools/ui.py"           # offline reads of saved dumps and screenshots
NOHC="android.permission.POST_NOTIFICATIONS android.permission.CAMERA"   # RT_GRANTS from Part 6 on
```

`EVID` is the run folder the driver pins: `EVID=$(cat ~/Documents/ont-release-2.5.0-evidence/current-run)` after P4. The driver keeps its own evidence there (`run.log`, `steps.tsv`, `logcat/logcat-NNN.txt`, `steps/<ID>/`). The script adds two folders: `$EVID/fixtures/` (P6) and `$EVID/exports/` (every pulled export). The logcat is `cat $EVID/logcat/logcat-*.txt`, never a single file.

**Both APKs report `versionName 2.4.0`, `versionCode 66`** ([#1431](https://github.com/simonoppowa/OpenNutriTracker/issues/1431)): the bump to 2.5.0+67 is not in the frozen candidate. So `dumpsys package` and `rt preflight 2.4.0` can't tell them apart. The run tells them apart by the sha256 of the installed `base.apk` (P6, U2) and by a feature only the candidate has: the add-food screen's Favourites chip `add-meal-source-favourites`.

### The driver

The driver is `docs/release-tests/2.5.0/tools/rt.sh` + `ui.py` ([#1432](https://github.com/simonoppowa/OpenNutriTracker/issues/1432), its [README](tools/README.md) is the reference). One action per call: `$RT ACTION …`, written below as `rt ACTION …`. The actions this script uses:

| Action | Used for |
| :-- | :-- |
| `rt tap SEL` / `rt longpress SEL` | A tap or a 900 ms press on the node SEL resolves to in a dump taken in the same call. There is no coordinate tap. A target under `fab-add-item` or the nav bar is refused (98): scroll first. |
| `rt field SEL VALUE` / `rt type TEXT` / `rt clear [N]` / `rt done` / `rt kb_hide` | Fill a field (tap, 64 deletes, type), type into the focused field (ASCII; refused if it looks like an API key or holds `%`), delete N characters, the keyboard's Done, hide the keyboard. To empty a field, `rt tap SEL` then `rt clear`; `field` with an empty value is not used. |
| `rt type_secret` | The AI key from `~/.config/ont-run/ai-key`, over stdin, into `id=ai-assist-key-field`, which it taps itself. It checks the key file and `show_password 0` and refuses otherwise. The next `rt tap` (Save) closes its secret window; until then `shot` and `save` refuse. |
| `rt slider SEL F [bottom]` | Tap a slider's track at fraction F. Read the value back. |
| `rt swipe up\|down` / `rt swipe_in SEL up\|down` / `rt scroll_to SEL [max]` | Scroll the page (refused with a dialog, a sheet or the keyboard open), scroll inside one node (the only way to scroll a dialog's list), swipe until SEL sits clear between y 300 and 2000. |
| `rt back` | BACK, only when there is something to go back from (a dialog, a sheet, the keyboard, an app-bar Back button, DocumentsUI in a picker step). |
| `rt ls` / `rt get SEL` / `rt has SEL` / `rt state` / `rt wait SEL [s]` | Read the screen. `get` prints a node's label and the text of its fields, **not** a switch's state: a switch or checkbox is read from `rt ls`, whose line ends in `{checked}` or `{unchecked}` (written *read its state* below, e.g. `rt ls \| grep health-sync-auto-import`). A toggle is never tapped blind: read it, then tap only if it isn't already the target state. |
| `rt save NAME` / `rt shot NAME` | Keep a screenshot, the dump (`.xml`, with every node's bounds) and its listing under `steps/<ID>/`. Bounds and pixels are then read offline: `$UI bounds <file>.xml SEL`, `$UI pixel <file>.png X Y`. |
| `rt launch` / `rt restart` | Bring the app up without a force-stop / a cold start (**R** below). `restart` force-stops, which cancels the reminder alarm until the app re-arms it at start-up. |
| `rt install APK` / `rt pm_clear` / `rt prep` | `adb install -r` + `prep`; `pm clear` + `prep`; the per-path grants (`RT_GRANTS`). |
| `rt init` / `rt preflight 2.4.0` / `rt charge_wait` / `rt resume` / `rt status` | Pin the run folder, the read-only preflight table, pause for charge, where a paused run stands. |
| `rt step_begin ID [export\|import]` / `rt step_end pass\|fail\|skip\|inconclusive "NOTE"` | Open and close a step. Exit 3 from `step_begin` means the step already has a verdict in this run: skip it. `export` / `import` is the only way DocumentsUI may hold focus. |
| `rt mark TEXT` / `rt errors` | A marker in logcat; the crash, ANR and Flutter-error lines seen during the open step. |
| `rt alarms` / `rt notif` / `rt clock` / `rt version` / `rt where` | Read-only system state. The app's per-app locale is read with raw `$ADB shell cmd locale get-app-locales $PKG` (written `locale?` below). |

Selectors: `id=` a `resource-id` (a Flutter `Semantics(identifier:)`), `text=` an exact label, `text^=` a label prefix (Flutter merges a tile's title and subtitle into one `content-desc`, so tiles are matched by their title), `text~=` a fragment, `edit=N` the N-th text field from the top. `@K` takes the K-th match, counted top to bottom.

**Every step** is written as **ID — title** with *Do / Expect / Note*, and runs as:

```
rt step_begin ID [export|import]    # rc 3: skip; rc 99: stop the run; rc 97: see below
… the Do lines …
rt step_end <verdict> "<what was seen, in one line>"
```

A step marked **`[export]`** or **`[import]`** is begun with that kind. A step that needs both is split into `.a` / `.b` steps, each begun with its own kind. *Settings →* means: `rt tap id=nav-you` → `rt has id=settings-food-units || { rt scroll_to "text^=Einstellungen"; rt tap "text^=Einstellungen"; }` → `rt wait id=settings-food-units 5`. Settings is an expansion tile inside the You tab's `IndexedStack`, so it stays open across tabs and screens; tapping its title a second time would close it. Every Settings row named after *Settings →* is brought on screen with `rt scroll_to <its selector>` right before it is tapped (uiautomator leaves rows outside the screen out of the dump, and rows under the Add button are refused). With the app in English (S2, Part 8) the title is *Settings*.

**Exit codes the script reacts to** (README): **99** ABORT, focus left the app: stop the run for good, a person looks first. **97** HALT, a crash, an ANR or a red ErrorWidget: `rt step_end fail "<reason>"`, then `rt recover`, then carry on with the next area. **98** refused, nothing sent: the step is written wrong; record it *inconclusive* with the refusal and carry on. **1** a soft miss (a selector not on screen, a `wait` timeout): the step decides. **5 / 6** battery or USB: `rt charge_wait`, or wait for the phone, then `rt resume`.

**Resuming.** A resumed run re-runs the open step from its start. So every step that **creates** something checks first whether it already exists and skips the creating action if it does. Those checks are written as **Guard:** lines. A step without one is safe to run twice as it stands (it only reads, sets a value, or imports something the app merges by id).

### Rules that hold everywhere

1. **The guard is the driver's.** Focus outside `$PKG` (or outside DocumentsUI in an `export`/`import` step) writes the ABORT flag, and every later call exits 99 without touching adb. Don't clear the flag inside the run.
2. **Never send HOME, APP_SWITCH or POWER** (the driver refuses them). Never open Android Settings. The one shell-side change to app state is `cmd locale set-app-locales` in E9; every other raw `$ADB` call reads, pushes or pulls.
3. **Links and buttons that leave the app.** Never tap these:
   - On meal detail: *Weitere Informationen unter OpenFoodFacts / FoodData Central*.
   - The Unsplash credit `unsplash-photo-credit`, `dri-panel-info-link`, `health-sync-privacy-policy`, `onboarding-healthy-range-sources`, and *Quellen unserer medizinischen Berechnungen ansehen*.
   - Fasting's *BEAT (UK)* / *NEDA (US)*.
   - Settings: *Datenschutz…* links, *Quellen*, *Fehler melden*'s OK, the links inside *Über*.
   - *Code teilen*, *Mahlzeit teilen* and *Rezept teilen* (the share sheet), *Geteilte Mahlzeit importieren* (the QR camera), `edit-meal-barcode-scan`, the AI photo buttons `bulk-add-photo` / `bulk-add-photo-camera` (the system camera app).
   - The Health Connect disclosure's *Weiter* (K8: on this phone the Health grants are already held, so *Weiter* would import the maintainer's real workouts without any system screen in between).
4. **Never tap these in Parts 1–5** (the data being tested lives in them):
   - *Profildaten zurücksetzen* (`settings-delete-all-data`), *Cache leeren*, a meal section's ⋮ → *Alle löschen*.
   - The trash icon on a custom-meal row, which also deletes every diary entry that uses the meal; the unlabelled delete button on a weight row.
   - The demo banner's *Eigenes Profil einrichten*.
   - In the *Daten* group, *Cache leeren* and *Profildaten zurücksetzen* sit directly below *App-Daten exportieren / importieren*, the row this script opens most. Tap it only by its full title, `rt tap "text^=App-Daten exportieren / importieren"`.
5. **Confirm a dialog only after reading its title** in a dump of the same step (`rt has "text^=<title>"`). An OK pressed on the wrong dialog is how a cache gets cleared.
6. **The file pickers.** The phone's Download folder may hold real backups (`opennutritracker-export*.zip`). An App-Data import is a merge: it can't be undone, and its picker takes any file.
   - Every file the run puts on the phone is named `ont-r25-…`, and an `[import]` step may pick **only** a file named `ont-r25-…`: `rt tap "text=ont-r25-<name>"`. If it isn't listed, `rt back` out of the picker and record the step *inconclusive*.
   - An export's file name can't be trusted: DocumentsUI may number it (`… (1).zip`) whatever the title field says. So right after every export: `$ADB shell ls -t /sdcard/Download | head -3`, and **check the newest file before using it**: its name must match `ont-r25-<tag>.zip` or `ont-r25-<tag> (<n>).zip`, and its mtime (`$ADB shell stat -c %Y /sdcard/Download/<name>`) must be at or after the step's start (`rt clock` at `step_begin`). Only then pull it to `$EVID/exports/<tag>.zip`, and, where it will be imported later, `$ADB push` the host copy back as `/sdcard/Download/ont-r25-<tag>.zip`. If the check fails, the export step is *inconclusive*: nothing is pulled under that tag and nothing is pushed, so no older file (a real backup, a leftover from an earlier run) can pose as this run's.
   - In DocumentsUI's save screen: `rt field id=android:id/title ont-r25-<tag>.zip`, then `rt tap id=android:id/button1`. Never select by German label text.
7. **Dialogs and swipes.** The driver refuses `swipe` with a dialog open. The only dialog lists scrolled here are the language list (DS8) and the shared-meal preview (DC2), with `swipe_in`; neither holds a slider. On the full-screen *Nährstoffziele* (sliders on a scrolling page), `rt kb_hide` after every `rt field` (the driver refuses to swipe with the keyboard up), and every field is read before and after each scroll and again before Save. If any value other than the one the step edits has moved, leave with `rt back` without saving and record it.
8. **The Add button covers the bottom of the You list and of Settings.** The driver refuses a tap under it (98): `rt scroll_to` the row first. DS3 measures the clearance #1384 added.
9. **A red error screen** halts the driver (97): `step_end fail`, `recover`. Text such as `Duplicate keys found` or `RenderFlex overflowed` in a dump is a **fail** too, even where the screenshot check doesn't fire.
10. **Typing.** After every `rt field id=meal-search-field …` (and any field whose screen has tappable rows below it), `rt kb_hide` before tapping a result: rows behind the keyboard are still in the dump, and a tap there lands on the keyboard, which can type into the query or open an IME screen and abort the run. `rt type` takes ASCII only, so every name the run types is ASCII ("ONT Gemuesecurry"). Read every typed field back (`rt get`) before confirming. The AI key goes only through `rt type_secret`.
11. **German first.** The phone is `de-DE` and the app runs in German until Part 8. The labels below are the German strings from `intl_de.arb` at `c293acff4`. Strings that are new in this release exist **only in English**, so the German build shows them in English: those are listed under *Expected English* and are never a failure on their own.
12. **Cache.** Changing the app language empties the search cache by design (`RemoteSearchCacheDataSource`, 2.4.0 run). No step before Part 8 changes the language, apart from the normalisation in S3.
13. **Logs.** `rt mark <ID>` before anything whose logs matter. Any crash, ANR or Flutter error in `rt errors` is a **fail** of the step, whatever the screen shows.

### Verdicts

Per step and then per area:

- **pass**: every Expect held, or the only deviations are listed as ship-with.
- **fail**: a *Blocks if* was hit, or an exception was logged. Name the step, quote what was seen and what was expected. Keep the evidence.
- **skipped**: not run, with the reason (decided out, can't be driven, a precondition missing).
- **inconclusive**: the step ran but its evidence doesn't decide, such as a chart that a screenshot can't settle or a log line whose channel wasn't proven. Never round it to pass or fail.

**The bar** (unchanged from 2.4.0, [#1428](https://github.com/simonoppowa/OpenNutriTracker/issues/1428)): a **crash**, **data loss**, **wrong nutrition numbers**, or a **regression against 2.4.0** blocks the release. Everything else ships with an issue filed. A blocker is filed with its evidence and the verdict is NO-GO. Nothing is fixed inside this run.

After any **fail** the run carries on with the next area unless the failure leaves the data unusable for what follows (the step says so). One failure doesn't hide the rest.

### Known, expected, not a finding

**Expected English in the German UI.** These keys are in `intl_en.arb` only (the Weblate pipeline, as decided for 2.4.0). Record each once under *ship-with*. None is a failure.
- Favourites: the chip "Favourites", the tooltips "Add to favourites" / "Remove from favourites", "No favourites yet" and its subtitle, "Error while loading favourites".
- Shared meal: "Parse", "Total", "Total (incomplete)", "Unavailable — this item will be skipped.", "Enter a valid shared meal code.", "Unnamed food".
- Search: "Search all"; "One food source didn't respond. Some results might be missing."; "No online food source responded. Showing your saved foods only."
- Recipes: "Calculated from ingredients. Liquids approximated as 1 ml ≈ 1 g.", "Entered manually, so changing ingredients won't change it.", "Use ingredient total".
- Settings: "Daily kJ adjustment" (the row and dialog title in kJ mode).
- Activities: "min" (#1415 made it translatable, German has no entry yet, and it reads the same anyway), and the twelve new activity names (e.g. "yoga", "rowing machine", "circuit training").
- The iOS widget strings, which never show on Android.

**Stale German.** These English sources changed and their German translations didn't follow:
- *Nährstoffziele*' fibre description still says "Standardreferenz: 30 g", while the field now opens at the age- and gender-based value (#1380).
- The four renamed activities (#1223) keep their old German names, so German still shows two "Boxen", two "Kampfsport" and two "Rugby".
- The delete dialog's typo fix (#1384) exists in English only.

Note each once. None is a failure.

**Carried over from earlier runs, not new:**
- The Trends calorie tooltip shows only while a finger is held, and is clipped at the card's right edge for today's point.
- `createCustomDialogContent` reads "Do you want create a custom meal item?" in English.
- Three hard-coded English snackbars on the custom-meal save path.

**Out of scope:** iOS and the home-screen widget (#1251), which are unit tests only. The real Health Connect import is *skipped* by decision ([#1430](https://github.com/simonoppowa/OpenNutriTracker/issues/1430)). The camera itself is *skipped*: the preview, decoding a real barcode or QR, and the AI photo ([#1429](https://github.com/simonoppowa/OpenNutriTracker/issues/1429)).

### Evidence

Everything stays on the laptop under `$EVID`: the driver's `steps/<ID>/` screenshots and dumps, `logcat/`, `run.log`, `steps.tsv`, and the script's `exports/` and `fixtures/`. The exports hold the test profile's diary. Issues quote counts, a kcal figure or a single field, never a whole zip or a raw log. The AI key never reaches any of it.

---

## Part 0 — Preflight and prep

*Blocks if:* nothing here blocks the release. A failed check stops the run before it touches the app, and the report says why. P1–P3 run before any step is open; from P4 on every step is wrapped in `step_begin` / `step_end`.

**P1 — Pin the run folder.**
Do: `rt init` (it re-uses a pinned run; `init --new` only for a deliberate fresh start), `EVID=$(cat ~/Documents/ont-release-2.5.0-evidence/current-run)`, `mkdir -p $EVID/exports $EVID/fixtures`, `rt resume`.
Expect: the run folder; `resume` shows no ABORT and no HALT. On a resumed run it lists the finished steps, which `step_begin` will skip.
Note: an `ABORT` file in `~/Documents/ont-release-2.5.0-evidence/` means a person must look at the phone first. Stop.

**P2 — Bring the app up, then the preflight table.**
Do: `rt launch`; `rt preflight 2.4.0`.
Expect: exit 0, every row `ok`: serial and `ro.serialno` `18101FDF60010M`, model `oriole` SDK 37, versionName `2.4.0`, the app in focus, USB charging, battery ≥ 40 %, storage, the key file (one line, mode 600, no placeholder), provider `openrouter`, stay-awake, the three animation scales `0`, `show_password 0`, no screen lock.
Note: both APKs read 2.4.0, so this row says nothing about which build is installed (P6 does). Exit 5 (battery): `rt charge_wait`, then P2 again; the battery stood at 25 % on 2026-10-22. Exit 4: read the table. The run doesn't change device settings, so a failed settings row stops the run.

**P3 — Clock and time zone.**
Do: `rt clock`; `$ADB shell getprop persist.sys.timezone`.
Expect: the date and time, zone `Europe/Berlin`. Write down **day 0** (the date) and the hour.
Note: DD2 needs the hour to be ≤ 22 when it runs. DW3 only applies if day 0 is 2026-10-26 or later. If the run crosses midnight, the expectations keep using day 0 as written down here.

**P4 — What is installed.**
Do: `rt step_begin P4` →
- `$ADB shell pm list packages | grep opennutritracker`
- `rt version`
- `$ADB shell pm path $PKG`, then `$ADB shell sha256sum <that base.apk path>`
- `$ADB shell dumpsys package $PKG | grep -E 'firstInstallTime|lastUpdateTime'`
- `rt step_end …`
Expect: exactly one package, `$PKG`; `versionName=2.4.0`, `versionCode=66`; a `base.apk` whose sha256 is **not** `95232d69…` (the candidate's); first install 2026-10-11.
Note: if `.develop` is present, leave it alone. If the installed sha256 is the candidate's, the phone was already upgraded: stop, because path 1 can't start from it.

**P5 — The two APKs.**
Do: `rt step_begin P5` → `(cd $APKS && sha256sum -c *.sha256)`; for each APK `aapt dump badging <apk> | head -1` and `apksigner verify --print-certs <apk> | grep SHA-256` → `rt step_end …`.
Expect: both checksums OK; `package: name='com.opennutritracker.ont.opennutritracker' versionCode='66' versionName='2.4.0'` for both; certificate digest `0bdae1d6…5ff5` for both.
Note: an APK with another package name (`….develop`) would install beside the app as a second app instead of upgrading it, and every later step would be driving the old one. Stop on any mismatch.

**P6 — Generate and push the fixtures.**
Do: `rt step_begin P6` → `python3 -I $FX/make_fixtures.py $EVID/fixtures --today <day 0>` → push each phone fixture under the run's prefix, one line each: `$ADB push $EVID/fixtures/ont-seed-meals.csv /sdcard/Download/ont-r25-seed-meals.csv`, the same for `ont-seed-recipes.json` → `ont-r25-seed-recipes.json`, `ont-seed-diary.json` → `ont-r25-seed-diary.json` and `ont-noid.zip` → `ont-r25-noid.zip` → `$ADB shell ls -l /sdcard/Download/ | grep ont-r25-` → `rt step_end …`.
Expect: `expected.json`, `meal-codes.txt` and the four phone files in `$EVID/fixtures/`; four `ont-r25-*` files on the phone, each larger than 0 bytes.
Note: every later "expected" number with a `fx:` prefix is read from `expected.json`. On a resume, regenerate with the same `--today` (day 0, not the resume date): the files come out identical. If a later picker doesn't list a pushed file, index it once: `$ADB shell content call --uri content://media/external/file --method scan_file --arg /sdcard/Download/<name>`. If it still isn't listed, that step is *inconclusive*.

**P7 — Grants.**
Do: `rt step_begin P7` → `rt prep --check` → `rt prep` → `rt step_end …`.
Expect: POST_NOTIFICATIONS, CAMERA, health.READ_EXERCISE and health.READ_TOTAL_CALORIES_BURNED all `ok` or `grant`. The two health reads are already held on this install (the settings run granted them; #1432's dry run saw them).
Note: CAMERA lets the scanner screen open without a system dialog (K3). Because the health reads are held, the Health Connect switch would import without any system screen: K8 stops at the in-app disclosure and never taps *Weiter*. From Part 6 on, every `prep`, `pm_clear` and `install` runs as `RT_GRANTS="$NOHC" rt …`, so the cleared app never holds a health grant.

**P8 — First look, read only.**
Do: `rt step_begin P8` → `rt mark P8` → `rt save P8-home` → `locale?` → `rt errors` → `rt step_end …`.
Expect: the main screen (`nav-home`), no demo banner (`main-demo-banner`), no errors. Write down which language the UI is in and what `locale?` prints: #1432's dry run saw **English** ("kJ left"), left by the settings run.
Note: if onboarding shows, the 2.4.0 data is gone: follow the fallback in Part 1.

---

## Part 1 — Seeding on 2.4.0, then the baseline

The phone holds 2.4.0 with the settings run's test data (#1430). That data is kept: a box written by 2.3.0 and 2.4.0 is the better upgrade subject. The run first takes a safety copy of it (S2, before anything is written). On top go a known set of rows, all named `ONT …`, which later steps compare against. The baseline export at the end (S15) is two things: the backup that path 3 restores, and the numeric "before" for path 1.

**Fallback if 2.4.0 or its data is gone (P4/P8).**
1. If `$PKG` is missing: in a step `S0`, `rt install $APK_240` (after P5 has verified it; `install -r` also installs an absent package) → **immediately** `rt launch` (as U2: no other `rt` call in between, or the guard reads the launcher and aborts).
2. Onboard manually as in N3–N8, with the R-profile (R1), reminder off. Skip S2.
3. Record "path 1 runs from a fresh 2.4.0 box, not a lived-in one".

*Blocks if:* nothing in Part 1 judges the candidate. A seeding step that can't be completed is recorded with what's missing, and every later step that needs it is *skipped: no seed*.

**S1 — Read the profile.**
Do: `rt tap id=nav-you`; `rt save S1-you`; read the tiles `profile-weight`, `profile-height`, `profile-age`, `profile-gender`, `profile-activity`, `profile-goal`, `profile-target-weight`.
Expect: a complete profile. Write down every value. **w0** is the weight in kg, to one decimal (the settings run left about 65–66 kg).
Note: DS6's expected fibre default depends on gender and age: IOM, men 19–50 → 38 g, 51+ → 30 g; women 19–50 → 25 g, 51+ → 21 g; non-binary averaged → 31.5 g / 25.5 g. If the profile shows st/lbs or ft, convert for the record; S3 switches the units.

**S2 — Safety copy of the settings run's data.** `[export]`
Do (the app is still in English from the settings run; if P8 found it German, use S15's German labels instead): `rt tap id=nav-you` → `rt has id=settings-food-units || { rt scroll_to "text^=Settings"; rt tap "text^=Settings"; }` → `rt scroll_to "text^=Export / Import App Data"` → `rt tap "text^=Export / Import App Data"` → `rt tap text=JSON` → `rt tap text=Export` → `rt field id=android:id/title ont-r25-pre.zip` → `rt tap id=android:id/button1` → `rt wait "text=Export / Import successful" 20` → `rt back` (closes the dialog). Pull the newest zip to `$EVID/exports/pre.zip`. `$CMP summary $EVID/exports/pre.zip > $EVID/exports/pre.txt`.
Expect: "Export / Import erfolgreich"; a zip with `user_intake.json`, `user_activity.json`, `user_tracked_day.json`, `user_recipes.json`, `weight_log.json` and `custom_activity_templates.json`.
Note: this zip is never imported. It exists so that nothing on the phone is lost unrecorded. If the export fails, stop: the run doesn't seed onto data it can't get back.

**S3 — Normalise the device-wide settings.**
None of these is in a backup, and they make every later expectation simpler.
Do:
1. Settings (English: `text^=Settings`) → `rt scroll_to "text^=Language"` (or `text^=Sprache` if P8 found German) → tap it → `rt tap text=Deutsch` → `rt tap text=OK`. From here on the labels are German.
2. `settings-energy-unit` → *Kilokalorien (kcal)* → OK.
3. `settings-food-units` → *Metrisch* → OK.
4. `settings-body-weight-unit` → `kg` → OK.
5. `settings-height-units` → metric → OK.
6. `rt scroll_to id=settings-health-sync` → tap it → read its state (`rt ls | grep health-sync-auto-import`). If the line ends in `{checked}`, tap it once to turn it **off** (turning it off shows no disclosure) and read it again: it must end in `{unchecked}` → `rt back`. If the state can't be read, stop the run here: the candidate must never launch with auto-import on.
7. Read *Tag beginnt um* (`settings-day-boundary`), *Mikronährstoffe anzeigen*, *Makros je Mahlzeit anzeigen*, *Aktivitätstracking anzeigen* and the *KI-Unterstützung* subtitle, and write them down.
8. If the day boundary isn't `0:00`: open it → *Zurücksetzen* → `rt tap id=day-boundary-save`.
Expect: the UI in German, the tiles reading kcal, metric and kg, auto-import off, the boundary `0:00`.
Note: auto-import must be off before the candidate's first launch (U3). The candidate's import works where 2.4.0's didn't (#948), and the health reads are already held, so a launch with auto-import on would import the maintainer's real workouts. Switching the language empties the search cache (rule 12), which is wanted here, before any search.

**S4 — Import the custom-meal library.** `[import]`
Guard: You → `profile-recipes` → *Eigene Mahlzeiten*: if ONT Haferbrei is listed, the import already ran; skip to the Expect check.
Do: Settings → `rt tap id=settings-import-custom-food` → `rt tap text=CSV` (inside `import-format-toggle`) → `rt tap "text=Mahlzeiten importieren (csv)"` → `rt tap text=ont-r25-seed-meals.csv` → `rt wait "text~=Mahlzeit(en) importiert" 20` → `rt back`.
Expect: "4 Mahlzeit(en) importiert." Then You → `profile-recipes` → tab *Eigene Mahlzeiten* lists ONT Haferbrei, ONT Joghurt, ONT Linsensuppe and ONT Riegel (brand "ONT Test").
Note: never tap the *Beispiel-…* buttons next to the import actions; they open a save picker for a sample file. A second run of this import would be harmless anyway: the meal importer dedupes by name and barcode.

**S5 — Import the recipes.** `[import]`
Guard: if the *Rezepte* tab already lists ONT Bananenbrot, skip the import. Each recipe import mints fresh ids, so a second one would duplicate both recipes.
Do: Settings → `settings-import-custom-food` → `rt tap text=JSON` → `rt tap "text=Rezepte importieren (json)"` → `rt tap text=ont-r25-seed-recipes.json` → wait for the result → `rt back`.
Expect: "2 Mahlzeit(en) importiert." (the recipe importer reuses the meal string). The *Rezepte* tab lists:
- ONT Gemuesecurry, "2 Zutat(en) · 275 kcal".
- ONT Bananenbrot, "2 Zutat(en) · 987 kcal". Its detail reads `Pro 100 g · 219 kcal …` (fx `recipes.ONT Bananenbrot.kcal_per_100g` = 219.33). 197 would be the 500 g ingredient sum.
Note: 2.4.0 already carries #1169, so the 450 g survives the import.

**S6 — Import six days of diary.** `[import]`
Guard: Diary → day 0 − 1: if ONT Haferbrei 300 g is listed, skip the import. A second JSON meal import adds every entry again.
Do: Settings → `settings-import-custom-food` → `rt tap text=JSON` → `rt tap "text=Mahlzeiten importieren (json)"` → `rt tap text=ont-r25-seed-diary.json` → wait → `rt back`.
Expect: "15 Mahlzeit(en) importiert." Diary → day 0 − 1 shows ONT Haferbrei 300 g, ONT Linsensuppe 350 g and ONT Joghurt 200 g.
Note: the importer files each entry at local midnight of its date and skips names already in the library, so no library row is added. The per-day totals are fx `diary_days`.

**S7 — Log today by hand: one Open Food Facts product.**
Guard: if Home's *Frühstück* already lists an Open Food Facts product logged today by this step, skip.
Do: `rt tap id=fab-add-item` → `rt tap id=add-item-breakfast` → `rt field id=meal-search-field nutella` → wait 2 s → `rt tap text=Produkte` → tap the first card whose source chip reads *Open Food Facts* (`rt tap "text~=<its name>"`) → wait until the *Einheit* button text is the same in two `rt get` reads 0.5 s apart (hydration) → `rt get edit=1` (Menge) → `rt field edit=1 30` → set *Einheit* to `g` → `rt tap id=meal-detail-add`.
Expect: the snackbar "Neue Aufnahme hinzugefügt", back on Home. Write down the product's name and barcode (from the detail screen, or from the export later).
Note: if no Open Food Facts card appears for `nutella`, try `seabrook`, then `chips`. If none does, record *S7 not seeded*; DF, DC, DM and K3 then use the S8 backend food in its place and say so.

**S8 — Log today by hand: one backend food.**
Guard: if *Mittagessen* already lists a BLS/FDC food logged today, skip.
Do: `fab-add-item` → `add-item-lunch` → `rt field id=meal-search-field apfel` → wait 2 s → `rt tap text=Lebensmittel` → a card whose chip reads *BLS* or *FDC …* → Menge `150`, `g` → `meal-detail-add`.
Expect: the snackbar, the row on Home under *Mittagessen*.

**S9 — Log today by hand: the barcode custom meal and a recipe.**
Guard: skip each half whose entry is already on Home today.
Do:
1. `fab-add-item` → `add-item-snack` → `rt field id=meal-search-field "ONT Riegel"` → tap the chip-less card ONT Riegel → Menge `40`, `g` → `meal-detail-add`.
2. You → `profile-recipes` → tab *Rezepte* → ONT Gemuesecurry → `rt tap "text=Dieses Rezept loggen"` → in the meal-type dialog `rt tap text=Abendessen` → on the detail screen Menge `350`, `g` → `meal-detail-add`.
Expect: Home shows ONT Riegel under *Snack* (168 kcal) and ONT Gemuesecurry under *Abendessen* (275 kcal).
Note: ONT Riegel logged from the library carries its barcode `2000000000015`; DR2 moves exactly this entry.

**S10 — One activity.**
Guard: if Home's activity card already lists an activity today, skip.
Do: `fab-add-item` → `add-item-activity` → tab *Alle* → the first card → `rt field id=activity-detail-quantity-input 30` (it held `0`) → `rt get id=activity-detail-quantity-input` reads `30` → `rt tap id=activity-detail-add-button`.
Expect: "Neue Aktivität hinzugefügt".
Note: if *Aktivität* isn't in the sheet, activity tracking is off (S3.7): turn on *Aktivitätstracking anzeigen* first and record it.

**S11 — Weight on four days.**
Do: You → `rt scroll_to "text^=Gewichtsverlauf"` → `rt tap "text^=Gewichtsverlauf"` (`profile-weight-history`; not the tile *Gewicht*, which opens the set-weight dialog) → four times: `rt tap id=weight-history-add` → `rt tap "text^=Datum"` → tap the day cell by its full German content-desc (`text~=<d>. <Monat> <yyyy>`) → OK → `rt field id=weight-history-weight-input <kg>` → OK:

| day | −6 | −4 | −2 | 0 (leave the date) |
| :-- | :-- | :-- | :-- | :-- |
| kg | w0 + 0.8 | w0 + 0.2 | w0 + 0.5 | w0 |

Expect: four tiles with those values (period decimal, `toStringAsFixed`), newest first. Count the tiles after every OK: the dialog closes silently on a bad value.
Note: entries are keyed by day, so running this step twice only rewrites the same four rows. Today's entry equals the profile weight, so the kcal goal doesn't move. Never tap a tile's trailing button: it has no label and deletes without asking.

**S12 — Goals that the backup carries from 2.5.0 on (#1381).**
2.4.0 drops a value typed and then confirmed with OK only (#1347), so each value gets Done before OK.
Do:
1. Settings → `rt tap id=settings-kcal-adjustment` → `rt field id=kcal-adjustment-input 250` → `rt done` → `rt tap id=kcal-adjustment-save`.
2. `rt tap id=settings-macro-split` → the carbs **text field** `edit=1` (`rt get edit=1` must read the current carbs %; `id=macro-split-carbs` is the carbs *slider*, never tap it) → `rt field edit=1 45` → `rt done` → `rt tap id=macro-split-save`.
3. `rt tap id=settings-per-meal-share` → `rt tap id=meal-share-preset-mediterranean` → `rt tap id=meal-share-save`.
4. You → `rt scroll_to id=profile-water-goal` → tap it → `rt field id=water-goal-input 2500` → `rt done` → `rt tap id=water-goal-save`.

Expect, reopening each (and closing with *ABBRECHEN*):
- kcal adjustment `250`.
- Macro split carbs `45`. Write down the two rebalanced values.
- Per-meal share `25/45/20/10`.
- Water goal "/ 2500 ml".
- Home's kcal goal 250 above S1's.

Note: the dialogs are never swiped (the driver refuses it). Only the preset is tapped on the per-meal sliders.

**S13 — The reminder.**
Do: Settings → `rt scroll_to "text^=Tägliche Erinnerung@2"` (the first match is the group header) → read its state (`rt ls | grep "Tägliche Erinnerung"`, the second line) → tap it only if `{unchecked}` → `rt tap "text^=Erinnerungszeit:"` → `rt tap "text=Zum Texteingabemodus wechseln"` → `rt field edit=1 20` → `rt field edit=2 30` → `rt tap text=OK`.
Expect: "Erinnerungszeit: 20:30"; `rt alarms` lists an alarm for `$PKG`.
Note: POST_NOTIFICATIONS was granted in P7, so no system dialog appears.

**S14 — The "before" screens on 2.4.0.**
Do:
1. Home: `rt save S14-home` (the gauge `home-kcal-gauge`, the meal sections).
2. `fab-add-item` → `add-item-dinner`, *Kürzlich* unfiltered: `rt save S14-recent`. Write down the first five card names top to bottom (the list has no identifier on 2.4.0).
3. Tap ONT Joghurt in that list → `rt save S14-custom-detail`: is the button *Benutzerdefinierte Mahlzeit* present? → `rt back` twice without adding.
4. `rt alarms` into the step's notes.

Expect, as 2.4.0 behaves:
- Recently starts with the chip-less custom meals (ONT Riegel, ONT Joghurt …) ahead of the Open Food Facts product and the backend food, although those two were logged later (#1252's "before").
- The custom meal's detail shows the dead *Benutzerdefinierte Mahlzeit* button (#1297's "before").

**S15 — The baseline export.** `[export]`
Do: Settings → `rt tap "text^=App-Daten exportieren / importieren"` → `rt tap text=JSON` → `rt tap text=Exportieren` → `rt field id=android:id/title ont-r25-base240.zip` → `rt tap id=android:id/button1` → wait for "Export / Import erfolgreich" → `rt back`. Pull the newest zip to `$EVID/exports/base240.zip`, then `$ADB push $EVID/exports/base240.zip /sdcard/Download/ont-r25-base240.zip`. `$CMP summary $EVID/exports/base240.zip > $EVID/exports/base240.txt`.
Expect:
- "Export / Import erfolgreich".
- `base240.txt` shows, for each of days −6 … −1, an intake count and kcal at least fx `diary_days` (more if the settings run left rows on those days).
- Recipes ONT Gemuesecurry `totalWeightG=350` and ONT Bananenbrot `totalWeightG=450`.
- S11's four weights.
- No `goal_settings.json`, `user_favourites.json` or `tracked_day_boundary.json` (2.4.0 doesn't write them).
- `intake ids stored twice or more: 0`. If it isn't 0, the settings run's #1357 left duplicates behind: record which ids. U8 then shows the candidate collapsing them.

Note: **nothing may write to the app between S15 and U2.** If a resumed run finds S15 done and anything else after it re-ran, redo S15 under a new step ID (`S15b`).

**S16 — A CSV export too.** `[export]`
Do: the same dialog → `rt tap text=CSV` → *Exportieren* → `ont-r25-base240csv.zip` → Save → pull to `$EVID/exports/base240csv.zip` → `unzip -l`.
Expect: exactly `user_activity.csv`, `user_intake.csv`, `user_tracked_day.csv`.
Note: kept as evidence only, never imported.

---

## Part 2 — Path 1: upgrade in place

*Blocks if:* the app opens to onboarding or a red screen after the upgrade; any intake, activity, recipe, weight entry or template from `base240.zip` is missing or changed; a day's consumed kcal differs from the sum of its intakes after the reconciler ran; the reminder's alarm is gone after the first launch; re-importing the app's own backup doubles a single entry (#1357 again).

**U1 — The right APK, checked right before it goes on.**
Do: `rt step_begin U1` → `sha256sum $APK_CAND` → `aapt dump badging $APK_CAND | head -1` → `rt step_end …`.
Expect: `95232d6937e34d0b84bda127af2116661510febed56ae529d8b9bc8468a40df0`; `package: name='com.opennutritracker.ont.opennutritracker'`.
Note: stop on any mismatch. Never `uninstall`: it deletes the data path 1 exists to test.

**U2 — Install the candidate over 2.4.0, and launch it at once.**
Do: `rt step_begin U2` → `rt mark U2` → `timeout 300 $RT install $APK_CAND` → **immediately** `rt launch` → `$ADB shell pm path $PKG` + `sha256sum` of that `base.apk` → `$ADB shell dumpsys package $PKG | grep -E 'firstInstallTime|lastUpdateTime'` → `rt step_end …`.
Expect: `Success` and `prep` all ok; the app in front; the installed `base.apk` sha256 is the candidate's (U1); `lastUpdateTime` is now; `firstInstallTime` unchanged (2026-10-11).
Note: `install -r` stops the app, so the launcher has focus until `rt launch`. No other `rt` call may come between the two, or the guard reads the launcher and aborts the run. The same versionCode is allowed, and the matching certificate keeps the data. If the install times out or prints `INSTALL_FAILED_VERIFICATION_FAILURE` (a Play Protect prompt waiting for a person), path 1 is *skipped: needs a person*, and the run stops there: every later Part assumes the candidate.

**U3 — The first launch was clean.**
Do: `rt step_begin U3` → `rt save U3-home` → `rt errors` → `cat $EVID/logcat/logcat-*.txt | sed -n '/MARK_U2/,$p' | grep -E 'TrackedDayReconciler|OffMicronutrientRepair|main: Starting App|SEVERE'` → `rt step_end …`.
Expect:
- `nav-home` and the same Home as S14: the meal sections, the kcal goal 250 above S1's.
- No onboarding, no red screen, nothing in `rt errors`, no `SEVERE:` line.
- `INFO: main: Starting App …`.
- Either no `TrackedDayReconciler` line, or one `INFO: TrackedDayReconciler: Brought N tracked days in line with the entries the Diary lists on them (#1317)`. Write down N.
- `OffMicronutrientRepair`: nothing (stamped long ago) or its `(#1152)` line.
Note: the reconciler (#1319) rewrites a day's consumed totals as the sum of the entries listed under it, on every activation. Settings-run data can hold rows that 2.4.0 left out of line, so an N above 0 is a migration doing its job, not data loss. U4 checks the numbers.

**U4 — Nothing lost: a candidate export against the baseline.** `[export]`
Do: Settings → `rt tap "text^=App-Daten exportieren / importieren"` → `JSON` → *Exportieren* → `ont-r25-up1.zip` → Save → `rt back` → pull to `$EVID/exports/up1.zip` → `$CMP diff $EVID/exports/base240.zip $EVID/exports/up1.zip > $EVID/exports/U4.txt`.
Expect:
- `intakes`, `activities`, `recipes`, `weight_log` and `templates` all read `missing 0 … changed 0 stored-twice 0`.
- No tracked-day line carries `NEW tracked != NEW sum`, `row lost …` or `no row although NEW lists intakes`. A line where `base_tracked` differs from `new_tracked` while `new_tracked` equals `new_sum` is the reconciler correcting a 2.4.0 row: list those days. There should be as many as U3's N.
- `goal_settings: … new present`; `boundary: … new present`.
- The last line reads `VERDICT: identical` or `VERDICT: superset`.
Note: `up1.zip`'s `goal_settings.json` must hold `kcalAdjustment 250`, `carbGoalPct 0.45`, `mealKcalSharesPct` 25/45/20/10, `dailyWaterGoalMl 2500`. Those are S12's values: the backup now carries them (#1381).

**U5 — The reminder survived the upgrade.**
Do: `rt step_begin U5` → `rt alarms` → Settings → `rt scroll_to "text^=Tägliche Erinnerung@2"` → read its state (`rt ls | grep "Tägliche Erinnerung"`) → `rt step_end …`.
Expect: the switch on, "Erinnerungszeit: 20:30", and an alarm for `$PKG` at the next 20:30.
Note: the install stopped the app; start-up re-arms the reminder through `DailyReminderScheduler` (#1379). A missing alarm with the switch on is a **fail**.

**U6 — The candidate is really running.**
Do: `rt step_begin U6` → `fab-add-item` → `add-item-dinner` → `rt has id=add-meal-source-favourites` → `rt back` → `rt step_end …`.
Expect: present. This and U2's sha256 are the two proofs that this is not 2.4.0.

**U7 — Recently is chronological now (#1252).**
Do: `rt step_begin U7` → `fab-add-item` → `add-item-dinner` → *Kürzlich* unfiltered → `rt save U7-recent` → `rt back` → `rt step_end …`. Compare the names top to bottom with S14.
Expect: most recent first. S9's ONT Gemuesecurry and ONT Riegel, S8's backend food and S7's Open Food Facts product (in reverse order of logging) come before the six-day-old ONT Haferbrei / ONT Joghurt / ONT Linsensuppe. Custom meals are no longer pinned to the top.
Note: custom meals still first is a **fail** of #1252. Not a blocker on its own (no data or numbers affected).

**U8.a — Re-import the app's own 2.4.0 backup (#1369).** `[import]`
Do: `rt mark U8` → Settings → `rt tap "text^=App-Daten exportieren / importieren"` → `JSON` → `rt tap text=Importieren` → `rt tap text=ont-r25-base240.zip` → `rt wait "text=Export / Import erfolgreich" 60` → `rt back` → Home `rt save U8-home` → Diary day 0 − 1 `rt save U8-diary` → `rt errors`.
Expect: "Export / Import erfolgreich"; Home and the Diary list every entry once. 2.4.0 doubled them and broke Home with "Duplicate keys found" (#1357, settings-run row 34). No errors.
Note: running this step twice is the test itself: the import merges by id. `base240.zip` has no `goal_settings.json`, so the goals stay as they are (S12's values). That is the old-archive rule of #1381.

**U8.b — Export and compare.** `[export]`
Do: export JSON `ont-r25-up2.zip` → pull → `$CMP diff $EVID/exports/up1.zip $EVID/exports/up2.zip > $EVID/exports/U8.txt`.
Expect: `intakes … missing 0 extra 0 changed 0 stored-twice 0`, the same for activities, recipes, weight log and templates. Today's tracked-day goal may have moved, because the import recomputes today's goals (#1381); that's the only expected difference. If `base240.txt` showed duplicate ids (S15), they are now stored once.

**U9 — Two cold starts change nothing.**
Do: `rt step_begin U9` → `rt mark U9` → `rt restart` → wait 5 s → `rt restart` → `cat $EVID/logcat/logcat-*.txt | sed -n '/MARK_U9/,$p' | grep TrackedDayReconciler` → `rt save U9-home` → `rt step_end …`.
Expect: at most one `Brought … tracked days` line (the first start may still correct today's row after U8), none from the second start; Home unchanged.
Note: a reconciler that rewrites rows on every launch would be a defect of #1319. `restart` force-stops, so the reminder alarm is re-armed by each start; U5 already showed that it is.

---

## Part 3 — The delta in depth

Every row of the map's delta table, area by area. The order is chosen so that nothing destroys a later step's subject: the shared code and favourites first, settings in the middle, the language last (Part 8). *Search screen* below means `rt tap id=fab-add-item` → the named meal tile (`add-item-breakfast` unless the step names another) → the add-food screen.

### DF — Favourites (#1320, new)

A per-profile list of starred foods and meals, filled without logging. Semantics: `add-meal-source-favourites` (chip), `add-meal-favourites-list` (list), `meal-detail-favourite` (detail page star), `add-item-recent-favourite-N` (stars on the add sheet's recent cards). Stars on search, Recently and Favourites cards carry **no** identifier (the dynamic-list rule); their content-desc is the tooltip, "Add to favourites" or "Remove from favourites" (English, see *Expected English*).

*Blocks if:* starring logs an entry or changes a day's kcal; a starred food logs different nutrition than its record; the favourites list loses entries over an export and restore; a crash.

**DF1 — Empty state.**
Do: search screen → `rt tap id=add-meal-source-favourites` → `rt save DF1` → `rt back`.
Expect: the chip selected, the hint "No favourites yet" and "Tap the star on any food or meal to keep it here, ready to log." No list.
Note: on a resumed run that already starred something, the hint is gone: record *inconclusive (resumed)*.

**DF2 — Star an Open Food Facts product on its detail page; nothing is logged.**
Do: write down Home's kcal consumed (`rt get id=home-kcal-gauge`) → search screen → `rt field id=meal-search-field nutella` (S7's query) → `rt tap text=Produkte` → tap the S7 product → wait for hydration → `rt get id=meal-detail-favourite` → **only if** it reads "Add to favourites": `rt tap id=meal-detail-favourite` → `rt get id=meal-detail-favourite` → `rt back` (to the search screen) → `rt tap id=add-meal-source-favourites` → `rt save DF2` → `rt back` → Home `rt get id=home-kcal-gauge`.
Expect:
- The star's content-desc goes from "Add to favourites" to "Remove from favourites".
- The Favourites chip lists the product inside `add-meal-favourites-list`.
- Home's kcal consumed is unchanged; the Diary for day 0 has no new row.
Note: the guard on the star makes the step safe to re-run: a second tap would unstar it.

**DF3 — Star a custom meal and a recipe.**
Do: search screen → `rt field id=meal-search-field "ONT Lin"` → tap ONT Linsensuppe (no source chip) → star it if it reads "Add to favourites" → `rt back`; `rt field id=meal-search-field "ONT Banan"` → tap ONT Bananenbrot → star it the same way → `rt back` → clear the field (`rt tap id=meal-search-field` → `rt clear`) → `rt tap id=add-meal-source-favourites` → `rt save DF3`.
Expect: three cards in `add-meal-favourites-list`, newest star first: ONT Bananenbrot, ONT Linsensuppe, then the S7 product.
Note: if the search doesn't offer the recipe, star ONT Gemuesecurry from *Kürzlich* instead and say so. DF6 then unstars that one.

**DF4 — The search field filters Favourites in place.**
Do: search screen → `rt tap id=add-meal-source-favourites` → `rt field id=meal-search-field ONT` → wait 1 s → `rt save DF4a` → `rt tap id=meal-search-field` → `rt clear` → wait 1 s → `rt save DF4b`.
Expect: still on Favourites (the chip selected, no Products/Food results). DF4a lists only the two ONT items; DF4b lists all three again. Typing never jumps to *Alle*.

**DF5 — Log from Favourites.**
Guard: if Home's *Frühstück* already lists ONT Linsensuppe today, skip to the Expect check.
Do: Favourites → tap ONT Linsensuppe → `rt field edit=1 200` (Menge; `rt get edit=1` first) → unit `g` → `rt tap id=meal-detail-add`.
Expect: the snackbar "Neue Aufnahme hinzugefügt"; Home *Frühstück* gains ONT Linsensuppe, 180 kcal (90 kcal/100 g × 200 g).

**DF6 — Unstar from the Favourites list.**
Guard: only if ONT Bananenbrot is still the first card of `add-meal-favourites-list`.
Do: search screen → Favourites → `rt save DF6a` → `rt tap "text=Remove from favourites@1"` → `rt save DF6b`.
Expect: ONT Bananenbrot leaves the list; ONT Linsensuppe and the S7 product remain.
Note: every card in this list is starred and the list is newest first, so the first "Remove from favourites" is ONT Bananenbrot's (DF6a shows the order). If DF6b shows a different card gone, record it and star that one again on its detail page.

**DF7 — The add sheet's recent cards carry a star.**
Do: Home → `rt tap id=fab-add-item` → `rt ls | grep add-item-recent-favourite` → `rt back` (closes the sheet).
Expect: `add-item-recent-favourite-1` … one per recent card shown. Don't tap them.

Export, restore and favourites coming back are R9 (path 3). Two profiles are never touched in this run. They are covered by `test/unit_test/favourite_cross_profile_test.dart` (a shared-library edit refreshes every profile's favourites) and `test/unit_test/favourite_meal_repository_test.dart` (keys, dedupe, the deleted-template fallback, the hashed long key).

### DC — Shared meal code import (#1329, new on Android) and a shared recipe's total weight (#1294)

A meal is imported from a pasted code:
1. ⋮ on a meal section (`intake-section-menu`) → *Code einfügen* (`intake-import-meal-code`).
2. A dialog with `import-meal-code-input` and "Parse" (`import-meal-code-parse`).
3. A preparation dialog with a Cancel button (`import-meal-prepare-cancel`).
4. A preview: title "{n} Einträge importieren?", rows, a total, and *Importieren* (`import-meal-preview-import`).
5. The snackbar "Mahlzeit importiert".

The codes are in `$EVID/fixtures/meal-codes.txt`. They were checked against the app's real parser at `c293acff4` when they were written. `rt type` accepts them (base64url, no `%`, not key-like).

On Home the four sections Frühstück, Mittagessen, Abendessen and Snack each carry an `intake-section-menu`, top to bottom, so Abendessen's is `@3` and Snack's `@4`. Before each tap, bring the menu on screen with `rt scroll_to id=intake-section-menu@<K>` (Snack's sits near the Add button and is refused until scrolled clear). The preview's sentence "Diese Einträge werden zu <meal> hinzugefügt." names the section the menu belonged to: the step's expectations follow that meal, and the step records it if it isn't the intended one.

*Blocks if:* an imported entry's kcal differs from the preview's; the preview's total differs from the fixture's; an unavailable item is imported anyway; an embedded recipe loses its hand-entered total weight (#1294: 250 kcal expected, 200 means the override was dropped); a crash.

DC1–DC3 run as **one driver step**, `step_begin DC1-3`: they share one open dialog, and a resumed or recovered run must start again from Home. DC3's guard keeps a second pass from importing twice.

**DC1 — An invalid code is refused, and the text stays.**
Do: Home → `rt save DC1-home` (*Abendessen*'s kcal before the import) → `rt tap id=intake-section-menu@3` → `rt tap id=intake-import-meal-code` → `rt tap id=import-meal-code-input` → `rt type keinGueltigerCode` → `rt tap id=import-meal-code-parse` → `rt save DC1`.
Expect: the dialog stays open with "Enter a valid shared meal code." under the field, and the field still holds `keinGueltigerCode`.
Note: the dialog stays open for DC2. Never tap *Code teilen* or *Mahlzeit teilen* (rule 3).

**DC2 — Code A: preview.**
Do: in the same dialog (if it isn't open, as after a recover: Home → `rt scroll_to id=intake-section-menu@3` → `rt tap id=intake-section-menu@3` → `rt tap id=intake-import-meal-code`), `rt tap id=import-meal-code-input` → `rt clear 64` → `rt type <CODE_A>` → `rt get id=import-meal-code-input` and compare it with `meal-codes.txt` character for character → `rt tap id=import-meal-code-parse` → `rt wait "text~=Einträge importieren?" 30` → `rt save DC2`.
Expect (fx `code_a`):
- Title "3 Einträge importieren?".
- "Diese Einträge werden zu Abendessen hinzugefügt." and the heading *Abendessen*.
- The rows: ONT Code Haferbrei "250 g" "375 kcal"; ONT Code Apfel "120 g" "62 kcal"; ONT Code Eintopf "100 g" "250 kcal".
- Below the divider, "Total" and "687 kcal".
- *Importieren* enabled.
Note: if the typed text doesn't match the fixture, clear it and type it once more. On a second mismatch the step is *inconclusive* (an input problem, not the app's). Three rows fit the dialog. If a row is missing from the dump, the step is *inconclusive*. The preview is never scrolled with `swipe`.

**DC3 — Code A: import.**
Guard: if *Abendessen* already lists ONT Code Haferbrei (a resumed run), don't import again: each import mints new ids. Tap *ABBRECHEN* and go to the Expect check.
Do: `rt mark DC3` → `rt tap id=import-meal-preview-import` → `rt wait "text=Mahlzeit importiert" 30` → `rt save DC3-home` → `rt errors`.
Expect:
- The snackbar "Mahlzeit importiert".
- *Abendessen* gains three rows and 687 kcal (its header goes up by 687 or 688 after rounding).
- You → `profile-recipes`: *Eigene Mahlzeiten* gains ONT Code Haferbrei and ONT Code Apfel, and *Rezepte* gains ONT Code Eintopf.
- No errors.

**DC4 — The embedded recipe kept its hand-entered total (#1294).**
Do: You → `profile-recipes` → *Rezepte* → ONT Code Eintopf → `rt save DC4-detail` → the pencil (edit) → `rt save DC4-builder` → `rt back`. If a dialog *Änderungen verwerfen?* appears, `rt tap text=Verwerfen` (discards, saves nothing).
Expect:
- Detail: `Pro 100 g · 250 kcal …`.
- Builder: *Gesamtgewicht (g)* reads `80`; the helper reads "Entered manually, so changing ingredients won't change it."; the button `recipe-builder-weight-reset` ("Use ingredient total") is shown.
Note: 200 kcal per 100 g, or 100 g in the builder, means the flag was dropped and the recipe was spread over its 100 g ingredient sum: **fail** (wrong nutrition numbers). The builder half also proves #1280 on a recipe the run never typed. Never tap `recipe-builder-weight-reset` or `recipe-builder-save` here.

**DC5 — Code B: an unknown barcode is shown as skipped, and the total says so.**
Guard: if *Snack* already lists ONT Code Rest, skip the import and go to the Expect check.
Do: Home → `rt tap id=intake-section-menu@4` → `rt tap id=intake-import-meal-code` → `rt tap id=import-meal-code-input` → `rt type <CODE_B>` → `rt get` it and compare → `rt tap id=import-meal-code-parse` → `rt wait "text~=Einträge importieren?" 180` (the barcode lookup makes up to three 60 s attempts) → `rt save DC5` → `rt tap id=import-meal-preview-import` → `rt wait "text=Mahlzeit importiert" 30` → `rt save DC5-home`.
Expect (fx `code_b`):
- The preview: "2 Einträge importieren?"; ONT Code Rest "100 g" "100 kcal"; a row titled `2999999999991` with "50 g", "—" and "Unavailable — this item will be skipped."; then "Total (incomplete)" and "100 kcal".
- After the import, *Snack* gains only ONT Code Rest, 100 kcal.
Note: if the lookup finds a product under that barcode after all, the "unavailable" half is *inconclusive*. Record the product it found, and tap *ABBRECHEN* instead of importing it.

**DC6 — The preparation dialog can be cancelled.**
Do: Home → `rt tap id=intake-section-menu@4` → `rt tap id=intake-import-meal-code` → `rt tap id=import-meal-code-input` → `rt type <CODE_B>` → `rt tap id=import-meal-code-parse` → at once `rt tap id=import-meal-prepare-cancel` → `rt save DC6`.
Expect: back on Home, nothing imported (*Snack* as after DC5).
Note: if the cancel button was already gone (the lookup finished first), the `tap` exits 1 and sends nothing. Then the preview is up: `rt tap text=ABBRECHEN` and record *could not win the race*. The cancellation is then covered by `test/features/home/presentation/widgets/shared_meal_import_test.dart`.

Not covered on the phone: the camera QR route and the share sheet. Both leave the package (#1429).

### DH — Home / dashboard (#1358, #1318)

*Blocks if:* an entry in a 0 % meal can't be seen, edited or deleted; Home's numbers disagree with the Diary's; a crash.

**DH1 — The calorie ring turns red over the goal (#1358).**
Guard: if Home already lists ONT Ueberschuss (a resumed run), skip step 2.
Do:
1. Home → `rt save DH1-under`. Read "kcal übrig" and its number. On the laptop, `$UI bounds <DH1-under>.xml id=home-kcal-gauge` gives the gauge's box; read `$UI pixel <DH1-under>.png X Y` at the top centre of its arc (x = box centre, y = the box top + 4 % of its height).
2. `rt tap id=fab-add-item` → `rt tap id=add-item-snack` → `rt tap id=add-meal-quick-add` → `rt field id=quick-add-title "ONT Ueberschuss"` → `rt field id=quick-add-energy <kcal left + 500>` → `rt tap id=quick-add-submit`.
3. Home → `rt save DH1-over` → the same pixel.
Expect:
- The snackbar "Zu Snack hinzugefügt".
- Under the goal, "kcal übrig" and an arc pixel in the primary colour.
- Over it, "kcal zu viel" with about 500, and an arc pixel in the theme's error red (hue near 0°, clearly unlike DH1-under).
Note: DD1 deletes ONT Ueberschuss again. If the arc pixel doesn't decide, the session judges the two screenshots by eye. If they don't decide either, *inconclusive*, covered by `test/features/home/presentation/widgets/dashboard_widget_test.dart`.

**DH2 — Food in a 0 % meal stays visible (#1318).**
Do:
1. Settings → `rt tap id=settings-per-meal-share` → `rt tap id=meal-share-preset-omad` → `rt tap id=meal-share-save`.
2. Home → `rt save DH2-home`; `rt tap id=nav-diary` → day 0 → `rt save DH2-diary`.
3. `rt tap id=fab-add-item` → `rt save DH2-sheet` (which tile carries `add-item-suggested-chip`) → `rt back`.
4. Restore: Settings → `settings-per-meal-share` → `rt tap id=meal-share-preset-mediterranean` → `meal-share-save` → reopen → read → *ABBRECHEN*.
Expect:
- With OMAD (0/0/100/0), Home and the Diary still show *Frühstück*, *Mittagessen* and *Snack*, because each holds entries from S7–S9 and DF5. Those sections show consumed kcal without a target.
- The suggested chip sits on *Abendessen*, whatever the hour.
- After the restore, the per-meal share reads 25/45/20/10.
Note: on 2.4.0 those three sections would vanish while their kcal still counted. Step 4 must run even if steps 2–3 failed: every later goal check assumes 25/45/20/10.

### DD — Diary / tracked day (#1333, #1382, #1319, #1385)

*Blocks if:* a day's listed entries and its totals disagree; moving the day boundary loses or doubles kcal; Home and the Diary count a different day as today; a crash.

**DD1 — The sorted macro shows on each row (#1333), and a delete.**
Do:
1. `rt tap id=nav-diary` → day 0 → `rt tap id=diary-section-sort-menu@1` (Frühstück's: the menu shows only on sections with kcal, top to bottom) → `rt tap "text=Protein (absteigend)"` → `rt save DD1-protein`.
2. `rt tap id=diary-section-sort-menu@1` → `rt tap "text=Hinzugefügt am"` → `rt save DD1-time`.
3. Only if ONT Ueberschuss is listed: `rt scroll_to "text^=ONT Ueberschuss"` → `rt longpress "text^=ONT Ueberschuss"` → `rt has "text=Eintrag löschen?"` → `rt tap text=OK` → Home `rt get id=home-kcal-gauge`.
Expect:
- With protein sorting, each *Frühstück* row shows "<value> g Protein" above its kcal (one decimal, German comma). For DF5's ONT Linsensuppe 200 g that is "12,0 g Protein" (6 g/100 g).
- With *Hinzugefügt am*, the rows show kcal only.
- The delete dialog reads "Eintrag löschen?" / "Möchten Sie den ausgewählten Eintrag löschen?" with *OK* and *ABBRECHEN*. After OK, Home is back below the goal ("kcal übrig").
Note: the rows are also `LongPressDraggable`. If the press lifts the card into a drag instead of opening the dialog, nothing is deleted: record it, and leave ONT Ueberschuss in place (later kcal checks then read relative to it). #1384's typo fix of the dialog text is English-only (E5).

**DD2.a — The per-day "before".** `[export]`
Precondition: `rt clock` hour H ≤ 22. Otherwise DD2.a–c are *skipped: run after 22:00*, covered by `test/features/diary/diary_page_logical_today_test.dart`, `test/features/settings/presentation/widgets/goal_edits_logical_day_test.dart` and `test/unit_test/tracked_day_listed_day_test.dart`.
Do: export JSON `ont-r25-dd2a.zip` → pull → `$CMP summary $EVID/exports/dd2a.zip > $EVID/exports/dd2a.txt`.

**DD2.b — The logical day is "today" everywhere (#1382), and rows follow it (#1319).**
Do:
1. Settings → `rt tap id=settings-day-boundary` → `rt slider id=day-boundary-hours-slider <(H+1)/23> bottom` → `rt get` the time label; tap again with a corrected fraction until it reads `H+1:00` → `rt tap id=day-boundary-save`.
2. `rt tap id=nav-diary` → `rt save DD2-diary`. Read the day header (`DateFormat.yMMMMEEEEd`, e.g. "Mittwoch, 21. Oktober 2026").
3. Home → `rt save DD2-home`.
4. Settings → `rt tap id=settings-nutrient-goals` → read all ten fields → the fibre field (`edit=1`, the field above `nutrient-fibre-slider`) → `rt field edit=1 44` → `rt kb_hide` → read all fields again (rule 7) → `rt tap id=nutrient-goals-save` → Diary → `rt tap "text^=Heutige Nährstoffe"` → `rt save DD2-panel`.
5. **Always, even if a check above failed:** Settings → `settings-day-boundary` → `rt tap text=Zurücksetzen` → `rt tap id=day-boundary-save` → reopen → it reads `0:00` → *ABBRECHEN*.
Expect:
- With the boundary at H+1:00, everything logged on calendar day 0 before H+1:00 now belongs to the logical yesterday, day 0 − 1, which is the current logical day. Every midnight-dated seed entry moves back a day as well (a moment before the boundary files under the day before): day 0 − 1's seed now lists under day 0 − 2, and so on. The Diary **opens on day 0 − 1**: its header names day 0 − 1, the calendar's today marker sits on day 0 − 1, and it lists exactly the entries logged on calendar day 0. Home counts the same entries.
- The settings run's "before" (2026-10-11, row 11): the Diary stayed on the calendar date, with nothing on it.
- The fibre goal saved in step 4 shows as "/ 44 g" on the Diary's logical today. 2.4.0 put it on the calendar date (settings-run B6).
- After step 5, the boundary is `0:00`.
Note: the dialog holds two sliders and is never swiped (the driver refuses it anyway). If the run stops inside this step, the boundary may stay moved. The resumed step runs again from step 1, and step 5 resets it.

**DD2.c — Nothing lost by moving the boundary there and back.** `[export]`
Do: export JSON `ont-r25-dd2c.zip` → pull → `$CMP diff $EVID/exports/dd2a.zip $EVID/exports/dd2c.zip > $EVID/exports/DD2.txt`.
Expect: intakes `missing 0 extra 0 changed 0 stored-twice 0`; no tracked-day line with `NEW tracked != NEW sum` or `row lost`; every day's tracked kcal equal before and after. The day 0 − 1 row carrying `fibreGoal 44` is the expected trace of step 4.

**DD3 — Creating a missing day never wipes one (#1385).** *Skipped on the phone:* the race needs two writers between a check and a write. Covered by `test/unit_test/tracked_day_create_if_absent_test.dart`; its three caller tests each fail with the old `addNewTrackedDay`. DD2.c and U4 check that rows and entries agree on the phone.

### DA — Add meal, search and recents (#1334, #1282, #1252, #1291)

*Blocks if:* a search result logs different nutrition than its record; Recently offers an edited recipe with its old nutrition (#1291); a crash.

**DA1 — Recent stays put while typing, and *Search all* (#1334).**
Do:
1. Search screen (`add-item-lunch`) → `rt field id=meal-search-field "ONT Lin"` **without** touching a chip → wait 1 s → `rt save DA1a`.
2. `rt tap id=meal-search-field` → `rt clear`.
3. `rt tap text=Kürzlich` → `rt field id=meal-search-field "ONT Lin"` → wait 1 s → `rt save DA1b`.
4. `rt tap id=meal-search-field` → `rt clear` → `rt type zzqqx` → wait 2 s → `rt kb_hide` → `rt save DA1c` → `rt tap id=search-no-results-search-all` → wait 3 s → `rt save DA1d` → `rt back`.
Expect:
- DA1a: typing without a chip choice switches to *Alle* (the unchanged default).
- DA1b: *Kürzlich* stays selected and lists only ONT Linsensuppe (`add-meal-recent-list`).
- DA1c: "Keine Ergebnisse gefunden", the scan and create buttons, and "Search all" (`search-no-results-search-all`).
- DA1d: *Alle* selected, and its own no-results state for `zzqqx`.
Note: the no-results buttons sit behind the keyboard until it is hidden (2.4.0 run). Never tap *Barcode scannen* or *Eigenes Lebensmittel erstellen* here.

**DA2 — A failed source vs. zero results (#1282).** *Skipped on the phone:* making one source fail needs one provider's network cut, and the run doesn't change device settings. Covered by `test/features/add_meal/presentation/add_meal_screen_provider_failure_test.dart` and `test/widget_test/partial_results_notice_test.dart`. Negative control on the phone: no search in this run should show the "One food source didn't respond…" banner. If one does, write down the query and the time; that alone isn't a failure.

**DA3 — Recents chronological (#1252).** Shown in U7.

**DA4 — An edited recipe is offered as it is now (#1291).**
Guard: if the *Rezepte* tab already reads ONT Gemuesecurry scharf, skip step 2.
Do:
1. If S9.2 didn't log ONT Gemuesecurry, log it now the S9.2 way.
2. You → `profile-recipes` → *Rezepte* → ONT Gemuesecurry → `rt tap "text=Rezept bearbeiten"` → `rt get edit=1` must read `ONT Gemuesecurry` (*Rezeptname*) → `rt field edit=1 "ONT Gemuesecurry scharf"` → `rt kb_hide` → `rt tap id=recipe-builder-save`.
3. Search screen (`add-item-dinner`) → *Kürzlich* → `rt save DA4-recent` → tap ONT Gemuesecurry scharf → `rt save DA4-detail` → `rt back` twice.
4. Diary day 0 → `rt save DA4-diary`.
Expect:
- Recently shows **ONT Gemuesecurry scharf**, the recipe as it is now, not the old name.
- The diary entry logged before the edit still reads ONT Gemuesecurry, 275 kcal: a logged entry is not rewritten.
- The detail screen's energy per 100 g is unchanged, 78.6 kcal (fx: 275 kcal over 350 g). Only the name was edited.
Note: never tap *Rezept teilen* (the share sheet).

### DM — Meal detail (#1297, #1376)

*Blocks if:* the detail screen shows wrong values for a food; a crash.

**DM1 — No dead info button on custom meals and recipes (#1297).**
Do:
1. Search screen → `rt field id=meal-search-field "ONT Jog"` → tap ONT Joghurt → `rt save DM1-custom` → `rt back`.
2. You → `profile-recipes` → *Rezepte* → ONT Bananenbrot → `rt tap "text=Dieses Rezept loggen"` → `rt tap text=Snack` → `rt save DM1-recipe` → `rt back` (no Add) → `rt back`.
3. Search screen → `nutella` → *Produkte* → the S7 product → `rt save DM1-off` → `rt back`.
Expect: no *Benutzerdefinierte Mahlzeit* button on the custom meal (S14 saw it on 2.4.0), and no info button on the recipe. The Open Food Facts product still shows "Weitere Informationen unter OpenFoodFacts".
Note: never tap that button (rule 3).

**DM2 — Micronutrients follow the switch (#1376).**
Do: Settings → `rt scroll_to "text^=Mikronährstoffe anzeigen"` → read its state → set it **off** → the S7 product → `rt save DM2-off` → `rt back` → Settings → switch it **on** → the same product → `rt save DM2-on` → `rt back` → **always:** Settings → set it back to S3's state.
Expect: off → no *Mikronährstoffe* section; on → the section, expanded.
Note: on 2.4.0, *off* still showed the section for a food that has data (settings-run row 14, "fail (design)"). The switch defaults to off, so a user who never touched it now sees no micronutrients: that is the PR's stated trade-off, not a defect.

### DR — Custom meals and recipes (#1404, #1420, #1280, #1294, #1328)

*Blocks if:* an edit leaves two copies of a meal; a past entry changes its kcal or macros through an edit; an entry is lost; a recipe's total weight changes without the user typing it.

**DR1 — Renaming a meal without a barcode replaces it, and its past entries follow (#1404, #1420).**
Guard: if *Eigene Mahlzeiten* already lists ONT Linsensuppe rot, skip step 2.
Do:
1. You → `profile-recipes` → `rt tap "text=Eigene Mahlzeiten"` → `rt save DR1-before`.
2. `rt tap "text^=ONT Linsensuppe"`: the row's title text, never the trash icon at its right. In *Mahlzeit bearbeiten*, `rt get edit=1` must read `ONT Linsensuppe` → `rt field edit=1 "ONT Linsensuppe rot"` → `rt get edit=1` → `rt kb_hide` → `rt tap id=edit-meal-save`.
3. `rt save DR1-library`; Diary day 0 − 6 → `rt save DR1-diary`.
Expect:
- *Eigene Mahlzeiten* lists **one** ONT Linsensuppe rot and no ONT Linsensuppe. 2.4.0 kept both (#1403).
- Day 0 − 6's entry now reads ONT Linsensuppe rot, with its old amount (350 g) and kcal (315).
Note: the German delete-confirm text still says entries *may* stay; the English source now says "in this profile" (#1420). Note it only.

**DR2 — Changing a barcode replaces the meal and moves its entry (#1404, #1420).**
Guard: if ONT Riegel's barcode already reads `2000000000022`, skip the edit.
Do: *Eigene Mahlzeiten* → `rt tap "text^=ONT Riegel"` → `rt get id=edit-meal-barcode-input` must read `2000000000015` → `rt field id=edit-meal-barcode-input 2000000000022` → `rt kb_hide` → `rt tap id=edit-meal-save` → `rt save DR2-library`.
Expect: one ONT Riegel in the library. Never tap `edit-meal-barcode-scan` (the camera).

**DR3 — The edits in the data.** `[export]`
Do: export JSON `ont-r25-dr.zip` → pull → `$CMP diff $EVID/exports/up2.zip $EVID/exports/dr.zip > $EVID/exports/DR.txt`; and over `dr.zip`'s `user_intake.json`, count the intakes whose `meal.name` is `ONT Linsensuppe` and `ONT Linsensuppe rot`, and read S9's ONT Riegel entry's `meal.code`.
Expect:
- 0 intakes named `ONT Linsensuppe`. Those named `ONT Linsensuppe rot`: the 6 from the seed plus DF5's, with the same amounts and kcal as in `up2`.
- S9's ONT Riegel entry has `meal.code` `2000000000022` and the same kcal (168). No entry keeps `2000000000015`.
- `DR.txt`: the only `changed` intakes are those renamed or recoded entries, and no day's tracked kcal moved.
Note: if S9.1 didn't seed the entry, the Riegel half is *skipped: no seed*.

**DR4 — A hand-entered total weight survives reopening (#1280).**
Do: *Rezepte* → ONT Bananenbrot → `rt tap "text=Rezept bearbeiten"` → `rt save DR4` → `rt back`. If *Änderungen verwerfen?* appears, `rt tap text=Verwerfen`.
Expect: *Gesamtgewicht (g)* `450`; the helper "Entered manually, so changing ingredients won't change it."; the button `recipe-builder-weight-reset` "Use ingredient total". Don't tap it.
Note: 2.4.0 reopened it at the 500 g sum, and any save would have stored 500 (#1277).

**DR5 — A shared recipe's total weight on import (#1294).** Shown in DC4.

**DR6 — Typed macros applied when the field loses focus (#1328).**
Do: Settings → `rt tap id=settings-macro-split` → `rt get edit=1` (carbs; `id=macro-split-carbs` is the slider, never tap it) → `rt field edit=1 50` → **without Done**, `rt tap text=Makro-Aufteilung` (the dialog title, outside every field) → `rt save DR6` → `rt tap text=ABBRECHEN`.
Expect: after the tap outside, protein and fat have already rebalanced, and the three fields add up to 100 (the PR's test: without the fix, carbs 60 stays and nothing moves). *ABBRECHEN* leaves the stored split as it was.
Note: #1328's other half, a dismissible number pad, is iOS-only and out of scope; Android's Done always worked.

### DS — Settings (#1371, #1273, #1384, #1370, #1372, #1353, #1380, #1390, #1332)

The "before" for most of these is the settings run on 2.4.0 (`docs/settings-test/run-2026-10-11/results.md` on `research/settings-pixel-test`). Every step here sets values, so each is safe to run twice. Each one that changes a goal also puts it back, because path 3 (R8) compares the goals with `cand.zip`.

*Blocks if:* a goal the user saved isn't the one stored; after a save, a goal shows on one screen and not on another (the Diary and Trends must now follow without a restart); a typed value is lost on OK; a crash.

**DS1 — A typed value is applied on OK, without Done (#1371).**
Do:
1. `rt tap id=nav-trends` → `rt save DS1-trends-before`; `rt tap id=nav-diary` → day 0 → `rt save DS1-diary-before`. Both blocs are now loaded, so the next steps are a real staleness test.
2. Settings → `rt tap id=settings-kcal-adjustment` → `rt field id=kcal-adjustment-input 300` → **no Done** → `rt tap id=kcal-adjustment-save`.
3. Reopen → `rt get id=kcal-adjustment-input` → `rt tap text=ABBRECHEN`.
4. Home `rt save DS1-home`; Diary day 0 `rt save DS1-diary`; Trends `rt save DS1-trends`.
5. You → `profile-water-goal` → `rt field id=water-goal-input 2600` → **no Done** → `rt tap id=water-goal-save` → reopen → read → *ABBRECHEN*.
Expect:
- The kcal adjustment reopens at `300` (2.4.0: 250, the typed value dropped, #1347).
- Home's goal is 50 higher than after S12. The Diary's day goal follows **at once**, without R (settings-run row 7: the Diary stayed old until R, B3). The Trends goal line moved between DS1-trends-before and DS1-trends.
- The water goal reopens at `2600`.
Note: the water goal stays 2600 from here on (X1 and R8 expect it).

**DS2 — kJ: the adjustment rounds (#1273), and the row says kJ (#1384).**
Do:
1. Settings → `rt tap id=settings-energy-unit` → *Kilojoule (kJ)* → OK.
2. `rt get id=settings-kcal-adjustment` → tap it → `rt save DS2-dialog` → `rt field id=kcal-adjustment-input 1255` → `rt tap id=kcal-adjustment-save`.
3. Reopen → read → *ABBRECHEN*.
4. `settings-energy-unit` → *Kilokalorien (kcal)* → OK → reopen the adjustment → read.
5. **Always, even if a check above failed or the step is resumed:** kcal mode, then `rt field id=kcal-adjustment-input 250` → `kcal-adjustment-save` (back to S12's value).
Expect:
- In kJ mode the row and the dialog title read "Daily kJ adjustment", in English (no German entry yet).
- `1255` kJ reopens as **1255** in kJ mode and as **300** in kcal mode. On 2.4.0 the settings run's K2 probe reopened it at 1251: `toInt` turned 299.95 kcal into 299.
- After step 5, `250`.

**DS3 — The settings list keeps its place, the cache count is fresh, and the last row clears the button (#1384).**
Do:
1. Settings → `rt scroll_to "text^=Makros je Mahlzeit anzeigen"` → read its state (S3 wrote down the start state) → `rt save DS3-a` → tap it → `rt save DS3-b` → read its state; if it differs from S3's, tap it again → `rt save DS3-c`.
2. `rt scroll_to "text^=Cache leeren"` → `rt get "text^=Cache leeren"` (**read only, never tap**). Then search screen (`add-item-snack`) → `rt field id=meal-search-field chips` → `rt tap text=Produkte` → wait 3 s → `rt back` → Settings → `rt scroll_to "text^=Cache leeren"` → `rt get` it again.
3. On the You page, `rt swipe up` until two `rt ls` listings match (the end of the list) → `rt save DS3-end`.
4. Settings → `settings-food-units` → *Imperial* → OK → search screen → `nutella` → *Produkte* → the S7 product → tap the *Einheit* button → `rt save DS3-imperial` → `rt back` (closes the menu) → `rt back` → **always:** Settings → `settings-food-units` → *Metrisch* → OK.
Expect:
- Step 1: `$UI bounds` on the three saved dumps gives the tile the same y (±10 px) each time. 2.4.0 jumped to the top after every save (inventory B10).
- Step 2: the cache count is higher after the search, without a restart (settings-run row 35: stale until restart).
- Step 3: in `DS3-end.xml`, the last tile (*Über*) ends at least 84 px (32 dp) above the top of `fab-add-item` (`$UI bounds` of both). #1384 measured 5 dp before.
- Step 4: the serving entry reads in ounces, e.g. "0.53 oz (Portion)", not "15 g (Portion)".

**DS4 — The Diary and Trends follow a settings change at once (#1370).**
Each sub-step opens the consumer once, changes the setting, then reads the consumer **without R**:
- (a) Macro split: `settings-macro-split` → `rt field edit=1 50` (carbs) → `rt done` → `macro-split-save` → Diary day 0 (macro goals) and Trends (daily averages) changed at once (settings-run row 8, B3). Then, **always**, the same dialog back to `45` with Done → save.
- (b) *Makros je Mahlzeit anzeigen* set off (read its state first) → the Diary's meal headers lose the c/f/p line at once (row 13, B1). Then set it back to S3's state.
- (c) `settings-nutrient-visibility` → set *Eisen* unticked (read its state first) → `rt back` → the Diary panel *Heutige Nährstoffe* has no iron row at once (row 15, B2). Then set it ticked again.
- (d) Trends' water card reads "/ 2600 ml" right after DS1 (row 42: "/ 1500 ml" until R).
- (e) Weight: DW2.
Expect: every consumer changes before any restart.
Note: (a)'s round trip can leave protein and fat a point away from S12's values. Later steps read them from `cand.zip`, not from S12.

**DS5 — Reset + Save clears the nutrient goals (#1353).**
Do: Settings → `rt tap id=settings-nutrient-goals` → read all ten fields (scrolling with `rt swipe up` and re-reading, rule 7) → `rt tap id=nutrient-goals-reset` → read them → `rt tap id=nutrient-goals-save` → reopen → read → Diary day 0 → *Heutige Nährstoffe* → `rt save DS5-panel`.
Expect:
- After Save and reopen, every field shows its default: fibre per DS6; iron by gender (8 mg male, 18 mg female, 14 mg otherwise); the others at the references their descriptions name. No value set earlier today survives (DD2's 44 g sits on day 0 − 1, not today).
- The Diary panel uses the same defaults.
- 2.4.0 kept the old values (#1349).

**DS6 — The fibre goal opens at the Diary's reference (#1380).**
Do: right after DS5 (no fibre goal saved today), `rt get edit=1` (fibre) and the slider `nutrient-fibre-slider`, and the Diary panel's fibre reference (DS5-panel).
Expect: both equal the IOM value for S1's gender and age (S1's note), e.g. 38 for a man of 36 or 25 for a woman of 30. Settings no longer shows a flat 30 while the Diary uses another number. The German description still says "Standardreferenz: 30 g" (stale German, noted above).

**DS7 — A comma decimal is accepted (#1390).**
Do: `settings-nutrient-goals` → `rt scroll_to id=nutrient-iron-slider` → `rt ls`: the iron field is the EditText directly above that slider; call it `edit=N` → `rt field edit=N "12,5"` → `rt kb_hide` → `rt get edit=N` → read every field (rule 7) → `rt tap id=nutrient-goals-save` → reopen → read the iron field → Diary panel → `rt save DS7-panel`. Then `nutrient-goals-reset` → `nutrient-goals-save`, which leaves today at the defaults.
Expect: the field shows `12.5` as soon as the comma is typed (the formatter turns it into a period); it reopens at `12.5`; the Diary panel's iron reference reads 12.5 (with either separator). 2.4.0 turned `12,5` into `125` and clamped it.

**DS8 — The language list scrolls (#1332).**
Do: Settings → `rt tap "text^=Sprache"` → `rt save DS8a` → up to 15 times: `rt swipe_in text=<the lowest language row in the last listing> up`, then `rt ls`, until the last shipped language (Español) is on screen → `rt save DS8b` → `rt tap text=ABBRECHEN`.
Expect: every row from Systemstandard through the last shipped language is reachable. In DS8b the last row's bounds lie inside the dialog, above *ABBRECHEN* / *OK*, which stay in place. The language is unchanged.
Note: `swipe_in` is the only way to scroll a dialog's list, and it drags half the chosen node's height, about 26 px of scroll per swipe after the touch slop. A short drag that a radio row reads as a tap only selects that row inside the dialog, and *ABBRECHEN* discards it. If the end is never reached, record *inconclusive*, with DS8a's saved XML showing whether the list is scrollable. Settings-run row 20 couldn't reach the languages below the fold (#1331). Never pick a language here (rule 12).

**DS9 — Today's tracked day on an empty day (#1372).** It needs a day with no entries and no row, which the upgraded profile no longer has today. Shown in N11 (path 2); covered by `test/features/settings/presentation/bloc/settings_bloc_update_tracked_day_test.dart`.

**DS10 — Health Connect *Jetzt importieren* gives feedback (#1384 item 5).** *Skipped:* pressing it imports the maintainer's real workouts, which was decided out (#1430). Covered by `test/features/settings/presentation/widgets/health_sync_screen_test.dart`.

### DW — Weight and profile (#1222, #1383, #1419)

*Blocks if:* a weight entry disappears; Trends shows a weight that the history doesn't; a crash.

**DW1 — *Eintrag hinzufügen* starts from the profile's weight (#1383, upgrade half).**
Do: You → `rt tap "text^=Gewichtsverlauf"` → `rt tap id=weight-history-add` → `rt get id=weight-history-weight-input` → `rt tap text=ABBRECHEN`.
Expect: **w0**, the profile weight, not the 70 kg fallback. The onboarding-weight half is N10.

**DW2 — A new reading shows on Trends at once (#1370).**
Do:
1. `rt tap id=nav-trends` → scroll to the weight card → `rt save DW2-before`.
2. You → *Gewichtsverlauf* → `weight-history-add` → *Datum* = day 0 − 3 → `rt field id=weight-history-weight-input <w0 + 0.3>` → OK.
3. Trends → the weight card → `rt save DW2-after`.
Expect: the history lists five tiles (S11's four and the new one), and the Trends weight card shows the new reading without R (#1370 reloads Trends after `_onAddEntry`; the settings run saw Trends stale after weight changes).
Note: entries are keyed by day, so a re-run rewrites the same row. **The delete half of #1419 is *skipped*:** a weight row's delete button carries no label, no text and no identifier, and the driver has no coordinate tap. The time-zone case it fixes can't be produced on the phone either. Both are covered by `test/unit_test/delete_weight_log_usecase_test.dart` and `test/features/profile/presentation/weight_history_screen_test.dart` (the shifted row is deleted by its storage key).

**DW3 — The weight chart windows by calendar days across DST (#1222).**
Only if day 0 is 2026-10-26 or later, when the 30-day window contains the 2026-10-25 fall-back: add two readings, one on a day before 2026-10-25 and one on a day from 2026-10-25 on, both inside the window and neither on a day S11 or DW2 already used (days −6, −4, −3, −2, 0), S11's way, at w0 + 0.1 and w0 − 0.1 → the chart at *30d* → `rt save DW3`.
Expect: one dot per reading, each on its own day's label, and no reading dropped at the window's start.
Otherwise *skipped: no DST transition inside the window on day 0*, covered by `test/features/profile/presentation/widgets/weight_trend_chart_test.dart` and `test/unit_test/calendar_day_calc_test.dart`, run under `TZ=Europe/Berlin` by `just test_dst`.

### DN — Notifications (#1379, #1391)

The reminder surviving the upgrade is U5. The language half of #1379 is E10–E11. Onboarding's reminder going through the scheduler (#1391) is N7–N9. The failed-reschedule half of #1391 (the alarm kept when `zonedSchedule` throws) can't be forced on the phone. It is covered by `test/unit_test/daily_reminder_scheduler_test.dart` ("a refresh whose zonedSchedule throws leaves the previous alarm").

### DT — Trends (#1377)

*Blocks if:* Trends shows kcal numbers labelled as kJ, or the reverse; a crash.

**DT1 — The calorie chart in the selected unit.**
Do: Settings → *Kilojoule (kJ)* → `rt tap id=nav-trends` → `rt save DT1-kj` → **always:** Settings → *Kilokalorien (kcal)* → Trends → `rt save DT1-kcal`.
Expect: Trends renders in both units, with no error.
Note: **the number itself is *skipped*.** The chart has no axis labels, the goal line and the points scale together, and the tooltip shows only while a finger is held; the driver has no hold-and-screenshot action. Covered by `test/features/trends/trends_calorie_chart_energy_unit_test.dart` (1039 kcal plots at 4347.18 in kJ mode; it fails on 2.4.0's code).

### DAI — AI meal assistance (#1378) and the real key

The key is OpenRouter's (`~/.config/ont-run/ai-key`). The run judges the flow, not which food the model names ([#1427](https://github.com/simonoppowa/OpenNutriTracker/issues/1427)).

*Blocks if:* a nutrition value arrives from the model (every row's numbers must come from a food database); the key is shown, logged or kept in the evidence; a crash.

**DAI1 — Save the key.**
Guard: if the *KI-Unterstützung* subtitle already reads "An — OpenRouter", a key is stored: skip to the Expect check.
Do:
1. Settings → `rt scroll_to id=settings-ai-assist` → `rt get id=settings-ai-assist` → tap it → `rt tap id=ai-assist-provider-openrouter`.
2. `rt type_secret`: it taps `ai-assist-key-field`, checks it is a password field, types the key from stdin and checks the bullet count.
3. `rt tap id=ai-assist-save-key`. This closes the secret window. Nothing else may come between steps 2 and 3.
4. If the route *Bevor du das einschaltest* opens, `rt save DAI1-consent` → `rt tap id=ai-consent-agree`.
5. `rt get id=settings-ai-assist`.
Expect:
- On a first save, the consent route holds "Dein Tagebuch und dein Profil werden nie gesendet. Nährwerte stammen immer aus den Lebensmitteldatenbanken, nie vom Modell. …".
- After saving: "Schlüssel gespeichert" and `ai-assist-remove-key`; the subtitle "An — OpenRouter".
- `step_end` runs the key audit over the run folder and finds nothing.
Note: a `type_secret` refusal (98) names its reason, e.g. `show_password` isn't 0 or the field isn't a password field. Record it and skip DAI2, never work around it.

**DAI2 — One typed meal through the real provider.**
Do: `rt mark DAI2` → search screen → `rt tap id=add-meal-bulk-add` → `rt field id=bulk-add-input "2 Eier und eine Scheibe Brot"` → `rt tap id=bulk-add-parse` → `rt wait id=bulk-add-row-list 90` → `rt save DAI2` → `rt back` (no submit) → `rt back` → `rt errors`.
Expect:
- The banner `bulk-add-model-notice` "Von KI gelesen — prüfe jede Zeile".
- Rows titled with database food names, each with an energy figure.
- `bulk-add-submit` reading "{n} Einträge speichern".
- In the logcat after the mark, the resolution against Supabase / Open Food Facts and the portion RPCs, and no `SEVERE: BulkAddBloc` or `SEVERE: BulkAddScreen`.
Note: a caption such as "KI nicht verwendet: Dein API-Schlüssel wurde abgelehnt." or "… Guthaben … aufgebraucht" is *inconclusive* (key or account), not a product failure. Nothing is submitted; the photo button stays untouched (rule 3).

**DAI3 — A typed model survives an address change, and a refused OK is shown (#1378).**
Do:
1. Settings → `settings-ai-assist` → `rt tap id=ai-assist-provider-own-server` → `rt field id=ai-assist-endpoint-field http://127.0.0.1:11434` → `rt field id=ai-assist-model-field llama3`.
2. `rt field id=ai-assist-endpoint-field http://127.0.0.1:11435` → `rt tap id=ai-assist-model-field` (focus leaving the address starts the fetch) → wait 5 s → `rt get id=ai-assist-model-field` → `rt save DAI3a`.
3. `rt tap id=ai-assist-model-field` → `rt clear` → `rt tap id=ai-assist-save-key` → `rt save DAI3b`.
4. `rt tap id=ai-assist-cancel` → `rt get id=settings-ai-assist`.
Expect:
- Step 2: "127.0.0.1:11435 war nicht erreichbar…" (nothing listens there), and the model field **still reads `llama3`**. 2.4.0 cleared it a moment after the address changed (settings-run row 29).
- Step 3: OK refuses. In DAI3b's XML, "Gib den Namen des Modells an, das dieser Server verwenden soll." lies inside the dialog's visible area above the keyboard, and the model field is focused.
- Step 4: the subtitle still reads "An — OpenRouter".
Note: **never tap OK while both own-server fields are filled**: that would make the unreachable server the active provider. If the subtitle no longer reads OpenRouter after step 4, open the dialog, select OpenRouter, OK, and record it.

### DL — Localization (#1230, #1223, #1415, Weblate)

*Blocks if:* the UI shows another language than the one chosen; a screen shows a raw key or `{placeholder}`; a crash. #1230 is E9.

**DL1 — New activity rows can be found (#1223).**
Do: `rt tap id=fab-add-item` → `rt tap id=add-item-activity` → `rt field edit=1 yoga` → wait 1 s → `rt save DL1a` → `rt tap edit=1` → `rt clear` → `rt type rowing` → `rt save DL1b` → `rt back`.
Expect: `yoga` finds a row named "yoga" (2.4.0 found nothing, #118), and `rowing` finds "rowing machine". Both names are English: new keys without German entries yet. The full uniqueness check runs in English, E7.

**DL2 — "min" on activities (#1415).**
Do: Home → `rt save DL2-home` (S10's activity card); the activity detail of any row → `rt save DL2-detail` → `rt back`.
Expect: "30 min" and "~<n> kcal / … min". German shows the same, because the new key has no German entry yet.

**DL3 — Weblate: no new shipped language.**
Do: compare DS8's language rows with `lib/core/l10n/shipped_locales.dart` at `c293acff4`.
Expect: the same entries as 2.4.0's picker. *Svenska*, *Nederlands* and *العربية* received translation files this cycle, but none is a shipped locale ([#1425](https://github.com/simonoppowa/OpenNutriTracker/issues/1425)). A language listed without being shipped is a finding.

---

## Part 4 — Every other area at smoke depth

One cheap step per area that the delta didn't already exercise. Each K step is a step of its own (`step_begin K<n>`). *Blocks if*, for every K step: a crash, a red screen, an empty list where the data is local, or a number that disagrees with the screen it came from.

**K1 — Diary navigation and the nutrient panel.**
Do: `rt tap id=nav-diary` → tap day 0 − 3's cell (`rt tap text=<its day number>`; read the header afterwards and, if it names another day, tap the next match `@2`) → `rt save K1` → `rt tap "text^=Heutige Nährstoffe"` → `rt tap text=Woche` → `rt save K1-week`.
Expect: the header names day 0 − 3, and the day lists its seed entries (fx `diary_days`, with DR1's new name); *Woche* renders.
Note: the "jump to today" icon has no label and isn't tapped. Day navigation is read-only, so a wrong cell costs nothing.

**K2 — Add meal, all providers.**
Do: search screen → `rt field id=meal-search-field "ONT Hafer"` → `rt save K2-all`; `nutella` → `rt tap text=Produkte` → `rt save K2-off`; `apfel` → `rt tap text=Lebensmittel` → `rt save K2-food`; clear → `rt tap text=Kürzlich` → `rt save K2-recent` → `rt back`.
Expect: each provider returns rows. Every card under *Produkte* carries the "Open Food Facts" chip, and every card under *Lebensmittel* a *BLS* / *FDC …* chip; the custom meal has none. The Open Food Facts cards show real thumbnails (judged from K2-off's screenshot).

**K3 — The scanner, by manual entry (the camera itself is skipped).**
Do: search screen (`add-item-snack`) → `rt tap id=meal-search-barcode` → `rt wait id=scanner-manual-entry-open 10` → tap it → `rt has "text=Barcode eingeben"` → `rt field id=scanner-manual-entry-field <S7's barcode>` → `rt tap id=scanner-manual-entry-submit` → `rt wait id=meal-detail-add 60` → `rt save K3` → `rt back` (no Add) → `rt back`.
Expect: the scanner opens without a system prompt (CAMERA granted in P7); the manual lookup lands on the product's detail screen, the same lookup a camera detection runs.
Note: if S7 recorded no barcode, use `3017620422003`. The driver screenshots after every action, so the camera preview lands in K3's evidence: the phone lies on the desk, so that is the ceiling. Those files stay in the run folder and are never attached anywhere.

**K4 — Meal detail chips.**
Do: search screen → `nutella` → *Produkte* → the S7 product → after hydration `rt ls | grep meal-detail-chip` → `rt tap id=meal-detail-chip-100g` → `rt get edit=1` → `rt back` (no Add).
Expect: `meal-detail-chip-100g`, plus `…-half-serving` / `…-one-serving` / `…-double-serving` if the product has a serving. After the 100 g chip: Menge `100`, unit `g`.

**K5 — Custom meals screen.**
Do: You → `profile-recipes` → *Eigene Mahlzeiten* → `rt save K5` → `rt tap id=custom-foods-merge-open@1` → `rt save K5-menu` → `rt back` (closes the menu, nothing picked).
Expect: ONT Haferbrei, ONT Joghurt, ONT Linsensuppe rot, ONT Riegel, ONT Code Haferbrei, ONT Code Apfel and ONT Code Rest, each once. The menu offers merging; it isn't used.

**K6 — Recipes.**
Do: *Rezepte* → `rt save K6`.
Expect: ONT Gemuesecurry scharf ("2 Zutat(en) · 275 kcal"), ONT Bananenbrot ("2 Zutat(en) · 987 kcal") and ONT Code Eintopf ("1 Zutat(en) · 200 kcal": 100 g of a 200 kcal/100 g ingredient).

**K7 — Activities.**
Do: `fab-add-item` → `add-item-activity` → *Alle* → the first card → `rt save K7` → `rt back` (no Add) → `rt tap text=Kürzlich` → `rt save K7-recent` → `rt back`.
Expect: the detail reads "~<n> kcal / … min"; *Kürzlich* lists S10's activity.

**K8 — Health Connect: the screen and the disclosure, nothing more.**
Do: Settings → `rt scroll_to id=settings-health-sync` → tap it → read its state (`rt ls | grep health-sync-auto-import`: must end in `{unchecked}`, as S3 left it; if it reads `{checked}`, stop the step and record it, never tap) → tap it → `rt wait "text^=Trainings aus Health Connect importieren?" 5` → `rt save K8` → `rt tap text=ABBRECHEN` → read its state again → `rt back`.
Expect: the in-app disclosure appears before anything else, with *ABBRECHEN* and *Weiter*. After *ABBRECHEN*, the switch is still off.
Note: **never** *Weiter*, `health-sync-import-now`, `health-sync-kcal-multiplier` or `health-sync-sources`. The health reads are held on this install (P7), so *Weiter* would import the maintainer's real workouts at once. The grant flow and the import are *skipped* (decision, #1430).

**K9 — Fasting.**
Do: You → `rt scroll_to id=profile-fasting-entry` → tap it → if *Bevor du beginnst* shows, `rt tap id=fasting-warning-accept` → `rt save K9` → `rt back`.
Expect: `fasting-preset-16h`, `fasting-preset-custom` and `fasting-start` ("Timer starten"). **No fast is started.** Never tap *BEAT (UK)* / *NEDA (US)*.

**K10 — Trends.**
Do: `rt tap id=nav-trends` → `rt tap text=7d` / `text=30d` / `text=90d` / `text=Alle` in `trends-range-selector`, `rt save` after each → `rt scroll_to "text^=Gewicht"` → `rt save K10-weight`.
Expect: each range renders; the weight card shows S11's and DW2's readings.

**K11 — Profile.**
Do: You → `rt save K11`.
Expect: S1's tiles unchanged, the weight **w0**, the water goal "2600 ml", the BMI card rendered.

**K12 — Settings smoke.**
Do: open and cancel each dialog this script hasn't opened yet: *Thema* (`rt tap text=ABBRECHEN`), `settings-accent-colour` (cancel), `settings-kcal-goal-info` (`rt back`), `settings-food-sources` (`rt back`), *Datenschutz…* (cancel), *Hinweis* (`settingsDisclaimerLabel`, close), *Über* (close; no links, no *Lizenzen*). `rt save` each.
Expect: each opens and closes; nothing changes; no red screen.
Note: *Fehler melden* isn't opened (its OK leaves for the mail app).

**K13 — Notifications.**
Do: `rt alarms`.
Expect: S13's reminder still armed for 20:30. Delivery is checked in E10–E11.

**K14 — Export in both formats.** Covered by X1/X2.

Onboarding is Part 6, AI is DAI.

---

## Part 5 — The candidate's own exports

**X0 — Everything Part 3 changed is back where X1 expects it.**
Do: Settings → read (and cancel each dialog): `settings-energy-unit`, `settings-food-units`, `settings-body-weight-unit`, `settings-kcal-adjustment`, `settings-macro-split`, `settings-per-meal-share`, `settings-day-boundary`, *Mikronährstoffe anzeigen* and *Makros je Mahlzeit anzeigen* (states from `rt ls`), `settings-nutrient-visibility` (*Eisen* ticked); You → water goal.
Expect: kcal, metric, kg; adjustment 250; carbs 45; 25/45/20/10; `0:00`; the two switches as S3 wrote them down; iron ticked; water 2600 ml. Anything that drifted (a step stopped before its restore) is set back here, with Done before OK, and recorded with the step that left it.

**X1 — JSON.** `[export]`
Do: Settings → `rt tap "text^=App-Daten exportieren / importieren"` → `JSON` → *Exportieren* → `ont-r25-cand.zip` → Save → `rt back` → pull to `$EVID/exports/cand.zip` → `$ADB push $EVID/exports/cand.zip /sdcard/Download/ont-r25-cand.zip` → `$CMP summary $EVID/exports/cand.zip > $EVID/exports/cand.txt`.
Expect, beyond the files 2.4.0 wrote:
- `goal_settings.json` with `kcalAdjustment 250`, `carbGoalPct 0.45`, `mealKcalSharesPct` 25/45/20/10 and `dailyWaterGoalMl 2600`.
- `user_favourites.json` with two entries, ONT Linsensuppe rot and the S7 product. The favourite moved with DR1's rename.
- `tracked_day_boundary.json` with `dayStartOffsetMinutes 0`.
- `intake ids stored twice or more: 0; blank ids: 0`.

**X2 — CSV.** `[export]`
Do: the same dialog → `CSV` → `rt save X2-note` → *Exportieren* → `ont-r25-candcsv.zip` → Save → pull → `unzip -l`.
Expect: `user_activity.csv`, `user_intake.csv`, `user_tracked_day.csv` and `tracked_day_boundary.csv`; no favourites, recipes or weight log. The note reads "CSV speichert Aktivitäten, das Essensprotokoll und protokollierte Tage. …" (the German still names only recipes; the English now names favourites too).

**X3 — Hold.** `cand.zip` is R8's and R9's subject. Nothing that X1 should have held may be written between X1 and N1. On a resumed run whose N1 isn't done yet, if anything ran after X1, redo X1 as `X1b`.

---

## Part 6 — Path 2: fresh onboarding

`pm clear` deletes the profile on the phone. Everything worth keeping is in `$EVID/exports/` by now: `pre`, `base240`, `up1`, `up2`, `dd2a`, `dd2c`, `dr`, `cand`. From here on every `prep`, `pm_clear` and `install` runs as `RT_GRANTS="$NOHC" rt …`, **including the `prep` of the driver's resume procedure** (README, *Resuming*, step 4): a plain `rt prep` would grant the health reads to the cleared app.

*Blocks if:* onboarding can't be finished; the first Home shows a goal that doesn't match the overview; the onboarding weight is missing from Weight history (#1383); the reminder switched on during onboarding has no alarm (#1391); a goal saved on an empty day is lost (#1372); the demo can't be entered, or leaves its data behind; a crash.

**N1 — Clear the candidate, and launch at once.**
Guard: `$EVID/exports/cand.zip` must exist and `unzip -l` must list `user_intake.json` and `goal_settings.json` in it, and X1 (or a redone X1b) must have a final status in `steps.tsv`, whichever verdict. Otherwise stop: nothing may be cleared before the candidate's own backup is off the phone.
Do: `RT_GRANTS="$NOHC" rt pm_clear` → **immediately** `rt launch` → `locale?`.
Expect: `Success`; `prep` reports POST_NOTIFICATIONS and CAMERA granted; the onboarding intro is in front.
Note: `pm clear` stops the app. As after U2, no `rt` call may come between it and `rt launch`, or the guard reads the launcher and aborts. `pm_clear` is only ever `$PKG`.

**N2 — The intro.**
Do: `rt save N2`.
Expect: `onboarding-checkbox-privacy`, `onboarding-checkbox-data`, `onboarding-try-demo` and `onboarding-button`; the UI German (from the device language, or from a per-app locale that survived `pm clear`; record which `locale?` printed).

N3–N8 run as **one driver step**, `step_begin N3-8`. The onboarding pages live in memory, so after a resume or a recover the step starts again: if `onboarding-checkbox-privacy` is on screen, from N3; if `nav-home` is, onboarding finished and the step goes straight to N8's checks.

**N3 — Accept the privacy policy.**
Do: `rt tap id=onboarding-checkbox-privacy` → `rt tap id=onboarding-button`.
Note: the data checkbox stays off, so crash reports stay off. Never tap the intro's sources link (rule 3).

**N4 — About you.**
Do: `rt tap id=onboarding-gender-genderFemale` → `rt tap id=onboarding-birthday-field` → `rt tap "text=Zur Texteingabe wechseln"` → `rt field edit=1 15.03.1996` → `rt tap text=OK` → `rt get id=onboarding-birthday-field` → `rt tap id=onboarding-button`.
Expect: the field shows 15.03.1996, age 30 on day 0.

**N5 — Body.**
Do: `rt field id=onboarding-height-field 168` → `rt field id=onboarding-weight-field 62` → leave the target weight empty → `rt kb_hide` → `rt tap id=onboarding-button`.
Note: if `onboarding-implausible-change` / `-keep` appears, a value was misread: `rt tap id=onboarding-implausible-change`, re-type, and record it.

**N6 — Activity and goal.**
Do: `rt tap id=onboarding-activity-low` → `onboarding-button` → `rt tap id=onboarding-goal-maintain` → `onboarding-button`.

**N7 — Other options, with the reminder on (#1391).**
Do: read its state (`rt ls | grep onboarding-daily-reminder`) → tap it only if `{unchecked}` → read it again → leave `onboarding-ai-assist` off → `onboarding-button`.
Expect: the switch on, and no system dialog (POST_NOTIFICATIONS granted in N1).

**N8 — Overview and start.**
Do: `rt save N8-overview` → read *Ihr Kalorienziel:* → `rt tap id=onboarding-button` → `rt wait id=nav-home 20` → `rt save N8-home`.
Expect: Home's goal equals the overview's kcal; no demo banner.

**N9 — The reminder went through the scheduler (#1391).**
Do: `rt alarms` → Settings → `rt scroll_to "text^=Tägliche Erinnerung@2"` → read its state (`rt ls | grep "Tägliche Erinnerung"`) → `rt restart` → `rt alarms`.
Expect: the switch on with "Erinnerungszeit: 08:00", and an alarm for `$PKG` at the next 08:00, before and after the restart.
Note: before #1391 a start-up refresh could cancel the alarm while the switch read on.

**N10 — Weight history starts at the onboarding weight (#1383).**
Do: You → `rt tap "text^=Gewichtsverlauf"` → `rt save N10` → `rt tap id=weight-history-add` → `rt get id=weight-history-weight-input` → `rt tap text=ABBRECHEN`.
Expect: one tile, "62 kg", dated day 0, and the chart's empty-state text "Trage mindestens zwei Tage ein, um deinen Verlauf zu sehen."; the add dialog opens at `62`. Before #1383 the list was empty and the dialog offered 70 (settings run, note 2.5d).

**N11 — A goal saved on an empty day is kept (#1372), at the right default (#1380).**
Do: Settings → `rt tap id=settings-nutrient-goals` → `rt get edit=1` (fibre) → `rt field edit=1 43` → `rt kb_hide` → read all fields (rule 7) → `rt tap id=nutrient-goals-save` → reopen → `rt get edit=1` → `rt back`.
Expect: the fibre field first opens at **25** (IOM, a woman of 30). After saving it reopens at **43**. On 2.4.0 a save on a day without a tracked-day row was lost: the field reopened at 30 (settings run, bonus row #1348).

**N12 — A first entry, and the goal on the Diary.**
Guard: if Home already lists ONT Neu, skip to the Expect check.
Do: `rt tap id=fab-add-item` → `rt tap id=add-item-snack` → `rt tap id=add-meal-quick-add` → `rt field id=quick-add-title "ONT Neu"` → `rt field id=quick-add-energy 400` → `rt tap id=quick-add-submit` → Diary day 0 → `rt tap "text^=Heutige Nährstoffe"` → `rt save N12`.
Expect: Home 400 kcal consumed; Diary day 0 lists ONT Neu with no "Nichts hinzugefügt" above it; the panel's fibre reads "/ 43 g".
Note: the panel only renders on a day with entries, which is why it is read here and not in N11. A "/ 25 g" here means N11's save was lost after all: **fail** of #1372.

**N13 — Try Demo.**
Do: `RT_GRANTS="$NOHC" rt pm_clear` → **immediately** `rt launch` → `rt mark N13` → `rt tap id=onboarding-checkbox-privacy` → `rt tap id=onboarding-try-demo` → `rt wait id=main-demo-banner 60` → `rt save N13-home` → Diary `rt save N13-diary` → Trends `rt save N13-trends` → You `rt save N13-you`.
Expect: the banner "Du siehst Beispieldaten" with "Eigenes Profil einrichten"; Home, Diary and Trends filled with sample data; no red screen; `DemoSeeder` lines in the logcat after the mark (the one place they are expected).
Note: path 2's own profile is a throwaway, so nothing is exported before this `pm_clear`.

**N14 — Leaving the demo.**
Do: `rt tap "text=Eigenes Profil einrichten"` → `rt has "text=Eigenes Profil einrichten?"` → `rt tap text=Weiter` → `rt wait id=onboarding-checkbox-privacy 20` → `rt save N14`.
Expect: the onboarding intro again. R1 then clears the app anyway, so no demo row can reach path 3; R3 checks that.

---

## Part 7 — Path 3: restore into a cleared candidate

*Blocks if:* any intake, activity, recipe or weight entry of `base240.zip` is missing or changed after the restore; a second import of the same backup doubles an entry (#1369); importing id-less rows twice doubles them, or two identical rows collapse into one (#1398); the goal settings in `cand.zip` aren't restored (#1381); the favourites in `cand.zip` don't come back (#1320); a crash.

**R1 — Clear, and onboard the R-profile.**
The **R-profile** is S1's profile: S1's gender, a birthday that gives S1's age on day 0 (1 January of the year that fits), S1's height, weight **w0**, S1's activity level and goal, and the reminder **off**. If Part 1 ran its fallback, it is male, 15.05.1990, 180 cm, 80.0 kg, *Leicht aktiv* (`onboarding-activity-low`), *Gewicht halten*.
Do: `RT_GRANTS="$NOHC" rt pm_clear` → **immediately** `rt launch` → onboard as N3–N8 with the R-profile (in N7, read `onboarding-daily-reminder`'s state from `rt ls` and leave it, or set it, `{unchecked}`).
Expect: Home with the goal for that profile and the default goals: kcal adjustment 0, macro split 60/15/25, per-meal 30/40/20/10, and the water default for the profile's gender (`ConfigEntity`: female 1500 ml, male 1900 ml, non-binary 1700 ml).

**R2 — Restore the 2.4.0 backup.** `[import]`
Do: `rt mark R2` → Settings → `rt tap "text^=App-Daten exportieren / importieren"` → `JSON` → `rt tap text=Importieren` → `rt tap text=ont-r25-base240.zip` → `rt wait "text=Export / Import erfolgreich" 60` → `rt back` → `rt errors`.
Expect: "Export / Import erfolgreich"; Home and the Diary fill in; no errors.

**R3 — Compare with the baseline.** `[export]`
Do: export JSON `ont-r25-r3.zip` → pull → `$CMP diff $EVID/exports/base240.zip $EVID/exports/r3.zip > $EVID/exports/R3.txt`.
Expect:
- `intakes`, `activities`, `recipes` and `templates`: `missing 0 extra 0 changed 0 stored-twice 0`.
- `weight_log`: `missing 0 changed 0`. R1's onboarding entry for day 0 had the same weight and the same day key, so the backup's day-0 row replaced it. If the run has crossed midnight since day 0, that entry sits on another day and shows as the one `extra`.
- Tracked days: no line with `NEW tracked != NEW sum`, `row lost` or `no row although NEW lists intakes`. Today's goal may differ, because the import recomputes today's goals for the current profile (#1381).
- Nothing from N13's demo anywhere.
- `goal_settings` in `r3.zip`: kcal adjustment 0 or null, macros, per-meal shares and water null (the defaults, so the water goal reads R1's gender default).
Note: an archive without `goal_settings.json` leaves the device's goals alone, which here are R1's defaults. That is #1381's rule for old archives, and it isn't data loss: 2.4.0 never exported goals. So a restore after a reinstall keeps a 2.4.0 backup's entries but not its era's goals (the settings run's D6). R8 shows that a 2.5.0 backup brings them back.

**R4.a — The same backup again.** `[import]`
Do: the same import of `ont-r25-base240.zip` → `rt save R4-home`.
Expect: "Export / Import erfolgreich"; Home and the Diary unchanged, no entry twice.

**R4.b — Nothing doubled (#1369).** `[export]`
Do: export JSON `ont-r25-r4.zip` → pull → `$CMP diff $EVID/exports/r3.zip $EVID/exports/r4.zip > $EVID/exports/R4.txt`.
Expect: `VERDICT: identical`, apart from today's goal.

**R5.a — Id-less rows get derived ids (#1398).** `[import]`
Guard: before the first import, Diary day 0 − 7 (fx `noid.day`) must show neither ONT Ohne ID nor ONT Ohne ID B. If they are already there (a resumed run), go straight to step 3.
Do:
1. `rt mark R5` → Settings → *App-Daten exportieren / importieren* → `rt tap text=CSV` → `rt tap text=Importieren` → `rt tap text=ont-r25-noid.zip` → wait for the result → `rt back`.
2. `rt tap id=nav-diary` → day 0 − 7's cell → `rt save R5-first`.
3. The same import once more → day 0 − 7 → `rt save R5-second` → `rt errors`.
Expect (fx `noid`):
- After the first import, day 0 − 7 lists three entries: ONT Ohne ID twice (100 g, 200 kcal each) and ONT Ohne ID B (150 g, 150 kcal), 550 kcal in all.
- After the second, the same three: no fourth, fifth or sixth, and no "Duplicate keys found" (the driver would halt on the red screen).
Note: before #1398 every import added the rows again with blank ids, and two of them in one meal collided on `ValueKey('')`: the red "Duplicate keys" screen. The import doesn't reconcile mid-session (a documented limit), so the day may lack a tracked-day row until the next launch (R6).

**R5.b — The derived ids.** `[export]`
Do: export JSON `ont-r25-r5.zip` → pull → `$CMP summary $EVID/exports/r5.zip > $EVID/exports/r5.txt` → read the ids of the three ONT Ohne ID rows in its `user_intake.json`.
Expect: three distinct, non-blank ids; `intake ids stored twice or more: 0; blank ids: 0`.

**R6 — A cold start, and the restored data holds.**
Do: `rt restart` → `rt errors` → Home, Diary day 0 − 1 and day 0 − 7 (`rt save` each).
Expect: everything as before the restart. Day 0 − 7 now has a tracked-day row of 550 kcal: the reconciler at activation created it. R9's diff shows the row.

**R7 — A file that isn't a backup is refused, and nothing is written.** `[import]`
Do: *App-Daten exportieren / importieren* → `JSON` → *Importieren* → `rt tap text=ont-r25-seed-recipes.json` (a JSON file, not a zip) → `rt save R7` → `rt back`.
Expect: the error line "Die ausgewählte Datei konnte nicht gelesen werden. Wählen Sie die von OpenNutriTracker exportierte .zip-Sicherung."; Home unchanged.

**R8 — The 2.5.0 backup brings the goals back (#1381).** `[import]`
Do: `rt mark R8` → *App-Daten exportieren / importieren* → `JSON` → *Importieren* → `rt tap text=ont-r25-cand.zip` → wait → `rt back` → without a restart, reopen and read (then *ABBRECHEN*) `settings-kcal-adjustment`, `settings-macro-split` and `settings-per-meal-share`, and You → the water goal.
Expect:
- kcal adjustment **250**.
- Macro split carbs **45**, with the protein and fat values `cand.zip`'s `goal_settings.json` holds.
- Per-meal **25/45/20/10**; water **2600 ml**.
- Home's goal 250 above R1's.
Note: no restart is needed: the dialog reloads Settings, Profile, Home, the Diary and Trends (`export_import_dialog.dart`, `refreshScreens`).

**R9 — Merged by id, and the favourites are back (#1369, #1320).** `[export]`
Do: export JSON `ont-r25-r9.zip` → pull → `$CMP diff $EVID/exports/cand.zip $EVID/exports/r9.zip > $EVID/exports/R9.txt` → search screen → `rt tap id=add-meal-source-favourites` → `rt save R9-favourites` → `rt back`.
Expect:
- `intakes`, `activities`, `recipes` and `templates`: `missing 0 changed 0 stored-twice 0`. The only extras are R5's three ONT Ohne ID rows.
- Every id `base240.zip` and `cand.zip` share is stored once, holding `cand.zip`'s version: DR1's and DR2's renamed and recoded entries replaced the 2.4.0 versions R2 brought.
- `favourites: … new present`; the Favourites chip lists ONT Linsensuppe rot and the S7 product.

**R10 — A favourite whose library meal is gone keeps its snapshot.** *Skipped on the phone:* it needs a custom meal deleted, which also deletes that meal's diary entries in this profile. Covered by `test/unit_test/favourite_meal_repository_test.dart` (the deleted-template fallback) and `test/unit_test/favourite_cross_profile_test.dart`.

The restored profile is the one the English pass tours.

---

## Part 8 — The English pass, then back to German

Switching the language empties the search cache (rule 12); nothing after this Part depends on it. The tour looks for German left in an English UI, raw keys, `{placeholders}`, and text cut off. Labels in this Part are English.

*Blocks if:* a screen shows a raw key or a `{placeholder}`; the reminder ignores the language (#1379); clearing the per-app language in Android is undone on the next start (#1230); a crash. German left in the English UI is a ship-with finding.

**E1 — Switch to English.**
Do: Settings → `rt tap "text^=Sprache"` → `rt tap text=English` → `rt tap text=OK` → `locale?` → `rt save E1`.
Expect: the UI in English at once; `locale?` prints `en`.

**E2 — Favourites and search (#1320, #1334).**
Do: search screen → `rt save E2-chips` → `rt tap id=add-meal-source-favourites` → `rt save E2-fav` → `rt tap text=Recently` → `rt field id=meal-search-field zzqqx` → `rt kb_hide` → `rt save E2-none` → `rt back`.
Expect: the chips "Recently", "Favourites", "All", "Products", "Food"; Favourites lists two; "No results found" with "Search all".

**E3 — The shared-code dialog (#1329).**
Do: Home → `rt tap id=intake-section-menu@3` → `rt save E3-menu` → `rt tap id=intake-import-meal-code` → `rt tap id=import-meal-code-input` → `rt type keinGueltigerCode` → `rt tap id=import-meal-code-parse` → `rt save E3` → `rt tap text=CANCEL`.
Expect: the menu reads "Copy to today", "Delete all", "Share meal", "Import shared meal" and "Paste code" (none of them tapped except *Paste code*); the hint "Paste the shared meal code here"; "Parse"; the error "Enter a valid shared meal code.".

**E4 — Meal detail and recipes (#1297, #1376, #1280).**
Do: search screen → `nutella` → *Products* → the S7 product → `rt save E4-detail` → `rt back` twice; You → `profile-recipes` → *Recipes* → ONT Bananenbrot → `rt tap "text=Edit Recipe"` → `rt save E4-builder` → `rt back` (and `rt tap text=Discard` if asked).
Expect: "More Information at\nOpenFoodFacts" (not tapped), the star "Remove from favourites"; "Total weight (g)", "Entered manually, so changing ingredients won't change it.", "Use ingredient total".

**E5 — Diary (#1333, #1384).**
Do: `nav-diary` → day 0 → `rt tap id=diary-section-sort-menu@1` → `rt tap "text=Protein (high to low)"` → `rt save E5-sort` → back to "Time added" → long-press the first entry of day 0 → `rt save E5-dialog` → `rt tap text=CANCEL`.
Expect: rows read "<n> g protein" (lowercase, from the English key); the dialog "Delete Item?" / "Do you want to delete the selected item?" (#1384's typo fix). Nothing is deleted.

**E6 — Settings (#1384, #1380, #1332).**
Do: Settings → `rt save E6-units` → `settings-energy-unit` → *Kilojoules (kJ)* → OK → `rt get id=settings-kcal-adjustment` → `settings-energy-unit` → *Kilocalories (kcal)* → OK → `settings-nutrient-goals` → `rt save E6-goals` → `rt back` → *Language* → `rt save E6-lang` → `rt tap text=CANCEL`.
Expect: in kJ mode the row reads "Daily kJ adjustment"; the fibre description reads "Daily fibre target in grams. Default varies by age and gender (21g to 38g)."; the language list as in DS8.

**E7 — Activities (#1223, #1415).**
Do: `fab-add-item` → `add-item-activity` → "All" → `rt save E7-1`, then `rt swipe up` and `rt save E7-<n>` until two listings match → `rt back`. On the laptop, collect every row title from the listings.
Expect:
- No two rows share a name.
- Among them: "boxing (punching bag)" beside "boxing", "martial arts (slower pace)", "touch rugby", "vigorous high intensity interval exercise", "track and field (throws)" / "(jumps and javelin)" / "(hurdles)", and "yoga".
- Durations read "min".

**E8 — Import / export and AI wording (#1381, #1378).**
Do: Settings → `rt tap "text^=Export / Import App Data"` → `rt tap text=CSV` → `rt save E8-csv` → `rt back` → `rt get id=settings-ai-assist`.
Expect: "CSV keeps your activity, meal log and tracked days. Recipes, favourites and any photos you've attached are JSON-only — switch to JSON if you want them in your backup."; the AI subtitle "Off — no key saved" (path 3's `pm clear` removed the key, and the run doesn't store it again).

**E9 — Clearing the per-app language from Android sticks (#1230).**
Do:
1. `rt mark E9` → `$ADB shell cmd locale set-app-locales $PKG --locales ""` → wait 3 s → `rt save E9a`.
2. Settings → `rt get "text^=Sprache"` (or `text^=Language` if the UI is still English).
3. `rt restart` → `locale?` → `rt save E9b`.
4. `rt restart` → `locale?`.
Expect:
- Step 1: the running app follows the device and turns German without a restart.
- Step 2: the tile reads *Systemstandard*.
- Steps 3–4: `locale?` prints no locale after each cold start, and the UI stays German. 2.4.0 pushed the saved language back on the next start (settings-run row 20, #810).
Note: this is the run's one shell write to app state (rule 2). It does what *System default* on Android's per-app language page does, for this app only, and leaves it where the run wants it, German. If the command itself errors (an unknown `--locales` form on this build), E9 is *inconclusive*: no other form is tried.

**E10 — The reminder follows a language change (#1379), into English.**
Do:
1. Settings → `rt tap "text^=Sprache"` → `rt tap text=English` → OK.
2. `rt scroll_to "text^=Daily Reminder@2"` → read its state from `rt ls` → tap it only if `{unchecked}` → `rt clock` → T = now + 3 min → `rt tap "text^=Reminder time:"` → `rt tap "text=Switch to text input mode"` → `rt field edit=1 <HH>` → `rt field edit=2 <MM>` → `rt tap text=OK` → `rt alarms`.
3. Poll `rt notif` every 20 s until a post at or after T, or T + 5 min.
Expect: the alarm at T; a notification "OpenNutriTracker" / "Don't forget to log your meals today!" within 3.5 minutes of T (inexact alarm, AOSP's 0.75 × lead-time window).
Note: the alarm present but nothing by T + 5 is *inconclusive* (delivery is the OS's call). No alarm after step 2 is a **fail**.

**E11 — The reminder follows a language change (#1379), back to German.**
Do: Settings → `rt tap "text^=Language"` → `rt tap "text=System default"` → OK (the device is German) → **no restart** → `rt scroll_to "text^=Tägliche Erinnerung@2"` → T = now + 3 min the E10 way (`text=Zum Texteingabemodus wechseln`) → poll `rt notif` until T + 5 min → then switch the reminder off (read its state, tap once, read again: `{unchecked}`) → `rt alarms`.
Expect: the new notification reads "Vergiss nicht, heute deine Mahlzeiten zu protokollieren!". The language switch rescheduled it with German text; in the settings run (B8) the Italian switch kept delivering English until a restart. After switching it off, no alarm for `$PKG`.

**E12 — Final state.**
Do: `locale?` → `rt save E12-home`.
Expect: no per-app locale, the UI German, the reminder off, no fast running. The maintainer's device settings are untouched (P2's rows).

---

## Part 9 — Wrap-up and the report

**W1 — Logs and the key.** `rt logcat_stop` → `rt secret_audit` (must list nothing) → `cat $EVID/logcat/logcat-*.txt` against each step's `errors.txt`: every crash, ANR or Flutter error is filed under the step whose `STEP_BEGIN_` marker precedes it.

**W2 — Leave the phone.** The candidate stays installed with the path-3 profile; the device language and the maintainer's settings stay as found. The run's `ont-r25-*` files stay in Download: the run deletes nothing on the phone, and the maintainer can remove them.

**W3 — Results.** Write `docs/release-tests/2.5.0/results.md` on this branch: the table below, a *ship-with* list (each finding with its step, what was seen, and an issue number or "to file"), and the *skipped* list with reasons. `rt status` and `steps.tsv` give every step's verdict.

| Area | Steps | Verdict | What was seen | Evidence |
| :-- | :-- | :-- | :-- | :-- |
| Preflight & seeding | P1–P8, S1–S16 | | | |
| Path 1 upgrade | U1–U9 | | | |
| Favourites #1320 | DF1–DF7, R9 | | | |
| Shared meal code #1329, #1294 | DC1–DC6 | | | |
| Home #1358 #1318 | DH1–DH2 | | | |
| Diary #1333 #1382 #1319 #1385 | DD1–DD3 | | | |
| Add meal #1334 #1282 #1252 #1291 | DA1–DA4, U7 | | | |
| Meal detail #1297 #1376 | DM1–DM2 | | | |
| Custom meals / recipes #1404 #1420 #1280 #1328 | DR1–DR6 | | | |
| Settings #1371 #1273 #1384 #1370 #1372 #1353 #1380 #1390 #1332 | DS1–DS10, N11–N12 | | | |
| Import / export #1369 #1398 #1381 | U4, U8, R2–R9 | | | |
| Weight / profile #1222 #1383 #1419 | DW1–DW3, N10 | | | |
| Notifications #1379 #1391 | U5, N9, E10–E11 | | | |
| Trends #1377 | DT1 | | | |
| AI #1378 + the real key | DAI1–DAI3 | | | |
| l10n #1230 #1223 #1415 | DL1–DL3, E7, E9 | | | |
| Smoke areas | K1–K13 | | | |
| Path 2 onboarding + demo | N1–N14 | | | |
| Path 3 restore | R1–R9 | | | |
| English pass | E1–E12 | | | |
| iOS widget #1251 | — | skipped: out of scope, unit tests only | | |

**W4 — Hand-off to [#1438](https://github.com/simonoppowa/OpenNutriTracker/issues/1438).** The run ticket's resolution comment carries the table, every *fail* with its issue, every *inconclusive* with why, and the *skipped* list. A *fail* that meets the bar is a NO-GO, and the comment says so plainly.

### Skipped by design, and what covers each

| Item | Why | Covered by |
| :-- | :-- | :-- |
| Camera preview, real barcode and QR decode, shared-QR routing from the scanner | needs a subject in front of the lens | K3 runs the same lookup by manual entry |
| AI photo | opens the system camera app | DAI2 covers the provider transport |
| Health Connect grant flow and the real import | decided out (#1430) | K8 (the disclosure); `health_sync_screen_test.dart` |
| The share sheet (*Code teilen*, *Rezept teilen*) | leaves the package | DC covers the paste route |
| #1282 partial provider failure | needs one source's network cut | `add_meal_screen_provider_failure_test.dart`, `partial_results_notice_test.dart` |
| #1385 create-if-absent race | needs two writers in one gap | `tracked_day_create_if_absent_test.dart` |
| #1419 delete by storage key | the delete button has no label and the driver has no coordinate tap; the time-zone shift can't be made | `delete_weight_log_usecase_test.dart`, `weight_history_screen_test.dart` |
| #1222 DST window (unless day 0 ≥ 2026-10-26) | no transition inside the window | `weight_trend_chart_test.dart`, `calendar_day_calc_test.dart` (`just test_dst`) |
| #1377 the tooltip number | shows only while a finger is held; no hold-and-screenshot action | `trends_calorie_chart_energy_unit_test.dart` |
| #1391 a failed reschedule keeps the alarm | `zonedSchedule` can't be made to throw | `daily_reminder_scheduler_test.dart` |
| #1384 Health *Import now* snackbar | would import real workouts | `health_sync_screen_test.dart` |
| #1328 iOS number pad | iOS | `keyboard_dismisser_test.dart` |
| Favourites across profiles; a deleted meal's snapshot | needs a second profile or a cascading delete | `favourite_cross_profile_test.dart`, `favourite_meal_repository_test.dart` |
| #1251 iOS widget | no Mac or device | its unit tests |
