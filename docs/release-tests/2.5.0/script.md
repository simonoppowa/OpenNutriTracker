# Release 2.5.0: the unattended run script

The script for [#1434](https://github.com/simonoppowa/OpenNutriTracker/issues/1434), written in [#1433](https://github.com/simonoppowa/OpenNutriTracker/issues/1433) on map [#1425](https://github.com/simonoppowa/OpenNutriTracker/issues/1425). A session runs it over adb on the Pixel 6 with nobody watching, and the result is a verdict per area for the go/no-go ([#1438](https://github.com/simonoppowa/OpenNutriTracker/issues/1438)).

Every identifier, string and number below was read from the candidate `c293acff4` (or from `v2.4.0`, `680eafaa8`, for the steps that run on the old build) and from the PRs behind each change. Three of the delta rows can't be shown on a phone. For those the step names the unit tests that cover them and is recorded as *skipped*. A step never waits for a person: anything that would need one is *skipped* with its reason.

**What it covers, in order:**

| Part | What | Steps |
| :-- | :-- | :-- |
| 0 | Preflight and prep | P1–P12 |
| 1 | Seeding on 2.4.0, then the baseline export | S1–S16 |
| 2 | Path 1: upgrade in place to the candidate | U1–U9 |
| 3 | The delta in depth, area by area | DF, DC, DH, DD, DA, DM, DR, DS, DW, DN, DT, DAI, DL |
| 4 | Every other area at smoke depth | K1–K14 |
| 5 | The candidate's own exports (the input to path 3) | X1–X3 |
| 6 | Path 2: fresh onboarding, manual and Try Demo | N1–N14 |
| 7 | Path 3: restore into a cleared candidate | R1–R11 |
| 8 | The English pass, then back to German | E1–E12 |
| 9 | Wrap-up and the report | W1–W4 |

Plan on seven to nine hours, plus up to four reminder waits of about five minutes each.

---

## How to run it

### Constants

```bash
ADB="$HOME/Android/Sdk/platform-tools/adb -s 18101FDF60010M"   # always the USB serial, never "the first device"
PKG=com.opennutritracker.ont.opennutritracker                   # the full flavour; the run never touches .develop
APKS=~/Documents/ont-release-2.5.0-evidence/apks
APK_240=$APKS/ont-full-2.4.0-66-debug.apk                       # sha256 0cbd3b31…dee6ab
APK_CAND=$APKS/ont-full-candidate-c293acff-debug.apk            # sha256 95232d69…a40df0
FX=docs/release-tests/2.5.0/fixtures                            # in this repo
CMP="python3 -I $FX/compare_exports.py"
```

`EVID` is the run's evidence folder, `~/Documents/ont-release-2.5.0-evidence/run-<timestamp>/`, pinned once in P4. Fixture files are generated into `$EVID/fixtures/` (P9) and exports are pulled into `$EVID/exports/`.

**Both APKs report `versionName 2.4.0`, `versionCode 66`** ([#1431](https://github.com/simonoppowa/OpenNutriTracker/issues/1431)): the bump to 2.5.0+67 is not in the frozen candidate. `dumpsys package` therefore can't tell them apart. The run tells them apart by the sha256 of the installed `base.apk` (P6, U2) and by a feature only the candidate has: the add-food screen's Favourites chip `add-meal-source-favourites`.

### The driver's actions

The driver from [#1432](https://github.com/simonoppowa/OpenNutriTracker/issues/1432) lives in `docs/release-tests/2.5.0/tools/`. It wasn't pushed when this was written, so the script uses `st.sh`'s action names from the settings run plus the three additions #1429 asked for. `st X` means one call of the driver with action `X`. If the driver names an action differently, use its name. If an action the script needs is missing, the step is *inconclusive*, and the run doesn't improvise a substitute.

| Action | Meaning |
| :-- | :-- |
| `st tap SEL` | Dump, find SEL, tap its centre, re-check focus. |
| `st tapxy X Y` | Tap a point. Only with coordinates read from the dump taken in the same step, never from an earlier one. |
| `st field SEL TEXT` | Tap, clear (64 deletes), type. No Done. |
| `st type TEXT` | Type into the focused field. Spaces become `%s`. ASCII only. |
| `st type_secret < FILE` | Type a secret read from stdin. Logs nothing, writes nothing to the evidence folder, turns `show_password` off first. |
| `st done` | `KEYCODE_ENTER`: the keyboard's Done. |
| `st kb_hide` | BACK only while the keyboard is up, so it never closes a dialog. |
| `st back` | BACK, refused while `nav-home` is on screen (one BACK too many leaves the app). |
| `st swipe up\|down` | Scroll the content. Never with a dialog that holds a slider open (see the rules). |
| `st scroll_to SEL` | Swipe until SEL sits between y=300 and y=2050. |
| `st open_settings` | You tab, scroll to the collapsed *Einstellungen* card, expand it. |
| `st restart` | `am force-stop`, `am start -W`, two warm-up dumps, wait for `nav-home`. This is **R** below. |
| `st ls` / `st get SEL` / `st has SEL` / `st wait SEL [s]` | Read the screen: every node, one node's text, presence, wait for presence. |
| `st bounds SEL` | `x1 y1 x2 y2` of SEL in a fresh dump. |
| `st save NAME` / `st shot NAME` / `st pixel NAME X Y` | Keep a dump, a screenshot, read a pixel of a screenshot. |
| `st longpress SEL` | 900 ms press. |
| `st holdshot X Y NAME` | Press and hold at X,Y for 3 s and take a screenshot 1.5 s in. Needed only by DT1. |
| `st mark ID` / `st errors ID` | A marker in logcat, then every Flutter exception, failed assertion, `FATAL EXCEPTION` or ANR logged since it (uiautomator noise filtered out). |
| `st step ID` | Record the step in the resumable step log before running it. |
| `st alarms` / `st notif` / `st locale` / `st clock` | Read-only system state: the app's pending alarms, its posted notifications, its per-app locale, the phone clock. |
| `[picker]` | A step marked like this may hand focus to `com.google.android.documentsui`. Only these steps allowlist that package, and only until focus is back in the app. |

Selectors: `id=` a `resource-id` (a Flutter `Semantics(identifier:)`), `text=` an exact label, `text^=` a label prefix (Flutter merges a tile's title and subtitle into one `content-desc`, so tiles are matched by their title), `text~=` a fragment, `edit=N` the N-th text field from the top. `@K` takes the K-th match.

### Rules that hold everywhere

1. **The guard.** Every screen action re-reads `mCurrentFocus`. The first time focus leaves `$PKG` outside a `[picker]` step, the driver drops its abort flag, and every later call refuses. The run stops for good there. Record the step, the screenshot the driver took, and what the step was doing. Don't clear the flag inside the run.
2. **Never send HOME, APP_SWITCH or POWER.** Never open Android Settings. The one shell-side change to app state is `cmd locale set-app-locales` in E9.
3. **Links and buttons that leave the app.** Never tap these:
   - On meal detail: *Weitere Informationen unter OpenFoodFacts / FoodData Central*.
   - The Unsplash credit `unsplash-photo-credit`, `dri-panel-info-link`, `health-sync-privacy-policy`, `onboarding-healthy-range-sources`, and *Quellen unserer medizinischen Berechnungen ansehen*.
   - Fasting's *BEAT (UK)* / *NEDA (US)*.
   - Settings: *Datenschutz…* links, *Quellen*, *Fehler melden*'s OK, the links inside *Über*.
   - *Code teilen* (the share sheet), the AI photo button `bulk-add-photo` / `bulk-add-photo-camera` (the system camera app).
   - The Health Connect disclosure's *Weiter*.
4. **Never tap these in Parts 1–5** (the data being tested lives in them):
   - *Profildaten zurücksetzen* (`settings-delete-all-data`), *Cache leeren*, a meal section's ⋮ → *Alle löschen*.
   - The trash icon on a custom-meal row, which also deletes every diary entry that uses the meal.
   - The demo banner's *Eigenes Profil einrichten*.
   - In the *Daten* group, *Cache leeren* and *Profildaten zurücksetzen* sit directly below *App-Daten exportieren / importieren*, the row this script opens most. Assert the row's title in the same dump before every tap there.
5. **Confirm a dialog only after reading its title** in the same dump. An OK from a stale dump is how a cache gets cleared.
6. **The file pickers.** The phone's Download folder may hold real backups (`opennutritracker-export*.zip`). An App-Data import is a merge: it can't be undone, and its picker takes any file.
   - Every file the run puts on the phone is named `ont-r25-…`, and a picker step may pick **only** a file named `ont-r25-…`. If it isn't listed, BACK out of the picker and record the step *inconclusive*.
   - An export's file name can't be trusted: DocumentsUI may number it (`… (1).zip`) whatever the title field says. So right after every export: `$ADB shell ls -t /sdcard/Download | head -3`, pull the newest `.zip` to `$EVID/exports/<tag>.zip`, and when that export is to be imported later, `adb push` the host copy back as `/sdcard/Download/ont-r25-<tag>.zip`.
   - In DocumentsUI, select by `resource-id` (`android:id/title` is the file name field, `android:id/button1` Save) or by the file's exact name, never by German label text.
7. **Dialogs and swipes.** Never swipe while a dialog that holds a slider is open (per-meal share, kcal adjustment, macro split, water goal, day boundary): the swipe moves a slider (settings run, 2026-10-11). The language list in DS8 and the import preview in DC are the only dialogs scrolled in this run, and neither holds a slider. On the full-screen *Nährstoffziele*, every field is read again before Save. If any value other than the one the step edits has moved, leave with BACK without saving and record it.
8. **The Add button covers the bottom of the You list and of Settings.** Never tap a row whose centre is within 150 px above the top of `fab-add-item` (read both from the same dump). Scroll first. #1384 added 28 dp of padding so the last row can scroll clear, and DS3 checks that.
9. **A red error screen.** If a dump shows Flutter's error text (`Duplicate keys found`, `RenderFlex overflowed`, a red ErrorWidget) or the main screen lacks `nav-home`, the area **fails** at that step. Take `st shot` and `st save`, send no BACK, and `st restart` before the next area.
10. **Typing.** `st type` takes ASCII only, so every name the run types is ASCII ("ONT Gemuesecurry"). Read every typed field back from the dump before confirming. The AI key goes only through `st type_secret`.
11. **German first.** The phone is `de-DE` and the app runs in German until Part 8. The labels below are the German strings from `intl_de.arb` at `c293acff4`. Strings that are new in this release exist **only in English**, so the German build shows them in English: those are listed under *Expected English* and are never a failure on their own.
12. **Cache.** Changing the app language empties the search cache by design (`RemoteSearchCacheDataSource`, 2.4.0 run). No step before Part 8 changes the language, apart from the normalisation in S3.
13. **One step at a time.** `st step <ID>` before each step, `st mark <ID>` before anything whose logs matter, `st errors <ID>` after it. Any exception, failed assertion or crash in `st errors` is a **fail** of that step, whatever the screen shows.

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

Everything stays on the laptop under `$EVID`: dumps, screenshots, `logcat.txt`, `run.log`, the step log, `exports/`. The exports hold the test profile's diary. Issues quote counts, a kcal figure or a single field, never a whole zip or a raw log. The AI key never reaches any of it.

---

## Part 0 — Preflight and prep

*Blocks if:* nothing here blocks the release. A failed check stops the run before it touches the app, and the report says why.

**P1 — The phone.**
Do: `$ADB devices -l`; `$ADB shell getprop ro.product.device`; `$ADB shell getprop ro.build.version.sdk`.
Expect: `18101FDF60010M  device … model:Pixel_6`, `oriole`, `37`. An extra `adb-18101FDF60010M-…` row (wireless debugging) is the same phone and is ignored.
Note: stop if the serial is missing or `unauthorized`.

**P2 — Battery and storage.**
Do: `$ADB shell dumpsys battery | grep -E 'level|powered'`; `$ADB shell df /data | tail -1`.
Expect: level ≥ 50 and `USB powered: true`; ≥ 5 GB free.
Note: the battery stood at 21 % on 2026-10-22, charging over USB only. Below 50, wait in 15-minute steps (read-only) until it is 50, up to 3 hours. During the run, re-check before each Part. Below 25, pause at the next step boundary until it is back at 40. The step log lets the run resume.

**P3 — Unattended settings the maintainer set ([#1430](https://github.com/simonoppowa/OpenNutriTracker/issues/1430)).**
Do: `$ADB shell settings get global stay_on_while_plugged_in`; the three `*_animation_scale`; `settings get system show_password`; `locksettings get-disabled`.
Expect: `15`; `0.0` ×3; `0`; `true`.
Note: the run doesn't change these. If one differs, record it and stop: the maintainer set them, and the run doesn't change device settings.

**P4 — Evidence folder and logcat.**
Do: `st init` (pins `$EVID`), `mkdir -p $EVID/exports $EVID/fixtures`, `st logcat_start`.
Expect: a fresh folder and a running capture.
Note: on a resume, never start a second capture over `logcat.txt`. The driver appends or rotates (settings-run lesson).

**P5 — Clock and time zone.**
Do: `st clock`; `$ADB shell getprop persist.sys.timezone`.
Expect: the date and time, zone `Europe/Berlin`. Write down **day 0** (the date) and the hour.
Note: DD2 needs the hour to be ≤ 22 when it runs. DW3 only applies if day 0 is 2026-10-25 or later.

**P6 — What is installed.**
Do:
- `$ADB shell pm list packages | grep opennutritracker`
- `st version`
- `$ADB shell pm path $PKG`, then `$ADB shell sha256sum <that base.apk path>`
- `$ADB shell dumpsys package $PKG | grep -E 'firstInstallTime|lastUpdateTime'`
Expect: exactly one package, `$PKG`; `versionName=2.4.0`, `versionCode=66`; a `base.apk` whose sha256 is **not** `95232d69…` (the candidate); first install 2026-10-11.
Note: if `.develop` is present, leave it alone. If the installed sha256 is the candidate's, the phone was already upgraded: stop, because path 1 can't start from it. If `$PKG` is missing, follow the fallback in S1.

**P7 — The two APKs.**
Do: `sha256sum -c $APK_240.sha256 $APK_CAND.sha256` (from `$APKS`); for each APK, `aapt dump badging … | head -1` and `apksigner verify --print-certs … | grep SHA-256`.
Expect: both checksums OK; `package: name='com.opennutritracker.ont.opennutritracker' versionCode='66' versionName='2.4.0'` for both; certificate digest `0bdae1d6…5ff5` for both.
Note: a different package name (`….develop`) would install beside the app as a second app instead of upgrading it. Stop on any mismatch.

**P8 — The AI key file.**
Do: `stat -c '%a %s' ~/.config/ont-run/ai-key`; `cat ~/.config/ont-run/ai-provider`.
Expect: mode `600`, a size above 0; `openrouter`.
Note: never `cat`, `head` or `grep` the key file.

**P9 — Generate the fixtures.**
Do: `python3 -I $FX/make_fixtures.py $EVID/fixtures --today <day 0>`.
Expect: `expected.json`, `meal-codes.txt`, `ont-noid.zip`, `ont-seed-diary.json`, `ont-seed-meals.csv`, `ont-seed-recipes.json`.
Note: every later "expected" number with a `fx:` prefix is read from `expected.json`.

**P10 — Push the fixtures.**
Do: `$ADB push` each phone fixture to `/sdcard/Download/` under the run's prefix: `ont-r25-seed-meals.csv`, `ont-r25-seed-recipes.json`, `ont-r25-seed-diary.json`, `ont-r25-noid.zip`. Then `$ADB shell ls -l /sdcard/Download/ | grep ont-r25-`.
Expect: four files, each larger than 0 bytes.
Note: if a later picker doesn't list a pushed file, index it: `$ADB shell content call --uri content://media/external/file --method scan_file --arg /sdcard/Download/<name>`. If it still isn't listed, the step is *inconclusive*.

**P11 — Runtime grants (idempotent, re-run after every `pm clear`).**
Do: `$ADB shell pm grant $PKG android.permission.POST_NOTIFICATIONS`; `$ADB shell pm grant $PKG android.permission.CAMERA`; then `dumpsys package $PKG | grep -E 'POST_NOTIFICATIONS|CAMERA'`.
Expect: both `granted=true`.
Note: the Health Connect permissions are **deliberately not granted**. K8 stops at the in-app disclosure, and without the grant an accidental *Weiter* opens Health Connect, which trips the guard instead of importing the maintainer's real workouts.

**P12 — First look, read only.**
Do: `st mark P12`, `st launch`, `st save P12-home`, `st shot P12-home`, `st locale`, `st errors P12`.
Expect: the main screen (`nav-home`), no red error screen, no demo banner (`main-demo-banner`). Write down which language the UI is in and what `st locale` prints. The settings run ended with the app in English and in kJ.
Note: if onboarding shows, the 2.4.0 data is gone: follow the fallback in S1.

---

## Part 1 — Seeding on 2.4.0, then the baseline

The phone holds 2.4.0 with the settings run's test data (#1430). That data is kept: a box written by 2.3.0 and 2.4.0 is the better upgrade subject. The run first takes a safety copy of it. On top go a known set of rows, all named `ONT …`, which later steps compare against. The baseline export at the end (S15) is two things: the backup that path 3 restores, and the numeric "before" for path 1.

**Fallback if 2.4.0 or its data is gone (P6/P12).**
1. If `$PKG` is missing: `$ADB install $APK_240`. That is a plain install, so it is safe only when the package is absent. Then P11.
2. Onboard manually as in N3–N8, with the S-profile: male, born 1990-05-20, 180 cm, 80 kg, no target weight, *Wenig aktiv*, *Gewicht halten*, reminder off. Skip S2.
3. Record "path 1 runs from a fresh 2.4.0 box, not a lived-in one".

*Blocks if:* nothing in Part 1 judges the candidate. A seeding step that can't be completed is recorded with what's missing, and every later step that needs it is *skipped: no seed*.

**S1 — Read the profile.**
Do: `nav-you`; `st save S1-you`; read the tiles `profile-weight`, `profile-height`, `profile-age`, `profile-gender`, `profile-activity`, `profile-goal`, `profile-target-weight`.
Expect: a complete profile. Write down every value.
Note: DS6's expected fibre default depends on gender and age: IOM, men 19–50 → 38 g, 51+ → 30 g; women 19–50 → 25 g, 51+ → 21 g; non-binary averaged → 31.5 g / 25.5 g.

**S2 — Safety copy of the settings run's data.** `[picker]`
Do: `st open_settings` → `st scroll_to "text^=App-Daten exportieren / importieren"` → assert the title → tap → segment `JSON` → *Exportieren* → in DocumentsUI set `id=android:id/title` to `ont-r25-pre.zip` → `id=android:id/button1` → back in the app, read the dialog → close it with BACK. Pull the newest zip to `$EVID/exports/pre.zip`. Run `$CMP summary $EVID/exports/pre.zip > $EVID/exports/pre.txt`.
Expect: "Export / Import erfolgreich"; a zip with `user_intake.json`, `user_activity.json`, `user_tracked_day.json`, `user_recipes.json`, `weight_log.json` and `custom_activity_templates.json`.
Note: this zip is never imported. It exists so that nothing on the phone is lost unrecorded. If the export fails, stop. The run doesn't seed onto data it can't get back.

**S3 — Normalise the device-wide display settings.**
These aren't part of a backup and make every later expectation simpler.
Do:
1. Settings → *Sprache* (globe tile, `text^=Sprache` / `text^=Language`) → `Deutsch` → OK.
2. `settings-energy-unit` → *Kilokalorien (kcal)* → OK.
3. `settings-food-units` → *Metrisch* → OK.
4. `settings-body-weight-unit` → `kg` → OK.
5. `settings-height-units` → metric → OK.
6. Read *Tag beginnt um* (`settings-day-boundary`), *Mikronährstoffe anzeigen* and *Makros je Mahlzeit anzeigen*, and write down their states.
7. If the day boundary isn't `0:00`: open it → *Zurücksetzen* → `id=day-boundary-save`.
Expect: the UI in German, the tiles reading kcal, metric and kg, the boundary `0:00`.
Note: with the app in English, the tiles read *Language*, *Energy unit* and so on; use `ST_SETTINGS_LABEL=Settings` until step 1 is done. Switching the language empties the search cache (rule 12), which is wanted here, before any search.

**S4 — Import the custom-meal library.** `[picker]`
Do: Settings → `id=settings-import-custom-food` → `id=import-format-toggle` segment `CSV` → *Mahlzeiten importieren (csv)* → pick `ont-r25-seed-meals.csv`.
Expect: "4 Mahlzeit(en) importiert." Then You → `profile-recipes` → tab *Eigene Mahlzeiten* lists ONT Haferbrei, ONT Joghurt, ONT Linsensuppe and ONT Riegel (subtitle brand "ONT Test").
Note: never tap the *Beispiel-…* buttons next to the import actions. They open a save picker for a sample file.

**S5 — Import the recipes.** `[picker]`
Do: the same dialog → segment `JSON` → *Rezepte importieren (json)* → pick `ont-r25-seed-recipes.json`.
Expect: "2 Mahlzeit(en) importiert." (the recipe importer reuses the meal string). The Rezepte tab lists:
- ONT Gemuesecurry, "2 Zutat(en) · 275 kcal".
- ONT Bananenbrot, "2 Zutat(en) · 987 kcal". Its detail reads `Pro 100 g · 219 kcal …` (fx: `recipes.ONT Bananenbrot.kcal_per_100g` = 219.33). Only 197 would be the 500 g ingredient sum.
Note: 2.4.0 already carries #1169, so the 450 g survives the import.

**S6 — Import six days of diary.** `[picker]`
Do: the same dialog → segment `JSON` → *Mahlzeiten importieren (json)* → pick `ont-r25-seed-diary.json`.
Expect: "15 Mahlzeit(en) importiert." Diary → day 0 − 1 shows ONT Haferbrei 300 g, ONT Linsensuppe 350 g and ONT Joghurt 200 g.
Note: the importer files each entry at local midnight of its date and skips names already in the library, so no duplicate library rows appear. The per-day totals are in fx: `diary_days`.

**S7 — Log today by hand: one Open Food Facts product.**
Do: `fab-add-item` → `add-item-breakfast` → `id=meal-search-field` → type `nutella` → wait 2 s → chip *Produkte* → tap the first card whose source chip reads *Open Food Facts* → wait until the *Einheit* button text is the same in two dumps 0.5 s apart (hydration) → `st field edit=1 30` (Menge) → *Einheit* = `g` → `id=meal-detail-add`.
Expect: the snackbar "Neue Aufnahme hinzugefügt", back on Home. Write down the product name and barcode (the URL/barcode on the detail screen, or the export later).
Note: if no Open Food Facts card appears for `nutella`, try `seabrook`, then `chips`. If none does, record *S7 not seeded*. DF and DC then use a backend food in its place and say so.

**S8 — Log today by hand: one backend food.**
Do: `fab-add-item` → `add-item-lunch` → type `apfel` → chip *Lebensmittel* → a card whose chip reads *BLS* or *FDC …* → Menge `150`, `g` → `meal-detail-add`.
Expect: the snackbar, the row on Home under *Mittagessen*.

**S9 — Log today by hand: the barcode custom meal and a recipe.**
Do:
1. `fab-add-item` → `add-item-snack` → type `ONT Riegel` → tap the chip-less card ONT Riegel → Menge `1`, unit = its serving if offered (else `40` g) → `meal-detail-add`.
2. You → `profile-recipes` → tab *Rezepte* → ONT Gemuesecurry → log it into *Abendessen*, 350 g, through the recipe screen's log action.
Expect: Home shows ONT Riegel under *Snack* and ONT Gemuesecurry under *Abendessen*.
Note: ONT Riegel logged from the library carries its barcode `2000000000015`. DR2 moves exactly this entry. If the recipe screen's log action isn't obvious in the dump, record *S9.2 not seeded*. DA4 then logs the recipe on the candidate instead.

**S10 — One activity.**
Do: `fab-add-item` → `add-item-activity` → tab *Alle* → the first card → clear `id=activity-detail-quantity-input` (it holds `0`) → `30` → `id=activity-detail-add-button`.
Expect: "Neue Aktivität hinzugefügt".
Note: if *Aktivität* isn't in the sheet, activity tracking is off. Record it and turn it on in Settings (*Aktivitätstracking anzeigen*) first.

**S11 — Weight on four days.**
Do: You → `profile-weight-history` (match by title *Gewichtsverlauf*, not the tile *Gewicht*) → four times `id=weight-history-add` → *Datum* → pick the day in the date picker by its full German content-desc → `st field id=weight-history-weight-input <kg>` → OK:

| day | −6 | −4 | −2 | 0 (leave the date) |
| :-- | :-- | :-- | :-- | :-- |
| kg | 81.2 | 80.6 | 80.9 | 80.4 |

Expect: four new tiles reading `81.2 kg`, `80.6 kg`, `80.9 kg`, `80.4 kg` (period decimal, not locale-formatted), newest first. Count the tiles after every OK: the dialog closes silently on a bad value.
Note: never tap a tile's trailing button. It has no label and deletes without asking. Today's entry rewrites the profile weight to 80.4 kg.

**S12 — Goals that the backup carries from 2.5.0 on (#1381).**
Do (2.4.0 drops a value typed and then confirmed with OK only, #1347, so each value gets Done before OK):
1. Settings → `settings-kcal-adjustment` → `st field id=kcal-adjustment-input 250` → `st done` → `id=kcal-adjustment-save`.
2. `settings-macro-split` → the carbs **text field** `edit=1` (`st get edit=1` must read the current carbs %; `id=macro-split-carbs` is the carbs *slider*, never tap it) → `st field edit=1 45` → `st done` → `id=macro-split-save`.
3. `settings-per-meal-share` → `id=meal-share-preset-mediterranean` → `id=meal-share-save`.
4. You → `profile-water-goal` → `st field id=water-goal-input 2500` → `st done` → `id=water-goal-save`.

Expect, reopening each:
- kcal adjustment `250`.
- Macro split carbs `45`. Write down the two rebalanced values.
- Per-meal share `25/45/20/10`.
- Water goal "/ 2500 ml".
- Home's kcal goal 250 above S1's.

Note: the per-meal sliders get no swipe (rule 7). Only the preset is tapped.

**S13 — The reminder.**
Do: Settings → *Tägliche Erinnerung* switch (`text^=Tägliche Erinnerung@2`; the first match is the group header) → on → `text^=Erinnerungszeit:` → in the time picker tap `text=Zum Texteingabemodus wechseln` → `st field edit=1 20` → `st field edit=2 30` → OK.
Expect: "Erinnerungszeit: 20:30"; `st alarms` lists an alarm for `$PKG`.
Note: POST_NOTIFICATIONS was granted in P11, so no system dialog appears.

**S14 — The "before" screens on 2.4.0.**
Do, saving a dump and a screenshot of each:
1. Home (`S14-home`): the kcal gauge `home-kcal-gauge` and the meal sections.
2. `fab-add-item` → `add-item-dinner`, with the *Kürzlich* list unfiltered (`S14-recent`). Write down the order of the first four card names. The Recently list has no identifier on 2.4.0, so read the names top to bottom.
3. A custom meal's detail: tap ONT Joghurt in that list, then `st save S14-custom-detail`. Record whether the button *Benutzerdefinierte Mahlzeit* is present. Then BACK twice without adding.
4. `st alarms` (`S14-alarms`).

Expect, as 2.4.0 behaves:
- Recently starts with the chip-less custom meals ONT Riegel, ONT Joghurt … ahead of the Open Food Facts product and the backend food, although those two were logged later (#1252's "before").
- The custom meal's detail shows the dead *Benutzerdefinierte Mahlzeit* button (#1297's "before").

**S15 — The baseline export.** `[picker]`
Do: Settings → *App-Daten exportieren / importieren* (assert the title) → `JSON` → *Exportieren* → title `ont-r25-base240.zip` → Save → close the dialog. Pull the newest zip to `$EVID/exports/base240.zip`, then `$ADB push $EVID/exports/base240.zip /sdcard/Download/ont-r25-base240.zip`. Run `$CMP summary $EVID/exports/base240.zip > $EVID/exports/base240.txt`.
Expect:
- "Export / Import erfolgreich".
- `base240.txt` shows, for each of days −6 … −1, an intake count and kcal at least the fx `diary_days` values (more if the settings run left rows on those days).
- Recipes ONT Gemuesecurry `totalWeightG=350` and ONT Bananenbrot `totalWeightG=450`.
- Weights 81.2, 80.6, 80.9, 80.4.
- No `goal_settings.json`, `user_favourites.json` or `tracked_day_boundary.json` (2.4.0 doesn't write them).
- `intake ids stored twice or more: 0`.

Note: **nothing may write to the app between S15 and U3.** If anything does, redo S15.

**S16 — A CSV export too.** `[picker]`
Do: the same dialog → `CSV` → *Exportieren* → `ont-r25-base240csv.zip` → pull to `$EVID/exports/base240csv.zip`; `unzip -l`.
Expect: exactly `user_activity.csv`, `user_intake.csv`, `user_tracked_day.csv`.
Note: kept as evidence only. It isn't imported.

---

## Part 2 — Path 1: upgrade in place

*Blocks if:* the app opens to onboarding or a red screen after the upgrade; any intake, activity, recipe, weight entry or template from `base240.zip` is missing or changed; a day's consumed kcal differs from the sum of its intakes after the reconciler ran; the reminder's alarm is gone after a launch; re-importing the app's own backup doubles a single entry (#1357 again).

**U1 — Stop the app cleanly.**
Do: `st mark U1`; `$ADB shell am force-stop $PKG`.
Note: force-stop cancels the reminder alarm until the next launch (settings run). U5 checks that the launch puts it back.

**U2 — Install the candidate over 2.4.0.**
Do: `$ADB install -r $APK_CAND` (never without `-r`, never `uninstall`). Then repeat P6's `pm path` + `sha256sum` and `dumpsys package … lastUpdateTime`.
Expect: `Success`; the installed `base.apk` sha256 is `95232d6937e34d0b84bda127af2116661510febed56ae529d8b9bc8468a40df0`; `lastUpdateTime` is now; `firstInstallTime` is unchanged (2026-10-11).
Note: the same versionCode is allowed, and the matching certificate keeps the data. If the install blocks for more than 2 minutes or prints `INSTALL_FAILED_VERIFICATION_FAILURE` (a Play Protect prompt), the upgrade path is *skipped: needs a person*. Stop the run there, since every later Part assumes the candidate.

**U3 — First launch.**
Do: `st launch`; `st save U3-home`; `st shot U3-home`; `st errors U1`; `grep -E 'TrackedDayReconciler|OffMicronutrientRepair|main: Starting App' $EVID/logcat.txt | tail -5`.
Expect:
- `nav-home` and the same Home as S14 (meal sections, the kcal goal 250 above S1's).
- No onboarding, no red screen, no `SEVERE:` line, nothing in `st errors`.
- `INFO: main: Starting App …`.
- Either no `TrackedDayReconciler` line, or one `INFO: TrackedDayReconciler: Brought N tracked days in line with the entries the Diary lists on them (#1317)`. Write down N.
- `OffMicronutrientRepair`: nothing (stamped long ago) or its `(#1152)` line.

Note: the reconciler (#1319) rewrites a day's consumed totals as the sum of the entries listed under it, on every activation. Settings-run data can hold rows that 2.4.0 left out of line, so an N above 0 is a migration doing its job, not data loss. U4 checks the numbers.

**U4 — Nothing lost: a candidate export against the baseline.** `[picker]`
Do: Settings → *App-Daten exportieren / importieren* → `JSON` → *Exportieren* → `ont-r25-up1.zip` → pull to `$EVID/exports/up1.zip` → `$CMP diff $EVID/exports/base240.zip $EVID/exports/up1.zip > $EVID/exports/U4.txt`.
Expect:
- `intakes`, `activities`, `recipes`, `weight_log` and `templates` all read `missing 0 … changed 0 stored-twice 0`.
- Every tracked-day line ends without `NEW tracked != NEW sum` or `row lost …`. A line where `base_tracked` differs from `new_tracked` while `new_tracked` equals `new_sum` is the reconciler correcting a 2.4.0 row: list those days, they're expected, and their number matches U3's N.
- `goal_settings: … new present` and `tracked_day_boundary` present.
- The last line reads `VERDICT: identical` or `VERDICT: superset`.

Note: open `up1.zip`'s `goal_settings.json` and expect `kcalAdjustment 250`, `carbGoalPct 0.45`, `mealKcalSharesPct` 25/45/20/10, `dailyWaterGoalMl 2500`. Those are S12's values: the backup now carries them (#1381).

**U5 — The reminder survived.**
Do: `st alarms`; Settings → read *Tägliche Erinnerung*.
Expect: the switch on, "Erinnerungszeit: 20:30", an alarm for `$PKG` whose time is the next 20:30.
Note: the candidate's start-up reschedules through `DailyReminderScheduler` (#1379). The alarm was cancelled by U1's force-stop, so its presence proves the reschedule.

**U6 — The candidate is really running.**
Do: `fab-add-item` → `add-item-dinner` → `st has id=add-meal-source-favourites` → BACK.
Expect: present. This and U2's sha256 are the two proofs that this is not 2.4.0.

**U7 — Recently is chronological now (#1252).**
Do: the same screen, *Kürzlich* unfiltered → `st save U7-recent`. Compare the order of names with S14.
Expect: the order is most recent first. ONT Gemuesecurry / ONT Riegel / the backend food / the Open Food Facts product (whichever was logged last in S7–S9) come before the six-day-old ONT Haferbrei / ONT Joghurt / ONT Linsensuppe. Custom meals are no longer pinned to the top.
Note: a regression (custom meals still first) is a **fail** of #1252. It isn't a blocker on its own (no data or numbers affected).

**U8 — Re-import the app's own 2.4.0 backup (#1369).** `[picker]`
Do: `st mark U8` → Settings → *App-Daten exportieren / importieren* → `JSON` → *Importieren* → pick `ont-r25-base240.zip` → wait for the result. Then Home and Diary day 0 − 1: `st save U8-home`, `st save U8-diary`. Then export as `ont-r25-up2.zip` → pull → `$CMP diff $EVID/exports/up1.zip $EVID/exports/up2.zip > $EVID/exports/U8.txt`.
Expect:
- "Export / Import erfolgreich".
- Home and the Diary list every entry once (2.4.0 doubled them and broke Home with "Duplicate keys found", #1357).
- `U8.txt`: `intakes … stored-twice 0`, `missing 0`, `changed 0`, and the same counts as `up1`. Today's tracked-day goal may have moved by the import's goal refresh (#1381); that's the only expected difference.
- `st errors U8` empty.

Note: `base240.zip` has no `goal_settings.json`, so the goals stay as they are (S12's values). That is the old-archive rule of #1381.

**U9 — Cold start twice.**
Do: R (`st restart`), wait 5 s, R again; grep the capture for `TrackedDayReconciler` after U8's mark.
Expect: no `Brought … tracked days` line on the second start (the first may correct today's row after the import); Home unchanged.
Note: a reconciler that rewrites rows on every launch would be a defect of #1319 (it must write nothing once the rows agree).

---

## Part 3 — The delta in depth

Every row of the map's delta table, area by area. The order is chosen so that nothing destroys a later step's subject: the shared code and favourites first, settings in the middle, the language last (Part 8).

### DF — Favourites (#1320, new)

A per-profile list of starred foods and meals, filled without logging. Semantics: `add-meal-source-favourites` (chip), `add-meal-favourites-list` (list), `meal-detail-favourite` (detail page star), `add-item-recent-favourite-N` (stars on the add sheet's recent cards). Stars on search, Recently and Favourites cards carry **no** identifier (the dynamic-list rule); their content-desc is the tooltip, "Add to favourites" or "Remove from favourites" (English, see the list above).

*Blocks if:* starring logs an entry or changes a day's kcal; a starred food logs different nutrition than its record; the favourites list loses entries over an export and restore; a crash.

**DF1 — Empty state.**
Do: `fab-add-item` → `add-item-breakfast` → `st tap id=add-meal-source-favourites` → `st save DF1`.
Expect: the chip selected, the hint "No favourites yet" and "Tap the star on any food or meal to keep it here, ready to log." No list.

**DF2 — Star an Open Food Facts product on its detail page; nothing is logged.**
Do: write down Home's kcal consumed. Breakfast search → chip *Produkte* → the S7 product → wait for hydration → `st get id=meal-detail-favourite` → `st tap id=meal-detail-favourite` → `st get id=meal-detail-favourite` → BACK to the search screen → `st tap id=add-meal-source-favourites`.
Expect:
- The star's content-desc goes from "Add to favourites" to "Remove from favourites".
- The Favourites chip now lists the product inside `add-meal-favourites-list`.
- Home's kcal consumed is unchanged and the Diary for day 0 has no new row.

**DF3 — Star a custom meal and a recipe.**
Do: on the *Kürzlich* or *Alle* results, open ONT Linsensuppe (chip-less) → `meal-detail-favourite` → BACK; open ONT Bananenbrot from *Alle* (type `ONT Banan`) → star → BACK; chip Favourites.
Expect: three cards, newest star first: ONT Bananenbrot, ONT Linsensuppe, then the S7 product.
Note: if a recipe isn't offered on the search screen, star ONT Gemuesecurry from Recently instead.

**DF4 — The search field filters Favourites in place.**
Do: with the Favourites chip selected, `st field id=meal-search-field ONT` → wait 1 s → `st save DF4a` → clear the field (`st field id=meal-search-field ""` or 12 deletes) → `st save DF4b`.
Expect: still on Favourites (the chip selected, no Products/Food results). DF4a lists only the two ONT items; DF4b lists all three again. Typing never jumps to *Alle*.

**DF5 — Log from Favourites.**
Do: Favourites → tap ONT Linsensuppe → Menge `200`, `g` → `meal-detail-add`.
Expect: the snackbar; Home *Frühstück* gains ONT Linsensuppe, 180 kcal (90 kcal/100 g × 200 g).

**DF6 — Unstar from the Favourites list card.**
Do: Favourites → the only "Remove from favourites" node in ONT Bananenbrot's card. Find that card's bounds with `st bounds "text^=ONT Bananenbrot"`, then tap the `text=Remove from favourites` match whose centre lies inside them.
Expect: ONT Bananenbrot leaves the list. Two remain.
Note: if no match lies inside the card, unstar it on its detail page (`meal-detail-favourite`) instead, and record that the card star couldn't be located.

**DF7 — The add sheet's recent cards carry a star.**
Do: Home → `fab-add-item` → `st ls | grep add-item-recent-favourite` → close the sheet with BACK.
Expect: `add-item-recent-favourite-1` … one per recent card shown. Don't tap them.

Export, restore and a deleted meal's snapshot are checked in R9 (path 3). Two profiles are never touched in this run; they are covered by `test/unit_test/favourite_cross_profile_test.dart` (shared library edits refresh every profile's favourites) and `favourite_meal_repository_test.dart` (keys, dedupe, the hashed long key).

### DC — Shared meal code import (#1329, new on Android) and a shared recipe's total weight (#1294)

A meal can be imported from a pasted code: ⋮ on a meal section → *Code einfügen* (`intake-import-meal-code`) → a dialog with `import-meal-code-input` and "Parse" (`import-meal-code-parse`) → a preparation dialog (`import-meal-prepare-cancel`) → a preview (title "{n} Einträge importieren?", rows, a total) with *Importieren* (`import-meal-preview-import`) → the snackbar "Mahlzeit importiert". The codes are in `$EVID/fixtures/meal-codes.txt`. They were checked against the app's real parser at `c293acff4` when they were written.

*Blocks if:* an imported entry's kcal differs from the preview's; the preview's total differs from the fixture's; an unavailable item is imported anyway; an embedded recipe loses its hand-entered total weight (#1294: 250 kcal expected, 200 means the override was dropped); a crash.

**DC1 — An invalid code is refused, and the text stays.**
Do: Home → `intake-section-menu` on *Abendessen* (`@K`: the menu whose section title reads *Abendessen* in the same dump) → `text=Code einfügen` → `st tap id=import-meal-code-input` → `st type keinGueltigerCode` → `st tap id=import-meal-code-parse` → `st save DC1`.
Expect: the dialog stays open with "Enter a valid shared meal code." under the field, and the field still holds `keinGueltigerCode`.
Note: never tap *Code teilen* or *Mahlzeit teilen* here.

**DC2 — Code A: preview.**
Do: in the same dialog, clear the field (`st clear 64`) → `st type <CODE_A>` → `st get id=import-meal-code-input` and compare with `meal-codes.txt` character for character → `st tap id=import-meal-code-parse` → `st wait text~=Einträge importieren 30` → `st save DC2` → `st shot DC2`.
Expect (fx `code_a`):
- Title "3 Einträge importieren?".
- The text "Diese Einträge werden zu Abendessen hinzugefügt." and the heading *Abendessen*.
- The rows: ONT Code Haferbrei "250 g" "375 kcal"; ONT Code Apfel "120 g" "62 kcal"; ONT Code Eintopf "100 g" "250 kcal".
- Below the divider, "Total" and "687 kcal".
- *Importieren* enabled.

Note: if the typed text doesn't match the fixture, clear it and type it once more. On a second mismatch the step is *inconclusive* (an input problem, not the app's). The preview holds no slider, so scrolling inside it with `st swipe up` is allowed if the rows don't all fit.

**DC3 — Code A: import.**
Do: write down Home's *Abendessen* kcal → `st mark DC3` → `st tap id=import-meal-preview-import` → `st wait text=Mahlzeit importiert 30` → `st save DC3-home`.
Expect:
- The snackbar "Mahlzeit importiert".
- *Abendessen* gains three rows and exactly 687 kcal (its header goes up by 687 or 688 after rounding).
- You → `profile-recipes`: *Eigene Mahlzeiten* gains ONT Code Haferbrei and ONT Code Apfel, and *Rezepte* gains ONT Code Eintopf.
- `st errors DC3` is empty.

**DC4 — The embedded recipe kept its hand-entered total (#1294).**
Do: *Rezepte* → ONT Code Eintopf → read the per-100 line → open the builder (the pencil) → `st save DC4-builder` → BACK. If *Änderungen verwerfen?* appears, tap *Verwerfen*.
Expect:
- Detail: `Pro 100 g · 250 kcal …`.
- Builder: *Gesamtgewicht (g)* reads `80`, the helper line reads "Entered manually, so changing ingredients won't change it.", and the button `recipe-builder-weight-reset` "Use ingredient total" is shown.
Note: 200 kcal per 100 g, or 100 g, means the flag was dropped and the recipe was spread over its 100 g ingredient sum: **fail** (wrong nutrition numbers). This also proves #1280 on a recipe the run never typed.

**DC5 — Code B: an unknown barcode is shown as skipped, and the total says so.**
Do: ⋮ on *Snack* → *Code einfügen* → type `<CODE_B>` → verify → Parse → `st wait text~=Einträge importieren 120` (the barcode lookup can take up to two minutes) → `st save DC5` → *Importieren* → `st save DC5-home`.
Expect (fx `code_b`):
- The preview: "2 Einträge importieren?"; ONT Code Rest "100 g" "100 kcal"; a row titled `2999999999991`, "50 g", "—", and "Unavailable — this item will be skipped."; then "Total (incomplete)" and "100 kcal".
- After import, *Snack* gains only ONT Code Rest, 100 kcal.

Note: if the lookup finds a product under that barcode after all, the step is *inconclusive* for the "unavailable" half. Record the product name it found.

**DC6 — The preparation dialog can be cancelled.**
Do: ⋮ on *Snack* → *Code einfügen* → type `<CODE_B>` → Parse → immediately `st tap id=import-meal-prepare-cancel`.
Expect: back on Home with nothing imported (*Snack* unchanged).
Note: if the lookup finished before the tap landed (the preview is already up), tap *ABBRECHEN* on the preview and record *could not win the race*. That half is then covered by `test/features/home/presentation/widgets/shared_meal_import_test.dart` (cancellation).

Not covered on the phone: the camera QR route and the share sheet. Both leave the package (#1429).

### DH — Home / dashboard (#1358, #1318)

*Blocks if:* an entry in a 0 % meal can't be seen, edited or deleted; Home's numbers disagree with the Diary's; a crash.

**DH1 — The calorie ring turns red over the goal (#1358).**
Do:
1. `st shot DH1-under` while under the goal. Read the ring's colour at a point on its arc: `st bounds id=home-kcal-gauge`, then `st pixel DH1-under` at the arc's top centre.
2. Log a quick entry large enough to go over: `fab-add-item` → `add-item-snack` → *Schnelles Tracking* (`id=add-meal-quick-add`) → `id=quick-add-title` `ONT Ueberschuss`, `id=quick-add-energy` = (Home's kcal left + 500) → `id=quick-add-submit`.
3. Home: `st shot DH1-over`, the same pixel.

Expect: under the goal, the label reads "kcal übrig" and the arc pixel is the primary colour. Over it, the label reads "kcal zu viel" and the arc pixel is the theme's error red (hue near 0°, clearly different from DH1-under).
Note: delete `ONT Ueberschuss` again in DD1. If the arc point can't be found reliably, judge the screenshots by eye. If they still don't decide, the step is *inconclusive*, covered by `test/features/home/presentation/widgets/dashboard_widget_test.dart`.

**DH2 — Food in a 0 % meal stays visible (#1318).**
Do:
1. Settings → `settings-per-meal-share` → `id=meal-share-preset-omad` → `id=meal-share-save`.
2. Home and Diary (day 0): `st save DH2-home`, `st save DH2-diary`.
3. `fab-add-item`: read which tile carries `add-item-suggested-chip`, then BACK.
4. Restore: `settings-per-meal-share` → `id=meal-share-preset-mediterranean` → `meal-share-save`.

Expect:
- With OMAD (0/0/100/0), Home and the Diary still show *Frühstück*, *Mittagessen* and *Snack*, because each holds entries from S7–S9 and DF5. Those sections show consumed kcal without a target.
- The suggested chip sits on *Abendessen* whatever the hour.
- After the restore, the per-meal share reopens at 25/45/20/10.

Note: on 2.4.0 those three sections would vanish while their kcal still counted.

### DD — Diary / tracked day (#1333, #1382, #1319, #1385)

*Blocks if:* a day's listed entries and its totals disagree; moving the day boundary loses or doubles kcal; Home and the Diary count a different day as today; a crash.

**DD1 — The sorted macro shows on each row (#1333).**
Do: `nav-diary` → day 0 → on *Frühstück*, `id=diary-section-sort-menu` (`@K` for that section) → *Protein (absteigend)* → `st save DD1-protein` → the menu again → *Hinzugefügt am*. Then delete `ONT Ueberschuss` (DH1): long-press its row → in the dialog titled *Eintrag löschen?* tap *OK* (`DeleteDialog`: OK / ABBRECHEN). If the card lifts into a drag instead, release and record it.
Expect:
- With protein sorting, each *Frühstück* row shows a line "<value> g Protein" above its kcal (one decimal, German comma). For ONT Linsensuppe 200 g that is "12,0 g Protein" (6 g/100 g × 200 g).
- With *Hinzugefügt am*, the rows show kcal only.
- After the delete, Home's kcal is back below the goal.

Note: the delete dialog reads "Möchten Sie den ausgewählten Eintrag löschen?" in German. The typo fix in #1384 is English-only and is checked in E5.

**DD2 — The logical day is "today" everywhere (#1382), and rows follow it (#1319).**
Precondition: the hour H ≤ 22 (`st clock`). Otherwise *skipped: run after 22:00*, covered by `test/features/diary/diary_page_logical_today_test.dart`, `test/features/settings/presentation/widgets/goal_edits_logical_day_test.dart` and `test/unit_test/tracked_day_listed_day_test.dart`.

Do:
1. Export `ont-r25-dd2a.zip` (JSON), pull it, run `$CMP summary` on it. That is the per-day "before".
2. Settings → `settings-day-boundary` → `st slider id=day-boundary-hours-slider <(H+1)/23> bottom` → read the label and correct it until it reads `H+1:00` → `id=day-boundary-save`.
3. Diary: `st save DD2-diary`, `st shot DD2-diary`. Read the header (`DateFormat.yMMMMEEEEd`, e.g. "Mittwoch, 21. Oktober 2026").
4. Home: `st save DD2-home`.
5. Settings → `settings-nutrient-goals` → read the fibre field → set it to `44` (rule 7: read all fields first) → `nutrient-goals-save`. Then Diary: open *Heutige Nährstoffe*.
6. Settings → `settings-day-boundary` → *Zurücksetzen* → `day-boundary-save`.
7. Export `ont-r25-dd2b.zip`, pull, `$CMP diff dd2a dd2b`.

Expect:
- With the boundary at H+1:00, everything logged today before H+1:00 now belongs to the logical yesterday (day 0 − 1), and so does every midnight-dated seed entry of day 0 − 1. The Diary **opens on day 0 − 1**: its header names day 0 − 1, and the calendar's today marker sits on day 0 − 1. Home counts the same entries.
- In the settings run (2026-10-11, row 11) the Diary stayed on the calendar date with nothing on it. That is the "before".
- The fibre goal saved in step 5 shows as "/ 44 g" on the Diary's logical today (2.4.0 put it on the calendar date, settings-run B6).
- After the reset, `$CMP diff dd2a dd2b` reads `missing 0 changed 0 stored-twice 0` for intakes, and no tracked-day line carries `NEW tracked != NEW sum`. The day 0 − 1 row's `ironGoal` and `fibreGoal` show the step-5 goal, which is expected.

Note: the dialog holds two sliders. The only touches are the slider taps, the label read and the Save; no swipe.

**DD3 — Creating a missing day never wipes one (#1385).** *Skipped on the phone:* the race needs two writers between a check and a write. Covered by `test/unit_test/tracked_day_create_if_absent_test.dart` (three callers each fail with the old `addNewTrackedDay`). DD2 and U4 check that rows and entries agree on the phone.

### DA — Add meal, search and recents (#1334, #1282, #1252, #1291)

*Blocks if:* a search result logs different nutrition than its record; a crash; Recently offers a deleted or stale recipe with the old nutrition (#1291).

**DA1 — Recent stays put while typing, and *Search all* (#1334).**
Do:
1. `fab-add-item` → `add-item-lunch`.
2. Type `ONT Lin` **without** touching the chips → `st save DA1a`.
3. Clear the field.
4. Tap the chip *Kürzlich* explicitly → type `ONT Lin` → `st save DA1b`.
5. Clear the field, type `zzqqx` → wait 2 s → `st kb_hide` → `st save DA1c` → `st tap id=search-no-results-search-all` → wait 2 s → `st save DA1d`.

Expect:
- DA1a: typing without a chip choice switches to *Alle* (unchanged default).
- DA1b: *Kürzlich* stays selected and lists only ONT Linsensuppe (`add-meal-recent-list`).
- DA1c: "Keine Ergebnisse gefunden", the scan and create buttons, and the button "Search all" (`search-no-results-search-all`).
- DA1d: *Alle* selected and a search for `zzqqx` ran (the no-results state of *Alle*).

Note: the buttons sit behind the keyboard until it is hidden (2.4.0 run). Re-dump after `kb_hide` before tapping.

**DA2 — A failed source vs. zero results (#1282).** *Skipped on the phone:* making one source fail needs the network cut for one provider, and the run doesn't change device settings. Covered by `test/features/add_meal/presentation/add_meal_screen_provider_failure_test.dart` and `test/widget_test/partial_results_notice_test.dart`. Negative control on the phone: every search in this run must show **no** "One food source didn't respond…" banner. If one appears, write down the query and the time. It isn't a failure on its own.

**DA3 — Recents chronological (#1252).** Shown in U7.

**DA4 — An edited recipe is offered as it is now (#1291).**
Do:
1. If S9.2 didn't log ONT Gemuesecurry, log it now (Recipes → ONT Gemuesecurry → log 350 g into *Abendessen*).
2. Recipes → ONT Gemuesecurry → builder (pencil) → `st field edit=1 "ONT Gemuesecurry scharf"` (assert the field held `ONT Gemuesecurry` before) → `id=recipe-builder-save`.
3. `fab-add-item` → `add-item-dinner` → *Kürzlich* → `st save DA4-recent` → tap ONT Gemuesecurry scharf → read the kcal for the default amount → BACK twice.
4. Diary day 0 → *Abendessen*.

Expect:
- Recently shows **ONT Gemuesecurry scharf** (the current recipe), not the old name.
- The diary entry logged before the edit still reads ONT Gemuesecurry and its kcal is unchanged (a logged entry is not rewritten).
- The recipe's nutrition is unchanged (only the name was edited), so the kcal per 100 g is still 78.6 (fx: 275 kcal / 350 g).

### DM — Meal detail (#1297, #1376)

*Blocks if:* the detail screen shows wrong values for a food; a crash.

**DM1 — No dead info button on custom meals and recipes (#1297).**
Do: open ONT Joghurt (custom) and ONT Bananenbrot (recipe) from a search → `st save DM1-custom`, `st save DM1-recipe` → BACK. Then the S7 product → `st save DM1-off` → BACK.
Expect: no *Benutzerdefinierte Mahlzeit* button on the custom meal and no info button on the recipe (S14 recorded it on 2.4.0); the Open Food Facts product still shows "Weitere Informationen unter OpenFoodFacts".
Note: never tap that button (rule 3).

**DM2 — Micronutrients follow the switch (#1376).**
Do: Settings → *Mikronährstoffe anzeigen*: set it **off** → open the S7 product (it has micronutrient data) → `st save DM2-off` → BACK → switch **on** → the same product → `st save DM2-on` → BACK → restore the S3 state.
Expect: off → no *Mikronährstoffe* section; on → the section, expanded.
Note: on 2.4.0, *off* still showed the section for a food that has data (settings-run row 14, "fail (design)"). With the switch default off, a user who never touched it now sees no micronutrients: that is the PR's stated trade-off, not a defect.

### DR — Custom meals and recipes (#1404, #1420, #1280, #1294, #1328)

*Blocks if:* an edit leaves two copies of a meal; a past entry changes its kcal or macros through an edit; an entry is lost; a recipe's total weight changes without the user typing it.

**DR1 — Renaming a meal without a barcode replaces it, and past entries follow (#1404, #1420).**
Do:
1. You → `profile-recipes` → *Eigene Mahlzeiten* → tap the **title text** ONT Linsensuppe (never the trash icon).
2. In *Mahlzeit bearbeiten*, `st get edit=1` must read `ONT Linsensuppe`. Then `st field edit=1 "ONT Linsensuppe rot"` → `st get edit=1` → `id=edit-meal-save`.
3. `st save DR1-library`; Diary day 0 − 6 and day 0.
4. Export `ont-r25-dr.zip`, pull, `$CMP summary`, and `python3 -I -c` over its `user_intake.json`: count intakes whose `meal.name` is `ONT Linsensuppe` and `ONT Linsensuppe rot`.

Expect:
- *Eigene Mahlzeiten* lists **one** ONT Linsensuppe rot and no ONT Linsensuppe (2.4.0 kept both, #1403).
- The Diary's past entries now read ONT Linsensuppe rot with their old amounts and kcal.
- In the export: 0 with the old name, all of them with the new one (6 from the seed plus DF5's), and every day's kcal unchanged against U4's `up1`.

Note: the German delete-confirm text of a custom meal still says entries "may" stay. The English source now says "in this profile" (#1420). Note it only.

**DR2 — Changing a barcode replaces the meal and moves its entry (#1404, #1420).**
Do: *Eigene Mahlzeiten* → ONT Riegel → `st get id=edit-meal-barcode-input` must read `2000000000015` → `st field id=edit-meal-barcode-input 2000000000022` → `edit-meal-save`. Then export `ont-r25-dr2.zip`, pull, and check `user_intake.json` for S9's ONT Riegel entry.
Expect: one ONT Riegel in the library. S9's entry has `meal.code` `2000000000022` and the same kcal. No entry with `2000000000015` remains.
Note: if S9.1 didn't seed the entry, the library half still runs and the entry half is *skipped: no seed*.

**DR3 — A hand-entered total weight survives reopening (#1280).**
Do: Recipes → ONT Bananenbrot → pencil → `st save DR3` → read *Gesamtgewicht (g)* → BACK. If *Änderungen verwerfen?* appears, *Verwerfen*.
Expect: `450`, the helper "Entered manually, so changing ingredients won't change it.", and the button `recipe-builder-weight-reset` "Use ingredient total". Don't tap it.
Note: 2.4.0 reopened it at the 500 g sum, and a save would have stored 500 (#1277).

**DR4 — A shared recipe's total weight on import (#1294).** Shown in DC4.

**DR5 — Typed macros applied when the field loses focus (#1328).**
Do: Settings → `settings-macro-split` → the carbs text field `edit=1` (not `id=macro-split-carbs`, which is the slider): `st field edit=1 50` → **without Done**, tap the dialog title (outside every field) → `st save DR5a` → *ABBRECHEN*.
Expect: right after the tap outside, protein and fat have already rebalanced so the three add up to 100 (the PR's test: carbs 60 → 53 without the fix). Cancel leaves the stored split as S12 set it.
Note: #1328 also lets the iOS number pad be dismissed. That is iOS-only and out of scope. Android's Done always worked.

### DS — Settings (#1371, #1273, #1384, #1370, #1372, #1353, #1380, #1390, #1332)

The "before" for most of these is the settings run on 2.4.0 (`docs/settings-test/run-2026-10-11/results.md` on `research/settings-pixel-test`).

*Blocks if:* a goal the user saved isn't the one stored; a goal shows on one screen and not another after a save (the Diary and Trends must follow without a restart now); a typed value is lost on OK; a crash.

**DS1 — A typed value is applied on OK, without Done (#1371).**
Do:
1. Open Trends once and the Diary once (so their blocs are loaded, which makes the next step a real staleness test).
2. Settings → `settings-kcal-adjustment` → `st field id=kcal-adjustment-input 300` → **no Done** → `kcal-adjustment-save`.
3. Reopen it and read the value → *ABBRECHEN*.
4. Home, Diary day 0 (the day's goal) and Trends (the goal line, `st shot DS1-trends`).
5. You → `profile-water-goal` → `st field id=water-goal-input 2600` → `water-goal-save` → reopen and read.

Expect:
- The kcal adjustment reopens at `300` (2.4.0: 250, the typed value dropped, #1347).
- Home's goal is 50 higher than after S12. The Diary's day goal follows **at once**, without R (settings-run row 7: the Diary stayed old until R, B3). The Trends goal line moves (compare with a screenshot taken before step 2).
- The water goal reopens at "2600".

**DS2 — kJ: the adjustment rounds (#1273), and the row says kJ (#1384).**
Do:
1. Settings → `settings-energy-unit` → *Kilojoule (kJ)* → OK.
2. `settings-kcal-adjustment`: the row and the dialog title read "Daily kJ adjustment". `st field id=kcal-adjustment-input 1255` → `kcal-adjustment-save`.
3. Reopen and read → *ABBRECHEN*.
4. Back to *Kilokalorien (kcal)*, reopen and read.
5. `st field … 250` → save, which restores S12's value.

Expect:
- In kJ mode the title is the English "Daily kJ adjustment" (German has no entry yet).
- `1255` kJ reopens as **1255** in kJ mode and **300** in kcal mode. The settings run's K2 probe on 2.4.0 reopened 1251: `toInt` turned 299.95 kcal into 299.

**DS3 — The settings list keeps its place, the cache count is fresh, and the last row clears the button (#1384).**
Do:
1. Settings → `st scroll_to "text^=Makros je Mahlzeit anzeigen"` → `st bounds` of it → toggle it → `st bounds` again → toggle it back.
2. Read *Cache leeren*'s subtitle ("{n} Eintrag/Einträge · {size}") **without tapping it**. Run one search (`fab-add-item` → `add-item-snack` → `chips` → *Produkte* → wait 2 s → BACK twice), return to Settings and read the subtitle again.
3. Fling to the end of the You list (`st swipe up` until two dumps match) → `st bounds` of the last tile (*Über*) and of `fab-add-item`.
4. Settings → `settings-food-units` → *Imperial* → OK → open the S7 product → open its *Einheit* menu → `st save DS3-imperial` → close the menu → BACK → back to *Metrisch*.

Expect:
- Step 1: after each toggle the tile is at the same y (±10 px). 2.4.0 jumped to the top after every save (inventory B10).
- Step 2: the count is higher after the search, without a restart (settings run row 35: stale until restart).
- Step 3: the last tile's bottom edge sits at least 84 px (32 dp) above the top of `fab-add-item`. #1384 measured 5 dp before.
- Step 4: the serving entry reads in ounces, e.g. "0.53 oz (Portion)", not "15 g (Portion)".

**DS4 — The Diary and Trends follow a settings change at once (#1370).**
Each sub-step first opens the consumer once, then changes the setting, then reads the consumer **without R**:
- (a) Macro split: carbs text field `edit=1` = `50` with Done → OK → the Diary's macro goals and Trends' daily averages change at once (settings-run row 8). Then back to `45`.
- (b) *Makros je Mahlzeit anzeigen* off → the Diary meal headers lose the c/f/p line at once (row 13). Then on.
- (c) *Nährstoffe* (`settings-nutrient-visibility`) → untick *Eisen* → the Diary panel *Heutige Nährstoffe* has no iron row at once (row 15). Then tick it again.
- (d) Water goal: Trends' water card reads "/ 2600 ml" right after DS1 (row 42: "/ 1500 ml" until R).
- (e) Weight: shown in DW2.

Expect: every consumer changes before any restart.

**DS5 — Reset + Save clears the nutrient goals (#1353).**
Do: Settings → `settings-nutrient-goals` → read all ten fields → `id=nutrient-goals-reset` → read them → `id=nutrient-goals-save` → reopen → read → Diary day 0 → *Heutige Nährstoffe*.
Expect:
- After Save and reopen, every field shows its default (fibre per DS6, iron by gender: 8 mg male, 18 mg female, 14 mg otherwise), not a value set earlier today (DD2's 44 g sits on day 0 − 1, not today).
- The Diary panel uses the defaults.
- 2.4.0 kept the old values (#1349).

**DS6 — The fibre goal opens at the Diary's reference (#1380).**
Do: right after DS5 (no fibre goal saved today), read the fibre field and slider, and the Diary panel's fibre reference.
Expect: both equal the IOM value for S1's gender and age (S1's note), e.g. 38 for a man of 36. They no longer show a flat 30 in Settings while the Diary uses another number. The German description still says "Standardreferenz: 30 g" (stale German, noted above).

**DS7 — A comma decimal is accepted (#1390).**
Do: `settings-nutrient-goals` → the iron field: `st field <iron field> "12,5"` → `st get` it → `nutrient-goals-save` → reopen → read it → Diary panel → iron reference.
Expect: the field shows `12.5` as soon as the comma is typed (the formatter turns it into a period), it reopens at `12.5`, and the Diary shows "/ 12,5 mg" or "12.5". 2.4.0 turned `12,5` into `125` and clamped it.
Note: the iron field is the text field in the same card as `nutrient-iron-slider`. Pick it as the EditText directly above that slider in the current dump. Then *Zurücksetzen* + *Speichern* to leave today's goals at their defaults.

**DS8 — The language list scrolls (#1332).**
Do: Settings → *Sprache* → `st save DS8a` → inside the dialog, `st swipe up` once (the swipe stays inside the list, which holds no slider) → `st save DS8b` → *ABBRECHEN*.
Expect: the rows Systemstandard, English, Deutsch, … through the last shipped language are all reachable. After the swipe, the last row's bounds lie inside the dialog, above *ABBRECHEN* / *OK*, which stay fixed. The language is unchanged.
Note: settings-run row 20 couldn't reach the languages below the fold (#1331). Don't pick a language here (rule 12).

**DS9 — Today's tracked day on an empty day (#1372).** It needs a day with no entries and no row, which the upgraded profile no longer has today. Shown in N11 (path 2) and covered by `test/features/settings/presentation/bloc/settings_bloc_update_tracked_day_test.dart`.

**DS10 — Health Connect *Jetzt importieren* gives feedback (#1384 item 5).** *Skipped:* pressing it imports the maintainer's real workouts, which is skipped by decision (#1430). Covered by `test/features/settings/presentation/widgets/health_sync_screen_test.dart`.

### DW — Weight and profile (#1222, #1383, #1419)

*Blocks if:* a weight entry other than the one deleted disappears; Trends shows a weight that the history doesn't; a crash.

**DW1 — *Eintrag hinzufügen* starts from the profile's weight (#1383, upgrade half).**
Do: You → `profile-weight-history` → `weight-history-add` → `st get id=weight-history-weight-input` → *ABBRECHEN*.
Expect: `80.4`, the profile weight S11 set, not the 70 kg fallback. The onboarding-weight half is N10.

**DW2 — Delete a row by its storage key (#1419), and Trends follows (#1370).**
Do:
1. Open Trends once and read the weight card (`st shot DW2-trends-before`).
2. `weight-history-add` → *Datum* = day 0 − 3 → weight `88.8` → OK. The tile `88.8 kg` appears.
3. `b=$(st bounds "text^=88.8 kg")` → `st tapxy <x2−70> <(y1+y2)/2>` from that same dump.
4. Count the tiles. Read Trends again (`st shot DW2-trends-after`).

Expect:
- The 88.8 kg tile is gone and the four S11 tiles remain, by value.
- Trends shows the deletion without R (settings-run note 5.2: Trends kept the deleted weight).

Note: this is the one tap on a tile's unlabelled delete button the run allows, and only on an entry it created in step 2. If step 3's bounds come from anything other than the `88.8 kg` tile, don't tap. The time-zone case #1419 fixes (a row filed under one day, showing another) can't be produced on the phone without changing its zone. It is covered by `test/unit_test/delete_weight_log_usecase_test.dart`.

**DW3 — The weight chart windows by calendar days across DST (#1222).** Only if day 0 is 2026-10-26 or later: the 30-day window then contains the 2026-10-25 fall-back. Add a reading for 2026-10-24 and 2026-10-26 (S11's way), open the chart at 30d, `st shot DW3`, then delete both again as in DW2.
Expect: one dot per reading, on its own day's label, and no reading dropped at the window's start.
Otherwise *skipped: no DST transition inside the window on day 0*, covered by `test/features/profile/presentation/widgets/weight_trend_chart_test.dart` and `test/unit_test/calendar_day_calc_test.dart` under `just test_dst`.

### DN — Notifications (#1379, #1391)

The reminder surviving the upgrade is U5. The language half of #1379 is E10–E11, and onboarding's reminder (#1391) is N8–N9. The failed-reschedule half of #1391 (an alarm kept when `zonedSchedule` throws) can't be forced on the phone. It is covered by `test/unit_test/daily_reminder_scheduler_test.dart` ("a refresh whose zonedSchedule throws leaves the previous alarm").

### DT — Trends (#1377)

*Blocks if:* Trends shows kcal numbers labelled as kJ, or the reverse; a crash.

**DT1 — The calorie chart in the selected unit.**
Do: Settings → *Kilojoule (kJ)* → `nav-trends` → `st bounds` of the calorie card → `st holdshot <x of a middle day> <y of the plot's centre> DT1-kj` → back to *Kilokalorien* → the same `holdshot` → `DT1-kcal`.
Expect: the tooltip number in kJ mode is 4.184 × the number in kcal mode, ±1 (e.g. 2.4.0's settings run showed 1039 where 4347 was due).
Note: without `holdshot` the tooltip can't be captured (it shows only while held): *inconclusive*, covered by `test/features/trends/trends_calorie_chart_energy_unit_test.dart`. The goal line and the points scale together, so a still picture of the chart doesn't decide.

### DAI — AI meal assistance (#1378) and the real key

The key is OpenRouter's (`~/.config/ont-run/ai-key`). The run judges the flow, not which food the model names ([#1427](https://github.com/simonoppowa/OpenNutriTracker/issues/1427)).

*Blocks if:* a nutrition value arrives from the model (every row's numbers must come from a food database); a key is shown, logged or screenshotted; a crash.

**DAI1 — Save the key.**
Do:
1. Settings → `settings-ai-assist` → read the subtitle → the dialog → `id=ai-assist-provider-openrouter` → `st tap id=ai-assist-key-field`.
2. **No screenshot until step 3 is done.** `st type_secret < ~/.config/ont-run/ai-key`. Then `st get id=ai-assist-key-field` must show only `•` characters.
3. `id=ai-assist-save-key`.
4. If the route *Bevor du das einschaltest* opens, `st save DAI1-consent` and tap `id=ai-consent-agree`.

Expect:
- The consent screen (on a first save) holds "Dein Tagebuch und dein Profil werden nie gesendet. Nährwerte stammen immer aus den Lebensmitteldatenbanken, nie vom Modell. …".
- After saving: "Schlüssel gespeichert" and `ai-assist-remove-key`. The Settings subtitle reads "An — OpenRouter".

Note: if the subtitle already read "An — OpenRouter" before step 1, a key is stored from earlier. Skip the typing and record it.

**DAI2 — One typed meal through the real provider.**
Do: `st mark DAI2` → `fab-add-item` → `add-item-breakfast` → `id=add-meal-bulk-add` → `st field id=bulk-add-input "2 Eier und eine Scheibe Brot"` → `id=bulk-add-parse` → `st wait id=bulk-add-row-list 60` → `st save DAI2` → `st shot DAI2` → BACK without submitting.
Expect:
- The banner `bulk-add-model-notice` "Von KI gelesen — prüfe jede Zeile".
- Rows titled with database food names, each with an energy figure that changes when its unit dropdown changes.
- `bulk-add-submit` reading "{n} Einträge speichern".
- In logcat after the mark, the resolution against Supabase/Open Food Facts and the portion RPCs, and none of `SEVERE: BulkAddBloc` / `SEVERE: BulkAddScreen`.

Note: an error caption such as "KI nicht verwendet: Dein API-Schlüssel wurde abgelehnt." or "… Guthaben … aufgebraucht" is *inconclusive* (key or account), not a product failure. Nothing is submitted.

**DAI3 — A typed model survives an address change, and a refused OK is shown (#1378).**
Do:
1. `settings-ai-assist` → `id=ai-assist-provider-own-server` → `st field id=ai-assist-endpoint-field http://127.0.0.1:11434` → `st field id=ai-assist-model-field llama3`.
2. `st field id=ai-assist-endpoint-field http://127.0.0.1:11435` → `st tap id=ai-assist-model-field` (moving focus off the address starts the fetch) → wait 5 s → `st get id=ai-assist-model-field` → `st save DAI3a`.
3. `st field id=ai-assist-model-field ""` (clear it) → `st tap id=ai-assist-save-key` → `st save DAI3b`.
4. `id=ai-assist-cancel`.

Expect:
- Step 2: "127.0.0.1:11435 war nicht erreichbar…" (nothing listens on the phone), and the model field **still reads `llama3`**. 2.4.0 cleared it a moment after the address changed (settings-run row 29).
- Step 3: OK refuses. "Gib den Namen des Modells an, das dieser Server verwenden soll." is visible in the dump, its bounds lie inside the dialog's visible area above the keyboard, and the model field has focus.
- Step 4: the dialog closes. The subtitle still reads "An — OpenRouter".

Note: **never tap OK while both own-server fields are filled.** That would make the unreachable server the active provider. If the subtitle no longer reads OpenRouter after step 4, select OpenRouter in the dialog and OK, then record it.

### DL — Localization (#1230, #1223, #1415, Weblate)

*Blocks if:* the UI falls back to another language than the one chosen; a screen shows a raw key or `{placeholder}`; a crash. #1230 is E9.

**DL1 — Every activity row has its own name, and yoga can be found (#1223).**
Do: `fab-add-item` → `add-item-activity` → search `yoga` → `st save DL1a` → clear → search `rudern` → `st save DL1b` → BACK.
Expect: `yoga` finds a row named "yoga" (English, new key; 2.4.0 found nothing, #118). The full English uniqueness check is E7.

**DL2 — "min" on activities (#1415).**
Do: Home's activity card (S10) and the activity detail of any row.
Expect: "30 min" and "~<n> kcal / 30 min", unchanged in German. The key is new and has no German entry yet. The English pass shows the same.

**DL3 — Weblate: no new shipped language.** In DS8's dump the language list holds the same entries as 2.4.0's picker. *Svenska*, *Nederlands* and *العربية* received translation files, but none is a shipped locale ([#1425](https://github.com/simonoppowa/OpenNutriTracker/issues/1425)). A language that appears in the list without being in `lib/core/l10n/shipped_locales.dart` at `c293acff4` is a finding.

---

## Part 4 — Every other area at smoke depth

One cheap step per area the delta didn't already exercise. *Blocks if* for every K step: a crash, a red screen, an empty list where the data is local, or a number that disagrees with the screen it came from.

**K1 — Diary navigation and the nutrient panel.** `nav-diary` → tap day 0 − 3 → `st save K1` → *Heutige Nährstoffe* → segment *Woche* → the today icon (the only clickable node to the right below the calendar card). Expect: day 0 − 3 lists the seed entries (fx `diary_days`); *Woche* renders; the today icon returns to today.

**K2 — Add meal, all providers.** On one search screen: `ONT Hafer` on *Alle* (chip-less custom), `nutella` on *Produkte* (*Open Food Facts* chips), `apfel` on *Lebensmittel* (*BLS* / *FDC …* chips), plus *Kürzlich* and the Favourites chip. Expect: each provider returns rows, and every card under *Produkte* / *Lebensmittel* carries the right source chip. Real thumbnails show on the Open Food Facts cards (`st shot K2`).

**K3 — Scanner, manual entry (the camera itself is skipped).** `add-item-snack` → `id=meal-search-barcode` → the scanner opens without a system prompt (CAMERA granted in P11; **no screenshot while it is open**, the preview films the room) → `id=scanner-manual-entry-open` → assert the title "Barcode eingeben" → `st field id=scanner-manual-entry-field <the S7 barcode>` → `id=scanner-manual-entry-submit`. Expect: the product's detail screen. BACK without adding. If S7 recorded no barcode, use `3017620422003`.

**K4 — Meal detail chips.** The S7 product → after hydration, `st ls | grep meal-detail-chip`. Expect: `meal-detail-chip-100g`, plus `…-half-serving` / `…-one-serving` / `…-double-serving` when it has a serving. Tap `-100g`: Menge `100`, unit `g`. BACK without adding.

**K5 — Custom meals screen.** *Eigene Mahlzeiten* lists the four ONT meals (DR1, DR2 renamed and recoded) and the two ONT Code meals. The merge menu `custom-foods-merge-open` opens (`st tap`) and is closed with BACK without picking.

**K6 — Recipes.** Rezepte lists ONT Gemuesecurry scharf, ONT Bananenbrot and ONT Code Eintopf with their counts and kcal.

**K7 — Activities.** `add-item-activity` → *Alle* → the first card's detail: "~<n> kcal / … min". BACK without adding. *Kürzlich* lists S10's activity.

**K8 — Health Connect, screen and disclosure only.** Settings → `id=settings-health-sync` → the screen opens → `st tap id=health-sync-auto-import` → `st wait "text^=Trainings aus Health Connect importieren?" 5` → `st save K8` → the dialog's cancel button (the other button than *Weiter*) → `st get id=health-sync-auto-import`. Expect: the disclosure appears before any system UI; cancel leaves the switch off. **Never** *Weiter*, `health-sync-import-now`, `health-sync-kcal-multiplier` or `health-sync-sources`. The grant and the import are *skipped* (decision, #1430).

**K9 — Fasting.** You → `profile-fasting-entry` → if *Bevor du beginnst* shows, `id=fasting-warning-accept` → the screen: `fasting-preset-16h`, `fasting-preset-custom`, `fasting-start`. **Don't start a fast.** BACK.

**K10 — Trends.** `nav-trends` → `id=trends-range-selector` 7d / 30d / 90d / *Alle* → the weight card at the end. Expect: each range renders, and the weight card shows S11's readings (`st shot K10`).

**K11 — Profile.** You: the tiles from S1 read the same, with weight 80.4 kg and the water goal "2600 ml". The BMI card renders.

**K12 — Settings smoke.** Every Settings group opens and every dialog this script didn't already open shows and cancels: *Thema* (pick nothing), *Akzentfarbe*, `settings-kcal-goal-info` (open, BACK), *Lebensmitteldatenbanken* (`settings-food-sources`, open, BACK), *Datenschutz…* (cancel), *Haftungsausschluss* (close), *Über* (close, no links). Expect: no red screen.

**K13 — Notifications.** The reminder from S13 is still armed (`st alarms`). Its delivery is checked in E10–E11.

**K14 — Export works in both formats.** Covered by X1/X2.

The onboarding area is Part 6. AI is DAI.

---

## Part 5 — The candidate's own exports

**X1 — JSON.** `[picker]`
Do: export JSON as `ont-r25-cand.zip` → pull to `$EVID/exports/cand.zip` → `adb push` it back as `/sdcard/Download/ont-r25-cand.zip` → `$CMP summary $EVID/exports/cand.zip > $EVID/exports/cand.txt`.
Expect, in addition to the files 2.4.0 wrote:
- `goal_settings.json` with `kcalAdjustment 250`, `carbGoalPct 0.45`, `mealKcalSharesPct` 25/45/20/10, `dailyWaterGoalMl 2600`.
- `user_favourites.json` with two entries (ONT Linsensuppe rot and the S7 product).
- `tracked_day_boundary.json` with `dayStartOffsetMinutes 0`.
- `intake ids stored twice or more: 0; blank ids: 0`.

**X2 — CSV.** `[picker]`
Do: export CSV as `ont-r25-candcsv.zip` → pull → `unzip -l`.
Expect: `user_activity.csv`, `user_intake.csv`, `user_tracked_day.csv` (and `tracked_day_boundary.csv`); no favourites and no recipes. The CSV info row reads "CSV speichert Aktivitäten, das Essensprotokoll und protokollierte Tage. …" (German still names only recipes; the English note now also names favourites).

**X3 — `cand.zip` is the subject of R9.** Nothing may write to the app between X1 and N1 that X1 should have held.

---

## Part 6 — Path 2: fresh onboarding

`pm clear` deletes the profile on the phone. Everything worth keeping is in `$EVID/exports/` by now (`pre`, `base240`, `up1`, `up2`, `cand`).

*Blocks if:* onboarding can't be finished; the first Home shows a goal that doesn't match the overview; the onboarding weight is missing from Weight history (#1383); the reminder switched on during onboarding has no alarm (#1391); the demo can't be entered, or leaves real-profile data behind; a crash.

**N1 — Clear the candidate.**
Do: confirm `$CMP summary $EVID/exports/cand.zip` worked (X1). Then `$ADB shell pm clear $PKG` (only `$PKG`) → P11 again.
Expect: `Success`; both grants `granted=true` again.

**N2 — First launch.**
Do: `st launch`.
Expect: the intro with `onboarding-checkbox-privacy`, `onboarding-checkbox-data`, `onboarding-try-demo` and `onboarding-button`. The UI is German (the device's language; `pm clear` also clears the app's own per-app locale record).

**N3 — Intro.**
Do: tap `onboarding-checkbox-privacy` → `onboarding-button`.
Note: don't touch the data checkbox. Crash reports stay off.

**N4 — About you.**
Do: `id=onboarding-gender-genderFemale` → `id=onboarding-birthday-field` → in the date picker `text=Zur Texteingabe wechseln` → `st field edit=1 15.03.1996` → OK → `onboarding-button`.
Expect: the field shows 15.03.1996, age 30 on day 0.

**N5 — Body.**
Do: `st field id=onboarding-height-field 168` → `st field id=onboarding-weight-field 62` → leave the target weight empty → `onboarding-button`. If `onboarding-implausible-change` / `-keep` appears, the values were misread: `…-change` and re-type.

**N6 — Activity and goal.**
Do: `id=onboarding-activity-low` → `onboarding-button` → `id=onboarding-goal-maintain` → `onboarding-button`.

**N7 — Other options, with the reminder on (#1391).**
Do: `id=onboarding-daily-reminder` → on (no system dialog, granted in N1) → leave `onboarding-ai-assist` off → `onboarding-button`.

**N8 — Overview and start.**
Do: `st save N8-overview` → read *Ihr Kalorienziel:* → `onboarding-button` → `st wait id=nav-home 20`.
Expect: Home's goal equals the overview's kcal. No demo banner.

**N9 — The reminder went through the scheduler (#1391).**
Do: `st alarms`; Settings → *Tägliche Erinnerung*.
Expect: the switch on, "Erinnerungszeit: 08:00", and an alarm for `$PKG` at the next 08:00. Then R and `st alarms` again: still armed.
Note: before #1391 a start-up refresh could cancel the alarm while the switch read on.

**N10 — Weight history starts at the onboarding weight (#1383).**
Do: You → `profile-weight-history` → `st save N10` → `weight-history-add` → read the field → *ABBRECHEN*.
Expect: one tile, "62 kg", dated day 0, and the chart's empty-state text ("Trage mindestens zwei Tage ein…"). The add dialog opens at `62`. Before #1383 the list was empty and the dialog offered 70 (settings run 2.5d).

**N11 — Saving a goal on an empty day creates the day (#1372) and the fibre default fits the profile (#1380).**
Do: Settings → `settings-nutrient-goals` → read the fibre field → set fibre `43` → `nutrient-goals-save` → reopen → read → `nav-diary` → day 0 → *Heutige Nährstoffe*.
Expect: the fibre field first opens at **25** (a woman of 30, IOM). After saving it reopens at **43**, and the Diary panel shows "/ 43 g". On 2.4.0 a save on a day without a tracked day was lost: it reopened at 30 (settings run, bonus row #1348).

**N12 — A first meal on the fresh profile.**
Do: `fab-add-item` → the suggested tile → `ONT` gets no result (no library) → *Schnelles Tracking* → `ONT Neu`, 400 kcal → submit.
Expect: Home 400 kcal consumed; Diary day 0 lists it; the tracked day is created (no "Nichts hinzugefügt" above the entry).

**N13 — Try Demo.**
Do: export nothing (the profile is a throwaway). `$ADB shell pm clear $PKG` → P11 → `st launch` → `onboarding-checkbox-privacy` → `id=onboarding-try-demo` → `st wait id=main-demo-banner 30` → `st save N13-home` → Diary, Trends, You (`st save` each).
Expect: the banner "Du siehst Beispieldaten" with "Eigenes Profil einrichten"; Home, Diary and Trends filled with sample data; no red screen; `DemoSeeder` lines in logcat (this is the one place they're expected).

**N14 — Leaving the demo.**
Do: tap "Eigenes Profil einrichten" → in the dialog titled "Eigenes Profil einrichten?" tap *Weiter*.
Expect: onboarding's intro again. No sample data survives a new onboarding (checked at R3).

---

## Part 7 — Path 3: restore into a cleared candidate

*Blocks if:* any intake, activity, recipe or weight entry of `base240.zip` is missing or changed after the restore; a second import of the same backup doubles an entry (#1369); importing id-less rows twice doubles them, or two identical rows collapse into one (#1398); the goal settings in `cand.zip` aren't restored (#1381); favourites in `cand.zip` don't come back (#1320); a crash.

**R1 — Clear and onboard a minimal profile.**
Do: `$ADB shell pm clear $PKG` → P11 → onboard as N3–N8 with the S-profile from S1 (gender, birthday, height, 80.4 kg, activity, goal), reminder **off**.
Expect: Home with the goal for that profile and the default goals (kcal adjustment 0, macro 60/15/25, per-meal 30/40/20/10, water 1500 ml).

**R2 — Restore the 2.4.0 backup.** `[picker]`
Do: `st mark R2` → Settings → *App-Daten exportieren / importieren* → `JSON` → *Importieren* → pick `ont-r25-base240.zip` → wait → close → `st errors R2`.
Expect: "Export / Import erfolgreich"; Home and Diary fill in; no red screen.

**R3 — Compare with the baseline.** `[picker]`
Do: export JSON `ont-r25-r3.zip` → pull → `$CMP diff $EVID/exports/base240.zip $EVID/exports/r3.zip > $EVID/exports/R3.txt`.
Expect:
- `intakes`, `activities`, `recipes`, `templates`: `missing 0 changed 0 stored-twice 0`.
- `weight_log`: `missing 0`. Day 0's 80.4 kg comes from the backup, replacing R1's onboarding entry for the same day, and nothing else is extra.
- Tracked days: every line without `NEW tracked != NEW sum` or `row lost`. Today's goal may differ (the import recomputes today's goals for the current profile, #1381).
- No N13 demo row anywhere.
- `goal_settings` in `r3.zip`: kcal adjustment `0`/null, macros null (defaults), per-meal null, water null. **An archive without `goal_settings.json` leaves the device's goals alone**, here the fresh defaults. That is #1381's old-archive rule and expected. It is not data loss: 2.4.0 never exported goals.

Note: a restore after a reinstall now keeps entries but not 2.4.0-era goals. That is the documented limit of a 2.4.0 backup (settings run D6). R9 shows that a 2.5.0 backup brings them back.

**R4 — Import the same backup again: nothing doubles (#1369).** `[picker]`
Do: the same import of `ont-r25-base240.zip` once more → export `ont-r25-r4.zip` → pull → `$CMP diff r3.zip r4.zip`.
Expect: `VERDICT: identical`, apart from today's goal.

**R5 — Id-less rows get derived ids (#1398).** `[picker]`
Do:
1. `st mark R5` → *App-Daten exportieren / importieren* → segment `CSV` → *Importieren* → pick `ont-r25-noid.zip`.
2. Diary → 2026-08-15 (calendar back two months) → `st save R5a`.
3. The same import again → `st save R5b`.
4. Export JSON `ont-r25-r5.zip` → pull → `$CMP summary` → its 2026-08-15 line, and the ids of the three ONT Ohne ID rows in `user_intake.json`.

Expect (fx `noid`):
- After the first import, 2026-08-15 lists three entries: ONT Ohne ID twice (100 g, 200 kcal each) and ONT Ohne ID B (150 g, 150 kcal), 550 kcal in all.
- After the second import, the same three entries: no fourth, fifth or sixth. No "Duplicate keys found".
- The three rows carry three distinct, non-blank ids, and `blank ids: 0`.

Note: before #1398 every import added the rows again with blank ids, and two of them in one meal collided on `ValueKey('')`, the red "Duplicate keys" screen. The day has no tracked-day row until the next launch (the import doesn't reconcile mid-session, a known limit). After one R its line must show 550 = 550.

**R6 — R, then the restored data holds.**
Do: R → `st errors R5` → Home, Diary day 0 − 1 and 2026-08-15.
Expect: unchanged; 2026-08-15 now has a tracked day with 550 kcal (the reconciler at activation).

**R7 — A malformed file is refused without writing (a smoke of #1369's validate-first).** `[picker]`
Do: *App-Daten …* → `JSON` → *Importieren* → pick `ont-r25-seed-recipes.json` (a JSON file, not a zip).
Expect: the red line "Die ausgewählte Datei konnte nicht gelesen werden. Wählen Sie die von OpenNutriTracker exportierte .zip-Sicherung."; Home unchanged.

**R8 — The 2.5.0 backup brings the goals back (#1381).** `[picker]`
Do: `st mark R8` → *App-Daten …* → `JSON` → *Importieren* → pick `ont-r25-cand.zip` → wait → Settings: reopen `settings-kcal-adjustment`, `settings-macro-split`, `settings-per-meal-share` and You → water goal, each read and cancelled.
Expect: kcal adjustment **250**; macro split carbs **45** with the protein and fat values `cand.zip`'s `goal_settings.json` holds (DS4a's round trip may have moved them from S12's); per-meal **25/45/20/10**; water **2600 ml**; Home's goal 250 above R1's. No restart needed: the dialog reloads Settings, Profile, Home, Diary and Trends (`export_import_dialog.dart` `refreshScreens`).

**R9 — Merge by id, and favourites come back (#1369, #1320).** `[picker]`
Do: export JSON `ont-r25-r9.zip` → pull → `$CMP diff $EVID/exports/cand.zip $EVID/exports/r9.zip`; then `fab-add-item` → any meal → the Favourites chip.
Expect:
- `intakes`, `activities`, `recipes`, `templates`: `missing 0 changed 0 stored-twice 0`. The only extras are R5's three ONT Ohne ID rows. Every id that `base240.zip` and `cand.zip` share is stored once.
- `favourites: … new present`, and the Favourites chip lists ONT Linsensuppe rot and the S7 product.

**R10 — A favourite whose library meal is gone keeps its snapshot.** *Skipped on the phone:* it needs a custom meal deleted, which also deletes its diary entries in this profile. Covered by `test/unit_test/favourite_meal_repository_test.dart` (deleted-template fallback) and `favourite_cross_profile_test.dart`.

**R11 — The restored profile is the one the English pass tours.** Nothing to do.

---

## Part 8 — The English pass, then back to German

Switching the language empties the search cache (rule 12); nothing after this Part depends on it. The tour looks for German left in an English UI, raw keys, `{placeholders}`, and text cut off.

*Blocks if:* a screen shows a raw key or a `{placeholder}`; the reminder ignores the language (#1379); clearing the per-app language in Android is undone on the next start (#1230); a crash. German left in the English UI is a ship-with finding.

**E1 — Switch to English.**
Do: Settings → *Sprache* → `English` → OK → `st locale`.
Expect: the UI in English at once; `st locale` prints `en`.

**E2 — Favourites and search (#1320, #1334).** `fab-add-item` → `add-item-breakfast` → chips "Recently", "Favourites", "All", "Products", "Food" → Favourites lists two → type `zzqqx` on Recently (chosen explicitly) → "No results found" with "Search all" → `st save E2`.

**E3 — Shared code dialogs (#1329).** ⋮ on *Dinner* → "Paste code" → "Paste the shared meal code here" → type `keinGueltigerCode` → "Parse" → "Enter a valid shared meal code." → "CANCEL".

**E4 — Meal detail and recipes (#1297, #1376, #1280).** The S7 product: "More Information at OpenFoodFacts", "Micronutrients" (if on), the star "Add to favourites" / "Remove from favourites". Recipes → ONT Bananenbrot → builder: "Total weight (g)", "Entered manually, so changing ingredients won't change it.", "Use ingredient total". BACK (discard if asked).

**E5 — Diary (#1333, #1384).** Sort by "Protein (high to low)": rows read "<n> g protein" (lowercase from the English key). Long-press an entry: the dialog reads "Delete Item?" / "Do you want to delete the selected item?" (the typo fix, #1384). *CANCEL*, delete nothing.

**E6 — Settings (#1384, #1380, #1390, #1332).** Units & energy → "Energy unit" → kJ → "Daily kJ adjustment" (row and dialog) → back to kcal. "Nutrient goals": the fibre description reads "Daily fibre target in grams. Default varies by age and gender (21g to 38g)." The language list scrolls.

**E7 — Activities (#1223, #1415).** `add-item-activity` → "All": swipe through the whole list, saving a dump each screen (`st save E7-<n>`). Then compare the names on the laptop.
Expect: no two rows share a name. Among them: "boxing (punching bag)" next to "boxing", "martial arts (slower pace)", "touch rugby", "vigorous high intensity interval exercise", "track and field (throws)" / "(jumps and javelin)" / "(hurdles)", and "yoga". Durations read "min".

**E8 — Import / export and AI wording (#1381, #1378).** "Export / Import App Data" → CSV: "CSV keeps your activity, meal log and tracked days. Recipes, favourites and any photos you've attached are JSON-only — switch to JSON if you want them in your backup." → close. "AI meal assistance": the subtitle "On — OpenRouter" (if R1 kept the key), "Cancel".

**E9 — Clear the per-app language from Android: it stays cleared (#1230).**
Do:
1. `st mark E9` → `$ADB shell cmd locale set-app-locales $PKG --locales ""` (what *Systemstandard* in Android's app-language page does) → wait 3 s → `st save E9a`.
2. Settings → read the *Sprache* tile.
3. R → `st locale` → `st save E9b`.
4. R once more → `st locale`.

Expect:
- Step 1: the running app follows the device and turns German without a restart.
- Step 2: the tile reads *Systemstandard*.
- Steps 3 and 4: `st locale` prints nothing (no override) after each cold start, and the UI is German.
- 2.4.0 pushed the saved language back on the next start (settings-run row 20, #810).

Note: this is the run's one shell write to app state (rule 2). It only resets this app's own language setting, which a user does in Android's settings, and it leaves the app where the run wants it, German.

**E10 — The reminder follows a language change (#1379), English half.**
Do:
1. Settings → *Sprache* → `English` → OK.
2. *Daily Reminder* → on (if R1 left it off) → `text^=Reminder time:` → text input → T = now + 3 min (`st clock`) → OK → `st alarms`.
3. Wait, polling `st notif` every 20 s until T + 5 min.

Expect: the alarm at T; a notification "OpenNutriTracker" / "Don't forget to log your meals today!" within 3.5 minutes of T (inexact alarm, AOSP window).
Note: nothing arriving by T + 5 with the alarm present is *inconclusive* (delivery is the OS's call). The alarm missing after step 2 is a **fail**.

**E11 — The reminder follows a language change (#1379), back to German.**
Do: Settings → *Language* → *System default* → OK (the device is German) → **no R** → *Tägliche Erinnerung* → T = now + 3 min → OK → poll `st notif` until T + 5.
Expect: the next notification reads "Vergiss nicht, heute deine Mahlzeiten zu protokollieren!". The language switch rescheduled it with German text (settings-run B8: the Italian switch delivered English until R).
Then switch the reminder off and `st alarms`: nothing for `$PKG`.

**E12 — Final state.** `st locale` empty, the UI German, the reminder off, no fast running, `stay_on` etc. untouched. `st save E12-home`, `st shot E12-home`.

---

## Part 9 — Wrap-up and the report

**W1 — Logs.** `st logcat_stop`. Run `st errors` over the whole capture and file every unexplained exception under the step whose mark precedes it.

**W2 — Leave the phone.** The candidate stays installed with the path-3 profile, the device language as found, the maintainer's settings untouched. The run's `ont-r25-*` files stay in Download. The run doesn't delete files on the phone; the maintainer can remove them.

**W3 — Results.** Write `docs/release-tests/2.5.0/results.md` on this branch with the table below, plus a *ship-with* list (each finding with the step, what was seen, and an issue number or "to file") and the *skipped* list with reasons.

| Area | Steps | Verdict | What was seen | Evidence |
| :-- | :-- | :-- | :-- | :-- |
| Preflight & seeding | P, S | | | |
| Path 1 upgrade | U1–U9 | | | |
| Favourites #1320 | DF1–DF7, R9 | | | |
| Shared meal code #1329 / #1294 | DC1–DC6, DC4 | | | |
| Home #1358 #1318 | DH1–DH2 | | | |
| Diary #1333 #1382 #1319 #1385 | DD1–DD3 | | | |
| Add meal #1334 #1282 #1252 #1291 | DA1–DA4, U7 | | | |
| Meal detail #1297 #1376 | DM1–DM2 | | | |
| Custom meals / recipes #1404 #1420 #1280 #1328 | DR1–DR5 | | | |
| Settings #1371 #1273 #1384 #1370 #1372 #1353 #1380 #1390 #1332 | DS1–DS10, N11 | | | |
| Import / export #1369 #1398 #1381 | U8, R2–R9 | | | |
| Weight / profile #1222 #1383 #1419 | DW1–DW3, N10 | | | |
| Notifications #1379 #1391 | U5, N9, E10–E11 | | | |
| Trends #1377 | DT1 | | | |
| AI #1378 + real key | DAI1–DAI3 | | | |
| l10n #1230 #1223 #1415 | DL1–DL3, E7, E9 | | | |
| Smoke areas | K1–K13 | | | |
| Path 2 onboarding + demo | N1–N14 | | | |
| Path 3 restore | R1–R11 | | | |
| English pass | E1–E12 | | | |
| iOS widget #1251 | — | skipped: out of scope, unit tests only | | |

**W4 — Hand-off to [#1438](https://github.com/simonoppowa/OpenNutriTracker/issues/1438).** In the run ticket's resolution comment: the table, every *fail* with its issue, every *inconclusive* with why, and the *skipped* list. A *fail* that meets the bar is a NO-GO, and the run says so plainly.

### Skipped by design, and what covers each

| Item | Why | Covered by |
| :-- | :-- | :-- |
| Camera preview, real barcode and QR decode, shared-QR routing | needs a subject in front of the lens | K3 covers the same lookup by manual entry |
| AI photo | opens the system camera app | DAI2 covers the provider transport |
| Health Connect grant and real import | decided out (#1430); needs a person or the Toolbox | K8 (disclosure); `health_sync_screen_test.dart` |
| The share sheet (*Code teilen*) | leaves the package | DC covers the paste route |
| #1282 partial provider failure | needs one source's network cut | `add_meal_screen_provider_failure_test.dart`, `partial_results_notice_test.dart` |
| #1385 create-if-absent race | needs two writers in a gap | `tracked_day_create_if_absent_test.dart` |
| #1419 time-zone-shifted row | needs a zone change | `delete_weight_log_usecase_test.dart` |
| #1222 DST window (unless day 0 ≥ 2026-10-26) | no transition in the window | `weight_trend_chart_test.dart`, `calendar_day_calc_test.dart` (`just test_dst`) |
| #1391 failed reschedule keeps the alarm | `zonedSchedule` can't be made to throw | `daily_reminder_scheduler_test.dart` |
| #1384 Health *Import now* snackbar | would import real workouts | `health_sync_screen_test.dart` |
| #1328 iOS number pad | iOS | `keyboard_dismisser_test.dart` |
| Favourites across profiles; a deleted meal's snapshot | needs a second profile or a cascading delete | `favourite_cross_profile_test.dart`, `favourite_meal_repository_test.dart` |
| #1251 iOS widget | no Mac or device | its unit tests |
