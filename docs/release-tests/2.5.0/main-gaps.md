# 2.5.0: which `main`-only lines are real gaps in `develop`?

Research for [#1436](https://github.com/simonoppowa/OpenNutriTracker/issues/1436), part of the 2.5.0
map [#1425](https://github.com/simonoppowa/OpenNutriTracker/issues/1425). It repeats the 2.4.0 check,
[#1242](https://github.com/simonoppowa/OpenNutriTracker/issues/1242), against the 2.5.0 candidate.

## Answer

**There is no real gap. `develop` is missing nothing `main` has, so there is nothing to cherry-pick.
The release still cannot be a direct merge: `develop` conflicts with `main` in 40 files and needs a
`release/2.5.0` branch.**

Every one of the 40 conflicts resolves to `develop`'s side. In each conflicted file, `main` holds
content that `develop` itself once had and has since changed.

## Inputs

| | Commit | Notes |
| :-- | :-- | :-- |
| Candidate | `c293acff4` | `origin/develop` at freeze, *chore(deps): bump fastlane in /android* (#1423) |
| `main` | `8d2420f03` | *Release 2.4.0+66* (#1270), one parent, so a squash |
| Merge base | `2789fa9f` | the same base #1242 found. The 2.4.0 squash did not move it |

Nothing has reached `main` since 2.4.0. `8d2420f03` is still its tip, and its tree is byte-identical
to `origin/release/2.4.0` (`759b754b2`). Fetched 2026-10-22.

## Method

#1242's method, plus the three listings in `docs/RELEASING.md`, "The release PR":

1. `git diff --name-status c293acff4 origin/main`: **301 files** differ. 195 are modified and 106
   exist on `develop` only. No file exists on `main` only.
2. For every file, compare `main`'s blob with the merge base's blob and with every blob reachable
   from `c293acff4`. Then walk `git log c293acff4 -- <path>` to find the develop commit that had
   `main`'s exact blob **at that path**, and the develop commits that changed it afterwards.
3. Classify each file's `main` side:
   - **(a) develop is simply newer.** `main`'s blob is byte-identical to the merge base, the file
     does not exist on `main` or at the base, or `main`'s blob is `develop`'s own earlier content
     (shipped by the 2.3.0/2.4.0 squashes) that later develop commits replaced.
   - **(b) hotfix pair.** The content reached `main` through a hotfix or release-branch commit, and
     a separate develop twin carries byte-identical content.
   - **(c) real gap.** `main` carries content that `develop` never had. The release merge would
     drop it or conflict on it.
4. Runbook listings:
   - The `+`-line loop prints **142 files**: 94 identical to the base, and 48 holding `develop`'s
     earlier content.
   - The deletion-aware listing (files `main` changed since the base that still differ from
     `develop`) prints **64 files**. All 64 are in the table below: 63 in (a), 1 in (b), and none in
     (c).
   - Rename check: `develop` has renamed **no** file since the base, so the `comm` command prints
     nothing.
5. Trial merge, on a throwaway branch in an agent worktree, never pushed:
   `git switch -c tmp/trial-merge-2.5.0 c293acff4 && git merge --no-commit --no-ff origin/main`,
   then `git merge --abort`. `git merge-tree --write-tree origin/main c293acff4` agrees (exit 1).

## Result by class

| Class | Files | |
| :-- | --: | :-- |
| (a) `main` = merge base | 131 | `develop` edited them after the base. `main` never touched them |
| (a) `develop`-only files | 106 | added on `develop` after the base. `main` deleted nothing |
| (a) `main` = `develop`'s earlier blob | 63 | the 2.3.0/2.4.0 squash content, superseded on `develop` |
| (b) hotfix pair | 1 differing file (+ 3 pairs with no diff left) | see below |
| **(c) real gap** | **0** | |

### (b) Hotfix pairs since the base

| `main` side | `develop` twin | State at the candidate |
| :-- | :-- | :-- |
| `759b754b2`, release/2.4.0 only: grams-first switch semantics identifier | `99a9fe035` (#1271) | `settings_screen.dart`: `main`'s blob is exactly the blob `99a9fe035` produced. Six later develop commits changed the file (#1370 onward). Not a gap |
| `a9b59f87b` / `783c3dddc`, hotfix/merge-weblate-prs (#1226) | `5bcebd032` (#1220) | `merge-weblate-prs.yml` is byte-identical on both tips (`ad5b6580`), so it is not in the diff at all |
| `2ab2e8284`, drop the iOS screenshot lane from `main` (#1145) | `f9bf4301e` (#1121) | `ios-screenshots.yml` and `ios_capture_screenshots.sh` are absent from both tips |
| `0b0d1c810` / `ec7d27fdc`, store assets and tooling level with `develop` (#1147) | `develop` was the source | `tools/` has no diff. Only `fastlane/metadata/ios/en-US/screenshots/README.md` differs, and `develop` replaced it in #1301 |

The other release-branch commits on `main` since the base, from 2.2.0, 2.3.0 and 2.4.0, all fall into
(a): their content is on `develop` and has since been edited further. The 2.4.0 bump `680eafaa8`
(#1263) is one example: `main`'s `pubspec.yaml` is the blob that commit left on `develop`.

### Version lines

```
origin/main  pubspec.yaml:18  version: 2.4.0+66
c293acff4    pubspec.yaml:18  version: 2.4.0+66
2789fa9f     pubspec.yaml:18  version: 2.3.0+64
```

The version line is identical on both sides, so it does not conflict. It is also not yet bumped.
`release-gate` refuses to deploy a reused build number, so `develop` needs **2.5.0+67** and a
`fastlane/metadata/android/en-US/changelogs/67.txt` of 500 characters or fewer before the release PR.
The highest note on `develop` today is `66.txt`. This blocks the release but is not a gap. The
`pubspec.yaml` conflict is in the dependency block, where `develop` is newer on every line: it adds
`home_widget` and raises `get_it`, `file_picker`, `hive_ce` and others.

## Merge verdict: release branch required

`git merge --no-commit --no-ff origin/main` on `c293acff4` stops with **40 conflicts: 26 `UU` and
14 `AA`**, and **no** non-conflicting change from `main` staged. Outside the conflicts, the merge
result is exactly `develop`. All 40 conflicted files are in the (a)/(b) table below: each holds
`develop`'s own earlier content on `main`'s side. So every conflict resolves with
`git checkout --ours -- <file> && git add <file>`, the `UU`/`AA` row of the RELEASING.md table.
There is no `DU`, `UD` or rename case to read by hand.

The conflicts come from the squashed 2.4.0 release, not from any hotfix. The base stayed at
`2789fa9f`, so every hunk `develop` edited after 2.4.0 conflicts with `main`'s copy. Follow
RELEASING.md's conflict path:

```bash
git switch -c release/2.5.0 origin/develop      # after the 2.5.0+67 bump lands
git merge --no-commit origin/main
# resolve all 40 to develop's side, per the table
git commit -m "Merge main into release/2.5.0"
git diff --stat origin/develop HEAD             # must print nothing
```

Merge the `release/2.5.0 → main` PR with **"Create a merge commit"**. A second squash would leave
the base at `2789fa9f` for a fourth release, and the conflict set would keep growing.

Conflicted files: `.github/workflows/default_workflow.yml`, `android/Gemfile`,
`android/Gemfile.lock`, `fastlane/metadata/ios/en-US/screenshots/README.md` (AA), `ios/Gemfile`,
`ios/Gemfile.lock`, `ios/Podfile.lock`, `lib/core/data/dbo/config_dbo.dart`,
`lib/core/data/dbo/config_dbo.g.dart`, `lib/core/domain/usecase/switch_profile_usecase.dart`,
`lib/core/utils/csv_data_exporter.dart`, `lib/core/utils/locale_provider.dart`,
`lib/core/utils/locator.dart`, `lib/dev/main_dev.dart`,
`lib/features/add_meal/presentation/add_meal_screen.dart`,
`lib/features/add_meal/presentation/widgets/no_results_widget.dart`,
`lib/features/edit_meal/presentation/bloc/edit_meal_bloc.dart`,
`lib/features/profile/presentation/widgets/weight_trend_chart.dart`,
`lib/features/settings/domain/usecase/export_data_usecase.dart`,
`lib/features/settings/domain/usecase/import_data_usecase.dart`,
`lib/features/settings/presentation/bloc/export_import_bloc.dart`,
`lib/features/settings/presentation/widgets/export_import_dialog.dart`,
`lib/features/settings/settings_screen.dart`, `lib/l10n/intl_en.arb`, `lib/l10n/intl_{es,fr,hu,ru,sv}.arb` (AA),
`lib/main.dart`, `pubspec.lock`, `pubspec.yaml`, and eight test files (AA):
`test/features/meal_detail/{default_to_raw_food_units_screen,quick_serving_chips_screen,quick_serving_chips_widget,serving_option_after_hydration}_test.dart`,
`test/unit_test/{export_import_bloc_failure,import_data_usecase_failure,import_data_usecase_off_repair}_test.dart`,
`test/widget_test/no_results_widget_test.dart`.

## Per-file classification

### Files `main` changed since the merge base (64)

These 64 files are what the deletion-aware listing prints. For each one, `develop` had `main`'s exact
blob at the same path, in the commit shown, and later develop commits replaced it. "Trial merge"
shows the conflict status, and a blank means the file merged cleanly to `develop`'s side.

| File | `main`-only `+` lines | Trial merge | Class | Develop had `main`'s exact blob at | Later develop commits | First superseding commit |
| :-- | --: | :-: | :-: | :-- | --: | :-- |
| `.github/workflows/default_workflow.yml` | 6 | UU | a | `dec6919f7` | 2 | `2643f31ac` #1222 |
| `AGENTS.md` | 1 |  | a | `3914e09ff` | 1 | `721b18dd7` #1320 |
| `README.md` | 1 |  | a | `c57e883f6` | 1 | `1bc934b15` #1225 |
| `android/Gemfile` | 1 | UU | a | `7e9597c88` | 2 | `1a3c036c7` #1374 |
| `android/Gemfile.lock` | 71 | UU | a | `7e9597c88` | 2 | `1a3c036c7` #1374 |
| `docs/RELEASING.md` | 12 |  | a | `1bf5ddd78` | 1 | `527492cc3` #1278 |
| `docs/export-format.md` | 6 |  | a | `c9226b3a5` | 5 | `0ff4a3b4c` #1369 |
| `fastlane/metadata/ios/en-US/screenshots/README.md` | 12 | AA | a | `f9bf4301e` | 1 | `70fed9ee2` #1301 |
| `ios/Gemfile` | 1 | UU | a | `241013efa` | 2 | `1a3c036c7` #1374 |
| `ios/Gemfile.lock` | 71 | UU | a | `241013efa` | 2 | `1a3c036c7` #1374 |
| `ios/Podfile.lock` | 1 | UU | a | `8d665755f` | 2 | `1a3c036c7` #1374 |
| `ios/Runner/PrivacyInfo.xcprivacy` | 0 |  | a | `d4a00894a` | 1 | `7f18db390` #1251 |
| `justfile` | 1 |  | a | `a4d1cebd4` | 1 | `2643f31ac` #1222 |
| `lib/core/data/data_source/config_data_source.dart` | 0 |  | a | `5abc6373b` | 3 | `0001194a2` #1381 |
| `lib/core/data/dbo/config_dbo.dart` | 0 | UU | a | `5abc6373b` | 2 | `8119b8578` #1319 |
| `lib/core/data/dbo/config_dbo.g.dart` | 2 | UU | a | `5abc6373b` | 2 | `8119b8578` #1319 |
| `lib/core/data/repository/config_repository.dart` | 8 |  | a | `5abc6373b` | 3 | `0001194a2` #1381 |
| `lib/core/domain/usecase/add_config_usecase.dart` | 16 |  | a | `5abc6373b` | 2 | `8119b8578` #1319 |
| `lib/core/domain/usecase/switch_profile_usecase.dart` | 5 | UU | a | `c55a2ccf4` | 1 | `8119b8578` #1319 |
| `lib/core/utils/csv_data_exporter.dart` | 55 | UU | a | `c9226b3a5` | 1 | `586ad4250` #1398 |
| `lib/core/utils/locale_provider.dart` | 1 | UU | a | `4808ea32f` | 2 | `f7a0b993b` #1379 |
| `lib/core/utils/locator.dart` | 15 | UU | a | `c55a2ccf4` | 9 | `0001194a2` #1381 |
| `lib/dev/main_dev.dart` | 1 | UU | a | `a4d1cebd4` | 1 | `b2a98da8e` #1230 |
| `lib/features/add_meal/domain/usecase/search_products_usecase.dart` | 10 |  | a | `d35610cf5` | 1 | `cc3c38c59` #1282 |
| `lib/features/add_meal/presentation/add_meal_screen.dart` | 54 | UU | a | `fdb2feff6` | 3 | `a8b475049` #1334 |
| `lib/features/add_meal/presentation/widgets/no_results_widget.dart` | 1 | UU | a | `fdb2feff6` | 1 | `a8b475049` #1334 |
| `lib/features/edit_meal/presentation/bloc/edit_meal_bloc.dart` | 5 | UU | a | `c55a2ccf4` | 3 | `8a98aa139` #1404 |
| `lib/features/meal_detail/meal_detail_screen.dart` | 0 |  | a | `5abc6373b` | 2 | `6d5208d50` #1384 |
| `lib/features/meal_detail/presentation/widgets/meal_detail_bottom_sheet.dart` | 3 |  | a | `07d26e413` | 2 | `6d5208d50` #1384 |
| `lib/features/profile/presentation/widgets/weight_trend_chart.dart` | 14 | UU | a | `86cd09d97` | 1 | `2643f31ac` #1222 |
| `lib/features/settings/domain/usecase/export_data_usecase.dart` | 101 | UU | a | `f787785e4` | 3 | `0001194a2` #1381 |
| `lib/features/settings/domain/usecase/import_data_usecase.dart` | 124 | UU | a | `c9226b3a5` | 5 | `0ff4a3b4c` #1369 |
| `lib/features/settings/presentation/bloc/export_import_bloc.dart` | 0 | UU | a | `f787785e4` | 2 | `0001194a2` #1381 |
| `lib/features/settings/presentation/bloc/settings_bloc.dart` | 56 |  | a | `5abc6373b` | 7 | `7c3b04ef1` #1370 |
| `lib/features/settings/presentation/widgets/export_import_dialog.dart` | 0 | UU | a | `f787785e4` | 1 | `0001194a2` #1381 |
| `lib/features/settings/settings_screen.dart` | 46 | UU | **b** | `99a9fe035` | 6 | `7c3b04ef1` #1370 |
| `lib/l10n/intl_cs.arb` | 2 |  | a | `f3f5b7c0a` | 2 | `689ad07bd` 689ad07bd |
| `lib/l10n/intl_de.arb` | 2 |  | a | `081903b06` | 2 | `689ad07bd` 689ad07bd |
| `lib/l10n/intl_en.arb` | 11 | UU | a | `5abc6373b` | 12 | `f70afe240` #1280 |
| `lib/l10n/intl_es.arb` | 2 | AA | a | `c0c1d54e0` | 2 | `689ad07bd` 689ad07bd |
| `lib/l10n/intl_fr.arb` | 2 | AA | a | `b764b638a` | 2 | `689ad07bd` 689ad07bd |
| `lib/l10n/intl_hu.arb` | 9 | AA | a | `96e52885b` | 10 | `19ee7e29f` 19ee7e29f |
| `lib/l10n/intl_it.arb` | 5 |  | a | `1b4d26eaf` | 3 | `761c24221` 761c24221 |
| `lib/l10n/intl_pl.arb` | 2 |  | a | `ce8caff56` | 2 | `689ad07bd` 689ad07bd |
| `lib/l10n/intl_ru.arb` | 2 | AA | a | `b764b638a` | 2 | `689ad07bd` 689ad07bd |
| `lib/l10n/intl_sk.arb` | 2 |  | a | `4accb4da8` | 2 | `689ad07bd` 689ad07bd |
| `lib/l10n/intl_sv.arb` | 5 | AA | a | `a4d1cebd4` | 3 | `13d86dfe8` 13d86dfe8 |
| `lib/l10n/intl_tr.arb` | 2 |  | a | `55a1e0873` | 2 | `689ad07bd` 689ad07bd |
| `lib/l10n/intl_uk.arb` | 2 |  | a | `23ddb060c` | 2 | `689ad07bd` 689ad07bd |
| `lib/l10n/intl_zh.arb` | 2 |  | a | `ee731a373` | 2 | `689ad07bd` 689ad07bd |
| `lib/main.dart` | 34 | UU | a | `a4d1cebd4` | 4 | `c2495193a` #1328 |
| `pubspec.lock` | 36 | UU | a | `803812697` | 2 | `1a3c036c7` #1374 |
| `pubspec.yaml` | 12 | UU | a | `680eafaa8` | 2 | `1a3c036c7` #1374 |
| `test/features/meal_detail/default_to_raw_food_units_screen_test.dart` | 0 | AA | a | `5abc6373b` | 1 | `721b18dd7` #1320 |
| `test/features/meal_detail/quick_serving_chips_screen_test.dart` | 0 | AA | a | `07d26e413` | 1 | `721b18dd7` #1320 |
| `test/features/meal_detail/quick_serving_chips_widget_test.dart` | 0 | AA | a | `07d26e413` | 1 | `6d5208d50` #1384 |
| `test/features/meal_detail/serving_option_after_hydration_test.dart` | 0 | AA | a | `c93c47118` | 1 | `721b18dd7` #1320 |
| `test/features/settings/presentation/widgets/health_sync_screen_test.dart` | 0 |  | a | `3e3d5cee4` | 1 | `6d5208d50` #1384 |
| `test/helpers/fake_hive_db_provider.dart` | 1 |  | a | `c9226b3a5` | 1 | `721b18dd7` #1320 |
| `test/unit_test/export_import_bloc_failure_test.dart` | 0 | AA | a | `f787785e4` | 2 | `0001194a2` #1381 |
| `test/unit_test/import_data_usecase_failure_test.dart` | 0 | AA | a | `f787785e4` | 2 | `0001194a2` #1381 |
| `test/unit_test/import_data_usecase_off_repair_test.dart` | 0 | AA | a | `c9226b3a5` | 2 | `0001194a2` #1381 |
| `test/unit_test/search_products_usecase_test.dart` | 0 |  | a | `d35610cf5` | 1 | `cc3c38c59` #1282 |
| `test/widget_test/no_results_widget_test.dart` | 0 | AA | a | `fdb2feff6` | 1 | `a8b475049` #1334 |

<details><summary>Class (a), <code>main</code> blob byte-identical to the merge base: 131 files</summary>

| File | `main`-only `+` lines |
| :-- | --: |
| `docs/ai-legal-constraints.md` | 0 |
| `ios/Runner.xcodeproj/project.pbxproj` | 0 |
| `ios/Runner/Runner.entitlements` | 0 |
| `ios/fastlane/Fastfile` | 0 |
| `ios/fastlane/Matchfile` | 1 |
| `lib/core/data/data_source/custom_activity_template_data_source.dart` | 8 |
| `lib/core/data/data_source/custom_meal_data_source.dart` | 1 |
| `lib/core/data/data_source/intake_data_source.dart` | 17 |
| `lib/core/data/data_source/recipe_data_source.dart` | 0 |
| `lib/core/data/data_source/tracked_day_data_source.dart` | 2 |
| `lib/core/data/data_source/user_activity_data_source.dart` | 16 |
| `lib/core/data/repository/custom_activity_template_repository.dart` | 2 |
| `lib/core/data/repository/intake_repository.dart` | 2 |
| `lib/core/data/repository/tracked_day_repository.dart` | 10 |
| `lib/core/data/repository/user_activity_repository.dart` | 2 |
| `lib/core/domain/entity/physical_activity_entity.dart` | 13 |
| `lib/core/domain/entity/weight_log_entity.dart` | 0 |
| `lib/core/domain/usecase/add_tracked_day_usecase.dart` | 0 |
| `lib/core/domain/usecase/delete_all_user_data_usecase.dart` | 38 |
| `lib/core/domain/usecase/delete_recipe_usecase.dart` | 2 |
| `lib/core/domain/usecase/delete_weight_log_usecase.dart` | 2 |
| `lib/core/domain/usecase/get_intake_usecase.dart` | 2 |
| `lib/core/domain/usecase/import_workouts_usecase.dart` | 10 |
| `lib/core/domain/usecase/log_user_activity_usecase.dart` | 3 |
| `lib/core/domain/usecase/merge_custom_meals_usecase.dart` | 35 |
| `lib/core/domain/usecase/send_intake_to_profiles_usecase.dart` | 29 |
| `lib/core/presentation/main_screen.dart` | 1 |
| `lib/core/presentation/widgets/activity_card.dart` | 1 |
| `lib/core/presentation/widgets/add_item_bottom_sheet.dart` | 1 |
| `lib/core/presentation/widgets/edit_activity_dialog.dart` | 1 |
| `lib/core/presentation/widgets/error_dialog.dart` | 4 |
| `lib/core/presentation/widgets/intake_card.dart` | 5 |
| `lib/core/utils/app_locale_service.dart` | 6 |
| `lib/core/utils/app_locale_sync.dart` | 9 |
| `lib/core/utils/calc/day_boundary_calc.dart` | 10 |
| `lib/core/utils/demo/demo_seeder.dart` | 4 |
| `lib/core/utils/hive_db_provider.dart` | 1 |
| `lib/core/utils/id_generator.dart` | 0 |
| `lib/core/utils/meal_type_suggester.dart` | 2 |
| `lib/core/utils/notification_service.dart` | 2 |
| `lib/core/utils/serving_label_localizer.dart` | 0 |
| `lib/core/utils/vertical_list_popup_menu_selections.dart` | 1 |
| `lib/features/activity_detail/activity_detail_screen.dart` | 4 |
| `lib/features/activity_detail/presentation/bloc/activity_detail_bloc.dart` | 8 |
| `lib/features/activity_detail/presentation/widget/activity_detail_bottom_sheet.dart` | 13 |
| `lib/features/add_meal/presentation/bloc/food_bloc.dart` | 22 |
| `lib/features/add_meal/presentation/bloc/food_state.dart` | 1 |
| `lib/features/add_meal/presentation/bloc/products_bloc.dart` | 23 |
| `lib/features/add_meal/presentation/bloc/products_state.dart` | 1 |
| `lib/features/add_meal/presentation/bloc/recent_meal_bloc.dart` | 28 |
| `lib/features/add_meal/presentation/bloc/recent_meal_event.dart` | 0 |
| `lib/features/add_meal/presentation/widgets/meal_item_card.dart` | 7 |
| `lib/features/add_meal/presentation/widgets/quick_add_bottom_sheet.dart` | 3 |
| `lib/features/diary/diary_page.dart` | 22 |
| `lib/features/diary/presentation/bloc/calendar_day_bloc.dart` | 76 |
| `lib/features/diary/presentation/bloc/calendar_day_state.dart` | 2 |
| `lib/features/diary/presentation/widgets/daily_nutrient_panel.dart` | 7 |
| `lib/features/diary/presentation/widgets/day_info_widget.dart` | 33 |
| `lib/features/diary/presentation/widgets/diary_table_calendar.dart` | 0 |
| `lib/features/edit_meal/presentation/edit_meal_screen.dart` | 3 |
| `lib/features/home/domain/entity/shared_meal_payload.dart` | 1 |
| `lib/features/home/home_page.dart` | 14 |
| `lib/features/home/presentation/bloc/home_bloc.dart` | 65 |
| `lib/features/home/presentation/bloc/home_state.dart` | 2 |
| `lib/features/home/presentation/screens/import_activity_scanner_screen.dart` | 1 |
| `lib/features/home/presentation/screens/import_meal_scanner_screen.dart` | 186 |
| `lib/features/home/presentation/widgets/dashboard_widget.dart` | 1 |
| `lib/features/home/presentation/widgets/intake_vertical_list.dart` | 9 |
| `lib/features/meal_detail/presentation/bloc/meal_detail_bloc.dart` | 6 |
| `lib/features/meal_detail/presentation/widgets/meal_detail_nutriments_table.dart` | 2 |
| `lib/features/meal_detail/presentation/widgets/meal_info_button.dart` | 6 |
| `lib/features/onboarding/onboarding_screen.dart` | 16 |
| `lib/features/onboarding/presentation/bloc/onboarding_bloc.dart` | 5 |
| `lib/features/profile/presentation/bloc/profile_bloc.dart` | 18 |
| `lib/features/profile/presentation/utils/profile_switch_coordinator.dart` | 1 |
| `lib/features/profile/presentation/weight_history_screen.dart` | 10 |
| `lib/features/profile/profile_page.dart` | 1 |
| `lib/features/recipes/domain/entity/shared_recipe_payload.dart` | 2 |
| `lib/features/recipes/presentation/bloc/recipe_builder_bloc.dart` | 1 |
| `lib/features/recipes/presentation/bloc/recipe_builder_event.dart` | 0 |
| `lib/features/recipes/presentation/screens/import_recipe_scanner_screen.dart` | 1 |
| `lib/features/recipes/presentation/screens/recipe_builder_screen.dart` | 1 |
| `lib/features/scanner/domain/usecase/search_product_by_barcode_usecase.dart` | 1 |
| `lib/features/settings/domain/usecase/import_meals_json_usecase.dart` | 26 |
| `lib/features/settings/presentation/bloc/custom_meals_bloc.dart` | 23 |
| `lib/features/settings/presentation/widgets/ai_assist_dialog.dart` | 11 |
| `lib/features/settings/presentation/widgets/diary_day_boundary_dialog.dart` | 3 |
| `lib/features/settings/presentation/widgets/kcal_adjustment_dialog.dart` | 3 |
| `lib/features/settings/presentation/widgets/macro_split_dialog.dart` | 10 |
| `lib/features/settings/presentation/widgets/nutrient_goals_screen.dart` | 31 |
| `lib/features/settings/presentation/widgets/nutrient_visibility_screen.dart` | 0 |
| `lib/features/settings/presentation/widgets/water_goal_dialog.dart` | 0 |
| `lib/features/trends/presentation/bloc/trends_bloc.dart` | 1 |
| `lib/features/trends/presentation/bloc/trends_event.dart` | 0 |
| `lib/features/trends/presentation/trends_page.dart` | 2 |
| `lib/hive_registrar.g.dart` | 0 |
| `test/core/presentation/widgets/add_item_bottom_sheet_test.dart` | 0 |
| `test/core/utils/meal_type_suggester_test.dart` | 0 |
| `test/features/edit_meal/presentation/edit_meal_unwind_test.dart` | 0 |
| `test/features/home/presentation/widgets/dashboard_widget_test.dart` | 12 |
| `test/features/home/presentation/widgets/intake_vertical_list_test.dart` | 2 |
| `test/features/profile/presentation/weight_history_screen_test.dart` | 3 |
| `test/features/recipes/domain/usecase/delete_recipe_no_cascade_test.dart` | 1 |
| `test/features/recipes/presentation/bloc/recipe_builder_bloc_test.dart` | 0 |
| `test/features/scanner/domain/usecase/search_product_by_barcode_usecase_test.dart` | 0 |
| `test/features/settings/presentation/ai_assist_dialog_test.dart` | 0 |
| `test/features/settings/presentation/widgets/macro_split_dialog_test.dart` | 1 |
| `test/features/settings/settings_screen_test.dart` | 4 |
| `test/unit_test/app_locale_service_test.dart` | 4 |
| `test/unit_test/app_locale_sync_test.dart` | 16 |
| `test/unit_test/config_health_fields_test.dart` | 0 |
| `test/unit_test/csv_data_exporter_test.dart` | 0 |
| `test/unit_test/custom_activity_template_repository_test.dart` | 3 |
| `test/unit_test/custom_meal_data_source_test.dart` | 0 |
| `test/unit_test/daily_nutrient_panel_goal_reference_test.dart` | 0 |
| `test/unit_test/day_boundary_calc_test.dart` | 0 |
| `test/unit_test/delete_all_user_data_cancels_notifications_test.dart` | 9 |
| `test/unit_test/delete_all_user_data_usecase_test.dart` | 4 |
| `test/unit_test/diary_day_selection_offset_test.dart` | 1 |
| `test/unit_test/edit_meal_serving_unit_test.dart` | 0 |
| `test/unit_test/export_archive_round_trip_test.dart` | 0 |
| `test/unit_test/export_user_image_paths_test.dart` | 0 |
| `test/unit_test/import_workouts_usecase_test.dart` | 0 |
| `test/unit_test/meal_pattern_entity_test.dart` | 6 |
| `test/unit_test/merge_custom_meals_usecase_test.dart` | 0 |
| `test/unit_test/onboarding_save_race_test.dart` | 0 |
| `test/unit_test/onboarding_unit_seeding_test.dart` | 0 |
| `test/unit_test/products_bloc_search_test.dart` | 0 |
| `test/unit_test/serving_label_localizer_test.dart` | 0 |
| `test/unit_test/shared_recipe_payload_test.dart` | 0 |
| `test/unit_test/trends_bloc_test.dart` | 4 |

</details>

<details><summary>Class (a), added on <code>develop</code> after the merge base, absent from both the base and <code>main</code>: 106 files</summary>

- `docs/ios-calorie-widget.md`
- `ios/CalorieWidget/CalorieWidget.entitlements`
- `ios/CalorieWidget/CalorieWidget.swift`
- `ios/CalorieWidget/CalorieWidget.xcconfig`
- `ios/CalorieWidget/Info.plist`
- `ios/CalorieWidget/PrivacyInfo.xcprivacy`
- `lib/core/data/data_source/box_upsert.dart`
- `lib/core/data/data_source/favourite_meal_data_source.dart`
- `lib/core/data/dbo/favourite_meal_dbo.dart`
- `lib/core/data/dbo/favourite_meal_dbo.g.dart`
- `lib/core/data/repository/favourite_meal_repository.dart`
- `lib/core/domain/usecase/get_favourite_meals_usecase.dart`
- `lib/core/domain/usecase/set_day_boundary_usecase.dart`
- `lib/core/domain/usecase/toggle_favourite_meal_usecase.dart`
- `lib/core/presentation/widgets/keyboard_dismisser.dart`
- `lib/core/utils/calc/calendar_day_calc.dart`
- `lib/core/utils/daily_reminder_scheduler.dart`
- `lib/core/utils/reload_diary_and_trends.dart`
- `lib/core/utils/tracked_day_lock.dart`
- `lib/core/utils/tracked_day_reconciler.dart`
- `lib/core/utils/widget/calorie_widget_labels.dart`
- `lib/core/utils/widget/calorie_widget_snapshot.dart`
- `lib/core/utils/widget/calorie_widget_writer.dart`
- `lib/features/add_meal/presentation/bloc/favourite_meal_bloc.dart`
- `lib/features/add_meal/presentation/bloc/favourite_meal_event.dart`
- `lib/features/add_meal/presentation/bloc/favourite_meal_state.dart`
- `lib/features/add_meal/presentation/bloc/favourite_toggle_bloc.dart`
- `lib/features/add_meal/presentation/bloc/favourite_toggle_event.dart`
- `lib/features/add_meal/presentation/bloc/favourite_toggle_state.dart`
- `lib/features/add_meal/presentation/widgets/favourite_toggle_button.dart`
- `lib/features/add_meal/presentation/widgets/partial_results_notice.dart`
- `lib/features/home/presentation/widgets/shared_meal_import_dialogs.dart`
- `lib/features/home/presentation/widgets/shared_meal_importer.dart`
- `lib/features/settings/domain/goal_settings_backup.dart`
- `lib/features/settings/domain/tracked_day_boundary_record.dart`
- `lib/l10n/intl_ar.arb`
- `lib/l10n/intl_nl.arb`
- `test/core/presentation/widgets/error_dialog_test.dart`
- `test/core/presentation/widgets/keyboard_dismisser_test.dart`
- `test/features/activity_detail/activity_detail_add_double_tap_test.dart`
- `test/features/add_meal/presentation/add_meal_screen_provider_failure_test.dart`
- `test/features/add_meal/presentation/add_meal_screen_recent_search_test.dart`
- `test/features/add_meal/presentation/favourites_tab_test.dart`
- `test/features/diary/diary_page_delete_test.dart`
- `test/features/diary/diary_page_logical_today_test.dart`
- `test/features/diary/presentation/bloc/calendar_day_bloc_activity_edit_test.dart`
- `test/features/diary/presentation/bloc/calendar_day_bloc_label_test.dart`
- `test/features/diary/presentation/bloc/calendar_day_bloc_stale_load_test.dart`
- `test/features/diary/presentation/widgets/day_info_widget_test.dart`
- `test/features/edit_meal/presentation/edit_meal_save_previous_meal_test.dart`
- `test/features/home/presentation/bloc/home_bloc_calorie_widget_test.dart`
- `test/features/home/presentation/bloc/home_bloc_held_lock_test.dart`
- `test/features/home/presentation/widgets/intake_card_sort_test.dart`
- `test/features/home/presentation/widgets/shared_meal_import_test.dart`
- `test/features/meal_detail/meal_detail_add_double_tap_test.dart`
- `test/features/meal_detail/meal_detail_favourite_refresh_test.dart`
- `test/features/meal_detail/presentation/widgets/meal_detail_nutriments_table_test.dart`
- `test/features/profile/presentation/profile_page_fab_clearance_test.dart`
- `test/features/profile/presentation/utils/profile_switch_coordinator_test.dart`
- `test/features/profile/presentation/widgets/weight_trend_chart_test.dart`
- `test/features/recipes/presentation/screens/recipe_builder_screen_test.dart`
- `test/features/settings/presentation/bloc/settings_bloc_update_tracked_day_test.dart`
- `test/features/settings/presentation/widgets/diary_day_boundary_dialog_test.dart`
- `test/features/settings/presentation/widgets/export_import_dialog_test.dart`
- `test/features/settings/presentation/widgets/goal_edits_logical_day_test.dart`
- `test/features/settings/presentation/widgets/kcal_adjustment_dialog_test.dart`
- `test/features/settings/presentation/widgets/kcal_adjustment_dialog_title_test.dart`
- `test/features/settings/presentation/widgets/kcal_adjustment_dialog_typed_value_test.dart`
- `test/features/settings/presentation/widgets/nutrient_goals_decimal_input_test.dart`
- `test/features/settings/presentation/widgets/nutrient_goals_screen_fibre_default_test.dart`
- `test/features/settings/presentation/widgets/nutrient_goals_screen_test.dart`
- `test/features/settings/presentation/widgets/nutrient_visibility_screen_test.dart`
- `test/features/settings/presentation/widgets/water_goal_dialog_test.dart`
- `test/features/settings/presentation/widgets/water_goal_dialog_typed_value_test.dart`
- `test/features/settings/settings_screen_reload_test.dart`
- `test/features/trends/trends_calorie_chart_energy_unit_test.dart`
- `test/helpers/fake_favourites.dart`
- `test/helpers/fake_notification_platform.dart`
- `test/helpers/fake_reload_blocs.dart`
- `test/helpers/recording_add_weight_log_usecase.dart`
- `test/unit_test/arb_activity_names_unique_test.dart`
- `test/unit_test/calendar_day_calc_test.dart`
- `test/unit_test/calorie_widget_labels_test.dart`
- `test/unit_test/calorie_widget_snapshot_test.dart`
- `test/unit_test/calorie_widget_writer_test.dart`
- `test/unit_test/daily_reminder_scheduler_test.dart`
- `test/unit_test/delete_dialog_copy_test.dart`
- `test/unit_test/delete_weight_log_usecase_test.dart`
- `test/unit_test/edit_meal_barcode_clear_test.dart`
- `test/unit_test/edit_meal_remap_intakes_test.dart`
- `test/unit_test/favourite_cross_profile_test.dart`
- `test/unit_test/favourite_export_import_test.dart`
- `test/unit_test/favourite_meal_bloc_test.dart`
- `test/unit_test/favourite_meal_repository_test.dart`
- `test/unit_test/favourite_toggle_bloc_test.dart`
- `test/unit_test/import_data_usecase_upsert_test.dart`
- `test/unit_test/import_goal_settings_test.dart`
- `test/unit_test/import_tracked_day_boundary_test.dart`
- `test/unit_test/intake_data_source_recent_test.dart`
- `test/unit_test/onboarding_daily_reminder_test.dart`
- `test/unit_test/recent_intake_recipe_refresh_test.dart`
- `test/unit_test/send_intake_to_profiles_boundary_test.dart`
- `test/unit_test/switch_profile_tracked_day_lock_test.dart`
- `test/unit_test/tracked_day_create_if_absent_test.dart`
- `test/unit_test/tracked_day_listed_day_test.dart`
- `test/widget_test/partial_results_notice_test.dart`

</details>
