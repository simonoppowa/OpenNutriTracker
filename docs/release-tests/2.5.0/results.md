# Release 2.5.0: results of the unattended run

The results of [#1434](https://github.com/simonoppowa/OpenNutriTracker/issues/1434) on map [#1425](https://github.com/simonoppowa/OpenNutriTracker/issues/1425), for the go/no-go [#1438](https://github.com/simonoppowa/OpenNutriTracker/issues/1438). The run followed [`script.md`](script.md) Part by Part with the driver [`tools/rt.sh`](tools/README.md). Nobody touched the phone.

| | |
| :-- | :-- |
| Candidate | `develop` at `c293acff4`, debug `full`, APK sha256 `95232d69…a40df0` |
| Baseline | `v2.4.0` (`680eafaa8`), APK sha256 `0cbd3b31…dee6ab`, put back over the settings run's test build in S0a |
| Phone | Pixel 6 `18101FDF60010M`, Android 17, `de-DE`, over USB |
| Run | 2026-10-22 18:04 → 2026-10-23 05:40 CEST, day 0 = 2026-10-22 (the run crossed midnight during DS1) |
| Evidence | `~/Documents/ont-release-2.5.0-evidence/run-20261022-1804/` (`steps.tsv`, `run.log`, `steps/<ID>/`, `exports/`, `logcat/logcat-001.txt`, `findings.md`, `day0.txt`) |
| Steps | 139 step IDs with a final status: **129 pass, 1 fail, 2 inconclusive, 7 skip**. No ABORT, no HALT, no crash, no ANR, no ErrorWidget, and no `EXCEPTION CAUGHT` line for the app in the whole logcat. The key audit is clean. |

## Per area

| Area | Steps | Verdict | What was seen | Evidence |
| :-- | :-- | :-- | :-- | :-- |
| Preflight & seeding | P1–P8, S0a–S16 | **pass** (S8 skipped) | Installed build was the settings run's `17cc4fc9…`. S0a put true 2.4.0 back with the data kept. Seed matched the fixtures to the kcal (days −6…−1, recipes 350/450 g, four weights). `base240.zip` holds no duplicate ids. S8 *skipped*: no backend food can be found in these builds (see *Build gap*). | `steps/S*`, `exports/pre.zip`, `base240.zip` |
| Path 1 upgrade | U1–U9 | **pass** | `install -r` kept the data. First launch clean, no reconciler line. Candidate export vs baseline: missing 0, changed 0, VERDICT identical (after ms-normalised timestamps). Goals in `goal_settings.json`. Reminder re-armed. Recents chronological. Re-import doubled nothing. Two cold starts: no reconciler line. | `exports/U4.txt`, `U8.txt` |
| Favourites #1320 | DF1–DF7, R9 | **pass** | Empty state. A star logs nothing. List newest first. Filter in place. Log from Favourites (+180 kcal). Unstar. Recent-card stars. The favourite followed DR1's rename into `cand.zip` and came back on restore. | `steps/DF*`, `exports/R9.txt` |
| Shared meal code #1329, #1294 | DC1–DC6 | **pass** (DC6 inconclusive) | Invalid code refused, text kept. Code A preview 375/62/250, Total 687, imported +687. Code B: unknown barcode "Unavailable — this item will be skipped.", "Total (incomplete)" 100, only 100 imported. Embedded recipe kept 80 g / 250 kcal per 100 g. DC6: the cached lookup beat the cancel button; ABBRECHEN on the preview imported nothing. | `steps/DC*` |
| Home #1358 #1318 | DH1–DH2 | **pass** | Arc pixel 213,195,182 under goal, then 255,180,171 (M3 error #FFB4AB) at "499 kcal zu viel". OMAD: Frühstück and Snack stay visible without a target; suggested chip on Abendessen. Restored. | `steps/DH*` |
| Diary #1333 #1382 #1319 #1385 | DD1–DD3 | **fail** (DD3 skipped) | DD1 pass ("12,0 g Protein"). DD2.b pass: the Diary opens on the logical day, Home counts the same 2457, and a goal saved lands there. **DD2.c fail**: the 23:00-and-back round trip overwrote 2026-10-14's tracked-day row with 2026-10-13's goals → [#1440](https://github.com/simonoppowa/OpenNutriTracker/issues/1440). Also [#1441](https://github.com/simonoppowa/OpenNutriTracker/issues/1441) (Home vs Diary macro targets). | `exports/DD2.txt`, `dd2a.zip`, `dd2c.zip` |
| Add meal #1334 #1282 #1252 #1291 | DA1–DA4, U7 | **pass** (DA2 skipped) | Recent stays selected while typing; "Search all". Recents chronological. Recents offers the renamed recipe; the old entry is unchanged. DA2 skipped as scripted, but the dead backend produced #1282's "One food source didn't respond…" banner with OFF results still listed. | `steps/DA*`, `steps/DF3/009-*` |
| Meal detail #1297 #1376 | DM1–DM2 | **pass** | No dead button on custom meals or recipes (2.4.0 had it, S14). Micronutrients hidden when off, shown expanded when on. | `steps/DM*` |
| Custom meals / recipes #1404 #1420 #1280 #1328 | DR1–DR6 | **pass** | Rename and barcode change replace the meal; past entries follow; only `meal.name`/`meal.code` changed. Manual 450 g kept on reopen. Macros rebalance on focus loss. Ship-with [#1443](https://github.com/simonoppowa/OpenNutriTracker/issues/1443). | `exports/DR.txt` |
| Settings #1371 #1273 #1384 #1370 #1372 #1353 #1380 #1390 #1332 | DS1–DS10, N11–N12 | **pass** (DS9, DS10 skipped) | Typed value applied on OK (300, 2600). 1255 kJ ↔ 300 kcal. List keeps its place. Cache count fresh. Last row clears the button by 512 px. Imperial serving 0.53 oz. Diary/Trends follow at once. Reset+Save clears (iron 12.5 → 18). Fibre default 25. Comma accepted. Language list fully reachable. Goal on an empty day kept (43). Ship-with [#1444](https://github.com/simonoppowa/OpenNutriTracker/issues/1444) (12.5 reopens as 13). | `steps/DS*`, `N11`, `N12` |
| Import / export #1369 #1398 #1381 | U4, U8, R2–R9 | **pass** | Re-imports idempotent (U8, R4 identical). Id-less CSV rows imported twice → three rows, three distinct derived ids. Non-backup refused. `cand.zip` restores the goals and favourites and merges by id. Note: `cand.zip` carries #1440's corrupted 2026-10-14 row. | `exports/R*.txt` |
| Weight / profile #1222 #1383 #1419 | DW1–DW3, N10 | **pass** (DW3 skipped) | Add dialog starts at w0. Trends shows a new reading at once. History starts at the onboarding weight. Ship-with [#1445](https://github.com/simonoppowa/OpenNutriTracker/issues/1445) (axis labels). | `steps/DW*`, `N10` |
| Notifications #1379 #1391 | U5, N9, E10–E11 | **pass** | Alarm survived the upgrade. Onboarding reminder armed before and after a cold start. Real deliveries: English at 05:17, then German at 05:28 after a switch with no restart. | `steps/E10/notif.txt`, `E11/notif.txt` |
| Trends #1377 | DT1 | **pass** | Renders in kJ and kcal. The tooltip number itself was skipped, as scripted. | `steps/DT1` |
| AI #1378 + the real key | DAI1–DAI3 (+DAI1b, DAI2b) | **pass** (DAI2 inconclusive) | A key from the settings run was stored and the guard kept it; DAI2 got a 401 (inconclusive). Re-run as DAI1b/DAI2b: `type_secret`, consent, "Von KI gelesen — prüfe jede Zeile", database rows only, nothing submitted. Model kept across an address change; refused OK visible. Audit clean. | `steps/DAI*` |
| l10n #1230 #1223 #1415 | DL1–DL3, E7, E9 | **pass** | yoga / rowing machine found. 109 activity rows, no duplicate names. "min". Shipped locales unchanged. A cleared per-app locale sticks across two cold starts. Ship-with [#1442](https://github.com/simonoppowa/OpenNutriTracker/issues/1442) (calendar English, as in 2.4.0) and [#1446](https://github.com/simonoppowa/OpenNutriTracker/issues/1446) ("Page N of 7"). | `steps/E7/E7-titles.txt`, `E9` |
| Smoke areas | K1–K14 | **pass** | Diary navigation, providers, scanner by manual entry, chips, custom meals, recipes, activities, Health Connect disclosure (cancelled, auto-import stays off), fasting (no fast started), Trends ranges, profile, settings dialogs, alarms. K2 *Lebensmittel* is inconclusive (build gap). K12 didn't reach `settings-kcal-goal-info`. | `steps/K*` |
| Path 2 onboarding + demo | N1–N14 | **pass** | `pm clear` with no Health grants. Onboarding total 2203 = Home. First-run *Hinweis* disclaimer (not in the script; confirmed). Demo seeded (21 days) and left cleanly. | `steps/N*` |
| Path 3 restore | R1–R10 | **pass** (R10 skipped) | R-profile 2452 (= 2702 − 250). Restore of `base240.zip` is a superset (only the onboarding weight extra). Goals back at 250 / 45-21-34 / 25-45-20-10 / 2600 without a restart. | `exports/R3.txt`, `R4.txt`, `R9.txt` |
| English pass | E1–E12 | **pass** | No raw keys or placeholders. English strings for every delta screen. #1384's "Do you want to delete the selected item?". Final state: system locale, German, reminder off, device settings untouched. | `steps/E*` |
| iOS widget #1251 | — | skipped | Out of scope; unit tests only. | — |

## Failures that need a ruling (for #1438)

- **[#1440](https://github.com/simonoppowa/OpenNutriTracker/issues/1440) (`backlog:critical`), DD2.c.** Moving *Tag beginnt um* to 23:00 and back overwrote 2026-10-14's stored goals with 2026-10-13's: calorie goal 2743.9 → 3004.6, fibre 44 → 42, nine nutrient goals → null, key re-normalised. Consumed totals are untouched. Both rows were 2.4.0-era rows keyed by clock time, and both fell on one logical day under the moved boundary. Stored goal data corrupted, but narrow trigger. The run doesn't rule.

## Ship-with (filed)

| Issue | Label | Step | Finding |
| :-- | :-- | :-- | :-- |
| [#1441](https://github.com/simonoppowa/OpenNutriTracker/issues/1441) | medium | DD2.b | With a moved boundary, Home and the Diary show different macro targets for the same logical day (330/110/154 vs 372/99/137 g). |
| [#1442](https://github.com/simonoppowa/OpenNutriTracker/issues/1442) | low | S6, U8 | The Diary calendar is English in the German UI (`TableCalendar` without `locale:`). Same on 2.4.0. |
| [#1443](https://github.com/simonoppowa/OpenNutriTracker/issues/1443) | low | DC4 | The recipe builder asks to discard changes when nothing was edited (the imported recipe). |
| [#1444](https://github.com/simonoppowa/OpenNutriTracker/issues/1444) | low | DS7 | A saved iron goal of 12.5 reopens as "13" (display rounding ≥ 10; stored value kept). |
| [#1445](https://github.com/simonoppowa/OpenNutriTracker/issues/1445) | low | DW2, K10 | The Trends weight chart repeats rounded y-axis labels. |
| [#1446](https://github.com/simonoppowa/OpenNutriTracker/issues/1446) | low | N4 | Onboarding's "Page N of 7" is English in the German UI. |

Expected and noted only (the script's *Known* list): English-only new strings (Favourites, the shared-meal preview, "Search all", the recipe weight helper, "Daily kJ adjustment", new activity names); stale German (the fibre "Standardreferenz: 30 g", the CSV note without favourites).

## Inconclusive

- **DC6:** the barcode lookup was cached, so the cancel button never showed. Covered by `shared_meal_import_test.dart`.
- **DAI2:** the stored settings-run key was rejected (401). Superseded by DAI2b (pass) with the run's own key.
- **K2 *Lebensmittel*** and **DAI2b's row quality:** limited by the build gap.

## Skipped

S8 (no backend food, build gap); DA2, DD3, DS10, DW3, R10, DS9 (→ N11) as scripted. The script's *Skipped by design* table still holds: camera/QR, AI photo, the Health Connect grant and import, the share sheet, #1282's network cut, #1385's race, #1419's delete, #1222 DST (day 0 < 2026-10-26), #1377's tooltip number, #1391's failed reschedule, iOS.

## Build gap (affects the coverage, not the verdict)

Both debug APKs were built with `.env.example` as `.env` ([#1431](https://github.com/simonoppowa/OpenNutriTracker/issues/1431)), so the Supabase URL is the literal `PROJECT_URL`. Every BLS/FDC search and the portion RPCs fail ("No host specified in URI PROJECT_URL/rest/v1/rpc/search_food_translation"). Uncovered as a result:
- backend food search on the phone (S8, K2 *Lebensmittel*);
- portion resolution in the AI flow ("2 Eier" stayed 2 g);
- the U7/DA/DR expectations that used S8's food.

Open Food Facts, the library, recipes and everything local ran normally. A release build has a real `.env`; this run doesn't vouch for the backend.

## Judgement calls during the run

- **S0a** ran as the pre-start amendment says (`17cc4fc9…` → `0cbd3b31…`).
- **DAI1b/DAI2b**: the DAI1 guard kept a stale key that was rejected. The run removed it (the install was going to be `pm clear`ed in Part 6 anyway) and saved the key file's key through `type_secret`. The script now says so.
- **DD2.b**: the script expected midnight seeds to roll back a day. The code keeps day labels on their date by design (`DayBoundaryCalc.dayLabelOf`), so the expectation was corrected and the step judged on the logical-day behaviour.
- **After midnight**: day 0 stayed 2026-10-22. DS1/DS4 judged "today" on 2026-10-23, and DS5's Reset+Save was decided by DS7's reset of a saved 12.5.
- **DC5, E3**: `intake-section-menu@K` counts on-screen nodes only, so the Snack menu was `@2` after scrolling; E3 used Breakfast's (empty) menu.
- **N3–N8, N13, R1**: a first-run *Hinweis* disclaimer appears after onboarding/demo; it was read and confirmed.
- **Input artefact**: Gboard autocorrected the typed "Gemuesecurry scharf" to "Gemüsecurry scharf" (DA4); later name checks use what the app saved.

## Driver and script fixes made during the run

All on `research/release-2.5.0-pixel-test`, each with the self-test at 129/129:
- `rt clock` quoting for `adb shell`;
- `scroll_to` heads towards a target already above the window first (saved ~5 min per call);
- the add sheet, full-height since #1320, reads as a modal, so `back` closes it;
- a tall merged text field is tapped on its value box (nutrient goals; the centre landed on the description);
- `compare_exports.py` compares timestamps to the millisecond (Hive vs in-memory microseconds made every same-session record read as "changed");
- the script names the save picker's filename box `edit=1` (`id=android:id/title` hit the first folder);
- the script's DD2.b and DAI1 texts were corrected.
