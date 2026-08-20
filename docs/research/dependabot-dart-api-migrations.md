# Dependabot Dart API migration classification

Research for [Classify Dart package upgrades and required API migrations](https://github.com/simonoppowa/OpenNutriTracker/issues/743), based on `origin/develop` at `3f5f1a45` and the versions proposed by the open Dependabot PRs on 2026-08-20.

## Decision

The ten Dart upgrades can share one rollup PR, but four packages need migrations in that PR. Apply the migrations before expecting analysis to pass.

| Proposed upgrade | Classification | Required work |
| --- | --- | --- |
| `json_serializable` 6.14.0 → 6.14.1 ([PR](https://github.com/simonoppowa/OpenNutriTracker/pull/613)) | Declaration and lockfile only | Regenerate; expect no checked-in output diff. 6.14.1 only widens the `analyzer` range to `<15.0.0`. [Official changelog](https://pub.dev/packages/json_serializable/changelog#6141) |
| `hive_ce_generator` 1.11.1 → 1.11.2 ([PR](https://github.com/simonoppowa/OpenNutriTracker/pull/612)) | Declaration and lockfile only | Regenerate; expect no checked-in output diff. 1.11.2 only upgrades `analyzer` to 12. [Official changelog](https://pub.dev/packages/hive_ce_generator/changelog#1112) |
| `flutter_image_compress` 2.4.0 → 2.5.1 ([PR](https://github.com/simonoppowa/OpenNutriTracker/pull/611)) | Declaration and lockfile only; targeted behavior test | No API change affects `FlutterImageCompress.compressWithFile` in [`user_image_storage.dart`](../../lib/core/utils/user_image_storage.dart). The release changes EXIF behavior, rejects same-path `compressAndGetFile`, adds Darwin SPM, and fixes Gradle 9 handling; this app uses WebP bytes, does not pass a target path, and leaves `keepExif` false. [Official changelog](https://pub.dev/packages/flutter_image_compress/changelog#251) |
| `path_provider_platform_interface` 2.1.2 → 2.1.3 ([PR](https://github.com/simonoppowa/OpenNutriTracker/pull/610)) | Declaration and lockfile only | Its only API note documents `getDownloadsPath` semantics; the app's two test fakes do not override or call that method. [Official changelog](https://pub.dev/packages/path_provider_platform_interface/changelog#213) |
| `sentry_flutter` 9.19.0 → 9.26.0 ([PR](https://github.com/simonoppowa/OpenNutriTracker/pull/609)) | Source-compatible; refresh native lockfile | No used API changed: `SentryFlutter.init`, `Sentry.captureException`, `Sentry.close`, and `tracesSampleRate` analyze cleanly. Refresh and commit `ios/Podfile.lock`; the existing PR failed only its three CocoaPods steps ([guard](https://github.com/simonoppowa/OpenNutriTracker/actions/runs/30769373598/job/91553690454), [build](https://github.com/simonoppowa/OpenNutriTracker/actions/runs/30769373598/job/91553690452), [integration](https://github.com/simonoppowa/OpenNutriTracker/actions/runs/30769373598/job/91553690415)). Releases 9.20–9.26 add opt-in tracing/features and native SDK updates, not a migration for these call sites. [Official changelog](https://pub.dev/packages/sentry_flutter/changelog#9260) |
| `image_picker` 1.2.2 → 1.2.3 ([PR](https://github.com/simonoppowa/OpenNutriTracker/pull/608)) | Declaration and lockfile only | The patch fixes the `limit: 1` multi-picker path; all repository calls use `pickImage`. [Official changelog](https://pub.dev/packages/image_picker/changelog#123) |
| `flutter_local_notifications` 19.5.0 → 20.1.0 ([PR](https://github.com/simonoppowa/OpenNutriTracker/pull/573)) | Dart call-site migration | Version 20 converts `initialize`, `cancel`, and `zonedSchedule` from positional to named parameters. All affected calls are in [`notification_service.dart`](../../lib/core/utils/notification_service.dart). [Official changelog](https://pub.dev/packages/flutter_local_notifications/changelog#2000) |
| `flutter_timezone` 3.0.1 → 5.1.0 ([PR](https://github.com/simonoppowa/OpenNutriTracker/pull/569)) | Dart return-type migration | `getLocalTimezone()` now returns `TimezoneInfo`, not `String`; pass its `identifier` to `tz.getLocation`. [Official changelog](https://pub.dev/packages/flutter_timezone/changelog#500), [API](https://pub.dev/documentation/flutter_timezone/5.1.0/timezone_info/TimezoneInfo-class.html) |
| `supabase_flutter` 2.12.4 → 2.16.0 ([PR](https://github.com/simonoppowa/OpenNutriTracker/pull/568)) | Dart deprecation migration for clean CI | Change `Supabase.initialize(anonKey: ...)` to `publishableKey:` in [`locator.dart`](../../lib/core/utils/locator.dart). The value remains `Env.supabaseProjectAnonKey`; this is terminology/API migration, not a credential-format change. The 2.16 behavior change disables debug logging under `flutter test`, while this app already passes `debug: false`. [Official changelog](https://pub.dev/packages/supabase_flutter/changelog#2160) |
| `share_plus` 10.1.4 → 12.0.2 ([PR](https://github.com/simonoppowa/OpenNutriTracker/pull/564)) | Dart API and Android toolchain migration | Replace both deprecated static `Share` calls in [`share_qr_dialog.dart`](../../lib/core/presentation/widgets/share_qr_dialog.dart) with `SharePlus.instance.share(ShareParams(...))`. Also raise AGP in `android/settings.gradle` from 8.11.1 to at least 8.12.1. Gradle 8.14, Kotlin 2.2.20, Java 17, Flutter 3.44.6, Dart 3.11+, and iOS 15.5 already satisfy the remaining requirements. [12.0.2 requirements and migration](https://pub.dev/packages/share_plus/versions/12.0.2) |

## Exact migration surface

The isolated exact-version probe resolved all ten packages together and found 24 package-related analyzer diagnostics, all confined to three files:

- [`lib/core/utils/notification_service.dart`](../../lib/core/utils/notification_service.dart): use `(await FlutterTimezone.getLocalTimezone()).identifier`; change `initialize(initSettings)` to `initialize(settings: initSettings)`; name `id:` on four `cancel` calls; and name `id`, `title`, `body`, `scheduledDate`, and `notificationDetails` on both `zonedSchedule` calls. Version 20's official example shows those parameter names. [Official 20.1.0 example](https://pub.dev/packages/flutter_local_notifications/versions/20.1.0/example)
- [`lib/core/presentation/widgets/share_qr_dialog.dart`](../../lib/core/presentation/widgets/share_qr_dialog.dart): migrate the file-sharing path to `ShareParams(files: [XFile(...)], text: widget.code, sharePositionOrigin: origin)` and the fallback to `ShareParams(text: widget.code, sharePositionOrigin: origin)`. The existing bounded-origin logic should be preserved. [Official migration](https://pub.dev/packages/share_plus/versions/12.0.2#migrating-from-shareshare-to-shareplusinstanceshare)
- [`lib/core/utils/locator.dart`](../../lib/core/utils/locator.dart): rename the `Supabase.initialize` argument from `anonKey` to `publishableKey`.

No generated Dart files changed after a clean `build_runner` pass with both proposed generator versions. No additional diagnostics appeared in the direct-use files for Sentry, image picking, compression, path-provider fakes, or Supabase queries.

## SDK and build floors

The repository declares Dart `>=3.11.0 <4.0.0` and FVM Flutter 3.44.6, so every proposed package's Dart/Flutter floor is already met. The highest new floors are Flutter 3.38/Dart 3.10 for `image_picker` and `path_provider_platform_interface`; notifications needs Flutter 3.32/Dart 3.8; Supabase needs Flutter 3.35/Dart 3.9. Share Plus 12.0.2's Android requirement is the sole mismatch: AGP 8.12.1+ versus the repository's 8.11.1. [Path-provider floor](https://pub.dev/packages/path_provider_platform_interface/changelog#213), [image-picker floor](https://pub.dev/packages/image_picker/changelog#123), [notifications floor](https://pub.dev/packages/flutter_local_notifications/changelog#2000), [Share Plus requirements](https://pub.dev/packages/share_plus/versions/12.0.2#requirements)

One exact-version trap: a fresh resolution of `sentry_flutter: ^9.26.0` now selects 9.27.0. To honor the requested Dependabot versions, construct the rollup from the Dependabot lockfile changes (or otherwise verify `pubspec.lock` contains exactly 9.26.0), then run `flutter pub get --enforce-lockfile` in CI rather than silently accepting a newer release.

## CI evidence and verification plan

The old PR checks match the classification but are stale relative to current `develop`:

- `json_serializable`, `hive_ce_generator`, `path_provider_platform_interface`, and `image_picker` passed Linux analysis/tests plus Android and iOS build/integration checks.
- `flutter_local_notifications` failed Linux analysis and both platform build/integration jobs, consistent with compile-breaking positional calls.
- `supabase_flutter` and `share_plus` failed only Linux analysis while both platform build/integration jobs passed, consistent with deprecation diagnostics rather than runtime/compiler breakage.
- `sentry_flutter` passed Linux and Android, and failed only CocoaPods preparation on iOS; refresh the native lock.
- `flutter_image_compress` and `flutter_timezone` have no recorded checks, so the rollup must supply their evidence.

After applying the migrations, run:

1. `just build`, then assert only intentional lock/generated changes; generator output should remain unchanged.
2. `flutter analyze` and the full `just test` suite.
3. Focused tests: `test/unit_test/notification_service_test.dart`, `test/widget_test/share_qr_dialog_test.dart`, `test/unit_test/user_image_storage_test.dart`, `test/unit_test/demo_meal_photos_test.dart`, `test/unit_test/sp_food_data_source_ranking_test.dart`, `test/unit_test/search_products_usecase_test.dart`, and `integration_test/app_boot_test.dart`.
4. Add a plugin-facing notification test if practical: the existing notification test covers only the pure next-occurrence calculation and would not catch named-parameter wiring or the `TimezoneInfo.identifier` bridge.
5. On macOS, run `cd ios && pod install --repo-update`, commit `ios/Podfile.lock`, then build iOS.
6. Build Android after the AGP bump and smoke-test: profile/recipe image selection and WebP persistence, daily and fasting notifications (including timezone initialization), QR file share plus text fallback, and a Supabase food search.
