# Release 2.6.0: the Pixel 6 run script

The device run that [#1464](https://github.com/simonoppowa/OpenNutriTracker/pull/1464)'s *Not verified on device* list asks for. A session runs it over adb on the Pixel 6 with the hardened driver from 2.5.0, and the result is a verdict per area for the release PR.

Written 2026-10-25 against `release/2.6.0` at `be31e6e5` (the candidate) and `v2.5.0` at `1ab4940a`. Every identifier and German label below was read from those two trees. The structure, rules and driver are 2.5.0's ([script](https://github.com/simonoppowa/OpenNutriTracker/blob/research/release-2.5.0-pixel-test/docs/release-tests/2.5.0/script.md), [driver README](tools/README.md)). This file only says what differs.

| Part | What | Steps |
| :-- | :-- | :-- |
| 0 | Preflight | P1–P6 |
| 1 | Before: data on 2.5.0, including a comma-decimal record | B1–B4 |
| 2 | Path 1: upgrade in place | U1–U6 |
| 3 | The add-food redesign (#1460) | AF1–AF15 |
| 4 | AI entry points with a real key (#1460) | AI1–AI4 |
| 5 | Robustness fixes (#1456, #1457, #1458, #1463) | RB1–RB4 |
| 6 | Every other area at smoke depth | K1–K10 |
| 7 | English pass, then back to German | E1–E4 |
| 8 | Wrap-up | W1–W3 |

Plan on three to four hours.

## What changed since 2.5.0 (and so what the run covers)

- **#1460 add food, redesigned.** Barcode / Snap meal / Describe tiles under the search field; one *To log* list that every entry method adds to; one button logs it all; a + on a search result adds the detail screen's default amount; a restyled review screen. Fixes on the release branch: `eb292893` (a + still fetching when the list was logged) and `be31e6e5` (the list's Clear).
- **#1463 an intake save is all or nothing.** The device can't make the tracked-day write fail, so the rollback is unit-tested only. The run checks the success path: one entry per item, and day totals equal to the sum.
- **#1456 / #1457 / #1458 robustness.** Comma-decimal quantities, bad meal URLs, info-link launches, bad Open Food Facts fields, Health Connect rate limits, and links going through the safe launcher.
- **Translations** (#1454, #1462: Russian, Dutch).
- iOS (#1450): out of scope.

## Constants

```bash
RT="bash docs/release-tests/2.6.0/tools/rt.sh"   # 2.5.0's driver, RT_ROOT moved to ~/Documents/ont-release-2.6.0-evidence
ADB="$HOME/Android/Sdk/platform-tools/adb -s 18101FDF60010M"
PKG=com.opennutritracker.ont.opennutritracker
APKS=~/Documents/ont-release-2.6.0-evidence/apks
APK_250=~/Documents/ont-release-2.5.0-evidence/apks/ont-full-candidate-c293acff-debug.apk   # sha256 95232d69…a40df0
APK_CAND=$APKS/ont-full-2.6.0-be31e6e5-debug.apk                                            # sha256 in U1
FX=docs/release-tests/2.6.0/fixtures
CMP="python3 -I $FX/compare_exports.py"
```

**The installed build is 2.5.0's code.** The phone holds the 2.5.0 run's candidate `c293acff` (sha256 `95232d69…`). It differs from `v2.5.0` only in `pubspec.yaml`'s version line (`git diff --stat c293acff4 v2.5.0 -- lib android pubspec.lock` is empty), so it is the "before" as it stands. It reads `versionName 2.4.0` for the same reason, and the candidate reads `2.6.0` / `68`.

**The candidate is built against the real backend.** Unlike 2.5.0's `.env.example` builds, the APK is built with `.env` symlinked to the main checkout's file. The app compiles in only `SENTRY_DNS`, `SUPABASE_PROJECT_URL` and `SUPABASE_PROJECT_ANON_KEY`, all of which ship in every store build, and Sentry starts only in release mode (`main.dart`, `kReleaseMode`), so this debug build never reports. BLS/FDC search and the portion RPCs are therefore in scope for the first time. The generated `env.g.dart` and the scratch worktree are deleted after the build.

## Rules

All of 2.5.0's *Rules that hold everywhere* apply, with the prefix `ont-r26-` instead of `ont-r25-`. Additions:

1. **The camera.** Snap meal's sheet item `bulk-add-photo-camera` ("Foto aufnehmen") opens the system camera app: focus would leave the package and the driver would abort. Never tap it. The same goes for `edit-meal-barcode-scan`. The barcode tile opens the app's own scanner, which is fine: it is entered by manual entry (K3 of 2.5.0).
2. **The To-log list holds nothing durable.** Leaving the add-food screen with items on it asks first. Every step that builds a list either logs it or discards it explicitly before the step ends. A resumed step starts from an empty list: if `rt has id=add-meal-tray-list`, `rt tap id=add-meal-tray-clear` first.
3. **The meal type.** Part 3 logs into *Frühstück* (`add-item-breakfast`) on day 0 unless the step says otherwise, so the totals are read off one meal section.
4. **Numbers.** Every kcal figure the run compares is read from the screen (`rt get`) before and after, never assumed. A difference of more than 1 kcal between a To-log row, the log button total, Home and the Diary is *wrong nutrition numbers* (blocks).

**The bar** is unchanged: a crash, data loss, wrong nutrition numbers, or a regression against 2.5.0 blocks the release. Everything else ships with an issue.

### Expected English in the German UI

New in #1460 and in `intl_en.arb` only: "Snap meal", "Describe", "Review items", "Update matches", "Your photo", "Retake", "Add to list", "Add {n} items", "To log · {n}", "Remove from list", "Added to list", "Couldn't log these items. Try again.". Note each once; none is a failure. "AI" on the two tiles is untranslated by design.

---

## Part 0 — Preflight

**P1 — Pin the run.** `rt init` → `EVID=$(cat ~/Documents/ont-release-2.6.0-evidence/current-run)` → `mkdir -p $EVID/exports $EVID/fixtures` → `rt resume`. No ABORT, no HALT.

**P2 — The phone is free.** Read the last line of the shared phone log (`~/.config/Claude/side-session-notes/local_27e760d0-…/pixel6-device-use.md`): it must be a *done* line from every other session, or this run's own start line. Append a start line otherwise. Stop if another session is mid-test.

**P3 — Launch and preflight.** `rt launch` → `rt preflight 2.4.0` (the installed build reads 2.4.0). Exit 0. Exit 4 on a device-settings row: stop and record it (the run doesn't change device settings). Write down day 0 and the hour from `rt clock`.

**P4 — What is installed.** `pm list packages | grep opennutritracker` (only `$PKG`), `rt version`, and the `base.apk` sha256 must be `95232d69…a40df0`.

**P5 — The candidate APK.** `sha256sum $APK_CAND`, `aapt dump badging` (`name='com.opennutritracker.ont.opennutritracker' versionCode='68' versionName='2.6.0'`), `apksigner verify --print-certs` (`0bdae1d6…5ff5`, the same as the installed app).

**P6 — Fixture and grants.** `python3 -I $FX/make_comma_fixture.py $EVID/fixtures --today <day 0>` → `$ADB push $EVID/fixtures/ont-comma.zip /sdcard/Download/ont-r26-comma.zip` → `rt prep`.

## Part 1 — Before: data on 2.5.0

*Blocks if:* nothing here judges the candidate; a failure here stops path 1.

**B1 — First look.** `rt mark B1` → `rt save B1-home` → note the language, the Home kcal ("verbleibend"), and *Frühstück*'s total on day 0. → `rt errors`.

**B2 — Log one entry on 2.5.0.** Guard: if the Diary already lists "ONT Vorher" on day 0, skip to Expect. Do: `fab-add-item` → `add-item-breakfast` → `add-meal-quick-add` → `quick-add-title` "ONT Vorher", `quick-add-energy` 123, carbs 10, fat 5, protein 8 → `quick-add-submit` → back to Home. Expect: *Frühstück* day 0 up by 123 kcal. This is the "logged before the upgrade" intake.

**B3 — Import the comma record on 2.5.0.** `[import]` Guard: if the Diary lists "ONT Komma" on day 0 − 2, skip. Do: Settings → `rt tap "text^=App-Daten exportieren / importieren"` → `CSV` → `Importieren` → `rt tap text=ont-r26-comma.zip` → `rt wait "text=Export / Import erfolgreich" 60` → `rt back` → Diary day 0 − 2 → `rt save B3-diary`. Expect: "ONT Komma" listed, 274 kcal. **Don't open the add-food screen on 2.5.0 after this step**: its Recent list would throw on this record (the bug #1456 fixes) and the run would halt.

**B4 — Baseline export.** `[export]` JSON → `ont-r26-base.zip` → pull to `$EVID/exports/base.zip` → `$CMP summary $EVID/exports/base.zip > $EVID/exports/base.txt`. Expect: "ONT Vorher" and "ONT Komma" in the intakes, the comma quantity stored as `137,0`.

## Part 2 — Path 1: upgrade in place

*Blocks if:* onboarding or a red screen after the upgrade; anything in `base.zip` missing or changed; day totals ≠ the sum of the day's entries.

**U1 — The right APK.** sha256 and badging as in P5.

**U2 — Install and launch at once.** `rt mark U2` → `timeout 300 $RT install $APK_CAND` → immediately `rt launch` → the installed `base.apk` sha256 is the candidate's; `rt version` reads 2.6.0 / 68; `firstInstallTime` unchanged.

**U3 — First launch clean.** `rt save U3-home` → `rt errors` → logcat after `MARK_U2`: `main: Starting App`, no `SEVERE`, no FATAL. Home's kcal equals B1's minus B2's 123.

**U4 — Nothing lost.** `[export]` JSON `ont-r26-up1.zip` → pull → `$CMP diff $EVID/exports/base.zip $EVID/exports/up1.zip > $EVID/exports/U4.txt`. Expect `VERDICT: identical` (or `superset` with only reconciler-corrected tracked days, each with `new_tracked == new_sum`).

**U5 — It's really 2.6.0.** `fab-add-item` → `add-item-breakfast` → `rt has id=add-meal-method-describe` → `rt has id=meal-search-barcode` must be **absent** → `rt back`.

**U6 — Two cold starts change nothing.** `rt restart` twice; at most one reconciler line; Home unchanged.

## Part 3 — The add-food redesign (#1460)

*Search screen* = `rt tap id=fab-add-item` → `rt tap id=add-item-breakfast`. *Blocks if:* a crash; an item logged twice or not at all; a To-log total, Home or the Diary disagreeing by more than 1 kcal; leaving with items on the list drops them without asking.

**AF1 — Layout.** Search screen → `rt save AF1` → `rt ls`.
Expect: `meal-search-field` with no barcode suffix (`meal-search-barcode` absent); three tiles `add-meal-method-barcode` "Barcode", `add-meal-method-photo` "Snap meal", `add-meal-method-describe` "Describe"; the chips Kürzlich / Favoriten / Alle / Produkte / Lebensmittel; no To-log list and no log button while it is empty; `add-meal-quick-add` "Schnelles Tracking" in the app bar. No label cut off in the screenshot.

**AF2 — The Recent list shows the comma record (#1456).** On the same screen with *Kürzlich* selected: `rt save AF2` → `rt has "text~=ONT Komma"`. Expect: the list renders, "ONT Komma" among the rows, no red screen, nothing in `rt errors`. 2.5.0 threw here (B3).

**AF3 — + on an Open Food Facts result adds the detail screen's default amount.**
Do: `rt field id=meal-search-field nutella` → `rt done` → `rt kb_hide` → `rt tap text=Produkte` → wait for results → note the first card's name → open that card (tap its title) → `rt wait id=meal-detail-add 60` → `rt save AF3-detail` (note the default Menge, unit and the kcal the add button shows) → `rt back` (no add) → `rt tap id=meal-item-add@1` → `rt wait id=add-meal-tray-list 30` → `rt save AF3-tray`.
Expect: one row with that name, reading "<amount> <unit> · <kcal>" with the same amount and kcal as the detail screen's default (one serving where the product has one); the title "TO LOG · 1"; `add-meal-tray-log` "1 Einträge speichern" plus the same kcal.

**AF4 — + on a database food (the backend).**
Do: `rt field id=meal-search-field apfel` → `rt done` → `rt kb_hide` → `rt tap text=Lebensmittel` → wait → `rt save AF4-results` → `rt tap id=meal-item-add@1` → `rt save AF4-tray`.
Expect: BLS/FDC rows with their source chip (the real `.env` reaches Supabase: no "No host specified" in logcat); a second row on the list; the button total = the sum of both rows.
Note: no rows plus a provider notice is *inconclusive* (network), and the step records the logcat line.

**AF5 — Meal detail adds to the list instead of logging.**
Do: open the second *Lebensmittel* result → `rt field edit=1 150` → `rt kb_hide` → `rt tap id=meal-detail-add` → back on the search screen → `rt save AF5`.
Expect: the search screen, not Home; a third row "150 g · <kcal>"; nothing logged yet (checked in AF10).

**AF6 — Barcode by manual entry adds to the list.**
Do: `rt tap id=add-meal-method-barcode` → `rt wait id=scanner-manual-entry-open 10` → tap it → `rt field id=scanner-manual-entry-field 3017620422003` → `rt tap id=scanner-manual-entry-submit` → `rt wait id=meal-detail-add 60` → `rt tap id=meal-detail-add` → `rt save AF6`.
Expect: back on the search screen with a fourth row (Nutella).

**AF7 — Quick add adds to the list.**
Do: `rt tap id=add-meal-quick-add` → title "ONT Schnell", energy 250, carbs 30, fat 10, protein 10 → `rt tap id=quick-add-submit` → `rt save AF7`.
Expect: a fifth row "ONT Schnell" · 250 kcal; nothing logged.

**AF8 — Remove one row.**
Do: `rt tap id=add-meal-tray-remove@4` (Nutella from AF6) → `rt save AF8`.
Expect: four rows, "TO LOG · 4", the total down by that row's kcal; the other rows unchanged.

**AF9 — Back with items asks first; Cancel keeps them.**
Do: `rt back` → `rt has "text=Änderungen verwerfen?"` → `rt save AF9` → `rt tap text=ABBRECHEN`.
Expect: the dialog "Änderungen verwerfen?" / "Deine ungespeicherten Änderungen gehen verloren." with ABBRECHEN and Verwerfen; after ABBRECHEN still on the search screen with four rows.

**AF10 — Nothing was logged yet; then log it all.**
Do: note the button's total T and the four names → `rt tap id=add-meal-tray-log` → `rt wait id=nav-home 30` → `rt save AF10-home` → Diary day 0 → `rt save AF10-diary` → `rt errors`.
Expect: the snackbar "Neue Aufnahme hinzugefügt"; back on the main screen; *Frühstück* day 0 up by T (±1) against B1 + 123; the Diary lists the four foods once each, with AF3's serving, AF4's 100 g default, AF5's 150 g and ONT Schnell 250 kcal. No entry twice.

**AF11 — Clear empties the list; Back then leaves without asking.**
Do: search screen → `rt field id=meal-search-field apfel` → `rt done` → `rt kb_hide` → `rt tap text=Lebensmittel` → `rt tap id=meal-item-add@1` → `rt wait id=add-meal-tray-clear 30` → `rt tap id=add-meal-tray-clear` → `rt save AF11` → `rt back`.
Expect: after Clear no list and no log button; Back returns to Home with no dialog; nothing logged (Frühstück unchanged).

**AF12 — Verwerfen discards.**
Do: search screen → *Kürzlich* → `rt tap id=meal-item-add@1` → `rt back` → `rt tap text=Verwerfen` → `rt save AF12`.
Expect: Home; Frühstück unchanged.

**AF13 — A + still fetching when Log is pressed (`eb292893`).**
Do: search screen → `rt field id=meal-search-field haferflocken` → `rt done` → `rt kb_hide` → `rt tap text=Produkte` → `rt tap id=meal-item-add@1` → wait for the row → then `rt tap id=meal-item-add@2` and, in the very next call, `rt tap id=add-meal-tray-log` → `rt save AF13`.
Expect: either the button was still disabled (the tap did nothing, and the second row arrives), then a second `rt tap id=add-meal-tray-log` logs **both**; or the fetch had already finished and both are logged. Either way both foods are in the Diary once.
Note: whether the tap landed inside the fetch can't be proven from adb timing. If both were logged and nothing was dropped, record *pass*, with the note that the race window wasn't proven.

**AF14 — A custom food from the add-food screen lands on the list.**
Do: search screen → `rt tap id=add-meal-custom-add` → `rt has "text=Benutzerdefinierte Mahlzeit erstellen?"` → `rt tap text=JA` → `rt ls` (read the editor's fields) → name "ONT Eigen 26", kcal 300, carbs 40, fat 10, protein 12 per 100 g, amount 100 g → `rt tap id=edit-meal-save` → `rt save AF14`.
Expect: back on the search screen, "ONT Eigen 26" on the list at 100 g · 300 kcal → then `rt tap id=add-meal-tray-log` → in the Diary once.
Note: if the editor's fields can't be told apart from `rt ls`, record *inconclusive* with the listing; don't guess.

**AF15 — Home and the Diary agree.** Home → note the kcal consumed; Diary day 0 → the day's total; `rt save` both. Expect: equal, and equal to B1 + 123 + every logged item above.

## Part 4 — AI entry points with a real key

The key is `~/.config/ont-run/ai-key` (OpenRouter), entered only through `rt type_secret`. *Blocks if:* the model supplies a nutrition value (every row's numbers come from a database); the key reaches the evidence; a crash.

**AI1 — Snap meal with no provider leads to AI setup.**
Do: Settings → `rt scroll_to id=settings-ai-assist` → `rt get id=settings-ai-assist`. Only if it reads off / no key: search screen → `rt tap id=add-meal-method-photo` → `rt wait id=ai-assist-provider-openrouter 10` → `rt save AI1` → `rt tap id=ai-assist-cancel` → `rt save AI1-after`.
Expect: the AI settings dialog opens by itself; after Cancel the screen is "Mehrere Einträge hinzufügen" with the text field (the user can still type the meal); `rt back` returns to the search screen.
Note: if a key is already stored, this step is *skipped: provider already configured*.

**AI2 — Save the key.** 2.5.0's DAI1 as written (provider OpenRouter → `rt type_secret` → `ai-assist-save-key` → consent if shown). Expect "An — OpenRouter"; the audit is clean.

**AI3 — Snap meal with a provider shows the disclosure, and stops there.**
Do: search screen → `rt tap id=add-meal-method-photo` → `rt wait id=bulk-add-photo-camera 15` → `rt save AI3` → `rt back` (closes the sheet) → `rt back`.
Expect: a sheet naming OpenRouter and the model, the common disclosure, the experimental note, and "Foto aufnehmen". **Not tapped** (rule 1). Closing it leaves the review screen with nothing sent.

**AI4 — Describe → review → list → log.**
Do: `rt mark AI4` → search screen → `rt tap id=add-meal-method-describe` → `rt wait id=add-meal-describe-input 5` → `rt tap id=add-meal-describe-input` → `rt type "2 Eier und eine Scheibe Vollkornbrot"` → `rt kb_hide` → `rt tap id=add-meal-describe-submit` → `rt wait id=bulk-add-row-list 90` → `rt save AI4-review` → `rt tap id=bulk-add-submit` → `rt wait id=add-meal-tray-list 15` → `rt save AI4-tray` → note the total → `rt tap id=add-meal-tray-log` → Diary day 0 → `rt save AI4-diary` → `rt errors`.
Expect:
- The Describe tile reads selected while its panel is open; the submit button is disabled until text is typed.
- The review screen is titled "Review items", carries "Von KI gelesen — prüfe jede Zeile", and shows rows named after database foods, each with macros; `bulk-add-submit` reads "Add <n> items".
- Back on the search screen: the snackbar "Added to list", the Describe panel closed, n rows on the list.
- Logged: the Diary has the n foods once each, and the day total moved by the list total.
- Portions resolve now (the real backend): "2 Eier" is not 2 g.
Note: "Dein API-Schlüssel wurde abgelehnt" or a credit message is *inconclusive* (account), not a product failure.

## Part 5 — Robustness

**RB1 — The comma record end to end (#1456).** Diary day 0 − 2 → open "ONT Komma" → `rt save RB1-detail` → `rt back`.
Expect: meal detail renders with 137 g; **no** "Weitere Informationen unter …" link (the `javascript:` URL is dropped or never shown); no red screen. Never tap any link.

**RB2 — Bad Open Food Facts data is tolerated (#1457).** Covered by AF3/AF6/AF13's OFF lookups: `rt errors` and logcat after `MARK_U2` hold no `FormatException`, `type 'String' is not a subtype` or `SEVERE: .*Off`. A product whose fields are mistyped can't be picked on purpose, so a clean log is *pass* with that caveat.

**RB3 — The safe launcher (#1458).** Not driven: every link leaves the package. *Skipped*, covered by `safe_url_launcher_test.dart`, `web_url_test.dart` and the meal-info-button tests.

**RB4 — All-or-nothing save (#1463).** The failure path can't be provoked on a phone. *Skipped*, covered by the `add_intake` rollback tests. The success path is AF10/AF15.

## Part 6 — Smoke

One step each, from 2.5.0's Part 4, labels unchanged: **K1** Diary navigation and the week panel; **K2** Recipes and custom meals list (ONT Eigen 26 present); **K3** Activities: open one, back without adding; **K4** Health Connect screen: the switch's state read, the disclosure opened and *ABBRECHEN* (never *Weiter*); **K5** Fasting: presets visible, no fast started; **K6** Trends 7d/30d/90d/Alle; **K7** Profile; **K8** Settings dialogs opened and cancelled (theme, accent, kcal info, food sources); **K9** `rt alarms`; **K10** CSV export `ont-r26-csv.zip` → pull → `unzip -l` lists the four CSVs and `user_intake.csv` carries ONT Komma's quantity as `137.0`.

## Part 7 — English pass, then back to German

**E1 — English.** Settings → *Sprache* → English → OK.
**E2 — The add-food screen in English.** Search screen → `rt save E2` → add one Kürzlich item with + → `rt save E2-tray` → `rt back` → `rt save E2-dialog` → `rt tap text=Discard`. Expect "Barcode", "Snap meal", "Describe", "TO LOG · 1", "Log 1 items" (or the plural form the key gives) with kcal, "Discard changes?"; no raw key, no `{count}`.
**E3 — Russian and Dutch, read only.** *Language* → Русский → search screen → `rt save E3-ru` → *Language* → Nederlands → search screen → `rt save E3-nl`. Expect no raw keys or placeholders; the new #1460 strings may be English.
**E4 — Back to German.** *Language* → system default → OK → `$ADB shell cmd locale get-app-locales $PKG` → `rt save E4`. Expect German, no per-app locale (as 2.5.0 left it).

## Part 8 — Wrap-up

**W1 — Logs and the key.** `rt logcat_stop` → `rt secret_audit` (nothing) → every crash, ANR or Flutter error filed under its step.
**W2 — Leave the phone.** Remove the stored AI key (Settings → `settings-ai-assist` → `ai-assist-remove-key` → OK), so the test install doesn't keep the maintainer's key. The candidate stays installed. Append the done line to the shared phone log.
**W3 — Results.** `docs/release-tests/2.6.0/results.md`: per-area table, ship-with list, skipped list, build identity.

### Skipped by design

| Item | Why | Covered by |
| :-- | :-- | :-- |
| The camera (Snap meal's photo, the live barcode preview) | opens the system camera / needs a subject | AI3 stops at the disclosure; AF6 uses manual entry |
| #1463 rollback | the tracked-day write can't be made to fail | `add_intake` rollback tests |
| #1458 link launches | every link leaves the package | `safe_url_launcher_test.dart` |
| #1457 Health Connect rate limit | needs Health Connect to refuse | `health_connect_workout_reader_test.dart` |
| #1460 large text sizes (`afc849d9`, `e89f252b`) | changing font scale is a device setting | widget tests at 2× text |
| Fresh onboarding, restore | unchanged since 2.5.0 (its N/R parts passed) | 2.5.0 results |
| iOS (#1450) | no Mac or device | — |
