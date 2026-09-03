# Stable dependency set for the 2026-09-03 Dependabot migration

## Decision

Use the versions below for the dependency names frozen by
[Consolidate the current Dependabot backlog into one stable migration PR](https://github.com/simonoppowa/OpenNutriTracker/issues/1037).
This is the newest stable set that is both solver-compatible with Flutter 3.44.6 and operationally compatible with
OpenNutriTracker's stored user data. It was resolved on 2026-09-03 from `origin/develop` at `7c67c6eb` with Flutter
3.44.6 / Dart 3.12.2.

| Frozen name | Manifest/action selection | Resolved version | Why |
| --- | --- | --- | --- |
| `actions/setup-java` | `actions/setup-java@v6.0.0` | n/a | Current stable major from the frozen action PR. |
| `flutter_secure_storage` | `^10.3.1` | 10.3.1 | Highest data-safe release for the app's current Android ciphertext; do not take 11.0.0 yet. |
| `path_provider` | `^2.1.6` | 2.1.6 | Latest stable. |
| `dynamic_color` | `^2.1.0` | 2.1.0 | Latest stable. |
| `mobile_scanner` | `^7.4.0` | 7.4.0 | Latest stable. |
| `table_calendar` | `^3.2.1` | 3.2.1 | Latest stable. |
| `file_picker` | `^12.2.0` | 12.2.0 | Stable replacement for both 11.0.3 and the rejected 12.0.0 beta proposal. |
| `supabase_flutter` | `^2.17.2` | 2.17.2 | Latest stable. |
| `flutter_svg` | `^2.3.0` | 2.3.0 | Latest stable. |
| `share_plus_platform_interface` | `^7.2.0` | 7.2.0 | Interface paired with `share_plus` 13.3.0. |
| `package_info_plus` | `^10.2.1` | 10.2.1 | Latest stable. |
| `health` | `^13.3.2` | 13.3.2 | Latest stable. |
| `share_plus` | `^13.3.0` | 13.3.0 | Latest stable. |
| `flutter_local_notifications` | `^22.3.0` | 22.3.0 | Latest stable. |
| `timezone` | `^0.11.1` | 0.11.1 | Latest stable. |
| `intl` | `^0.20.2` | 0.20.2 | Flutter 3.44.6 pins this exact version; do not take 0.20.3. |
| `meta` | `^1.18.0` | 1.18.0 | Flutter 3.44.6 pins this exact version; do not take 1.19.0. |

The upstream package records for the selected releases are the primary version evidence:
[`flutter_secure_storage` 10.3.1](https://pub.dev/packages/flutter_secure_storage/versions/10.3.1),
[`path_provider` 2.1.6](https://pub.dev/packages/path_provider/versions/2.1.6),
[`dynamic_color` 2.1.0](https://pub.dev/packages/dynamic_color/versions/2.1.0),
[`mobile_scanner` 7.4.0](https://pub.dev/packages/mobile_scanner/versions/7.4.0),
[`table_calendar` 3.2.1](https://pub.dev/packages/table_calendar/versions/3.2.1),
[`file_picker` 12.2.0](https://pub.dev/packages/file_picker/versions/12.2.0),
[`supabase_flutter` 2.17.2](https://pub.dev/packages/supabase_flutter/versions/2.17.2),
[`flutter_svg` 2.3.0](https://pub.dev/packages/flutter_svg/versions/2.3.0),
[`share_plus_platform_interface` 7.2.0](https://pub.dev/packages/share_plus_platform_interface/versions/7.2.0),
[`package_info_plus` 10.2.1](https://pub.dev/packages/package_info_plus/versions/10.2.1),
[`health` 13.3.2](https://pub.dev/packages/health/versions/13.3.2),
[`share_plus` 13.3.0](https://pub.dev/packages/share_plus/versions/13.3.0),
[`flutter_local_notifications` 22.3.0](https://pub.dev/packages/flutter_local_notifications/versions/22.3.0), and
[`timezone` 0.11.1](https://pub.dev/packages/timezone/versions/0.11.1).

## Why the Dependabot proposals do not resolve unchanged

Flutter 3.44.6's own packages impose two exact constraints:
[`flutter_localizations` pins `intl` 0.20.2](https://github.com/flutter/flutter/blob/3.44.6/packages/flutter_localizations/pubspec.yaml)
and [`flutter_test` pins `meta` 1.18.0](https://github.com/flutter/flutter/blob/3.44.6/packages/flutter_test/pubspec.yaml).
The Flutter solver therefore rejects the proposed `intl ^0.20.3` and `meta ^1.19.0`; these two names remain in the
migration set but stay at the newest versions Flutter 3.44.6 can resolve.

Stable `file_picker` 11.0.3 is also incompatible with the rest of the requested ecosystem. It requires `win32
^5.9.0`, while `share_plus` 13.1+, `package_info_plus` 10.1+, and `health` 13.3.2 through `device_info_plus` require
`win32 ^6.0.1`. The bot's grouped 12.0.0-beta.1 proposal crossed that boundary but violates the no-prerelease
decision. Stable `file_picker` 12.2.0 now exists, requires `win32` 6, and resolves the whole requested graph. Its
[12.x changelog](https://pub.dev/packages/file_picker/changelog) documents the stable federated rewrite and the
Flutter 3.38 / Dart 3.10 / iOS 14 floors.

The newest solver-compatible `flutter_secure_storage` is 11.0.0, but it is not operationally compatible with the
data already written by this app. `SecureAppStorageProvider` explicitly selects `AES_CBC_PKCS7Padding` and stores
the key that decrypts every Hive box. Version 11 removes that cipher and `sharedPreferencesName`, and warns that
data using removed algorithms is inaccessible unless it was migrated while running v10. This dependency migration
must therefore stop at 10.3.1 and defer v11 until a separately shipped v10 bridge has reached users. See the
[`flutter_secure_storage` 11.0.0 changelog](https://github.com/juliansteenbakker/flutter_secure_storage/blob/flutter_secure_storage-v11.0.0/flutter_secure_storage/CHANGELOG.md)
and the [v10 migration options](https://pub.dev/packages/flutter_secure_storage/versions/10.3.1#android).

## Resolver-required lockfile movement

After changing 15 direct declarations (14 resolved-version moves plus normalization of the `meta` constraint;
`intl` is unchanged), `fvm flutter pub get` succeeds and reports 63 changed package entries: 14 direct lockfile
entries and 49 transitives. This movement is solver-required; do not add unrelated direct upgrades from
`flutter pub outdated`.

The important transitive edges are:

- `file_picker` becomes federated, adding `android_file_picker` 1.1.0, `file_picker_darwin` 1.1.0,
  `file_picker_linux` 1.1.0, `file_picker_web` 3.1.0, `windows_file_picker` 1.2.0, and
  `file_picker_platform_interface` 3.3.0. The shared graph moves to `win32` 6.4.0 and `ffi` 2.2.0.
- `health` moves `device_info_plus` to 13.2.0 and `carp_serializable` to 3.0.0.
- `supabase_flutter` adds `supabase_common` 0.1.2 and moves `supabase` to 2.16.1, `gotrue` to 2.27.2,
  `postgrest` to 2.9.1, `realtime_client` to 2.13.0, `storage_client` to 2.8.0, and `functions_client` to 2.7.1.
  It also removes the no-longer-used `jwt_decode` and `retry` packages.
- `flutter_local_notifications` moves its platform interface to 12.2.0, Linux implementation to 8.0.1,
  Windows implementation to 3.1.1, and adds the web implementation at 1.0.0.
- `dynamic_color` adds `material_ui` 1.1.1 and `cupertino_ui` 1.0.2 and moves
  `material_color_utilities` to 0.13.0.
- `flutter_svg` moves `vector_graphics` to 1.2.3 and `vector_graphics_compiler` to 1.3.0.

Commit the solver-produced `pubspec.lock` as a unit with these direct constraints. The direct declarations remain
the scope boundary; these transitive entries are not new independently selected dependencies.

## Required source and platform adaptations

### File import and export

`file_picker` 12 is source-breaking. `FilePickerResult` is removed, `pickFiles()` returns
`Future<List<PlatformFile>>`, cancellation is an empty list, and single-selection flows should call `pickFile()`.
`saveFile()` now returns `Uri?`, whose scheme may be `file`, `content`, `http`, `data`, or `blob`. The upstream
[`pickFiles` API](https://pub.dev/documentation/file_picker/12.2.0/file_picker/FilePicker/pickFiles.html) and
[`saveFile` API](https://pub.dev/documentation/file_picker/12.2.0/file_picker/FilePicker/saveFile.html) define the
new contracts.

Migrate every settings import use case from `result.files.single` to the nullable single-file result, and treat a
null result as cancellation. Migrate the three save flows to test only for a non-null `Uri`. Change
`ExportWriteVerifier` to accept a `Uri`: use `File.fromUri` only for `file:` URIs, retain the best-effort skip for
`content:` URIs, and do not pretend other URI schemes are filesystem paths. Targeted analysis of the unchanged
call sites under 12.2.0 produced 16 errors plus six nullability warnings, all explained by these two return-type
changes.

Version 11.0.2 already fixed Android external-provider path traversal, and 12.2.0 retains the fix; see the
[upstream changelog](https://pub.dev/packages/file_picker/changelog) and
[GHSA-r2rg-pm28-j8gw](https://github.com/advisories/GHSA-r2rg-pm28-j8gw).

### Secure storage

Keep `flutter_secure_storage` at 10.3.1. The current AES-CBC and `sharedPreferencesName` options remain supported,
so no secure-storage source edit is required merely to take this patch release. The agreed persistence smoke test
must nevertheless install over an existing build with real data; a clean-install test does not prove that the Hive
encryption key remains readable.

Before any later v11 upgrade, a release running v10 must move the Android Hive-key value from the explicitly
selected AES-CBC storage cipher to the default AES-GCM cipher. If the source-migration decision deliberately makes
this combined PR that bridge, keep `sharedPreferencesName: "SharedPrefs"` so lookup stays on the existing preference
file; do not mechanically replace it with `storageNamespace`, because that also changes key/config isolation. Keep
`resetOnError: false`, enable `migrateOnAlgorithmChange`, and enable `migrateWithBackup` for crash-resistant
migration. Add an upgrade test that writes the Hive encryption key with the old CBC options, reopens it through the
new v10 options, and proves the same key still decrypts existing Hive data. The v10 documentation describes the
algorithm migration and backup markers; v11's changelog is the evidence that completing such a bridge before
removing the old APIs is mandatory.

### Notifications and timezone

`flutter_local_notifications` 21 raised its floors to Flutter 3.38.1, Dart 3.10, Android API 24, iOS 13, and Android
`compileSdk` 36. The app already uses Android min/target/compile 26/36/36, Java 17, core-library desugaring 2.1.4,
iOS 15.5, the scheduled-notification receivers and permissions, and an iOS notification-center delegate. No
source or platform edit is required for the app's current APIs. The
[notifications changelog](https://github.com/MaikuB/flutter_local_notifications/blob/master/flutter_local_notifications/CHANGELOG.md)
and [Android setup guide](https://github.com/MaikuB/flutter_local_notifications/blob/master/flutter_local_notifications/README.md#android-setup)
state the upstream requirements.

`timezone` 0.11 changes `Location.offset` from `int` to `Duration`, and 0.11.1 changes the default location name
from `UTC` to `Etc/UTC`. OpenNutriTracker does not read `Location.offset` and explicitly initializes and selects the
device timezone, so no source edit is required; keep the DST/timezone regression tests. See the
[`timezone` changelog](https://pub.dev/packages/timezone/changelog).

### Health, sharing, package metadata, and the remaining packages

`health` 13.3.2 requires iOS 15 and raises Android compile SDK to 36 through the 13.2 line; both are already met.
It changes the native iOS plugin class, but apps using Flutter's generated registrant are explicitly unaffected.
Its [changelog](https://pub.dev/packages/health/changelog) also records the iOS 15 crash fix and the move to the
Health Connect 1.2.0 alpha client, so device-level HealthKit and Health Connect import tests remain required.

`share_plus` 13 and `package_info_plus` 10 require Flutter 3.41.6 / Dart 3.11 and iOS 13 because of their `win32` 6
transition. The app's current `SharePlus.instance.share(ShareParams(...))` and `PackageInfo.fromPlatform()` calls
remain valid; no source migration was found. Their primary changelogs are
[`share_plus`](https://pub.dev/packages/share_plus/changelog) and
[`package_info_plus`](https://pub.dev/packages/package_info_plus/changelog).

The selected `path_provider`, `dynamic_color`, `mobile_scanner`, `table_calendar`, `flutter_svg`, and
`supabase_flutter` releases require no application API migration found by source audit. Their important changes
are platform/dependency refreshes already represented in the lockfile. Preserve the agreed focused smoke checks
for barcode/QR scanning and Supabase-backed food search rather than inferring behavior from compilation alone.

### GitHub Actions

Replace all six `actions/setup-java@v5.6.0` uses with `actions/setup-java@v6.0.0`. The existing `zulu` and `temurin`
distributions and `java-version: '17'` inputs remain supported. Version 6 runs on Node 24, so self-hosted runners
would need runner 2.327.1 or newer; these workflows use GitHub-hosted `ubuntu-latest`, so no runner migration is
needed. Version 6 also removes legacy AdoptOpenJDK distribution aliases and changes GPG-related inputs, none of
which this repository uses. See the
[`setup-java` v6 release](https://github.com/actions/setup-java/releases/tag/v6.0.0) and
[`setup-java` v6 inputs](https://github.com/actions/setup-java/blob/v6.0.0/action.yml).

No selected package requires raising or lowering OpenNutriTracker's Android API 26 or iOS 15.5 support floors.

## Verification evidence and implementation gate

The following checks were run against the selected graph before reverting the experimental manifest and lockfile
changes from this research branch:

- `fvm flutter pub get`: passed; 63 package entries changed and no prerelease package was selected.
- `fvm flutter pub outdated --no-transitive`: every named package was current except the deliberate holds at
  `flutter_secure_storage` 10.3.1, `intl` 0.20.2, and `meta` 1.18.0.
- `fvm flutter test test/unit_test/notification_service_test.dart`: 12 tests passed.
- `fvm flutter test test/unit_test/health_package_service_test.dart test/widget_test/share_qr_dialog_test.dart`:
  15 tests passed.
- Targeted static analysis confirmed the unchanged notification, health, and sharing APIs compile. The settings
  use-case analysis failed only at the expected file-picker 12 return-type call sites described above.

This is resolver and migration research, not acceptance of the implementation. The combined migration still must
pass `just ci`, every Android/iOS GitHub build and integration check, and the agreed upgrade/device smoke tests for
secure-storage persistence, file import/export, sharing, notifications, barcode/QR scanning, and health import.
