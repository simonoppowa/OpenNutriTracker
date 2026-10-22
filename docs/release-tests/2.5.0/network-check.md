# 2.5.0 network check: destinations and declared data flows since 2.4.0

Ticket: [#1435](https://github.com/simonoppowa/OpenNutriTracker/issues/1435), part of map [#1425](https://github.com/simonoppowa/OpenNutriTracker/issues/1425).
Method reused from the 2.4.0 check, [#1241](https://github.com/simonoppowa/OpenNutriTracker/issues/1241).
Checked on 2026-10-22.

## Verdict

**No change since 2.4.0 adds, removes or redirects a network destination, and no new data type leaves the device.** The Play Data safety record, the App Store Connect App Privacy answers and the collected-data part of `PrivacyInfo.xcprivacy` all stand for 2.5.0. No console edit is needed.

Two things did change outside the data declarations, and both come from the iOS widget's plugin (`home_widget` 0.10.0):

1. **The Android merged manifest gains two permissions, `WAKE_LOCK` and `FOREGROUND_SERVICE`,** along with WorkManager, Glance and Room components. Android has no widget UI yet, so nothing in the app uses them. They trigger no data-safety answer and no foreground-service declaration (details below). They will show up in the permission list that Play generates for the listing.
2. **iOS gains an App Group** shared by Runner and the new `CalorieWidget` extension, plus the `1C8F.1` required-reason entry for App Group `UserDefaults`. That is on-device storage. Neither store counts it as collection.

## Scope and method

- Range: `680eafaa8` (chore(release): bump to 2.4.0+66) to `c293acff4` (the frozen candidate, equal to `origin/develop` at the time of the check).
- Paths: `lib/`, `android/`, `ios/`, `pubspec.yaml`, `pubspec.lock`. 177 files changed. On Android only `Gemfile` and `Gemfile.lock` changed (fastlane tooling).
- I read the delta, not the commit log, in four steps:
  1. **Transport files.** I listed every file at the candidate that holds a network construct (`package:http`, `Uri.parse/https/http`, `HttpClient`, Supabase, `.rpc(`, Sentry, `launchUrl`, literal `http(s)://`) and intersected that list with the changed files. Every changed file in the intersection was then read.
  2. **New imports.** I grepped the diff for added third-party imports. None of them is a networking package (list below).
  3. **Merged manifest.** I built the Android merged manifest for `fullRelease` at both ends: `./gradlew :app:processFullReleaseManifest`, once with the candidate's `pubspec.yaml`/`pubspec.lock` and once with v2.4.0's (`android/app` is identical at both ends). I diffed the two outputs and traced each addition with the manifest-merger report and `dependencyInsight`.
  4. **Dependency changelogs.** For each package whose version moved in `pubspec.lock`, I read the changelog between the two versions, taken from the published package archive in the local pub cache (the same `CHANGELOG.md` pub.dev renders).
- `test/unit_test/store_declarations_test.dart` passes at the candidate (28 tests).

## Findings

### Transport layer: untouched

`git diff --stat 680eafaa8 c293acff4` is **empty** for all of these:

- `lib/features/add_meal/data/**`: `off_data_source.dart`, `sp_food_data_source.dart`, `openai_meal_items_api.dart`, `anthropic_meal_items_api.dart`, `openai_compatible_meal_items_api.dart`, `meal_items_api_factory.dart`, `products_repository.dart`, all DTO constants
- `lib/core/utils/ont_http_client.dart`, `sentry_config.dart`, `env.dart`, `url_const.dart`, `off_const.dart`, `ai_model_list_api.dart`, `plaintext_destination_guard.dart`, `ai_credential_storage.dart`, `ont_image_cache_manager.dart`
- `lib/core/data/data_source/remote_search_cache_data_source.dart` and `lib/core/data/data_source/health/**`
- `probe_ai_endpoint_usecase.dart` and `read_meal_text_usecase.dart`
- `android/app/**`, `ios/Runner/Info.plist` and `ios/Runner/AppDelegate.swift`

The consequences:

- **Open Food Facts:** search, barcode and legacy hosts, paths and parameters are unchanged.
- **Supabase:** the same RPCs and request bodies.
- **AI providers:** still `api.openai.com/v1/responses`, `api.anthropic.com/v1/messages`, `openrouter.ai/api/v1/chat/completions`, or the user's own server.
- **Sentry:** same DSN source and same `beforeSend`. The `SentryFlutter.init` block in `lib/main.dart:139-170` is still gated on `kReleaseMode && hasAcceptedAnonymousData` and has no diff. `lib/main.dart` changed only in its locale and reminder plumbing and in `KeyboardDismisser`.

`sentry_flutter`, `supabase_flutter`, `http`, `cached_network_image` and `flutter_cache_manager` keep their v2.4.0 versions in `pubspec.lock`.

### Changed files that touch the network

| File | Before → after | On the wire |
|---|---|---|
| `lib/features/add_meal/presentation/bloc/products_bloc.dart:48`, `food_bloc.dart:42` | Retry used to call `searchOFFProductsByString` / `searchFDCFoodByString` directly. It now re-runs `_loadProducts` / `_loadFood` with `force: true`. A generation counter drops stale results. | **No change.** Same use-case methods, same query. |
| `lib/features/add_meal/domain/usecase/search_products_usecase.dart` | `_safeRemoteCall` returns `({meals, failed})`, and the result gains `remoteSourceFailed`. | **No change.** This only tells the UI that the provider failed. |
| `lib/features/scanner/domain/usecase/search_product_by_barcode_usecase.dart:60-65` | After the existing OFF barcode lookup, `refreshDetailedSnapshot(remote)` writes the fresh record over a matching favourite. | **No change.** One lookup as before. The new write goes to Hive. |
| `lib/features/meal_detail/presentation/bloc/meal_detail_bloc.dart:211-226` | The existing background OFF refresh after logging also refreshes a favourite's snapshot. The write is now inside a tracked-day lock. | **No change.** Same lookup, local write. |
| `lib/features/meal_detail/presentation/widgets/meal_info_button.dart` | Hides the button when the info URL is empty, and reformats code. | **No change.** Same URLs. It opens the browser and makes no request itself. |
| `lib/features/settings/presentation/widgets/ai_assist_dialog.dart:549, 593` | Changing the address no longer clears the model field up front (#1364). The field is cleared only when the new server's model list lacks the name. Also focus and scroll handling. | **No new destination or field.** The model list request (`ai_model_list_api.dart`, unchanged) goes to the address the user typed, as before. Edge case: if that fetch fails and the user presses OK, the old model name can now be saved against the new address. That changes the value of an existing field sent to a destination the user chose. It is not a new data type. |
| `lib/core/domain/usecase/delete_all_user_data_usecase.dart:72, 82` | Also clears `FavouriteMealBox` and the widget's App Group copy. The reminder goes through `DailyReminderScheduler`. | **Still no remote deletion request.** It stays a local wipe. |
| `lib/core/utils/demo/demo_seeder.dart` | Corrects a comment: demo meal photos were already bundled by `_importMealPhoto` at v2.4.0 (`demo_content.dart:89`). | None. |

Added third-party imports in the `lib/` diff: `bloc_concurrency`, `equatable`, `flutter_bloc`, `hive_ce`, `hive_ce_flutter`, `home_widget`, `intl`, `json_annotation`, `logging`, `package_info_plus`, `stream_transform`, `synchronized`, `uuid`, and Flutter SDK libraries. None of them is a networking package.

### Favourites (#1320): local only

New files: `favourite_meal_data_source.dart`, `favourite_meal_dbo.dart`, `favourite_meal_repository.dart`, `toggle_favourite_meal_usecase.dart`, `get_favourite_meals_usecase.dart`, the `favourite_meal_*` and `favourite_toggle_*` blocs, and `favourite_toggle_button.dart`.

- Their imports are Hive, bloc and in-app types only. No file reaches `ProductsRepository` or any HTTP client.
- `FavouriteMealBox` (`hive_db_provider.dart:68`) opens through the same per-profile path and AES cipher as the other boxes (`:242`, `:277`).
- A starred food is refreshed only as a side effect of the two OFF lookups above, which already ran. Favourites add no request of their own.
- The Favourites list renders images through the existing `meal_item_card.dart` `CachedNetworkImage`. Those are the stored meal's image URLs, the same ones the Recent list already loads.

### Shared meal code import (#1329): parses locally, fetches what the QR path already fetched

**Entry point.** A new "Paste code" item in the meal section menu (`intake_vertical_list.dart:290-305`), plus a second entry from the import scanner (`import_meal_scanner_screen.dart:152`). The item is not platform-gated in Dart, so it appears on iOS as well, despite the commit's `feat(android)` scope.

**What a code is.** `SharedMealCodeDialog._parse` (`shared_meal_import_dialogs.dart:22-29`) calls `SharedMealPayload.fromJsonString` (`shared_meal_payload.dart:316`): base64url, then gzip, capped at 64 KiB decompressed (`:249`), then a JSON array. It falls back to raw JSON. The decoded payload is the same one the QR scanner reads: items (with `thumbnailImageUrl`/`mainImageUrl` at indices 11/12), recipes, and OFF barcode references.

**What it fetches.** `SharedMealImporter._prepareItems` (`shared_meal_importer.dart:168-183`) looks up each OFF barcode reference through `SearchProductByBarcodeUseCase`. That is the cache first, then the OFF barcode endpoint. Nothing else is fetched at parse or preview time, and the preview dialog renders no images.

**Before → after.** At v2.4.0, `import_meal_scanner_screen.dart:194` parsed the same payload and `:297-300` ran the same per-barcode lookup, wrapped in an extra `withRetry`. #1329 removed that retry, so a failing code now costs at most OFFDataSource's own three attempts instead of nine.

**Already true before 2.4.0, now reachable by paste.** A sender's `thumbnailImageUrl`/`mainImageUrl` are stored with the imported intake, and `intake_card.dart:171` later loads them with `CachedNetworkImage`. Their host is whatever the sender's meal carried (normally Open Food Facts' image CDN). The QR path has always worked this way. Pasting is a second way to receive the same payload, not a new destination.

### iOS widget (#1251): App Group, no network

**Extension.** `ios/CalorieWidget/CalorieWidget.swift` imports only `SwiftUI` and `WidgetKit`. It has no `URLSession`, `URL(` or `widgetURL`. `Info.plist` declares only `com.apple.widgetkit-extension` and `ONTAppGroupId`. The extension's own `PrivacyInfo.xcprivacy` declares `NSPrivacyTracking` false, no tracking domains, **no collected data types**, and `UserDefaults` with reason `1C8F.1`.

**Entitlements.** `CalorieWidget.entitlements` (new) and `Runner.entitlements` (+4 lines) both grant `com.apple.security.application-groups` = `$(ONT_APP_GROUP_ID)`. That is `group.com.opennutritracker.ont.opennutritracker` for full and `….develop` for develop (`project.pbxproj`). `ios/Runner/PrivacyInfo.xcprivacy` adds `1C8F.1` beside `CA92.1` under `NSPrivacyAccessedAPICategoryUserDefaults`, because `home_widget` ships no manifest of its own.

**Writer.** `lib/core/utils/widget/calorie_widget_writer.dart:118-147` uses `HomeWidget.setAppGroupId`, `saveWidgetData` and `updateWidget(iOSName:)`, and nothing else. The snapshot holds today's consumed kcal, the goal and labels. On Android the same keys go to the plugin's SharedPreferences, with `updateWidget` skipped. `allowBackup="false"` already keeps that out of Android backup.

**Signing.** `ios/fastlane/Matchfile` and `Fastfile` add the extension's App Store profile. That is release logistics, not a declaration.

**Verdict for iOS.** Both stores define collection as data leaving the device, and none leaves it here. The App Store Connect App Privacy answers are unaffected. The required-reason entry is the privacy-manifest obligation, and it is already met.

### Android merged manifest: two new permissions, from `home_widget`

`fullRelease` merged manifest, v2.4.0 dependencies against candidate dependencies:

| Added | Source (manifest-merger report / `dependencyInsight`) |
|---|---|
| `android.permission.WAKE_LOCK` | `androidx.work:work-runtime:2.11.2` ← `work-runtime-ktx` ← `project :home_widget` (and `glance-appwidget:1.2.0` ← `:home_widget`) |
| `android.permission.FOREGROUND_SERVICE` | same |
| WorkManager `SystemJobService`, `SystemForegroundService`, `RescheduleReceiver`, `ForceStopRunnable$BroadcastReceiver`, `DiagnosticsReceiver` (exported, guarded by `android.permission.DUMP`), `WorkManagerInitializer` startup entry | same |
| Glance `ActionTrampolineActivity`, `InvisibleActionTrampolineActivity`, `ActionCallbackBroadcastReceiver`, `UnmanagedSessionReceiver`, `MyPackageReplacedReceiver`, `GlanceRemoteViewsService` (`BIND_REMOTEVIEWS`), `RemoteViewsCompatService` | `glance-appwidget:1.2.0` ← `:home_widget` |
| Room `MultiInstanceInvalidationService` | WorkManager's Room dependency |

`ACCESS_NETWORK_STATE` only moved position: v2.4.0 already had it, through ML Kit's `transport-backend-cct` (see #872). Nothing was removed.

What the additions mean:

- **None of them sends anything.** WorkManager, Glance and Room are local scheduling, widget-rendering and storage libraries. Android has no widget UI in this release (`docs/ios-calorie-widget.md`), so the app never enqueues work or renders a Glance widget.
- **No Play foreground-service declaration is triggered.** That declaration covers foreground service *types* for apps targeting Android 14+ ([Play Console Help 13392821](https://support.google.com/googleplay/android-developer/answer/13392821)). The merged manifest has no `foregroundServiceType` and no `FOREGROUND_SERVICE_*` permission at either end (`targetSdkVersion` 36). `WAKE_LOCK` and `FOREGROUND_SERVICE` are normal-protection permissions with no runtime prompt.
- **The Data safety form is not about permissions.** No answer on it moves.
- What does change is the auto-generated permission list on the Play listing. If the unused footprint is unwanted, `tools:node="remove"` in the app manifest could strip it. Whether that is safe while `home_widget` stays on the classpath is untested. That is a code decision, not a declaration one.

### Dependency rollup (#1374) and other lockfile moves

`pubspec.lock` moves 19 packages:

- Version bumps: `android_file_picker` 1.1.0→2.1.0, `cupertino_icons` 1.0.9→2.0.0, `envied`/`envied_generator` 1.3.9→1.3.10, `file_picker` 12.2.0→13.1.0 (with `file_picker_darwin`/`_linux`/`_platform_interface`/`_web` and `windows_file_picker`), `flutter_timezone` 5.1.0→5.1.1, `get_it` 9.2.1→9.3.0, `hive_ce` 2.20.0→2.21.0, `hive_ce_flutter` 2.3.4→2.4.0, `image_picker` 1.2.3→1.2.4, `package_info_plus` 10.2.1→10.2.2, `share_plus` 13.3.0→13.3.1, `url_launcher` 6.3.2→6.3.3.
- New: `home_widget` 0.10.0.
- `Podfile.lock` adds `home_widget` and a new `share_plus` checksum. The `Sentry` and `sentry_flutter` checksums are unchanged.

None of these packages is a network or telemetry SDK. I read every changelog in the range anyway, and none adds network behaviour:

| Package | What the changelog range covers |
|---|---|
| `url_launcher` 6.3.3 | A `supportsCloseForLaunchMode` fix and a minimum SDK bump |
| `share_plus` 13.3.1 | iPad popover, `keyWindow` fallback removal, Kotlin Gradle plugin |
| `package_info_plus` 10.2.2 | Kotlin Gradle plugin |
| `image_picker` 1.2.4 | A documentation note and a minimum SDK bump |
| `flutter_timezone` 5.1.1 | Gradle warning, Equatable 3 |
| `envied` 1.3.10 | Build-time code generation |
| `get_it` 9.3.0 | DI diagnostics |
| `hive_ce` 2.20.1–2.21.0 | `openBox` race fixes, DateTime microseconds, web reads |
| `hive_ce_flutter` 2.4.0 | Absolute init paths, a TimeOfDay adapter |
| `file_picker` 12.3.0–13.1.0 | Breaking API clean-up, accept labels, UIScene |
| `home_widget` 0.10.0 | Fonts, previews, null handling. Its source has no HTTP client, and its own Android manifest is empty. The permissions come from its WorkManager and Glance dependencies. |

## What the declarations say, and why they stand

- **Play Data safety** (`docs/play-data-safety.md`, as entered under map #935/#941): in-app search history (shared), crash logs and diagnostics (optional), and approximate location. The AI meal photo and typed meal line are still missing from the live record. That gap is tracked in #1050 (open), predates 2.4.0, and is neither widened nor narrowed by this delta.
- **Apple App Privacy:** four types, none linked to identity (#941). `ios/Runner/PrivacyInfo.xcprivacy` declares the meal photo and meal text, pinned by `store_declarations_test.dart`. Its collected-data entries have no diff in this range: the only change there is the `1C8F.1` reason.

Every flow in this delta either goes to a destination that already received the same fields at v2.4.0, or stays on the device (favourites, the widget snapshot, the App Group). Nothing needs changing, so no issue was filed.

Doc-only drift spotted on the way, not a declaration: `docs/play-data-safety.md` says delete-all clears "the active profile's eight Hive boxes". It now clears nine, plus the widget's App Group copy. The point that section makes (no remote deletion request) still holds.

## Limits

- **SDK defaults are still unproven by capture.** As in #1241, this check pins how SDKs are configured and which packages moved, not what an SDK does by default at runtime. The SDKs that do network (`sentry_flutter`, `supabase_flutter`, `cached_network_image`) did not move this cycle, so last cycle's open question is not widened. It is still not answered: only a network capture of a release build would prove it.
- **Merged manifest built locally.** It came from the `full` flavour's release variant with `.env.example` values, not from the signed bundle CI produces. The flavour inputs (`android/app/**`) are identical at both ends, so the diff isolates dependency changes. A difference from CI's Gradle resolution is not excluded.
- **The Supabase host is opaque.** It is an obfuscated `envied` field read from a `.env` that is not in the repo. Only "`env.dart` unchanged" is established.
- **Pre-existing, out of scope.** ML Kit's `transport-backend-cct` telemetry transport, pulled in by `mobile_scanner`, is in both manifests unchanged (#872 recorded it). Image URLs embedded in shared-meal payloads have always pointed wherever the sender's food pointed. Neither changed in this range, and neither is re-adjudicated here.
- **iOS was checked by reading only.** I did not build or run the widget. The no-network claim rests on its source (two framework imports, no networking API) and its empty collected-data list.
