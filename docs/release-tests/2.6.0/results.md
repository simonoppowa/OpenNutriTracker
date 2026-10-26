# Release 2.6.0: results of the Pixel 6 run

The device run for [#1464](https://github.com/simonoppowa/OpenNutriTracker/pull/1464)'s *Not verified on device* list, following [`script.md`](script.md) with 2.5.0's driver ([`tools/rt.sh`](tools/README.md)). Nobody touched the phone.

| | |
| :-- | :-- |
| Candidate | `release/2.6.0` at `be31e6e5`, debug `full`, 2.6.0 (68), APK sha256 `64e3f9fe…d052a35f`, built against the **real** `.env` (Supabase reachable) |
| Before | the 2.5.0 run's `c293acff` (= `v2.5.0` code; only `pubspec.yaml`'s version differs), sha256 `95232d69…a40df0`, with that run's data |
| Phone | Pixel 6 `18101FDF60010M`, Android 17, `de-DE`, USB |
| Run | 2026-10-25 22:54 → 2026-10-26 05:52 CET (paused 00:17–05:28 with nothing sent); day 0 = 2026-10-25 |
| Evidence | `~/Documents/ont-release-2.6.0-evidence/run-20261025-2254/` (`steps.tsv`, `run.log`, `steps/<ID>/`, `exports/`, `logcat/`) |
| Steps | **50 pass, 3 skip, 1 aborted** (W2, wrap-up only). No crash, no ANR, no ErrorWidget, no `EXCEPTION CAUGHT` / `SEVERE` for the app since the upgrade. Key audit clean. |

**Verdict from the device: no blocker found.** No crash, no data loss, no wrong stored nutrition numbers, no regression against 2.5.0. The findings below are ship-with.

## Per area

| Area | Steps | Verdict | What was seen |
| :-- | :-- | :-- | :-- |
| Preflight | P1–P6 | pass | Phone free (shared log), preflight all ok, installed = 2.5.0 code, candidate verified (same debug cert). The driver's default `prep` granted two Health Connect reads the install didn't hold; revoked again at once. |
| Before, on 2.5.0 | B1–B4 | pass | Quick add "ONT Vorher" 123 kcal logged. CSV fixture imported: "ONT Komma" 137 g / 274 kcal, stored as `mealQuantity "137,0"` and `url "javascript:alert(1)"` (the broken kind #1456 is about). Baseline `base.zip`: 33 intakes, every tracked day = its sum. |
| Upgrade in place | U1–U6 | pass | `install -r` kept data (first install 2026-10-11). First launch clean, Home unchanged, no reconciler line. `base` vs `up1`: **VERDICT identical**. New UI present. Two cold starts change nothing. |
| Add-food screen #1460 | AF1–AF2 | pass | Field without barcode suffix; tiles Barcode / Snap meal (AI) / Describe (AI); nothing clipped. Recent lists "ONT Komma / 137 g" and renders (2.5.0's `MealItemCard` threw on this record). |
| + and the To-log list #1460 | AF3–AF9 | pass | + on OFF Nutella = detail default (1 × 15 g serving). + on an FDC food, detail at 150 g, barcode by manual entry, and Quick add each add a row instead of logging. Remove takes exactly that row (1435 → 896). Back with items asks "Änderungen verwerfen?"; ABBRECHEN keeps them. An incomplete BLS food's + opens its detail with Add disabled, as designed. |
| Logging the list #1460, #1463 | AF10–AF15 | pass | One tap logged 4 items: Home +896 = the button total; each item once in the Diary. Clear empties the list; Verwerfen discards. + still fetching then Log: both logged (race window not provable over adb). Custom food → detail → list → logged. Export: day 0 has 8 entries, tracked 1839.8 = sum 1839.8, `superset` with 0 changed. |
| AI entry points #1460 | AI1–AI4 | pass | No key: Snap meal opens the AI dialog by itself. Key saved through `type_secret` (consent shown). With a key: the disclosure sheet names OpenRouter → Anthropic; the camera is never opened. Describe → "Review items" → "Von KI gelesen — prüfe jede Zeile" → rows with database macros → list → logged (+254). |
| Robustness #1456–#1458 | RB1–RB4, K10–K10c | pass (RB3, RB4 skip) | ONT Komma's detail renders 137 g with no info link; the editor shows "137.0". Logcat since the upgrade: 0 FormatException / subtype / SEVERE. A CSV re-import on 2.6.0 stores the record as `137.0` with `url null`. |
| Smoke | K1–K9, K3b | pass | Diary + nutrient week panel, recipes / custom meals, activity detail (same "~0 kcal / 0 min" default as 2.5.0), Health Connect disclosure (ABBRECHEN, switch stays off), fasting (none started), Trends ranges, profile, settings dialogs, alarms (reminder off). K3's tap missed and its note overstates it; K3b redid it. |
| English pass | E1–E4 | pass (E3 skip) | English strings for every #1460 screen, no raw keys or `{count}`. Back to German, no per-app locale. E3 skipped: ru and nl aren't in `shippedLocales`, so #1454/#1462 are inert. |
| Wrap-up | W1–W3 | W2 aborted | Key audit clean, no app crash/ANR in the logcat. W2 removed the AI key, then aborted on the closing tap; see *Abort* below. |

## Ship-with (to file)

| # | Step | Finding | Suggested label |
| :-- | :-- | :-- | :-- |
| 1 | AF3–AF5 | The To-log rows and total each truncate (`EnergyDisplay.formatValue` → `toInt()`), so rows "80 + 14" sit over a total of "95"; the detail screen rounds the same 80.85 kcal to "+81". Display only, ≤ 1 kcal; stored values are exact. | low |
| 2 | AF3, E2 | The log button reads "1 Einträge speichern" / "Log 1 items": `bulkAddSubmitLabel` has no plural form, and #1460 puts it under every add path. | low |
| 3 | AI1 | Snap meal with no key → AI dialog → ABBRECHEN leaves you on the full Settings screen; it takes a second Back to reach the review screen. The code comment says backing out "leaves them here". | low |
| 4 | AI4 | "2 Eier und eine Scheibe Vollkornbrot" matched OFF products without a serving (Eier/Lidl, Vollkornbrot/Kaufland); both rows held out ("Einheit für diese Menge prüfen", "Add 0 items") until a weight was typed. The dropdown offers only g / oz / g/ml. Designed (#973), but the first Describe can end with nothing to add. | low |
| 5 | AF4 | Backend search ranking: "banane" (Lebensmittel) shows puddings, baby food and smoothies, no plain banana in the first dozen; "apfel" leads with an FDC baby juice. Not in the 2.6.0 delta (first device run with a reachable backend). | low |
| 6 | AF4 | BLS "Apfel getrocknet" lacks a macro, so + opens detail with Add disabled. The screen then shows "0.0 g Fett", which reads as a real value. | low |
| 7 | E2 | In English, OFF "Vollkornbrot Kaufland" shows as "pâine integrala cu secară" (name fallback picks another language). | low |
| 8 | K10 | #1456 normalises comma quantities on import and parses them leniently on display, but doesn't rewrite stored records, so a CSV export still writes `137,0` and the `javascript:` URL. A backup taken on 2.6.0 can still crash ≤ 2.5.0's Recent list. Edge case. | low |

Noted, pre-existing: CSV round-trips drop `detailed`, `machineTranslatedName` and `backendSource` (no numbers change). Expected English in the German UI as the script lists it.

## Skipped

RB3 (#1458 links leave the package), RB4 (#1463 rollback can't be provoked), E3 (ru/nl not shipped). By design, as the script's table says: the camera, the Health Connect rate limit, large text sizes, fresh onboarding and restore (unchanged since 2.5.0), iOS.

## Abort (W2)

At 05:52:16 another adb client reinstalled `de.simono.nightcitymap` and ran `am start` on it, without the start line the shared phone log asks for. The driver's next post-input check (05:52:37) saw NightCityMap in focus and wrote ABORT. ONT's process was alive throughout, and the crash buffer is empty. The ABBRECHEN tap that triggered the check passed the pre-input check on ONT, so it most likely landed there. If it reached NightCityMap, it hit open map: the abort screenshot shows no dialog or change.

The stored OpenRouter key is gone. `ai-assist-remove-key` was tapped at 05:52:10, before the other session's install. Its handler (`_remove` in `ai_assist_dialog.dart`) clears the key from storage at once and reloads, and the reloaded dialog read "Für diesen Anbieter ist kein Schlüssel gespeichert.". Only the closing tap and the tile read-back didn't run.

## Driver notes for the next run

- `prep`'s default `RT_GRANTS` includes the Health Connect reads; set `RT_GRANTS` explicitly.
- The *Settings →* recipe collapses Settings when it's open but scrolled past `settings-food-units`. Read the header's *Minimiert*/*Maximiert* first (`settings_open` in this run).
- Flutter's German modal-barrier label "Gitter" isn't recognised as a modal, so `back` is refused on bottom sheets; tap the scrim (`text=Gitter`) instead.
- A shared phone needs a lock other sessions honour; the log line alone didn't stop an install.
