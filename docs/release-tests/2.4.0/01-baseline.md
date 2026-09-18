# Release 2.4.0 — Part 1: the pre-upgrade baseline

Done by hand on the Pixel 6, before the candidate goes on. Map: [#1232](https://github.com/simonoppowa/OpenNutriTracker/issues/1232); this script is the asset of [#1237](https://github.com/simonoppowa/OpenNutriTracker/issues/1237) and is run in [#1239](https://github.com/simonoppowa/OpenNutriTracker/issues/1239).

**Why this exists.** The candidate's startup repair (#1193) rewrites every Open Food Facts row that an older build saved: cholesterol, sodium, potassium, magnesium, calcium, iron, zinc, phosphorus, vitamin C, vitamin B6 and niacin ×1000; vitamins A, D and B12 ×1,000,000. Macros, fibre, sugar and the fat fractions never change; custom, FDC/BLS and recipe-*logged* rows are never touched. Everything below is the "before".

**Where the numbers really live.** The product screen rounds micronutrients to two decimals and the diary panel to one (none from 10 up), so a pre-#775 iron of 0.0021 shows as `0.0mg` on both — the screen cannot be the numeric baseline. The **export zip** holds the raw doubles (`user_intake.json`, `user_recipes.json`); the session diffs those after the upgrade. The tables you fill in only show what the screens said, so the candidate script can check the screens went from "tiny or `—`" to "sensible".

**A step whose Expect does not match is a pre-existing finding on that build, not a candidate bug.** Write it down and carry on.

**Take the notes on the laptop**, not on the phone — the tables are too wide for a phone screen. Reckon on about an hour for Part A and ten minutes for Part B.

The facts about what is on the phone (the two installs, the second profile, which days have meals) come from the session's adb inspection on 2026-09-18, not from the code; where a day turns out empty, use the nearest day that has meals and write the date.

## Before you start

- The session has just reinstalled `.develop` as a true v2.3.0 build (data kept). Check the version string at the bottom of **You → Settings** at the start of each part:
  - **`.develop`** (`com.opennutritracker.ont.opennutritracker.develop`) must read **"Version 2.3.0-develop"**. Part A.
  - **`full`** (`com.opennutritracker.ont.opennutritracker`) must read **"Version 2.2.0"**. Part B, notes only.
- Tabs are **Home**, **Diary**, the centre **+** (tooltip "Add"), **Trends**, **You**. Settings is the collapsed **"Settings"** tile at the bottom of **You**.
- Tapping a logged meal row opens only an **"Edit item"** amount dialog — it never shows nutrients. Micronutrients are read on a *product screen*, reached from **+ → a meal tile → the "Recently" cards** or from a search; you leave it with the phone's back button unless the step says **"Add"**.
- **Never tap the pencil (edit) icon on a product screen.** Saving that form and then tapping Add logs an Open Food Facts row with hand-typed values that the repair would scale like the rest. If you did, back out without saving and say so.
- **Never open "Switch profile", "Add profile" or "Manage profiles"** on either install. Tapping a row switches at once; a profile that has not finished onboarding (the second one on `.develop` is empty) lands in onboarding, whose "Try Demo" wipes that profile's data and clears the shared recipe and custom-meal libraries — your Baseline recipe and Baseline custom with them.
- **On a meal list, do not open a section's ⋮ menu (Copy to today / Delete all / Share), do not drag a row, and do not tap the weight chip on Home** — each of those writes.
- In Settings → Data, the tiles under Export/Import are **"Clear cached items"** and the red **"Reset profile data"**. Tap neither; if "Clear cached items?" opens, choose Cancel. The cache is one of the boxes the repair covers.
- Have ready: a laptop path for two zip files (the session pulls them from the phone's Download folder), and optionally one packaged food with a barcode (A7). No AI key, no Health Connect.

---

## Part A — `.develop` on v2.3.0

Fill this table as you go. Copy values exactly as printed (`0.0mg`, `—`); for the Diary panel copy `value / reference` and drop the italic *limit* word on the sodium row.

| Row | Item (name + brand) | Where | Sodium | Potassium | Magnesium | Calcium | Iron | Vitamin A | Vitamin D | Vitamin B12 |
|---|---|---|---|---|---|---|---|---|---|---|
| A4 | Diary panel, 2026-08-22 | "Today's nutrients" | | | | | | n/a | | |
| A5a | | cached OFF product (Recently) | | | | | | | | |
| A5b | | cached OFF product (Recently) | | | | | | | | |
| A6 | | new OFF intake, by search | | | | | | | | |
| A7 | | new OFF intake, by barcode | | | | | | | | |
| A8 | | backend food — chip: | | | | | | | | |
| A9 | Baseline custom | custom meal | | | | | | | | |
| A10a | Baseline recipe | recipe, via "Log this Recipe" | | | | | | | | |
| A10b | Baseline recipe | the logged Lunch row, via Recently | | | | | | | | |
| A15 | Diary panel, today | "Today's nutrients" | | | | | | n/a | | |

**A1. Version, language, units.**
**Do:** open `.develop` → **You** → expand **"Settings"** → scroll to the bottom. Then find **"Language"**, **"Food units"** and **"Energy unit"**.
**Expect:** the logo and **"Version 2.3.0-develop"**; Language shows a language name or the system default; Food units **"Metric (g, kg, ml, l)"**; Energy unit kcal.
**Note:** the language and the energy unit. If Food units is Imperial, switch to Metric now and note that you did (for products with a serving size the nutrient table switches to "Per Serving" in imperial and the numbers would not compare). Every "kcal" below means the energy unit noted here.

**A2. Which profile.**
**Do:** on **You**, read the header only: avatar, name, subtitle "Switch profile". Do not tap it.
**Expect:** a name (an unnamed profile shows as "Profile 1").
**Note:** the name. That is the profile every later step must stay on.

**A3. Display switches.**
**Do:** Settings → **"Display"** → **"Show Micronutrients"** and **"Show Activity Tracking"**. Then **"Nutrients"** ("Pick which nutrients appear on the diary panel") and, under Goals & nutrition, **"Nutrient goals"**.
**Expect:** two switches; the Nutrients list; the Nutrient goals screen.
**Note:** which switches were already on (turn both on if not); whether every nutrient is shown; whether any Nutrient goal has a value — the panel's reference then shows that value instead of the age/sex default.

**A4. The existing day.**
**Do:** **Diary** → tap the calendar's left chevron until August 2026 → tap **22**. Expand **"Today's nutrients"** (leave "Day" selected).
**Expect:** the meals logged that day under Breakfast / Lunch / Dinner / Snack — all four headers show, an empty one has only a grey card with a + icon. If 22 August is empty, use the nearest August day with meals and write the date. Panel rows read like `0.0 / 15µg` (vitamin D; the reference depends on the profile's age and sex) and `0.0 / 2.4µg` (B12).
**Note:** each meal's name, amount and kcal; the panel's sodium, potassium, magnesium, calcium, iron, vitamin D and B12 into row A4. Do not tap or long-press a row (tap = edit, long-press = copy/delete).

**A5. Two cached Open Food Facts products.**
**Do:** **+** → the sheet "Add new Item:" → tap the **"Breakfast"** tile (not a card in the sheet's own "Recently" strip). The meal screen opens with the **"Recently"** chip selected; do not type in the search field. Pick two cards carrying the muted **"Open Food Facts"** chip. For each: tap it → wait until the thin progress bar under the macro row is gone (a first open may fetch the product) → scroll to **"Nutrition Information"** (header "Per 100g/ml") → the **"Micronutrients"** section is open when the product has data; tap its header only if it is collapsed. Copy the values. Press the phone's **back** button — do **not** press "Add".
**Expect:** a two-line button "More Information at / OpenFoodFacts" and the Open Food Facts disclaimer under the table; micro rows tiny or `—`.
**Note:** rows A5a and A5b (A5b is optional if time is short), and whether the progress bar appeared. For any Open Food Facts card the screen may be showing the cached product rather than the stored intake, bar or no bar; the repair rewrites both stores, and the export holds the intake's own numbers either way.

**A6. A new Open Food Facts intake, by search.**
**Do:** **+** → **"Lunch"** → **"Products"** chip → search e.g. `cheddar` → pick a card with the **"Open Food Facts"** chip. On the product screen wait for the progress bar to go and the Micronutrients rows to fill; if every row is `—`, back out and pick another product. Copy the values. Set **Unit** to **g** first, then **Quantity** `100` (the screen may default to 1 serving). Tap **"Add"**; if "This food has already been added to this meal today. Add it again?" appears, tap "Add".
**Expect:** snackbar "Added new intake"; on Home the item sits under Lunch.
**Note:** row A6 and the exact name + brand — A10 reuses it.

**A7. A new Open Food Facts intake, by barcode.** *(Skip if you have no product to hand — write "skipped".)*
**Do:** **+** → **"Snack"** → the barcode icon in the search bar → scan. On the product screen do exactly as in A6 (wait, copy, unit g — ml if it is a drink — quantity 100, "Add").
**Expect:** as A6.
**Note:** row A7 and the unit logged.

**A8. One backend food.**
**Do:** **+** → **"Dinner"** → **"Food"** chip → search `banana` → pick a card whose chip reads **"FDC Foundation"**, "FDC SR Legacy", "FDC Survey", "FDC Branded" or "BLS" — not "Open Food Facts". Copy the values, unit g, quantity 100, **"Add"**.
**Expect:** a two-line button "More Information at / FoodData Central (Foundation Foods)" (or the long name matching the chip); micro values already in sensible mg/µg. If the Food chip returns nothing, check Settings → Food databases has a source enabled and note which.
**Note:** row A8 with the chip text. These must be identical after the upgrade.

**A9. One custom meal.**
**Do:** **You** → **"Recipes"** → **+** (top right) → **"New Custom Food"**. The screen is titled "Edit meal". "Meal name" `Baseline custom`; **"Form view" → "Advanced"**; "Energy (kcal)" `105`, Carbohydrates `10`, Fat `5`, Protein `5`; under Micronutrients: sodium `200`, calcium `100`, iron `2`, vitamin D `5`, vitamin B12 `1`. Leave every other field alone. Tap **"Save"** (there is no "Save for next time" box on this path; if "Numbers don't quite line up" appears, tap "Save anyway"). Then log it: **+** → **"Snack"** → search `Baseline custom` (the card has no source chip) → unit g, quantity 100 → **"Add"**.
**Expect:** button "Custom Meal Item"; sodium `200.0mg`, calcium `100.0mg`, iron `2.0mg`, vitamin D `5.0µg`, vitamin B12 `1.0µg`, vitamin A `—` (the form has no vitamin A field).
**Note:** row A9. Must be unchanged after the upgrade.

**A10. One recipe with an Open Food Facts ingredient.**
**Do:** **You** → **"Recipes"** → **+** → **"Create Recipe"**. "Recipe name" `Baseline recipe`. **"Add Ingredient"** → **"Products"** tab → search the A6 product (this picker shows no source chip — match name + brand) → tap it → Amount `100`, Unit g → **"Add"**. Repeat with `Baseline custom`, 100 g. Check "Total weight (g)" reads 200, then **"Save Recipe"**.
Open the recipe → **"Log this Recipe"** → **"Lunch"**. On the product screen copy the Micronutrients into row **A10a** (sodium should be roughly (200 + tiny) / 2 ≈ `100mg`; if a row is `—`, write it and say so), set unit g and quantity `100`, then **"Add"**.
Then **+** → **"Lunch"** → in "Recently" tap the **Baseline recipe** card → copy the same rows into **A10b** → back button, not "Add".
**Expect:** button "Custom Recipe" on both screens; A10a and A10b identical today.
**Note:** both rows. After the upgrade they diverge on purpose: the recipe library (A10a) is recomputed from its repaired ingredient; the Lunch row logged from it (A10b) is a recipe-source intake and is left alone.

**A11. One activity.**
**Do:** **+** → the **"Activity"** tile (if it is missing, A3 was not done) → search `walking` → tap a result → Quantity `30` (the unit is fixed to min) → **"Add"**.
**Expect:** snackbar "Added new activity"; the Home "burned" mini-stat rises.
**Note:** the activity's name and kcal.

**A12. Weight on seven days.**
**Do:** **You** → **"Weight history"**. First write down any rows already listed. Then **"Add entry"** → **"Date"** → pick the day → Weight → OK, for the **six previous days first and today last** (e.g. 80.3, 79.8, 80.1, 79.9, 80.2, 79.7, then today 80.0 — those are kg; the field is in the profile's body-weight unit, so use your own plausible values in that unit and note the unit). Do not touch the trash icons — they delete instantly.
**Expect:** "Log at least two days to see your trend." disappears after the second entry; at least seven rows, one per day (an entry on a day that already had one replaces it). Today's entry becomes the profile weight (the weight chip on Home changes).
**Note:** the seven date = weight pairs on one line, and whether any day was replaced.

**A13. Today's calorie goal** — after A12, because today's weight feeds it.
**Do:** **Home** → tap the big calorie ring (tooltip "How your goal is calculated") → scroll to **"Today's calorie goal"**.
**Expect:** rows **"Your TDEE"**, **"Applied adjustment"**, **"Daily kcal adjustment"**, **"Activity"** and the total.
**Note:** all five numbers. After the upgrade the first three must be unchanged; the Activity row and the total move with whatever is logged that day.

**A14. Water and fasting.**
**Do:** nothing, unless you use them. If you log a glass via the Home water chip, say how much.
**Expect:** untouched, the water chip reads `0 / <goal> ml`; no fasting chip shows while no fast runs.
**Note:** "water: not used / used <ml>", "fasting: not used / running since <time>".

**A15. Today's panel.**
**Do:** **Diary** → today → expand **"Today's nutrients"**.
**Expect:** today's meals (A6–A10 and the activity), the panel populated.
**Note:** the panel's rows into row A15.

**A16. Export.**
**Do:** **You** → **"Settings"** → **"Data"** → **"Export / Import App Data"**. Leave **JSON** selected → tap only **"Export"**. The picker that opens asks you to name and save a *new* file: choose **Downloads**, rename it to `ont-develop-230.zip`, Save. (If the picker instead asks you to pick an *existing* file, you tapped "Import" — press back; the dialog then shows "Export / Import error", which is harmless; tap "Export".) Close the dialog by tapping outside it.
**Expect:** a check icon and "Export / Import successful". The zip holds `user_intake.json`, `user_recipes.json`, `user_activity.json`, `user_tracked_day.json`, `weight_log.json`, `custom_activity_templates.json` and photos — not the saved custom-meal templates (the logged Baseline custom row is in `user_intake.json`), not settings, not water or fasting.
**Note:** the file name as saved (if the picker would not rename, keep `opennutritracker-export.zip` and say so). Tell the session ".develop baseline done".

> **Session:** `adb pull /storage/emulated/0/Download/ont-develop-230.zip`, check the size is well above 0 and `unzip -l` lists `user_intake.json`, before Part B. If the default name was kept, `adb shell ls -t /sdcard/Download | head` and pull the newest zip, renaming it locally. Delete nothing on the phone.

---

## Part B — `full` on v2.2.0

**Add nothing, change nothing on this install.** Read and export only. Do not open any product screen; do not tap or long-press any meal or activity row (tap = edit dialog, long-press = copy/delete); do not open a section's ⋮ menu, drag a row, tap the weight chip, or touch Weight history; do not open "Switch profile".

The panel is your real August data before the repair. Its one-decimal rounding turns every pre-repair Open Food Facts contribution into `0.0`, so no ratio can be read off the screen — the session compares the exports instead; the rows here only show the screen went from `0.0` to something.

| Row | Day | Where | Sodium | Potassium | Magnesium | Calcium | Iron | Vitamin D | Vitamin B12 |
|---|---|---|---|---|---|---|---|---|---|
| B2 | 2026-08-31 | "Today's nutrients" | | | | | | | |
| B3 | | "Today's nutrients" | | | | | | | |

**B1. Version, language, units, profile.**
**Do:** open `full` → **You**: read the header name; expand **"Settings"** → scroll to the bottom; read "Language" and "Food units".
**Expect:** **"Version 2.2.0"**.
**Note:** profile name, language, food units. Change nothing.

**B2. The last logged day.**
**Do:** **Diary** → left chevron to August 2026 → tap **31** (if it is empty, the nearest earlier day with meals; write the date) → expand **"Today's nutrients"**.
**Expect:** that day's meals under their headers and the panel.
**Note:** each meal's name, amount and kcal; the panel rows into B2.

**B3. One earlier day with meals.**
**Do:** the same for another August day.
**Expect:** as B2.
**Note:** the date, the meal list, the panel rows into B3.

**B4. Export — the backup.**
**Do:** **You** → **"Settings"** → **"Data"** → **"Export / Import App Data"** → JSON → tap only **"Export"** → in the save picker choose Downloads, rename to `ont-full-220.zip`, Save. (A picker asking for an *existing* file means you tapped "Import": press back, ignore the harmless "Export / Import error", tap "Export".)
**Expect:** "Export / Import successful".
**Note:** the file name as saved.

> **Session:** `adb pull /storage/emulated/0/Download/ont-full-220.zip`, same checks and same default-name fallback as before. This zip is the backup for the `full` upgrade later in the run.

**B5. Leave it.**
**Do:** return to **Home**.
**Expect:** Home with today (probably empty).
**Note:** "nothing else touched".

---

## Part C — hand back

- [ ] Part A table, every row (or "skipped" for A7).
- [ ] A1–A3: language, energy unit, food units, profile name, which Display switches were already on, Nutrients all shown, any Nutrient goal set.
- [ ] A4: the 2026-08-22 meal list. A15: today's.
- [ ] A5: which two products; A6/A7: name + brand and the unit/quantity actually logged; A8: the chip text.
- [ ] A9: as shown. A10: "Total weight (g)", A10a and A10b.
- [ ] A10: unit and quantity logged. A11: activity + kcal. A12: seven date = weight pairs, the unit, replaced days. A13: the five goal-screen numbers. A14: water / fasting.
- [ ] A16 and B4: the two file names as saved; whether "Export / Import successful" appeared.
- [ ] Part B table with dates and the meal lists; B1 strings.
- [ ] Anything that did not match its Expect, with what you saw instead.
