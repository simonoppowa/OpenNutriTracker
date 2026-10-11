# What users say is broken in Settings

Research for [#1342](https://github.com/simonoppowa/OpenNutriTracker/issues/1342), part of the settings map [#1338](https://github.com/simonoppowa/OpenNutriTracker/issues/1338). Collected 2026-10-11 from public sources only: Google Play, the App Store, GitHub issues and discussions. Reviewer names are left out on purpose.

## Answer

**The 1-star review is on Google Play (2026-10-04, English), and it names no setting.** It says the app "doesn't save 70% of settings" and nothing else that could be tested. Play shows no app version for it. 2.4.0 was already live on Play that day: another review from the same date carries 2.4.0. The maintainer's reply (2026-10-11) asks which settings. Until the reviewer answers, the only lead is what the review says: changes **don't persist**. That points at the cold-restart half of the Pixel test, not at any one row.

Nobody else in the stores says that settings don't save. Across 148 Play reviews and 33 App Store reviews, the settings complaints are about **limits**:

- You can't type a calorie goal. 12 store reviews ask for it, and it's tracked in #671.
- The macro split only works by percentage sliders, with floors. 7 store reviews.
- Older versions had missing units: kJ and imperial.

On GitHub, the closest match to "doesn't save" is **#541**: on 2.0.0 everything reset to a fresh install once the process was killed. It was fixed in 2.2.0 by #542, which added the missing `await`s on ten config writes and stopped Hive resetting the app when its key was lost. If the reviewer is on a version before 2.2.0, #541 explains the review completely.

## The 1-star review

| | |
| :-- | :-- |
| Source | [Google Play, review `cee81a75-542f-4edb-b40f-f519e0a42fd6`](https://play.google.com/store/apps/details?id=com.opennutritracker.ont.opennutritracker&reviewId=cee81a75-542f-4edb-b40f-f519e0a42fd6) |
| Date | 2026-10-04 |
| Rating | 1★ |
| Platform | Android (Google Play), English |
| Version | Not shown. Play leaves out the version when it doesn't have it, e.g. for a sideloaded or F-Droid install. 2.3.0 and 2.4.0 were both current around that date. |
| Symptom | Says "nothing works" and that the app "doesn't save 70% of settings". No setting, screen or step is named. |
| Developer reply | 2026-10-11: asks which settings aren't saved (calorie goals, units, profile data) and what happens when they reset, and points to GitHub. |

No other store review, issue or discussion says settings fail to save. The App Store has no 1★ review with text in any storefront I could read (see *Couldn't access* below).

## Google Play reviews about settings

Fetched from Play's public review endpoint, the one the store page's "See all reviews" uses, in 32 languages (14 had any): 148 reviews with text, 2024-01 to 2026-10. Links take the form `…/details?id=com.opennutritracker.ont.opennutritracker&reviewId=<id>`. Only reviews that touch a setting are listed, newest first.

| Date | ★ | Version | Lang | Setting: what the review says | Status |
| :-- | :-: | :-- | :-- | :-- | :-- |
| 2026-10-04 | 1 | — | en | **Unspecified:** "doesn't save 70% of settings" | **The review.** Nothing to match it against. |
| 2026-09-21 | 3 | 2.3.0 | de | **Calorie goal calculation:** doesn't understand why the target isn't based on BMR | Design; #1308 (explain the target) |
| 2026-09-21 | 3 | 2.3.0 | en | **Nutrient visibility:** wants to choose which nutrients are tracked. Also a black box after switching apps while adding food. | Display → nutrient visibility already exists, so this is probably a discoverability problem. The black box is #1325 (not Settings). |
| 2026-09-17 | 2 | 2.3.0 | en | **AI assistance:** "configured with Gemini" but it couldn't identify calories | By design, the model never supplies nutrition values. An expectation gap, not a failing setting. |
| 2026-08-18 | 4 | 2.0.2 | en | **Calorie goal:** can't set the daily goal by hand | #671 |
| 2026-08-09 | 4 | 2.0.2 | de | **kcal adjustment + macro split:** sliders are tedious; wants to type the numbers from a coach | #671, #642 |
| 2026-07-10 | 3 | 1.5.0 | en | **Macro split:** stuck between a high-carb and a very-high-protein option | #642. The sliders have changed since. |
| 2026-06-06 | 3 | 1.5.0 | en | (Not Settings) edits to a non-custom food's serving size or name aren't saved | #506 (open) |
| 2026-05-30 | 1 | 1.5.0 | en | **Calorie goal:** can't set the calorie intake | #671 |
| 2026-05-20 | 5 | 1.3.1 | uk | **Calorie + macro goals:** waiting for manual entry | #671, #642 |
| 2026-05-06 | 1 | 1.0.0 | en | **Macro split:** the lowest protein it allows is 155 g | Slider floor; #642 |
| 2026-04-16 | 2 | — | en | **Macro split:** carbs can't go below 5 % (21 g), so keto isn't possible | Slider floor; #642 |
| 2026-04-02 | 1 | 1.0.0 | en | **Energy unit:** no kJ | kJ added since. #1315 (labels) is open. |
| 2026-03-02 | 5 | 1.0.0 | de | **Profile weight:** a decimal weight is shown rounded | Fixed in 1.3.0 (#305) |
| 2026-01-28 | 4 | — | en | **Calorie + macro goals:** wants them without the calculation | #671 |
| 2025-03-09 | 3 | 0.9.0 | de | **Default unit:** serving instead of grams, and it can't be changed permanently | Grams-first switch #1126 / #1195. It's on `develop` but **not in v2.4.0**. |
| 2025-02-16 | 1 | 0.8.0 | en | **Height + weight:** hard to adjust | Old pickers. #253 (imperial weight skips values) was fixed in #348. |
| 2024-11-22, 2024-07-22, 2024-03-27 | 2, 1, 4 | 0.6.x | en | **Units:** no imperial units | Added since |
| 2024-07-06, 2024-05-27, 2024-10-08 | 4, 5, 4 | 0.6.x | en, fr | **Calorie goal:** can't set a specific intake | #671 |

## App Store reviews

The RSS feed, `itunes.apple.com/{cc}/rss/customerreviews/id=6451490901/sortBy=mostRecent/json`, came back **empty** for almost every storefront, on every try. Only `it`, `no` and `nl` returned entries, and not every time. The reviews below come from the public "Ratings & Reviews" page, `apps.apple.com/{cc}/app/opennutritracker/id6451490901?see-all=reviews`, in us, de, gb, ch, fr, nl, it, ie, no, mx and cz. That page shows no app version. Where a version is given, it comes from the issue that already cites the review.

| Date | ★ | Store | Version | Setting: what the review says | Status |
| :-- | :-: | :-- | :-- | :-- | :-- |
| 2026-09-29 | 2 | it | 2.2.0 | **Onboarding:** can't dismiss the keyboard; the macro target "boxes" do nothing | #1324 (open). Onboarding, not Settings, but a user may call it either. |
| 2026-09-24 | 4 | de | 2.2.0 | **Language:** at first "cannot set the app to English"; a later update says switching worked. **Calorie goal:** can't set your own. After switching to English, staple foods had wrong calories. | Language works but is hard to find or reach; compare #1331 (picker doesn't scroll) and #1214 (food names follow the device locale, fixed on `develop`, **not in v2.4.0**). Calorie goal is #671. Food data is #1326. |
| 2026-08-22 | 4 | ch | — | **Calorie goal + macros:** wants their own kcal goal and macros in grams | #671, #642 |
| 2025-08-11 | 3 | us | — | **Height (imperial):** onboarding asks for feet only, with no inches. **Macro split:** sliders only, and moving one rebalances the others. **Units:** height in cm with weight in lb didn't work. **Calorie goal:** the kcal adjustment slider doesn't show the resulting total. | Mixed units: separate height and weight units exist now. The rest is #642, #671, #1308. |
| 2026-06-03 | 5 | us | — | **Calorie goal:** the suggestion was too high, so they lowered it 500 kcal with the adjustment | The adjustment works; #1308 |

The other App Store reviews with text are about search and food data, the sodium unit, and adding custom food (gb, 2026-01-18: the dialog closes on its own). None of them concern Settings.

## GitHub issues and discussions

Searched all 626 issues, open and closed, and all 37 discussions. Bot PRs are excluded.

**Already known; the map lists them, so they're not reported again:** #715, #1331, #1316, #1306, #1315, #1253, #765, #763.

| Issue | State | Date | Platform / version | Setting: symptom |
| :-- | :-- | :-- | :-- | :-- |
| [#541](https://github.com/simonoppowa/OpenNutriTracker/issues/541) | closed (fixed in 2.2.0 by #542) | 2026-07-18 | Android (LineageOS), 2.0.0 | **Everything**: the app resets to its first-run state whenever the process is killed. #542 added missing `await`s on ten config writes (activity tracking, meal macros, notifications, reminder time, language, micronutrients, day boundary, …) and stopped a silent reset on Hive key loss. |
| [#517](https://github.com/simonoppowa/OpenNutriTracker/issues/517) | closed (fixed in 2.2.0 by #525) | 2026-07-07 | — | **Macro split:** typed percentages ignored; only the sliders apply |
| [#506](https://github.com/simonoppowa/OpenNutriTracker/issues/506) | **open** | 2026-06-23 | iOS (and Android, per a Play review) | (Not Settings) edits to database foods aren't saved, and the last-used amount isn't remembered |
| [#1324](https://github.com/simonoppowa/OpenNutriTracker/issues/1324) | **open** | 2026-10-05 | iOS 2.2.0 | **Onboarding:** keyboard can't be dismissed; the macro targets look editable but aren't |
| [#1214](https://github.com/simonoppowa/OpenNutriTracker/issues/1214) | closed; fix on `develop`, **not in v2.4.0** | 2026-09-17 | iOS; Android < 13 | **Language:** the in-app language doesn't reach food names, which follow the device locale |
| [#671](https://github.com/simonoppowa/OpenNutriTracker/issues/671) | **open** (high) | 2026-08-15 | both | **Calorie goal:** can't be set; and because it's recalculated on every weight change, the offset has to be redone each time |
| [#642](https://github.com/simonoppowa/OpenNutriTracker/issues/642) | **open** | 2026-08-13 | iOS | **Macro split:** percentages only; moving one slider overwrites the others |
| [#1308](https://github.com/simonoppowa/OpenNutriTracker/issues/1308) | **open** | 2026-10-04 | — | **Goal / kcal adjustment:** users can't tell whether "lose weight" or an adjustment was applied (5 emails) |
| [#1302](https://github.com/simonoppowa/OpenNutriTracker/issues/1302) | closed (dup of #671) | 2026-10-03 | — | **Calorie goal:** manual override |
| [Discussion #652](https://github.com/simonoppowa/OpenNutriTracker/discussions/652) | — | 2026-08-15 | iOS | **kcal adjustment:** at −1000 with "sedentary", the goal stops at 1221 kcal and can't go lower |
| [Discussion #794](https://github.com/simonoppowa/OpenNutriTracker/discussions/794) | — | 2026-08-23 | — | **Macro split:** wants absolute targets |
| [#586](https://github.com/simonoppowa/OpenNutriTracker/issues/586) | closed (fixed in 2.0.2) | 2026-07-24 | Android 1.5.0 | **Diary day boundary:** the offset shifted the calendar selection to the previous day |
| [#504](https://github.com/simonoppowa/OpenNutriTracker/issues/504) | closed | 2026-06-18 | Android | **Export:** to Downloads, writes a 0-byte ZIP and reports success |
| [#1103](https://github.com/simonoppowa/OpenNutriTracker/issues/1103) | closed | 2026-09-06 | — | **Export/import:** every failure shows the same "Export / Import error" |
| [#764](https://github.com/simonoppowa/OpenNutriTracker/issues/764) | closed | 2026-08-21 | Android 2.0.2 | **Delete all data:** leaves the daily reminder scheduled |
| [#892](https://github.com/simonoppowa/OpenNutriTracker/issues/892) | closed | 2026-08-27 | — | **Delete all data:** leaves the AI API key in secure storage |
| [#848](https://github.com/simonoppowa/OpenNutriTracker/issues/848) | closed | 2026-08-25 | — | **AI assistance:** Cancel leaves the newly tapped provider active |
| [#253](https://github.com/simonoppowa/OpenNutriTracker/issues/253) | closed (#348) | 2025-07-06 | — | **Body weight (lb):** some values can't be picked (233 jumps to 234) |
| [#282](https://github.com/simonoppowa/OpenNutriTracker/issues/282) | closed | 2025-10-12 | — | **Units:** names not translated in German |

## Suspects, ranked

1. **Persistence across a cold restart, for any setting.** It's the only symptom the 1-star names, and #541 / #542 is a confirmed earlier case, fixed in 2.2.0. Every config write in `AddConfigUsecase` on `develop` is awaited now. This research didn't check writes that go through other paths (nutrient goals, meal shares, the profile). → Kill the app after every row in the Pixel run, not just at the end.
2. **Calorie goal and kcal adjustment.** Named in 8 Play and 4 App Store reviews, plus #671, #1302, #1308 and discussion #652. The goal can't be typed (#671); the adjustment has a floor (#652) and is redone on every weight change (#671); users can't see whether it took effect (#1308). A user who sets an adjustment and then sees the goal move after a weight update could fairly say the setting "did not work".
3. **Macro split.** Named in 7 store reviews. Slider floors (155 g protein, 5 % carbs), sliders that rebalance each other (#642), and typed values ignored before 2.2.0 (#517). Per-meal shares are impossible to adjust (#715, known).
4. **Nutrient goals.** They only apply on the day they're set (#1316, known). The reported symptom is that the app "isn't letting me" set them. Of the known open bugs, this one fits "doesn't save" most closely.
5. **Language.** One App Store review couldn't switch at first. The picker doesn't scroll (#1331, known), and food names ignore the in-app language on iOS and Android < 13 (#1214; the fix isn't in 2.4.0).
6. **Units and energy.** kJ was missing in early versions; kJ labels are still wrong (#1315, known); water ignores imperial (#1306, known); mixed unit systems failed in a 2025 review.

## Couldn't access

- **Play review versions.** Play leaves the version out for some reviews, including the 1-star. The Play Console would show the reviewer's device, Android version and app version. That needs a login, which this research doesn't use.
- **Play reviews without text.** Star-only ratings can't be read through the public endpoint. Play also lists a review under its language, so a language I didn't query (32 were tried, 18 returned nothing) could hide more.
- **App Store RSS.** It returned empty feeds for nearly every storefront, so App Store versions and anything older than what the web page shows were out of reach. The web page shows a capped selection: 9 reviews in us, 10 in de. The storefront averages (de 3.9★ from 23 ratings; us 4.3★ from 15) include ratings without text, which no public source exposes.
- **The App Store web page rate-limits (HTTP 429)** after about five storefronts. It was fetched slowly; es, ca, au, in, at, pl, be, se, dk, fi, pt, br and jp returned no reviews with text.
