# Settings test script: every setting on the Pixel 6, row by row, over adb

Asset of [#1343](https://github.com/simonoppowa/OpenNutriTracker/issues/1343), part of the settings map [#1338](https://github.com/simonoppowa/OpenNutriTracker/issues/1338). It is built from [the inventory](inventory.md) (45 rows), [the user reports](user-reports.md), the pass bar in [#1340](https://github.com/simonoppowa/OpenNutriTracker/issues/1340) and the phone-state decision in [#1341](https://github.com/simonoppowa/OpenNutriTracker/issues/1341). Every id and label below was read from `origin/develop` at `05fcce7e`. `lib/features/settings` there is identical to `v2.4.0`, the build that goes on the phone. `v2.3.0` differs by the grams-first switch (row 5), the export error text and two more languages (Magyar, Español), so every row of the upgrade leg exists in both builds.

The session runs this script over adb. The maintainer steps in only where a step says **HAND-OFF**.

## How to read and run it

**Commands.** Run everything from the root of a worktree on `research/settings-pixel-test`. The helper `docs/settings-test/tools/st.sh` is the driver, one action per call:

```bash
ST="bash docs/settings-test/tools/st.sh"   # written out in full in each call; shell state does not persist
ADB=~/Android/Sdk/platform-tools/adb       # raw adb, only for install / uninstall / pm clear / pull; always -s 18101FDF60010M
```

In this script `st tap id=…` means `bash docs/settings-test/tools/st.sh tap id=…`. Selectors: `id=` a `resource-id` (a `Semantics(identifier:)`), `text=` an exact label, `text^=` a label prefix (Flutter merges a tile's title and subtitle into one `content-desc`, `"Food units\nMetric (g, kg, ml, l)"`, so tiles are matched by their title), `text~=` a fragment, `edit=N` the N-th text field from the top. Append `@K` for the K-th match. `st ls` prints every node as `x,y  resource-id | label  {flags}`, and `{checked}` or `{unchecked}` shows a switch's state.

**The guard.** Every `st` action that touches the screen re-reads `mCurrentFocus` and exits **99** if the focused window is not `com.opennutritracker.ont.opennutritracker`. On 99: stop, read the screenshot it saved, press nothing, tell the maintainer. During a HAND-OFF the session does not drive. It waits for the maintainer to say "done" in chat, then runs `ST_HANDOFF=1 st focus` and carries on only when focus is back in the app.

**Never** send HOME (the helper refuses keycodes 3, 187, 26, 223 and 276). Never open Android Settings or the clock, and never tap a link that leaves the app: privacy policy, "Learn more", source code, the ⓘ buttons on Food databases, or Report Error's OK. Never tap **Try Demo** (`onboarding-try-demo`). Never open *Switch profile*, *Add profile* or *Manage profiles*. Do not dump or screenshot while the maintainer is typing the AI key.

**R** means a cold restart: `st restart` (`am force-stop`, `am start -W`, two warm-up dumps, wait for `nav-home`). "Before R" checks happen in the same process, without leaving the app. Tab switches don't reload anything (the tabs sit in an `IndexedStack`), so they don't hide a missing reload. **After every R, open Trends once before changing a setting.** A Trends check is only a staleness test if Trends had already loaded.

**Settings** is the collapsed card at the bottom of **You**. `st open_settings` taps `nav-you`, scrolls to the card and expands it. Rows further down are reached with `st scroll_to id=…` or `st scroll_to "text^=…"`. Watch for the *You* list jumping after a toggle (inventory B10: every toggle reloads Settings through a loading state). A jump that hides whether a toggle took is a Note with a screenshot. With the app in German (the upgrade leg before U1, the per-app-locale hand-off in row 20), prefix calls with `ST_SETTINGS_LABEL=Einstellungen`.

**Typed dialogs run twice** (#1340): *OK only* (type, tap OK, no Done), then *Done + OK* (type, `st done`, tap OK). `st done` sends `KEYCODE_ENTER`, which Flutter's text input turns into the field's Done action. Step 2.4 proves that on the phone before any row relies on it. Clear a field before typing: `st field edit=1 300` taps it, deletes 12 characters and types.

**Sliders** are tapped at a fraction of the track: `st slider id=… 0.65`. Read the value back from the dialog's field or label. If it is a step off, tap again with a corrected fraction. Write down the exact value that landed. That value is what must come back after R.

**Evidence.** Before each row, `st mark "row 7"`. After it, `st errors "row 7"` prints any Flutter exception, failed assertion or crash logged since the mark, and any line there is a **fail**. Screenshots are `st shot <row>-<step>` (e.g. `07-home-before`), and dumps are `st save <row>-<step>`. Both land in the run's evidence folder, which `st init` pins in preflight.

**Verdicts** (#1340). *pass*: the value sticks across R **and** the effect shows at the consumer; for a flagged row, at every consumer, before and after R. *fail*: the value doesn't stick, an effect is missing (even only until R), there is a crash or logged exception, or the control can't be operated. *inconclusive*: the evidence doesn't decide. *skipped*: not run, with the reason. *reference → #N*: a known bug, not re-run. *Note* (no fail): untranslated text, overflow that still works, unclear wording. A row fails only when the user's intent is lost.

**Known bugs are referenced at the check that hits them.** #1347 (typed value dropped on OK) is the *OK only* half of rows 7, 10 and 42. #1348 (no save on a day without an entry), #1349 (Reset + Save) and #1316 (next day) are three checks of row 10. #715 is the per-meal sliders, #1331 the languages below the fold, #1306 water under imperial, #1315 the "kcal" on meal headers in kJ mode, #1253 a Gemini `AQ…` key, #763 an export onto an existing file name, and #765 the theme-change assertion. Those checks are written as `reference → #N` and not run. The rest of each row runs. The brief allowed that split explicitly for #1347 and #1348. Applying it to the others is this script's choice: theme, language, energy unit, per-meal share and water would otherwise go without a verdict. The theme switch is still made once to test that it persists. If the #765 red screen appears on that one switch, record `fail → #765` and R. Don't repeat the switch to provoke it.

**The 13 flagged rows** are the rows behind the inventory's persistence suspects (A1–A10) and effect suspects (B1–B10): **4, 7, 7b, 8, 10, 11, 13, 15, 20, 24, 34, 37, 42**. Each is checked at every consumer the inventory lists, before and after R. Section 3A runs them first, in inventory order, apart from 11 (slow, section 4) and 34 (destructive, section 5).

**Order.**

| Section | Rows |
| :-- | :-- |
| 0 Preflight | — |
| 1 Upgrade leg 2.3.0 → 2.4.0 | U1–U9 |
| 2 Main run setup | baseline B |
| 3A Flagged rows | 4 (+ pair K), 7, 7b, 8, 10, 13, 15, 20, 24 (+ 43), 37, 42 |
| 3B Other non-destructive rows | 1, 2 (+ P4), 3 (+ pair I), 5, 6, 9, 12, 14, 16, 17, 18, 19, 23, 25, 26, 27, 28 (+ 44), 29, 30, 31, 38, 39, 40, 41, P1, P2 |
| 4 Slow rows | 21, 22, 11 |
| 5 Destructive rows, behind the export | 33, 34, 32, 35, 36, D6 |
| 6 Wrap-up and report | — |

Reckon on four to five hours, plus the waits in section 4.

---

## 0. Preflight

**0.1 Device.** `$ADB devices -l`. **Expect:** `18101FDF60010M  device … model:Pixel_6`, possibly a second `adb-18101FDF60010M-… (2)._adb-tls-connect._tcp` entry for the same phone. Every command passes `-s 18101FDF60010M`. **Stop if** the USB serial is missing or `unauthorized`. HAND-OFF: the maintainer reconnects or accepts the USB-debugging prompt.

**0.2 Installed build.** `st version`. **Expect:** `versionCode=66 … versionName=2.4.0`, the leftover from the 2.4.0 release test. It holds no personal data (#1338), so section 1 uninstalls it without a backup.

**0.3 APKs.** `ls -l ~/Documents/ont-settings-test-evidence/apks/` and `sha256sum` both files into the run log. **Expect:** `ont-full-2.3.0-65-debug.apk` and `ont-full-2.4.0-66-debug.apk`, both signed with the debug key `0bdae1d6…5ff5` (#1346), so `install -r` is an in-place upgrade.

**0.4 Evidence and logcat.** `st init` (pins `~/Documents/ont-settings-test-evidence/run-<date-time>/`), then `st logcat_start`. Every later `st` call writes into that folder.

**0.5 Clock and screen.** `st clock`. Write down the time. Section 4's day-boundary row needs the current hour to be **22 or earlier** when it runs, so if the run will reach section 4 after 22:00, run 4.2 the next day before 22:00. The 15-minute waits in 4.1 will let the screen sleep: tell the maintainer before 4.1 starts, so the wake-up hand-off is expected. Keep the phone unlocked on the desk. If the screen sleeps, the guard sees the keyguard and stops. HAND-OFF: the maintainer wakes and unlocks it. The session never sends POWER or WAKEUP and never changes the screen timeout.

**0.6 Keyboard probe.** `$ADB -s 18101FDF60010M shell dumpsys input_method | grep -c mInputShown`. **Expect** `1` or more. `st kb_hide` relies on that line; if it is missing, use `st back` only after a screenshot shows the keyboard.

**0.7 Phone language.** The phone stays **German**. System dialogs (permission sheet, file picker, Health Connect) show German labels. The app is switched to English in U1 and in 2.3.

---

## 1. Upgrade leg: v2.3.0 → 2.4.0 (#1341)

Nine settings across five groups, chosen from the persistence suspects and from both stores (device-wide `AppConfigBox` and the per-profile `ConfigBox`). All nine exist in 2.3.0.

**1.1 Install 2.3.0.**
`$ADB -s 18101FDF60010M uninstall com.opennutritracker.ont.opennutritracker`
`$ADB -s 18101FDF60010M install ~/Documents/ont-settings-test-evidence/apks/ont-full-2.3.0-65-debug.apk`
If Google Play Protect puts up a dialog about the debug-signed APK, that is a **HAND-OFF**: the maintainer decides (install anyway or stop). `st version` → **Expect** `versionCode=65`, `versionName=2.3.0`. `st locale` → note what it prints (the per-app locale should be empty after an uninstall).

**1.2 Onboard (German UI).** `st launch`, then:
1. `st wait id=onboarding-checkbox-privacy 20` → `st tap id=onboarding-checkbox-privacy` (only this box; leave `onboarding-checkbox-data` unticked) → `st tap id=onboarding-button`.
2. `st tap id=onboarding-gender-genderFemale` → `st tap id=onboarding-birthday-field` → date picker: `st tap text=OK` (accepts the default, today minus 30 years) → `st tap id=onboarding-button`.
3. `st field id=onboarding-height-field 170` → `st field id=onboarding-weight-field 65` → `st kb_hide` → leave the target weight empty → `st tap id=onboarding-button`.
4. `st tap id=onboarding-activity-active` → `st tap id=onboarding-button`.
5. `st tap id=onboarding-goal-maintain` → `st tap id=onboarding-button`.
6. Other options: change nothing → `st tap id=onboarding-button`.
7. Overview → `st tap id=onboarding-button` → the disclaimer: `st tap "text=Ich habe verstanden"`. (On 2.4.0 with the app in English it reads "I understand".)

**Expect:** `nav-home` on screen, UI in German. If any other first-launch dialog appears, `st ls`, record its text, close it with its own button.

**1.3 Change the nine settings, on 2.3.0.** For each one, write down exactly what the screen shows afterwards.

| # | Setting (group, store) | Do | Value to see |
| :-- | :-- | :-- | :-- |
| U1 | Language (Appearance, device-wide + Android per-app locale) | `ST_SETTINGS_LABEL=Einstellungen st open_settings` → `st scroll_to "text^=Sprache"` → tap it → `st tap text=English` → `st tap text=OK` | UI turns English at once; the row reads "Language / English"; `st locale` → `en` |
| U2 | Daily kcal adjustment (Goals, per-profile) | `st scroll_to id=settings-kcal-adjustment` → tap → `st field id=kcal-adjustment-input 300` → `st done` → `st tap id=kcal-adjustment-save` | Reopen: field `300`. CANCEL. |
| U3 | Macro split (Goals, per-profile) | `st tap id=settings-macro-split` → `st ls` and note the three fields (expected 60 / 15 / 25) → `st field edit=1 50` → `st tap id=macro-split-save` (OK only; #525 applies pending text) | Reopen: **50 / 19 / 31** (from 60/15/25: protein 15 → 18.75, fat 25 → 31.25, rounded to sum 100). If the start was not 60/15/25, compute it the same way. CANCEL. |
| U4 | Per-meal kcal share (Goals, per-profile) | `st tap id=settings-per-meal-share` → `st tap id=meal-share-preset-mediterranean` → `st tap id=meal-share-save` | Reopen: Breakfast 25 %, Lunch 45 %, Dinner 20 %, Snack 10 %. CANCEL. |
| U5 | Food units (Units, device-wide) | `st tap id=settings-food-units` → `st tap "text=Imperial (lbs, oz, fl oz)"` → `st tap text=OK` | Row subtitle "Imperial (lbs, oz, fl oz)" |
| U6 | Body weight unit (Units, device-wide) | `st tap id=settings-body-weight-unit` → `st tap text=st` → `st tap text=OK` | Row subtitle "st"; You → `profile-weight` reads **10 st 3.3 lbs** (65 kg) |
| U7 | Energy unit (Units, device-wide + provider) | `st tap id=settings-energy-unit` → `st tap "text=Kilojoules (kJ)"` → `st tap text=OK` | Subtitle "Kilojoules (kJ)"; `home-kcal-gauge` desc contains "kJ left" (the node also carries a hint, so match by fragment) |
| U8 | Show Meal Macros (Display, device-wide) | `st scroll_to "text^=Show Meal Macros"` → tap it | `{unchecked}` |
| U9 | Accent colour (Appearance, device-wide, two unawaited writes) | `st tap id=settings-accent-colour` → `st tap id=accent-preset-13` (violet `#8E24AA`) → `st back` | Subtitle "Custom"; `st shot U9-home` on Home; `st pixel U9-home <x> <y>` at the `fab-add-item` centre gives a hue of roughly 270–300 |

`st save U-before` on the Settings list, and `st shot U-before`.

**1.4 Cold restart on 2.3.0.** `st restart`, then re-check all nine as in the table: open each dialog, read it, CANCEL. For U2, the field now shows **1255** with suffix kJ, because U7 switched units (300 kcal × 4.184 = 1255.2). That is the same value in kJ, not a change.
**Fail if** any value differs (that is a 2.3.0 persistence fail; record it, but the leg goes on).

**1.5 Upgrade in place.** `st mark "upgrade"` → `$ADB -s 18101FDF60010M install -r ~/Documents/ont-settings-test-evidence/apks/ont-full-2.4.0-66-debug.apk` → Play Protect again possible: HAND-OFF as in 1.1. `st version` → **Expect** `66` / `2.4.0`. `st launch`.

**1.6 Verify after the upgrade.** All nine again, same reads, plus:
- U1: the app starts in English without being touched, and `st locale` still prints `en`.
- U7: the Home gauge says "kJ left".
- U8: Home meal headers carry no "… c  … f  … p" line.
- U9: `st shot U9-after` and `st pixel` at the FAB: the same hue as before.
- New in 2.4.0: `settings-default-raw-food-units` exists and is `{unchecked}` (null reads as off).
- `st errors upgrade` is empty.

**Verdict per U-row:** *pass* if the value is identical after R on 2.3.0 and after the upgrade. *fail* if either differs. The upgrade leg is the only check of the 2.3.0 → 2.4.0 migration, so a fail here goes in a new issue.

---

## 2. Main run setup (#1341)

**2.1 Fresh state.** `$ADB -s 18101FDF60010M shell pm clear com.opennutritracker.ont.opennutritracker` → `st locale` → note whether `en` survived `pm clear`. → `st launch`.
If the app comes up in English, the per-app locale survived the clear (`reconcileAppLocale` copied it into Hive). That's a note, not a fail. Use the English labels below.

**2.2 Onboard by hand**, exactly as 1.2. Privacy box only, so crash reports start **off** (row 37 needs that). Female, default birthday, 170 cm, 65 kg, no target weight, Active, Maintain, defaults on page 5. **Not** Try Demo.

**2.3 App language English.** As U1 (German labels, `ST_SETTINGS_LABEL=Einstellungen`). Skip it if 2.1 already came up English. **Expect** `st locale` → `en`.

**2.4 Does `st done` fire Done?** `st open_settings` → `st scroll_to id=settings-kcal-adjustment` → tap → `st field id=kcal-adjustment-input 5000` → `st done` → `st get id=kcal-adjustment-input`.
**Expect** `1000`, because `_applyKcalInput` clamps to ±1000 and runs only on Done. Then `st tap text=CANCEL`, which writes nothing.
If the field still reads `5000`, ENTER is not reaching the action. From here on, every *Done + OK* step instead takes `st shot`, finds the keyboard's ✓ key and uses `st tapxy` on it. Record that in the run log.

**2.5 Give the consumers something to show.**
- **a. Open Food Facts item (Breakfast).** `st tap id=fab-add-item` → `st tap id=add-item-breakfast` → `st tap text=Products` → `st tap id=meal-search-field` → `st type nutella` → `st tap id=meal-search-submit` → `st wait "text~=Open Food Facts" 20` → `st ls`. Choose the first card whose label contains "Open Food Facts" **and** a serving size, and tap the `meal-item-add` on its row (`@K`).
  On the product screen, write down (i) the **Unit** dropdown's starting value, a "Serving (…)" entry being the baseline for row 5, and (ii) whether a **Micronutrients** section is listed, the baseline for row 14.
  Then `st field edit=1 100`, set Unit to **g** (tap the Unit dropdown → `st tap text=g`) → `st tap id=meal-detail-add` (if "already been added" appears, `st tap text=Add`).
  **Expect** the snackbar "Added new intake". Write down the product name and brand.
- **b. Custom item (Lunch, quick add).** `st tap id=fab-add-item` → `st tap id=add-item-lunch` → `st tap id=add-meal-quick-add` → `st field id=quick-add-title "ST custom"` → `st field id=quick-add-energy 500` → `st field id=quick-add-carbs 60` → `st field id=quick-add-fat 20` → `st field id=quick-add-protein 25` → `st kb_hide` → `st tap id=quick-add-submit`. This stores an intake with source *custom*.
- **c. Activity.** `st tap id=fab-add-item` → `st tap id=add-item-activity` → `st tap id=add-activity-quick-add` → `st field id=quick-add-activity-name "ST walk"` → `st field id=quick-add-activity-energy 200` → `st field id=quick-add-activity-duration 30` → `st kb_hide` → `st tap id=quick-add-activity-submit`.
- **d. A second weight (yesterday)**, so Trends and the weight chart have a trend. `st tap id=nav-you` → `st tap id=profile-weight-history` → `st tap id=weight-history-add` → `st tap text^=Date` → in the date picker tap yesterday's day cell (`st tap "text^=<d>,"`: a day cell's label is "<d>, <weekday>, <full date>"; if yesterday is in last month, tap the "previous month" arrow first) → `st tap text=OK` → `st field id=weight-history-weight-input 65.8` → `st kb_hide` → `st tap text=OK`.
  **Expect** two rows, 65 kg today and 65.8 kg yesterday. `st back`.

**2.6 Baseline "B".** Record every value below in the run log. Later rows compare against it.
- **Home:** `st get id=home-kcal-gauge` → "**L0** kcal left". Macro tiles "x/**C0** g", "x/**F0** g", "x/**P0** g" (`st ls`). The four meal headers "consumed / **target** kcal" plus the "… c  … f  … p" line under Breakfast and Lunch.
- **Kcal goal info:** `st tap id=home-kcal-gauge` → `st save B-goalinfo` → TDEE, "Daily kcal adjustment" (0), total **G0** → `st back`.
- **Diary:** `st tap id=nav-diary` (today is selected) → day line "a/**DG0** kcal", macro view "x/y g" ×3. Expand `st tap "text=Today's nutrients"` → fibre "… / 30g", iron "… / 18mg" (female default), sodium, and the other rows → `st save B-diary`.
- **Trends:** `st tap id=nav-trends` → "Daily average" rows "x / y g" → `st shot B-trends` (calorie chart and weight card).
- **You:** `profile-weight` "65 kg" (with the yesterday entry the subtitle may show a trend), `profile-height` "170 cm", `profile-water-goal` "**W0** ml", `profile-activity` "Active", `profile-goal` "Maintain Weight".
- **Settings:** `st open_settings`, then `st save B-settings-1`, swipe, `st save B-settings-2`… until the version banner "2.4.0". That gives every subtitle and switch state.
- **R**, then repeat the Home and Settings reads. **Expect** them unchanged, which shows a freshly onboarded profile persists.

---

## 3A. Flagged rows (every consumer, before and after R)

### Row 4: Energy unit, kcal / kJ [flagged: B4] + pair K (kJ × typed goals)

*Ids:* `settings-energy-unit`; dialog radios "Kilocalories (kcal)" / "Kilojoules (kJ)", OK. *DE:* "Energieeinheit", "Kilojoule (kJ)".
*Consumers:* Home gauge and supplied/burned stats (`EnergyUnitProvider`), Diary day line, Trends calorie chart (suspect B4), quick-add and activity sheets, the kcal adjustment dialog, meal headers (#1315).

**Do.** `st mark "row 4"` → Trends visited since the last R? If not, `st tap id=nav-trends` once. → `st open_settings` → `st tap id=settings-energy-unit` → `st tap "text=Kilojoules (kJ)"` → `st tap text=OK`.

**Expect, before R** (no restart, no leaving the app):
1. Settings subtitle "Kilojoules (kJ)".
2. Home `home-kcal-gauge` desc "**N** kJ left" with N = L × 4.184 (±5: the gauge truncates the unrounded value), where L is the kcal value just before the switch. The supplied and burned stats are in kJ too.
3. Diary day line "a/g **kJ**", with g = DG × 4.184.
4. Trends: tap a point on the Calories chart and `st shot 04-trends-before`. **Expect** the tooltip in kJ (today's kcal × 4.184). The inventory expects raw kcal here (`trends_page.dart:267`, `:299`).
5. `st tap id=fab-add-item` → `st tap id=add-item-snack` → `st tap id=add-meal-quick-add` → the energy field label reads "Energy (kJ)" → `st kb_hide` → `st back` → `st back` → `st has id=nav-home`. (The sheets autofocus a field, so the first BACK would only close the keyboard.) Same for `add-item-activity` → `add-activity-quick-add`: the energy label is in kJ.
6. `settings-kcal-adjustment` dialog: heading "Daily kJ adjustment:", suffix kJ → CANCEL.
7. Meal headers: reference → #1315 (they still say "kcal"; not judged here).

**R**, then **expect after R:** 1–6 again, identical.

**Pair K: kJ × typed goals** (still in kJ mode):
- **K1, kcal adjustment typed in kJ, Done + OK.** `st tap id=settings-kcal-adjustment` → `st field id=kcal-adjustment-input 1674` → `st done` → `st get id=kcal-adjustment-input` → `1674` → `st tap id=kcal-adjustment-save`.
  **Expect** Home "kJ left" up by ≈1674 against the value before. Kcal goal info: "Daily kcal adjustment" **+1673 kJ** (1674 / 4.184 = 400.1 → stored as 400 kcal; this screen truncates 400 × 4.184 = 1673.6, while the dialog rounds it to 1674). Reopen the dialog: `1674`. R → reopen: `1674`.
- **K1, OK only:** reference → #1347 (not run).
- **K2, truncation probe (Note only).** Same dialog, `st field id=kcal-adjustment-input 1255` → `st done` → save → reopen.
  **Expect** `1251`, not `1255`. `_save` stores `toInt()` (299.95 → 299 kcal) and 299 × 4.184 = 1251. That's a Note, not a fail: 4 kJ, under 1 kcal.
- **K3, macro split typed in kJ mode.** `st tap id=settings-macro-split` → note the three values → `st field edit=1 55` → `st tap id=macro-split-save` (OK only). Then `st tap id=settings-macro-split` → `st field edit=2 20` → `st done` → `st tap id=macro-split-save` (Done + OK).
  **Expect** after the OK-only save: reopen shows **55 / 17 / 28** from 60/15/25 (the other two fields only re-sync on submit, so before OK they still read 15 and 25; that is not drift). After the Done + OK save: **53 / 20 / 27**. Home macro tiles are in **g** and match goal × pct / 4 (carbs, protein) or / 9 (fat), the goal taken in kcal.
- **Clean up.** Kcal adjustment dialog: tap `text=Reset` → `st tap id=kcal-adjustment-save` (back to 0). Energy unit → "Kilocalories (kcal)" → OK. **Expect** Home "kcal left" equal to L0 again (if nothing else was logged).

**Fail if:** any of 1–6 is missing before R or after R; the Trends tooltip is not in kJ (B4, a new issue: it's not #1315); K1 doesn't come back as 1674 / 400; K3 values drift.
**Note:** K2 truncation; any "kcal" left in kJ mode outside the meal headers.

### Row 7: Daily kcal adjustment [flagged: A1, B3]

*Ids:* `settings-kcal-adjustment` → `kcal-adjustment-input`, `kcal-adjustment-slider`, `kcal-adjustment-save`, `text=Reset`, `text=CANCEL`. *DE:* "Tägliche kcal-Anpassung".
*Consumers:* Home gauge (`home_bloc.dart:167`), kcal goal info (row 6), Diary day goal (today's tracked day via `CalendarDayBloc`, not reloaded: B3), Trends goal line (B3). Range ±1000 kcal in 200 steps of 10.

**OK only (type 300, OK):** reference → #1347 (not run).

**Do, Done + OK.** `st mark "row 7"` → Trends loaded since the last R → note L (Home), DG (Diary day goal) and `st shot 07-trends-pre` → Settings → `st tap id=settings-kcal-adjustment` → `st field id=kcal-adjustment-input 300` → `st done` → `st tap id=kcal-adjustment-save`.

**Expect, before R:**
1. Reopen the dialog: field `300` → CANCEL.
2. Home: "L+300 kcal left".
3. Kcal goal info: "Daily kcal adjustment" +300, total G+300.
4. Diary, today: day line goal **DG+300**. The inventory expects it unchanged until resume (B3).
5. Trends: `st shot 07-trends-before`. Compare the calorie chart's goal line with `07-trends-pre`: it should have moved up. If the chart can't show it, write *inconclusive* for this consumer.

**R**, then **expect after R:** 1–4 again (all +300), and Trends (visit it fresh) `st shot 07-trends-after`.

**Do, slider.** `st tap id=settings-kcal-adjustment` → `st slider id=kcal-adjustment-slider 0.75` → `st get id=kcal-adjustment-input` → should read `500` (correct by ±10-steps if not) → `st tap id=kcal-adjustment-save`.
**Expect** 1–5 with +500 before R, and 1–5 after R (Trends visited fresh). Leave it at **+500**; rows 6 and 9 read it.

**Fail if:** the value isn't there after reopen or R; Home doesn't move; the Diary or Trends goal stays old before R (B3: effect missing until restart).
**Note:** discussion #652, a floor on the total goal at very negative adjustments, is out of scope here.

### Row 7b: Calorie reference, non-binary only, inside the kcal dialog [flagged: A9]

*Ids:* You → `profile-gender` → dialog `text=non-binary`; kcal dialog tile `text^=Calorie reference` → radios "Averaged reference (default)" / "Estrogen-typical reference" / "Testosterone-typical reference", OK. You → `profile-calories-profile`. *DE:* "Kalorienreferenz", "nicht-binär".
*Consumers:* `GetKcalGoalUsecase` → Home gauge, kcal goal info; today's tracked day → Diary day goal (through `ProfileBloc.updateUser`, which reloads Home, Diary, CalendarDay and Trends).

**Do.** `st mark "row 7b"` → `st tap id=nav-you` → `st tap id=profile-gender` → `st tap text=non-binary`. Note Home L_nb and Diary DG_nb (the goal changes with the gender). → Settings → `st tap id=settings-kcal-adjustment` → `st tap "text^=Calorie reference"` → `st tap "text=Testosterone-typical reference"` → `st tap text=OK` → back in the kcal dialog, **`st tap text=CANCEL`**.

**Expect, before R:**
1. You → `profile-calories-profile` reads "Testosterone-typical reference".
2. Home goal ≠ L_nb (written on pick, `kcal_adjustment_dialog.dart:109`).
3. Kcal goal info total changed by the same amount.
4. Diary day goal changed by the same amount.

**R**, then **expect after R:** 1–4 the same.

**Clean up.** `st tap id=profile-calories-profile` → "Averaged reference (default)" → OK → `st tap id=profile-gender` → `st tap text=female`. **Expect** Home back to the value from before this row.

**Fail if:** the pick doesn't persist, or Home/Diary don't follow it.
**Note:** Cancel on the outer dialog doesn't undo the pick (A9). It's recorded as a Note; the user's intent there is ambiguous.

### Row 8: Macro split [flagged: B3]

*Ids:* `settings-macro-split` → sliders `macro-split-carbs`, `macro-split-protein`, `macro-split-fat`; the three text fields have no id (`edit=1` carbs, `edit=2` protein, `edit=3` fat); `macro-split-save`; `text=Reset`. *DE:* "Makro-Aufteilung".
*Consumers:* Home macro tiles "x/goal g" (reloaded); Diary macro view "x/goal g" (today's tracked day, not reloaded: B3); Trends "Daily average" "x / goal g" (B3).

**Do, OK only.** `st mark "row 8"` → Trends loaded since the last R → note Home, Diary and Trends macro goals → `st tap id=settings-macro-split` → `st tap text=Reset` → `st tap id=macro-split-save` (start from 60/15/25) → `st tap id=settings-macro-split` → `st field edit=1 50` → `st tap id=macro-split-save`.

**Expect, before R:**
1. Reopen: **50 / 19 / 31** → CANCEL.
2. Home tiles: carbs goal = ⌊G × 0.50 / 4⌋, protein ⌊G × 0.19 / 4⌋, fat ⌊G × 0.31 / 9⌋, where G is the kcal goal from kcal goal info (±1 g).
3. Diary macro view: the same three goals.
4. Trends "Daily average": today's goals are averaged into the three "/ y g" values, so y moves.

**R**, then **expect after R:** 1–4.

**Do, Done + OK.** `st tap id=settings-macro-split` → `st field edit=2 25` → `st done` → `st ls` shows **46 / 25 / 29** in the fields → `st tap id=macro-split-save`. **Expect** 1–4 with 46/25/29, before and after R.

**Do, slider (control).** `st slider id=macro-split-protein 0.235` (5 + 0.235 × 85 ≈ 25) → read the three fields → OK → reopen shows them.

**Fail if:** typed values are lost (#517 regression); Diary or Trends lag before R (B3).
**Note:** the 5 % floor and the rebalancing are by design (#642).

### Row 10: Nutrient goals [flagged: A2, A3, A4, B6]

*Ids:* `settings-nutrient-goals` → `nutrient-goals-save`, `nutrient-goals-reset`, sliders `nutrient-fibre-slider`, `nutrient-sat-fat-slider`, `nutrient-sugars-slider`, `nutrient-sodium-slider`, `nutrient-calcium-slider`, `nutrient-iron-slider`, `nutrient-potassium-slider`, `nutrient-magnesium-slider`, `nutrient-vitamin-d-slider`, `nutrient-vitamin-b12-slider`; text fields without ids (`edit=1` fibre … in screen order). Fibre 0–80 g in steps of 1 (default 30); iron 0–30 mg in steps of 0.5 (female default 18). *DE:* "Nährstoffziele", "Speichern", "Zurücksetzen".
*Consumers:* Diary "Today's nutrients" panel ("x / goal" per row, `daily_nutrient_panel.dart:82-108`); the screen's own prefill on reopen.

References, not run: **OK only** → #1347. **A day with no diary entry** → #1348 (today already has entries from 2.5). **Reset + Save** → #1349. **The next day** → #1316.

**Do, slider.** `st mark "row 10"` → Settings → `st tap id=settings-nutrient-goals` → `st slider id=nutrient-fibre-slider 0.5` → `st get edit=1` → `40` → `st tap id=nutrient-goals-save`.

**Expect, before R:**
1. Reopen the screen: fibre `40` → `st back`.
2. Diary → today → "Today's nutrients" expanded: the fibre row reads "… / 40g".

**R**, then **expect after R:** 1 and 2.

**Do, Done + OK.** `st tap id=settings-nutrient-goals` → `st field edit=1 42` → `st done` → `st scroll_to id=nutrient-iron-slider` → the iron field (`st ls`, the EditText on the iron row) → `st field edit=<n> 25` → `st done` → `st tap id=nutrient-goals-save`.
**Expect** fibre "/ 42g" and iron "/ 25mg" in the Diary panel before R, and both on reopen and in the Diary after R.

**Fail if:** a slider or Done value doesn't come back; the Diary panel shows the old reference before R or after R.
**Note:** values are stored on today's tracked day only. That's #1316, by reference. B6 (goal edits use `DateTime.now()`, not the logical day) is checked in 4.2, while the boundary is moved.

### Row 13: Show Meal Macros [flagged: B1]

*Ids:* text `text^=Show Meal Macros` (switch, no id). *DE:* "Makros je Mahlzeit anzeigen".
*Consumers:* Home meal headers (reloaded); **Diary** meal headers (`diary_page.dart:77`, not reloaded: B1).

**Do.** `st mark "row 13"` → check Home and Diary both show the "… c  … f  … p" line under Breakfast and Lunch → Settings → `st scroll_to "text^=Show Meal Macros"` → tap → `{unchecked}`.

**Expect, before R:**
1. Home: no "c f p" line.
2. **Go straight to Diary** (`st tap id=nav-diary`, no backgrounding): no "c f p" line. The inventory expects them still shown.

**R**, then **expect after R:** 1 and 2, and the switch `{unchecked}`.

**Then turn it back on**, and before R both Home and Diary show the line again. Same B1 check in the other direction.
**Fail if:** Diary disagrees with the switch before R; the switch doesn't persist.

### Row 15: Nutrients (panel visibility) [flagged: B2]

*Ids:* `settings-nutrient-visibility` → checkboxes by text (`text=iron`, `text=fiber`, …; lowercase in English). Written on every tick; no Save. *DE:* "Nährstoffe", "Eisen".
*Consumer:* Diary "Today's nutrients" (refetches visibility only when intakes or the day change: B2).

**Do.** `st mark "row 15"` → Diary → today → panel expanded → iron row present → Settings → `st tap id=settings-nutrient-visibility` → `st tap text=iron` (→ `{unchecked}`) → `st back`.

**Expect, before R:**
1. Reopen the screen: iron `{unchecked}` → `st back`.
2. **Straight to Diary:** the panel has no iron row. The inventory expects iron still shown.

**R**, then **expect after R:** 1 and 2.

**Then re-tick iron**: before R the Diary shows iron again, and after R as well.
**Fail if:** the Diary panel disagrees with the setting before R; the tick doesn't persist.

### Row 20: Language [flagged: A6, B8]

*Ids:* text `text^=Language` → radios "System default", "English", "Deutsch", "Türkçe", "Čeština", "Italiano", "Українська", "中文", "Polski", "Slovenčina", "Magyar", "Español", then OK. *DE:* "Sprache", "Systemstandard". *IT:* "Lingua", "Impostazioni".
*Consumers:* `LocaleProvider` (whole UI); Android per-app locale (`st locale`); startup `reconcileAppLocale`; the daily reminder's text (B8, section 4.1); the food-search locale (not judged).

References, not run: **the languages below the dialog's fold** → #1331. Italiano is sixth, inside the fold.

**Do, in-app.** `st mark "row 20"` → Settings → `st scroll_to "text^=Language"` → tap → `st tap text=Italiano` → `st tap text=OK`.

**Expect, before R:**
1. The UI is Italian at once: the Settings card reads "Impostazioni", the row "Lingua / Italiano".
2. `st locale` → `it`.

**R**, then **expect after R:** 1 and 2.

Back to English: `ST_SETTINGS_LABEL=Impostazioni st open_settings` → `st scroll_to "text^=Lingua"` → tap → `st tap text=English` → `st tap text=OK` → `st locale` → `en`.

**HAND-OFF (optional; #1340 puts it in scope; the maintainer may decline, giving *inconclusive* for 3–4):** Android's per-app language.
> Maintainer: on the phone open **Einstellungen → Apps → OpenNutriTracker → Sprache**, choose **Italiano**, come back to OpenNutriTracker and say "done".

The session: `ST_HANDOFF=1 st focus` → app focused. Then:
3. Before R, the app may already be Italian (`didChangeLocales`). Record it. **R** → **Expect** the UI Italian, Settings "Lingua / Italiano" (the system override wins and is copied into Hive), `st locale` → `it`.

> Maintainer: same page, choose **Systemstandard**, come back, say "done".

4. **R** → **Expect** the app in German (the phone's language). **Fail if** it is Italian again: suspect A6, the null tag ignored (`main.dart:248`) and the Hive value re-pushed at launch (`app_locale_sync.dart:32`).

Finally, in-app back to English (labels in whatever language is showing), then `st locale` → `en`.
**Fail if:** 1, 2 or 4 fail; any exception.

### Row 24: Health Connect automatic import [flagged: A8] + row 43: the health disclosure

*Ids:* `settings-health-sync` → `health-sync-auto-import` (switch), `health-sync-import-now`, `health-sync-kcal-multiplier`, `health-sync-apply-suggestion`, `health-sync-sources`, `health-sync-privacy-policy` (leaves the app: not tapped). Disclosure "Import workouts from Health Connect?" → CANCEL / "Continue". *DE:* "Trainings aus Health Connect importieren?", "Weiter".
*Consumers:* the switch's own state; `import_workouts_usecase` on launch and resume → Diary and Home activities.

**Do, row 43 cancel path.** `st mark "row 24"` → Settings → `st scroll_to id=settings-health-sync` → tap → `st tap id=health-sync-auto-import` → **Expect** the disclosure dialog (`st save 43-disclosure`). No system UI may come first. → `st tap text=CANCEL`. **Expect** the switch `{unchecked}` and focus still in the app.

**Do, grant path.** `st tap id=health-sync-auto-import` → `st tap text=Continue` →
**HAND-OFF:** the Health Connect permission sheet (system UI, German, e.g. "Zulassen" / "Alle zulassen").
> Maintainer: grant OpenNutriTracker the requested read permissions (training / exercise and calories), then come back. Also tell the session whether Health Connect holds any workout from the last few days.

`ST_HANDOFF=1 st focus` → back in the app.

**Expect, before R:**
1. `health-sync-auto-import` `{checked}`; no "access was not granted" snackbar.
2. If HC holds a workout: it appears in Diary → today (or its day) under Activity, and Home's burned stat includes it. If not: *inconclusive* for this consumer (#948).

**R**, then **expect after R:** 1 (reopen the screen), and 2 for the launch import.

Leave it **on** for rows 25–26.
**Fail if:** the switch shows off while the store says on (A8: reopen after R shows on); system UI before the disclosure; the switch doesn't persist.
**Note:** a denied grant gives the snackbar "Health Connect access was not granted…" and an off switch. That's correct and gets recorded.

### Row 37: Privacy Settings, "Send crash reports" [flagged: B9]

*Ids:* text `text^=Privacy Settings` → dialog switch `text^=Send crash reports`, OK / CANCEL. *DE:* "Datenschutzeinstellungen", "Absturzberichte senden".
*Consumer:* `main.dart:130-149`, which starts Sentry only at launch and only in **release** builds. This is a debug build, so the effect can't be observed.

**Do.** `st mark "row 37"` → Settings → `st scroll_to "text^=Privacy Settings"` → tap → the switch is `{unchecked}` (onboarding left it off) → tap it → `st tap text=OK`.
**Expect, before R:** reopen → `{checked}` → CANCEL. **R**, then **expect after R:** reopen → `{checked}`.
Then switch it off → OK → R → `{unchecked}`.
**Verdict:** persistence decides pass or fail. The effect is *inconclusive (debug build)* by construction; say so in the table.

### Row 42: Daily water goal, from You [flagged: A5] + You value P5 + pair I (water half)

*Ids:* You → `profile-water-goal` → `water-goal-input`, `water-goal-slider`, `water-goal-save`, `water-goal-reset`. Range 100–10 000 ml in steps of 100. *DE:* "Tägliches Wasserziel".
*Consumers:* You `profile-water-goal` "N ml"; Home `home-water-chip` "x / N ml"; Trends water card "avg / N ml" (`trends_bloc.dart:109`, not reloaded).

References, not run: **OK only** → #1347. **Water under imperial food units** → #1306.

**Do, Done + OK.** `st mark "row 42"` → Trends loaded since the last R → `st tap id=nav-you` → `st tap id=profile-water-goal` → `st field id=water-goal-input 3000` → `st done` → `st tap id=water-goal-save`.

**Expect, before R:**
1. You: "3000 ml".
2. Home chip "… / 3000 ml".
3. Trends water card "… / 3000 ml" (`st shot 42-trends-before`).

**R**, then **expect after R:** 1–3.

**Do, slider.** `st tap id=profile-water-goal` → `st slider id=water-goal-slider 0.2424` → `st get id=water-goal-input` → `2500` (adjust) → `st tap id=water-goal-save` → 1–3 with 2500, before and after R.
**Do, Reset.** `st tap id=profile-water-goal` → `st tap id=water-goal-reset` → the field returns to W0 → `st tap id=water-goal-save` → You shows W0.
**Fail if:** a Done or slider value is lost; Trends lags before R.

---

## 3B. Other non-destructive rows, inventory order

Each row: change it → expect the value and the effect at the main consumer → R → expect both again.

### Row 1: Food units
*Ids:* `settings-food-units` → "Metric (g, kg, ml, l)" / "Imperial (lbs, oz, fl oz)", OK. *DE:* "Lebensmitteleinheiten".
**Do.** `st mark "row 1"` → tap → `st tap "text=Imperial (lbs, oz, fl oz)"` → OK.
**Expect:** subtitle "Imperial (lbs, oz, fl oz)"; Home Breakfast row for the 2.5a product shows its amount in **oz** (100 g ≈ 3.5 oz); Diary the same; open the product (Breakfast → Recently → its card): the Unit dropdown offers "oz". R → all the same.
Water stays in ml: reference → #1306.
**Then** back to Metric → OK → Home shows "100 g".
**Fail if:** any of the above is lost after R.

### Row 2: Height units + You value P4 (height typed in ft/in)
*Ids:* `settings-height-units` → "Metric (mm, cm, m)" / "Imperial (ft, in)", OK; You `profile-height` → dialog fields `set-height-dialog-feet-input`, `set-height-dialog-inches-input`, OK. *DE:* "Größeneinheit".
**Do.** `st mark "row 2"` → "Imperial (ft, in)" → OK.
**Expect:** subtitle "Imperial (ft, in)"; You `profile-height` "5 ft 7 in" (170 cm). R → the same.
**P4, OK only.** `st tap id=profile-height` → `st field id=set-height-dialog-feet-input 5` → `st field id=set-height-dialog-inches-input 9` → `st tap text=OK` → **Expect** "5 ft 9 in", and Home goal and BMI change (`ProfileBloc.updateUser` reloads them).
**P4, Done + OK.** Same with inches `8` → `st done` → OK → "5 ft 8 in". R → "5 ft 8 in".
**Then** set it back with inches `7` (OK) → "5 ft 7 in" → Height units → Metric → OK → "170 cm".
**Fail if:** the unit or a typed height is lost; the cm round trip doesn't return 170.

### Row 3: Body weight unit + pair I (imperial × weight entry) + You value P3
*Ids:* `settings-body-weight-unit` → "kg" / "lbs" / "st", OK; You `profile-weight` → dialog `set-weight-dialog-stones-input`, `set-weight-dialog-pounds-input` (st only; kg and lbs use a scroll picker), OK. *DE:* "Einheit für Körpergewicht".
*Consumers:* You weight; Home `home-weight-chip` (read it, don't tap); Trends weight card (rate label "… st/week"); Weight history rows (on open).
**Do.** `st mark "row 3"` → `st tap text=st` → OK.
**Expect, before R:** subtitle "st"; You "10 st 3.3 lbs"; Home chip "10 st 3.3 lbs"; Trends weight card rate in st (`st shot 03-trends`); Weight history rows in st. R → all the same.
**Pair I, OK only.** You → `st tap id=profile-weight` → `st field id=set-weight-dialog-stones-input 10` → `st field id=set-weight-dialog-pounds-input 7` → `st tap text=OK` → **Expect** You "10 st 7 lbs", Home chip the same, Weight history today "10 st 7 lbs".
**Pair I, Done + OK.** Pounds `5` → `st done` → OK → "10 st 5 lbs". R → "10 st 5 lbs" in all three places.
**Then** `st tap id=settings-body-weight-unit` → `st tap text=lbs` → OK → You "145 lbs". Then the same dialog → `st tap text=kg` → OK → "65.8 kg" (10 st 5 lb = 65.77 kg).
**Fail if:** a typed weight or the unit is lost; a consumer shows another unit than the setting.
**Note:** the lbs and kg entry is a scroll picker with no text field, so P3 is tested through st.

### Row 5: Default to weight or volume, not servings
*Ids:* `settings-default-raw-food-units` (switch). *DE:* none; the German ARB has no translation, so the row shows English (a Note for the German UI).
*Consumer:* the product screen's Unit dropdown, read on open.
**Do.** `st mark "row 5"` → tap → `{checked}`. Open the 2.5a product (`fab-add-item` → `add-item-breakfast` → chip `text=Recently` → tap the card, not `+`).
**Expect:** Unit starts on "g" (the 2.5a baseline was "Serving (…)"). R → switch `{checked}`, the product again starts on "g".
**Then** off → the product starts on "Serving (…)".
If the product has no serving, the row is *inconclusive* until a food with a serving is used.

### Row 6: How your goal is calculated (read-only)
*Ids:* `settings-kcal-goal-info`. *DE:* "So wird dein Ziel berechnet".
**Do.** tap → `st save 06-info`.
**Expect:** "Daily kcal adjustment" reads **+500** (from row 7), and the total equals Home's "left" + supplied − burned (Home shows no goal number of its own). "Learn more" leaves the app: not tapped. No R needed (no write).

### Row 9: Per-meal kcal share
*Ids:* `settings-per-meal-share` → `meal-share-preset-standard`, `-mediterranean`, `-two_meal`, `-omad`, `-five_small`; sliders `meal-share-breakfast`, `-lunch`, `-dinner`, `-snack`; `meal-share-save`; `text=Reset`. *DE:* "kcal-Anteil je Mahlzeit".
*Consumers:* Home and Diary meal headers "consumed / target kcal" (both reloaded).
**Moving a slider:** reference → #715 (not run).
**Do.** `st mark "row 9"` → note the four Home targets and their sum T → tap → `st tap id=meal-share-preset-five_small` → `st tap id=meal-share-save`.
**Expect, before R:** reopen → 20 / 25 / 25 / 30 % → CANCEL; Home targets in the ratio 20 : 25 : 25 : 30 of T (±1 each); Diary today the same. R → the same.
**Then** Reset → OK → 30 / 40 / 20 / 10.
**Fail if:** the preset doesn't persist; Home or Diary targets don't follow.

### Row 12: Show Activity Tracking
*Ids:* text `text^=Show Activity Tracking` (switch). *DE:* "Aktivitätstracking anzeigen".
*Consumers:* Home activity card; the + sheet's `add-item-activity`; Diary's Activity section.
**Do.** `st mark "row 12"` → toggle off.
**Expect, before R:** Home has no activity card ("ST walk" gone from Home); `st tap id=fab-add-item` → `add-item-activity` absent → `st back`; Diary today has no Activity section. R → the same, switch `{unchecked}`.
**Then** on → all three back.

### Row 14: Show Micronutrients
*Ids:* text `text^=Show Micronutrients` (switch). *DE:* "Mikronährstoffe anzeigen".
*Consumer:* the product screen's nutrient table, read on open.
**Do.** `st mark "row 14"` → flip it to the opposite of the 2.5a baseline → open the 2.5a product.
**Expect:** a "Micronutrients" section present when on, absent when off. R → the same. **Then** flip back and check again.

### Row 16: Theme
*Ids:* text `text^=Theme` → "System default" / "Light" / "Dark", OK. *DE:* "Thema", "Systemstandard", "Hell", "Dunkel".
**The assertion on change:** reference → #765 (not provoked; see the top of the script).
**Do.** `st mark "row 16"` → tap → `st tap text=Dark` → OK → `st shot 16-dark` → `st pixel 16-dark 540 1200`.
**Expect:** a dark background (lum < 60). R → `st shot 16-dark-after` → still dark.
**Then** Light → OK → lum > 200 → R → light. **Then** System default → OK.
**Fail if:** the theme doesn't persist. If the red error screen appears: `fail → #765`, R, carry on.

### Row 17: Accent, Material You
*Ids:* `settings-accent-colour` → `accent-option-material-you`. *DE:* "Akzentfarbe", "Systemfarben verwenden".
**Do.** `st mark "row 17"` → tap the row → `st tap id=accent-option-material-you` → `st back`.
**Expect:** subtitle "Material You"; the trailing swatch is a rainbow; `st shot 17-home` and `st pixel` at the FAB give the wallpaper-derived colour (no wallpaper change, #1341). R → the same subtitle and FAB colour.
If the colour can't be told apart from the default accent, the effect is *inconclusive*.

### Row 18: Accent, preset swatch
*Ids:* `accent-preset-00` (red `#E53935`) … `accent-preset-15`.
**Do.** `st mark "row 18"` → `st tap id=settings-accent-colour` → `st tap id=accent-preset-00` → `st back`.
**Expect:** subtitle "Custom"; FAB hue ≈ 0–15 or 345–360 (`st shot 18-home`, `st pixel`). R → the same.

### Row 19: Accent, custom colour (typed hex)
*Ids:* `accent-custom-colour` → dialog `accent-custom-slider`, `accent-custom-hex-field` (prefix "#"), OK / CANCEL. *DE:* "Eigene Farbe…".
**Do, OK only.** `st mark "row 19"` → `st tap id=accent-custom-colour` → `st field id=accent-custom-hex-field FF5733` → `st tap text=OK`.
**Expect:** the accent turns orange-red (FAB hue ≈ 5–20); subtitle "Custom". R → the same.
**Do, Done + OK.** Again with `00897B` → `st done` → OK (if Done already closes or applies, record it). **Expect** teal (hue ≈ 160–185). R → teal.
**Then** `st tap id=accent-option-material-you` to leave the accent on its default for the rest of the run.
**Fail if:** the typed hex is ignored on OK (the inventory says it is read on confirm).

### Row 23: Food databases
*Ids:* `settings-food-sources` → switches by title: "Open Food Facts" (fixed on), "FoodData Central (Foundation Foods)", "FoodData Central (SR Legacy)", "FoodData Central (FNDDS Survey)", "FoodData Central (Branded Foods)", "Bundeslebensmittelschlüssel (BLS)". The ⓘ buttons leave the app: not tapped. *DE:* "Lebensmitteldatenbanken".
*Consumer:* the search RPC's source list, read per search.
**Do.** `st mark "row 23"` → first the baseline: `add-item-snack` → `st tap text=Food` → search `Apfel` → `st save 23-before` → note the result chips containing "BLS" → back out. Then Settings → `st tap id=settings-food-sources` → `st tap "text^=Bundeslebensmittelschlüssel"` → `{unchecked}` → `st back`.
**Expect:** the same search returns no "BLS" chips. R → the switch is still off, and the search is still without BLS.
**Then** turn BLS on again.
If the baseline had no BLS results, the row is *inconclusive*.

### Row 25: Health Connect, workout calorie credit
*Ids:* `health-sync-kcal-multiplier` (50–100 % in 5 % steps), `health-sync-apply-suggestion`. *DE:* "Anrechnung von Trainingskalorien".
**Do.** `st mark "row 25"` → Settings → `settings-health-sync` → `st slider id=health-sync-kcal-multiplier 0.2` → the label shows "60%" (adjust).
**Expect:** reopen → 60 %; R → 60 %. The effect applies to *future* imports only, so it's *inconclusive* unless HC delivers a new workout.
**Then** `st tap id=health-sync-apply-suggestion` (if shown) → the label shows the suggested value → R → kept.

### Row 26: Health Connect, Import now / sources / privacy
**Do.** `st tap id=health-sync-import-now` → **Expect** a snackbar "No new workouts" or "N workouts imported", and the subtitle shows a last-import time. `st tap id=health-sync-sources` → the in-app Sources screen → `st back`. `health-sync-privacy-policy` opens the browser: **skipped**.
**Then** turn auto import off (`health-sync-auto-import` → `{unchecked}`) → R → still off. The HC grant itself stays until revoked in HC, which isn't part of this run.

### Row 27: AI meal assistance, provider radio
*Ids:* `settings-ai-assist` → `ai-assist-provider-anthropic`, `ai-assist-provider-openrouter`, `ai-assist-provider-openai`, `ai-assist-provider-own-server`, `ai-assist-cancel`, `ai-assist-save-key`. *DE:* "KI-Unterstützung".
**Do.** `st mark "row 27"` → note the subtitle ("Off — no key saved") → tap the row → note which provider is selected → `st tap id=ai-assist-provider-openai` → `st tap id=ai-assist-cancel`.
**Expect:** the subtitle is unchanged; reopen → the originally selected provider (by design, #848) → cancel.

### Row 28: AI key + row 44: the AI consent screen. HAND-OFF
*Ids:* `ai-assist-key-field` (obscured), `ai-assist-save-key`, `ai-consent-agree`, `ai-consent-decline`.
**Do.** `st mark "row 28"` → `st tap id=settings-ai-assist` →
**HAND-OFF:** typing one AI key.
> Maintainer: pick the provider whose key you'll use, type the key into the key field and tap OK. Stop there and say "done"; the session handles the consent screen. (A Gemini key in the new `AQ…` format through *own server* is a known failure, reference → #1253; prefer Anthropic, OpenRouter or OpenAI.) The key does not survive the run: row 36 wipes it by design and it is not in the export.

The session takes no dump or screenshot while the key is being typed. Then `ST_HANDOFF=1 st focus` → **row 44:** `st save 44-consent` (the key field behind it is obscured) → **Expect** the consent screen with `ai-consent-agree` and `ai-consent-decline` → `st tap id=ai-consent-agree`.
**Expect, before R:**
1. Subtitle "On — <Provider>".
2. Used: `st tap id=fab-add-item` → `add-item-breakfast` → `st tap id=add-meal-bulk-add` → `bulk-add-photo` is present and `bulk-add-model-hint` absent → `st field id=bulk-add-input "1 apple"` → `st kb_hide` → `st tap id=bulk-add-parse` → `st wait "text^=Read by AI" 60` → a row for an apple. **Do not** tap `bulk-add-submit`. → `st back` (×2).

**R**, then **expect after R:** 1, and `bulk-add-photo` present. Reopening the dialog shows "Key saved ••••" (masked), never the key.
Row 44: *pass* if the consent screen came up on the first save, before anything was stored. If **Decline** had been chosen, nothing would be stored; that path isn't run, because it would cost a second key entry.
**Fail if:** the key or the provider doesn't survive R; the AI action is missing while On.

### Row 29: AI, own server (endpoint, model, load models)
*Ids:* `ai-assist-provider-own-server`, `ai-assist-endpoint-field`, `ai-assist-model-field`, `ai-assist-load-models`, `ai-assist-model-picker`, `ai-assist-probe-run`.
The endpoint is loopback, `127.0.0.1`, on ports where nothing listens on the phone: the probe and "load models" fail harmlessly and nothing leaves the device. (A public plain-http address such as TEST-NET `192.0.2.x` is refused before saving by `_refusedBeforeItLeaves`, so it can't be used.)
**Do, OK only.** `st mark "row 29"` → `st tap id=settings-ai-assist` → `st tap id=ai-assist-provider-own-server` → `st field id=ai-assist-endpoint-field http://127.0.0.1:11434` → `st field id=ai-assist-model-field llama3` → `st tap id=ai-assist-save-key`.
**Expect:** the dialog closes; subtitle "On — 127.0.0.1:11434". (The probe runs in the background after the dialog pops; its result isn't on screen, so it isn't judged.)
**Do, Done + OK.** Reopen → `st field id=ai-assist-endpoint-field http://127.0.0.1:11435` (the field is prefilled with the saved URL; `st field` deletes 64 characters first) → `st done` → OK → subtitle "On — 127.0.0.1:11435". R → the same.
`st tap id=ai-assist-load-models` (in the dialog) → an error message, no crash.

### Row 30: AI, pause switch
*Ids:* `ai-assist-enabled`.
**Do.** Reopen → **switch to the maintainer's provider** (`st tap id=ai-assist-provider-<theirs>`; OK appears because the switch is a change, #979) → `st tap id=ai-assist-save-key` → subtitle "On — <Provider>". Reopen → `st tap id=ai-assist-enabled` (→ off) → `st tap id=ai-assist-cancel` (the pause persists immediately, so Cancel doesn't undo it).
**Expect:** subtitle "Paused — key saved"; bulk add has no `bulk-add-photo`. R → still paused. **Then** on again → "On — <Provider>".

### Row 31: AI, remove key (on the own-server entry, never on the maintainer's)
*Ids:* `ai-assist-remove-key`.
**Do.** Reopen → `st tap id=ai-assist-provider-own-server` → `st ls` and confirm the own-server radio is `{checked}` and the endpoint reads 127.0.0.1:11435 → **only then** `st tap id=ai-assist-remove-key`.
**Expect:** the endpoint is gone. Switch back to the maintainer's provider → OK → subtitle "On — <Provider>". R → reopen → own server empty, the maintainer's key still "Key saved".
**Fail if:** removing own server touched the hosted key.
Never remove the maintainer's key here. Row 36 tests that a reset clears it.

### Row 38: Disclaimer
*Ids:* text `text^=Disclaimer` → "I understand". *DE:* "Hinweis", "Ich habe verstanden".
**Do/Expect:** the dialog opens with the disclaimer text; "I understand" closes it. No write.

### Row 39: Sources & References
*Ids:* text `text^=Sources & References`. *DE:* "Quellen & Referenzen".
**Do/Expect:** the in-app Sources screen opens → `st back`. Links on it leave the app: not tapped.

### Row 40: Report Error
*Ids:* text `text^=Report Error` → CANCEL / OK. *DE:* "Fehler melden".
**Do/Expect:** the dialog opens with its text → **CANCEL**. OK would open the mail app and leave a draft behind: **skipped**.
**Verdict:** pass for the dialog; the mail hand-over is skipped.

### Row 41: About
*Ids:* text `text^=About` (the last tile; the category header is also "About", so use `@2` if two match). *DE:* "Über".
**Do/Expect:** the About dialog shows version **2.4.0** → `st tap text=Close`. "Source Code" and "Privacy Policy" open the browser: skipped.

### P1: Activity level (You)
*Ids:* `profile-activity` → "Sedentary" / "Low Active" / "Active" / "Very Active". *DE:* "Sitzend", "Leicht aktiv", "Aktiv", "Sehr aktiv".
**Do.** note Home L → `st tap id=profile-activity` → `st tap "text=Low Active"`.
**Expect:** subtitle "Low Active"; Home goal lower than before; kcal goal info TDEE lower. R → the same. **Then** back to "Active".

### P2: Weight goal (You)
*Ids:* `profile-goal` → "Lose Weight" / "Maintain Weight" / "Gain Weight".
**Do.** `st tap id=profile-goal` → `st tap "text=Lose Weight"`.
**Expect:** subtitle "Lose Weight"; Home goal lower; kcal goal info "Applied adjustment" negative. R → the same. **Then** back to "Maintain Weight".

(P3, the weight, is pair I under row 3. P4, the height, is under row 2. P5, the water goal, is row 42.)

---

## 4. Slow rows (real time, no clock change)

### 4.1 Rows 21 + 22: Daily reminder and its time
*Ids:* text `text^=Daily Reminder@2` (the switch; the first match is the Notifications category header with the same text) and, once it's on, `text^=Reminder time:` (opens Flutter's time picker). *DE:* "Tägliche Erinnerung", "Erinnerungszeit: …".
*Consumers:* the system alarm (`st alarms`), the posted notification (`st notif`), and the startup reschedule (`main.dart:109-128`).

**Note on force-stop.** `am force-stop` cancels an app's alarms, and Android keeps them cancelled until the app runs again. So the check is force-stop, **relaunch**, wait. The relaunch is what proves the app reschedules from its stored setting. "Force-stop and wait" without the relaunch would fail on any app, so it isn't a test.

**Do, switch on.** `st mark "row 21"` → Settings → `st scroll_to "text^=Daily Reminder@2"` → `st tap "text^=Daily Reminder@2"` →
**HAND-OFF:** the Android notification permission dialog (German, "OpenNutriTracker erlauben, dir Benachrichtigungen zu senden?").
> Maintainer: tap **Zulassen**, say "done".

`ST_HANDOFF=1 st focus`.
**Expect:** the switch `{checked}`, subtitle "Reminder time: HH:MM" (the stored default), a "Reminder time: …" row below it, `st alarms` lists an alarm for the package.

**Do, time OK only (row 22).** `st clock` → T = now + 3 min (roll the hour if needed) → `st tap "text^=Reminder time:"` → in the picker switch to typing: `st tap "text=Switch to text input mode"` → `st field edit=1 <HH>` → `st field edit=2 <MM>` → `st tap text=OK`.
**Expect:** the row reads "Reminder time: HH:MM" = T; `st alarms` shows the alarm re-armed.
**R**, then **expect:** the subtitle is still T; `st alarms` shows the alarm again (the startup reschedule).
**Wait:** poll `st notif` every 30 s until T + 15 min. The schedule is `inexactAllowWhileIdle`, so minutes of delay are normal. **Expect** an entry with title "OpenNutriTracker" and text "Don't forget to log your meals today!". `st shot 21-notification` if the heads-up is visible.
Verdict: the alarm is gone after R → **fail**. The alarm is there but nothing arrives by T + 15 → *inconclusive* (delivery is the OS's call).

**Do, time Done + OK.** Open the picker again → text input → hour `21` → `st done` → minute `30` → `st done` → OK (if Done already closed the picker, record it).
**Expect:** "Reminder time: 21:30"; R → still 21:30; `st alarms` has the alarm.

**B8, language × reminder (row 20's last consumer).** Set T again (now + 3, OK only) → switch the app to **Italiano** (row 20 steps) **without R** → wait as above.
**Expect** the notification text in Italian ("Non dimenticare…"). The inventory expects English: the language handler doesn't reschedule (`main.dart:109-128` is the only place the text is localised). English → **fail** (effect missing until restart). Then **R**, set T = now + 3 again (OK only) and wait once more: **expect** the text in Italian, from the startup reschedule. Back to English.

**Do, switch off.** Tap the switch → `{unchecked}` → `st alarms` lists nothing for the package → R → still off, still no alarm.

### 4.2 Row 11: Day starts at (diary day boundary) [flagged: B5]
*Ids:* `settings-day-boundary` → `day-boundary-hours-slider` (0–23, wraps label and slider: use `bottom`), `day-boundary-minutes-slider`, `day-boundary-save`, `text=Reset`. *DE:* "Tag beginnt um".
*Consumers:* Home's logical day (reloaded), the Diary day view (`CalendarDayBloc`, reloaded), the Diary calendar's today-marker (`DiaryBloc`, **not** reloaded: B5), the intake date of anything logged.

**Precondition:** `st clock` hour H ≤ 22.
**Do.** `st mark "row 11"` → Settings → `st tap id=settings-day-boundary` → `st slider id=day-boundary-hours-slider <(H+1)/23> bottom` → read the time label (`st ls`, "H+1:00") and correct → `st tap id=day-boundary-save`.
Intakes are filed by the moment they were logged (`DayBoundaryCalc.isMomentInLogicalDayMinutes`), and the + sheet logs at `DateTime.now()`. With the boundary at H+1:00, everything logged earlier today now belongs to logical **yesterday**, which is the current logical day.

**Expect, before R:**
1. Reopen → "H+1:00" → CANCEL.
2. Home still shows the 2.5 items (they are now in the current logical day, yesterday) and its date reads yesterday's.
3. Diary: the calendar's today-marker sits on **yesterday**. The inventory expects it still on the calendar date (B5).

Log one item now: `fab-add-item` → `add-item-snack` → `add-meal-quick-add` → title `ST boundary`, energy `100` → `st kb_hide` → submit.
4. Diary → yesterday: the 2.5 items **and** Snack "ST boundary". Diary → the calendar date today: empty.

**B6 (row 10's goal-date suspect), while the boundary is moved.** Nutrient goals → fibre `44` → `st done` → Save. **Expect** the Diary panel for the current logical day (yesterday) to read "/ 44g". The inventory expects the goal on the calendar date's tracked day instead (`nutrient_goals_screen.dart:233`), where it is invisible, or nowhere (#1348 if that day has no row). Record which; a goal not shown on the day the user is looking at is a **fail**.

**R**, then **expect after R:** 1–4, and the B6 reading unchanged.

**Reset.** Dialog → `text=Reset` → OK → reopen "0:00" → R → "0:00". Everything logged today, "ST boundary" included, moves back to the calendar date today (filing is by moment, not by a stored day). Yesterday is empty again apart from the 65.8 kg weight.
**Then** Nutrient goals → fibre `42` → `st done` → Save, so today again carries 42 for section 5.
**Fail if:** the boundary doesn't persist; an item lands on the wrong logical day; the Diary today-marker lags before R.
If 4.2 runs on a later calendar day than section 2, the 2.5 items are on an older day: then 2 and 4 read "Home empty; yesterday holds only ST boundary", and the reset puts ST boundary on today.

---

## 5. Destructive rows, last, behind the export

Order: export first, so nothing here destroys data without a backup. Re-import is the persistence check. Then the custom-food import, the cache, and **Reset profile data** last of all.

**Settings are not in the export.** The export holds activities, intakes, tracked days, recipes, the weight log, activity templates and images (inventory row 33, `export_data_usecase.dart`). #1341 asks for a re-import "to check the settings came back". The script reads that as two checks. Config settings are **untouched** by an import (5.2). Values that live on **tracked days**, today's nutrient goals and today's kcal and macro goals, **do** come back. What a user loses on a reinstall shows in D6.

### 5.1 Row 33: Export app data. HAND-OFF (file picker)
*Ids:* text `text^=Export / Import App Data` → segments "JSON" / "CSV", buttons "Export" / "Import". *DE:* "App-Daten exportieren / importieren", "Exportieren", "Importieren".
**Before:** if section 5 starts on a different calendar day from row 10, set Nutrient goals → fibre `42` (Done + OK) now: the goal lives on one day's tracked day only. `st save 33-settings-1..n` (every Settings subtitle and switch, as in 2.6). Note today's fibre goal (42), the Diary entries today and yesterday, and the weight history rows.
**Do.** `st mark "row 33"` → Settings → tap the row → JSON stays selected → `st tap text=Export` →
**HAND-OFF:** the system file picker (German, DocumentsUI).
> Maintainer: choose **Downloads**, rename the file to **`ont-settings-run.zip`** (a fresh name; saving over an existing name is reference → #763), tap **Speichern**, say "done".

`ST_HANDOFF=1 st focus`.
**Expect:** "Export / Import successful" with a check icon.
**Then on the laptop:** `$ADB -s 18101FDF60010M pull /sdcard/Download/ont-settings-run.zip "$(cat ~/Documents/ont-settings-test-evidence/current-run)/"` → `unzip -l` it → **Expect** `user_activity.json`, `user_intake.json`, `user_tracked_day.json`, `user_recipe*.json`, `weight_log.json`, `custom_activity_template*.json`, size well above 0.
**Fail if:** an error is shown for a fresh name; the zip is empty or missing an entry.

### 5.2 Row 34: Import app data [flagged: B7]. HAND-OFF (file picker)
*Consumers:* Home, Diary, CalendarDay (reloaded by the dialog); **Trends and You weight** (not reloaded: B7); the weight history screen (on open).
**Make the import visible first** (after the backup, so this destroys nothing unrecoverable):
- Diary → today → `st longpress "text^=ST custom"` → `st tap text=DELETE`.
- You → `profile-weight-history` → yesterday's 65.8 kg row → the trash icon at the row's right edge (`st tapxy 1000 <row y>`, from `st ls`). It deletes instantly.
- Nutrient goals: fibre `45` → `st done` → Save.
- Trends visited.

**Do.** `st mark "row 34"` → Settings → Export / Import → JSON → `st tap text=Import` →
**HAND-OFF:** the file picker.
> Maintainer: pick **Downloads → ont-settings-run.zip**, say "done".

**Expect, before R:**
1. "Export / Import successful".
2. Home and Diary: "ST custom" is back under Lunch. **Duplicates:** the import appends intakes and activities (`_intakeBox.addAll`, `_userActivityBox.addAll`), and only tracked days and the weight log are keyed by day. So every intake and activity still on the phone is expected **twice** (the Nutella breakfast, ST walk, …). Count them. Doubled entries mean a restore onto a live install doubles the diary: a **fail** for a new issue (none open as of 2026-10-11). Totals in 5.3–5.5 carry the doubling; those rows don't read totals.
3. Today's fibre goal reads **42** again (the tracked day was replaced by the exported one).
4. Weight history (opened fresh): yesterday's 65.8 kg is back.
5. **Trends weight card and You weight subtitle/trend**: they should include the restored entry. The inventory expects them stale (B7). `st shot 34-trends-before`.
6. Settings: every subtitle and switch is identical to `33-settings-*` (the import doesn't touch config).

**R**, then **expect after R:** 2–6.
**Fail if:** any of 1–4 or 6 fails; 5 lags before R; duplicates as above.
**Not covered:** the Recipes consumer of B7 (no recipe exists at export time).

### 5.3 Row 32: Import custom food data (the app's own samples). HAND-OFF (file picker ×4)
*Ids:* `settings-import-custom-food` → `import-format-toggle` ("CSV" / "JSON"); buttons "Sample meals (csv)", "Import meals (csv)", "Sample recipes (csv)", "Import recipes (csv)", and the same with "(json)". *DE:* "Eigene Lebensmittel-Daten importieren", "Beispiel-Mahlzeiten (csv)", "Mahlzeiten importieren (csv)".
**Do, CSV.** `st mark "row 32"` → tap the row → CSV selected → `st tap "text=Sample meals (csv)"` →
**HAND-OFF:** the save picker.
> Maintainer: save `opennutritracker-meals-sample.csv` to Downloads, say "done".

Then `st tap "text=Import meals (csv)"` → **HAND-OFF:** the open picker.
> Maintainer: pick that CSV, say "done".

**Expect:** "Imported 2 meal(s)."; You → `profile-recipes` → tab "Custom Meals" lists **Banana** and **Whole Milk 3.25%** (Acme Dairy).
**Do, JSON.** `st tap id=import-format-toggle` → JSON → "Sample meals (json)" → HAND-OFF save → "Import meals (json)" → HAND-OFF pick.
**Expect:** "Imported 3 meal(s)."; Home today: **Banana** under Snack and **Greek salad** under Lunch; Diary 2026-05-13: **Porridge with milk** under Breakfast. R → all present.
**Fail if:** fewer meals imported than the sample holds; imported items missing after R.
**Note:** the JSON sample logs to the diary, the CSV sample only to the library. That's by design, but worth a line in the report.

### 5.4 Row 35: Clear cached items
*Ids:* text `text^=Clear cached items` (disabled at 0) → dialog "Clear cached items?" CANCEL / OK. *DE:* "Cache leeren".
**Do.** `st mark "row 35"` → the subtitle reads "N item(s) · size" with N > 0 (from the 2.5a and row 23 searches) → tap → `st tap text=OK`.
**Expect:** subtitle "0 item(s) · 0 B", the row `{disabled}`. R → still 0. A new `nutella` search still returns results (from the network) and the count rises again.
**Fail if:** the count doesn't drop, or search breaks.

### 5.5 Row 36: Reset profile data, last of all
*Ids:* `settings-delete-all-data` → dialog "Reset profile data?" CANCEL / "Reset profile". *DE:* "Profildaten zurücksetzen", "Profil zurücksetzen".
**Preconditions** (to test what the reset must clean):
- The daily reminder on again (no permission dialog the second time; time any) → `st alarms` shows the alarm.
- The maintainer's AI key is still saved (subtitle "On — <Provider>").
- `st save 36-settings-*` for the device-wide values.

**Do.** `st mark "row 36"` → `st scroll_to id=settings-delete-all-data` → tap → `st tap "text=Reset profile"`.
**Expect:**
1. The app lands on onboarding (`onboarding-checkbox-privacy`).
2. `st alarms`: no alarm for the package (#764 fixed).
3. R → still onboarding.

(The AI-key check is in D6, after re-onboarding.)
**Fail if:** 1–3 fail; any exception.

### 5.6 D6: Restore after reset, what a reinstalling user sees (after the end)
**Do.** Onboard again exactly as 2.2 (English labels if the app is still English: device-wide settings survive). Then:
**Expect, by design (`delete_all_user_data_usecase.dart:49-52`):**
- **Survive (device-wide):** language English, theme, food, height and body-weight units, energy unit, accent, the three Display switches, nutrient visibility, food databases, the grams-first switch: all as in `36-settings-*`.
- **Back to defaults (per-profile):** kcal adjustment 0, macro split 60/15/25, per-meal share 30/40/20/10, water goal W0, Health Connect off.
- AI: subtitle "Off — no key saved" (#892).

Then **import the zip** (Settings → Export / Import → JSON → Import → **HAND-OFF** the picker → `ont-settings-run.zip`).
**Expect:** the diary and weight history come back; **per-profile goals stay at their defaults** (they're not in the export).
**Verdict:** pass if it matches the lists above. The goals not coming back is *by design*. It belongs in the report as a **Note** with weight, because it is a path on which a user would say "settings don't save" (inventory: `allowBackup=false`, settings not in the export).

---

## 6. Wrap-up

1. `st logcat_stop`; `st errors` over the whole run. Every exception must already sit on a row. Any new one gets attributed by its `mark`.
2. Leave 2.4.0+66 installed, on its onboarded D6 profile. Do not uninstall or `pm clear`.
   **HAND-OFF (cleanup, the maintainer decides):** the run leaves behind the Health Connect grant, the notification permission, and `ont-settings-run.zip` plus the two sample files in Downloads. The session doesn't remove them, because that is system settings and shared storage.
3. `run.log`, `logcat.txt`, `shots/` and `dumps/` stay in the evidence folder (laptop only). Durable notes go to the run ticket's resolution comment.
4. Fill the report table.

## Report table (template for the run ticket)

One line per row. *Verdict:* `pass` / `fail` / `inconclusive` / `skipped` / `reference → #N` (a check may also be `fail → #N` when a known bug was hit anyway). *Did / saw / expected* is short and concrete. *Evidence* is the file under the run's evidence folder.

| Row | Setting | Verdict | Did / saw / expected | Evidence |
| :-- | :-- | :-- | :-- | :-- |
| U1 | Language → English (2.3.0 → 2.4.0) | | | `dumps/U-before.txt`, … |
| U2 | Kcal adjustment +300 | | | |
| U3 | Macro split 50/19/31 | | | |
| U4 | Per-meal share Mediterranean | | | |
| U5 | Food units Imperial | | | |
| U6 | Body weight st | | | |
| U7 | Energy kJ | | | |
| U8 | Show Meal Macros off | | | |
| U9 | Accent preset 13 | | | |
| 1 | Food units | | | |
| 2 | Height units | | | |
| P4 | Height typed (ft/in), OK only / Done + OK | | | |
| 3 | Body weight unit | | | |
| I | Imperial × weight entry, OK only / Done + OK | | | |
| I-w | Imperial × water | reference → #1306 | | |
| 4 | Energy unit [flagged], Home / Diary / Trends / sheets | | | |
| 4-h | Meal headers in kJ | reference → #1315 | | |
| K1 | kJ × kcal adjustment typed, Done + OK | | | |
| K1-ok | kJ × kcal adjustment typed, OK only | reference → #1347 | | |
| K2 | kJ truncation 1255 → 1251 | Note | | |
| K3 | kJ × macro split typed | | | |
| 5 | Default to weight/volume | | | |
| 6 | Kcal goal info | | | |
| 7 | Kcal adjustment [flagged], Done + OK / slider; Home / info / Diary / Trends | | | |
| 7-ok | Kcal adjustment, OK only | reference → #1347 | | |
| 7b | Calorie reference [flagged] | | | |
| 8 | Macro split [flagged], OK only / Done + OK / slider; Home / Diary / Trends | | | |
| 9 | Per-meal share, presets | | | |
| 9-s | Per-meal share, sliders | reference → #715 | | |
| 10 | Nutrient goals [flagged], slider / Done + OK; Diary panel | | | |
| 10-ok | Nutrient goals, OK only | reference → #1347 | | |
| 10-empty | Nutrient goals on a day without an entry | reference → #1348 | | |
| 10-reset | Nutrient goals Reset + Save | reference → #1349 | | |
| 10-next | Nutrient goals the next day | reference → #1316 | | |
| 10-B6 | Nutrient goal saved while the day boundary is moved (4.2) | | | |
| 11 | Day starts at [flagged] | | | |
| 12 | Show Activity Tracking | | | |
| 13 | Show Meal Macros [flagged], Home / Diary | | | |
| 14 | Show Micronutrients | | | |
| 15 | Nutrient visibility [flagged], Diary panel | | | |
| 16 | Theme | | | |
| 16-a | Theme-change assertion | reference → #765 | | |
| 17 | Accent, Material You | | | |
| 18 | Accent, preset | | | |
| 19 | Accent, custom hex, OK only / Done + OK | | | |
| 20 | Language [flagged], in-app / per-app locale hand-off / reminder text | | | |
| 20-f | Languages below the fold | reference → #1331 | | |
| 21 | Daily reminder switch | | | |
| 22 | Reminder time, OK only / Done + OK | | | |
| 23 | Food databases | | | |
| 24 | Health Connect auto import [flagged] | | | |
| 25 | HC calorie credit | | | |
| 26 | HC import now / sources | | | |
| 27 | AI provider radio | | | |
| 28 | AI key (hand-off), persists and is used | | | |
| 28-g | Gemini `AQ…` key | reference → #1253 | | |
| 29 | AI own server, OK only / Done + OK | | | |
| 30 | AI pause | | | |
| 31 | AI remove (own server) | | | |
| 32 | Import custom food, CSV / JSON samples | | | |
| 33 | Export app data | | | |
| 33-r | Export onto an existing name | reference → #763 | | |
| 34 | Import app data [flagged], Home / Diary / tracked-day goals / Trends / You / config untouched | | | |
| 34-dup | Import onto a live install: intakes and activities doubled? | | | |
| 35 | Clear cached items | | | |
| 36 | Reset profile data | | | |
| D6 | Restore after reset (what a reinstalling user keeps) | | | |
| 37 | Crash reports [flagged] (persistence; effect inconclusive in a debug build) | | | |
| 38 | Disclaimer | | | |
| 39 | Sources & References | | | |
| 40 | Report Error (dialog; mail hand-over skipped) | | | |
| 41 | About | | | |
| 42 | Water goal [flagged], Done + OK / slider / Reset; You / Home / Trends | | | |
| 42-ok | Water goal, OK only | reference → #1347 | | |
| 43 | Health disclosure, before any system UI | | | |
| 44 | AI consent screen | | | |
| P1 | Activity level (You) | | | |
| P2 | Weight goal (You) | | | |

## Appendix: rows without an id, by label

The rows the ticket asked about, with the label the Pixel shows in each language. Everything else has a `resource-id` (above).

| Row | English (run language) | German (phone, before U1/2.3, during the row 20 hand-off) |
| :-- | :-- | :-- |
| Settings card on You | Settings | Einstellungen |
| 12 | Show Activity Tracking | Aktivitätstracking anzeigen |
| 13 | Show Meal Macros | Makros je Mahlzeit anzeigen |
| 14 | Show Micronutrients | Mikronährstoffe anzeigen |
| 15 checkboxes | fiber, sodium, saturated fat, sugar, calcium, iron, potassium, vitamin D, vitamin B12, magnesium (lowercase) | Ballaststoffe, Natrium, …, Eisen, … |
| 16 | Theme: System default / Light / Dark | Thema: Systemstandard / Hell / Dunkel |
| 20 | Language | Sprache |
| 21 | Daily Reminder | Tägliche Erinnerung |
| 22 | Reminder time: HH:MM | Erinnerungszeit: HH:MM |
| 23 switches | Open Food Facts, FoodData Central (…), Bundeslebensmittelschlüssel (BLS) | the same (proper names) |
| 33/34 | Export / Import App Data; Export; Import | App-Daten exportieren / importieren; Exportieren; Importieren |
| 35 | Clear cached items | Cache leeren |
| 37 | Privacy Settings; Send crash reports | Datenschutzeinstellungen; Absturzberichte senden |
| 38 | Disclaimer; I understand | Hinweis; Ich habe verstanden |
| 39 | Sources & References | Quellen & Referenzen |
| 40 | Report Error | Fehler melden |
| 41 | About | Über |
| Dialog buttons | OK, CANCEL, Reset, Save | OK, ABBRECHEN, Zurücksetzen, Speichern |
| System: notification permission | — | Zulassen / Nicht zulassen |
| System: file picker | — | Downloads, Speichern |
