# Privacy permission audit — what the released build actually requests

Research for [#872](https://github.com/simonoppowa/OpenNutriTracker/issues/872) on map [#867](https://github.com/simonoppowa/OpenNutriTracker/issues/867). Audited 2026-08-27 against tag `v2.0.2` (`9ab14fe3`), the released build.

**Short answer: the policy overclaims on both entries. There is no storage permission of any kind — not in the app manifest, not injected by any plugin, not requested at runtime — and export/import goes through the Storage Access Framework, which by design needs none; "Storage permission" is false in every sense and should go. "Reminders permission" is a misnaming, not a fabrication: the app's own UI calls the feature "Daily Reminder", it is delivered by `flutter_local_notifications` over `POST_NOTIFICATIONS`, and no Reminders/EventKit API is touched on either platform. The transitive permissions the merged manifest does add — `CAMERA`, `VIBRATE`, `ACCESS_NETWORK_STATE` — appear in neither policy, so the same audit that removes an overclaim also uncovers three underclaims.**

## Method

Route taken: **a real merged manifest**, produced by the Android manifest merger in this checkout.

`fvm flutter build apk --flavor full --debug` fails in this environment for an unrelated reason — `lib/core/utils/env.g.dart` is an `envied` codegen artifact that needs a `.env` the repo does not carry, so `:app:compileFlutterBuildFullDebug` dies before Gradle reaches the merge. The manifest merger does not depend on the Dart compile, so it was run directly instead:

```
./gradlew :app:processFullDebugMainManifest
./gradlew :app:processFullReleaseMainManifest
```

Both succeeded. The `full` flavor is the public artifact (`develop` is the sideload flavor; there is no `production` flavor — see `android/app/build.gradle`). **The release and debug merges produce an identical permission set**, so nothing below is a debug-only artefact. Outputs read:

- `build/app/intermediates/merged_manifest/fullRelease/processFullReleaseMainManifest/AndroidManifest.xml`
- `build/app/intermediates/merged_manifest/fullDebug/processFullDebugMainManifest/AndroidManifest.xml`
- `build/app/outputs/logs/manifest-merger-full-debug-report.txt` (per-permission attribution)

Plugin manifests in `~/.pub-cache` and the `:app:dependencies` tree were used only to corroborate attribution, not as a substitute.

## Android — the merged permission set at `v2.0.2`

Eight `uses-permission` entries survive the merge (six real, one signature-level plumbing counted twice under a placeholder and a resolved application id).

| Permission | Source | What needs it |
| --- | --- | --- |
| `android.permission.INTERNET` | app manifest, line 4 (also merged from `io.sentry:sentry-android-core:8.39.1` and `transport-backend-cct:2.3.3`) | food search, barcode lookup, Supabase/FDC, Sentry upload |
| `android.permission.RECEIVE_BOOT_COMPLETED` | app manifest, line 6 | re-arming the scheduled daily reminder after a reboot (`ScheduledNotificationBootReceiver`) |
| `android.permission.POST_NOTIFICATIONS` | app manifest, line 7 (also merged from `flutter_local_notifications`) | the daily reminder and the fasting-timer notification |
| `android.permission.VIBRATE` | **injected** by `flutter_local_notifications` 19.5.0 (`android/src/main/AndroidManifest.xml:3`) | notification vibration; never requested by app code |
| `android.permission.CAMERA` | **injected** by `mobile_scanner` 7.2.0 (`android/src/main/AndroidManifest.xml:3`) | barcode scanning; also gates `image_picker`'s `ImageSource.camera` path for meal/recipe/profile photos |
| `android.permission.ACCESS_NETWORK_STATE` | **injected** transitively: `mobile_scanner` → `com.google.mlkit:barcode-scanning:17.3.0` → `play-services-mlkit-barcode-scanning:18.3.1` → `transport-backend-cct:2.3.3` | nothing the app calls; ML Kit's telemetry transport declares it |
| `<applicationId>.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` | **injected** by `androidx.core:core:1.18.0` | signature-level internal guard; not user-visible, not a privacy-relevant capability |

Also merged, for completeness: `uses-feature android.hardware.camera` with `android:required="false"` (from `mobile_scanner`) — a Play-filtering hint, not a permission.

**Not present anywhere in the merged manifest:** `READ_EXTERNAL_STORAGE`, `WRITE_EXTERNAL_STORAGE`, `MANAGE_EXTERNAL_STORAGE`, `READ_MEDIA_IMAGES`, `READ_MEDIA_VISUAL_USER_SELECTED`, `SCHEDULE_EXACT_ALARM`, `USE_EXACT_ALARM`, `READ_CALENDAR`/`WRITE_CALENDAR`. Grepping the merger report for `STORAGE`, `READ_MEDIA`, `ALARM`, `maxSdkVersion`, `REMINDER` and `CALENDAR` returns no permission hits — the only `STORAGE` matches are the plugin *name* `flutter_secure_storage`, and the only `ALARM` match is a datatransport `AlarmManagerSchedulerBroadcastReceiver` class name. There is no `maxSdkVersion`-gated legacy storage permission hiding in the merge either.

`permission_handler` is not a dependency, and `grep -rn "permission_handler\|Permission\."` over `lib/` returns nothing. The only runtime permission request in the app is `NotificationService.requestPermission()` (`lib/core/utils/notification_service.dart:48`).

## iOS — usage-description keys at `v2.0.2`

`ios/Runner/Info.plist` declares exactly two, and a `grep` for `NS[A-Za-z]*UsageDescription` across `ios/` and `macos/` finds no others:

| Key | Line | Declared purpose | Which plugin requires it |
| --- | --- | --- | --- |
| `NSCameraUsageDescription` | `ios/Runner/Info.plist:62` | "scan barcodes and to attach a photo to a custom meal…" | `mobile_scanner`, `image_picker_ios` (camera source) |
| `NSPhotoLibraryUsageDescription` | `ios/Runner/Info.plist:64` | "attach a photo to a custom meal… and for exporting data" | `image_picker_ios` (gallery source) |

**`NSRemindersUsageDescription` is absent, and nothing asks for it.** Grepping the iOS sources of `flutter_local_notifications` 19.5.0, `image_picker_ios`, `mobile_scanner`, `share_plus` and `file_picker` for `EKEventStore`, `EKReminder`, `EventKit` and `RemindersUsage` returns nothing. No plugin in the tree links EventKit, so no plugin can demand the key. This is expected: iOS local notifications go through `UNUserNotificationCenter`, whose authorization is a runtime prompt with no Info.plist usage-description key at all — `notification_service.dart:60` calls `ios.requestPermissions(alert: true, badge: true, sound: true)`.

`ios/Runner/PrivacyInfo.xcprivacy` is consistent with this: it declares only `UserDefaults`, `FileTimestamp` and `DiskSpace` API categories and crash/performance data types. It says nothing about storage or reminders access, and nothing there contradicts the merged manifest.

## Adjudicating the two suspect entries

### "Storage permission"

False in three independent ways.

1. **No storage permission is declared.** Not by the app, not by any plugin, in either build variant. See the merged-manifest section above.
2. **The export/import path uses the Storage Access Framework, which needs no permission.** Export builds a zip in memory and hands the bytes to a document picker: `lib/features/settings/domain/usecase/export_data_usecase.dart:189` calls `FilePicker.saveFile(fileName: …, type: FileType.custom, allowedExtensions: ['zip'], bytes: …)`, which on Android is `ACTION_CREATE_DOCUMENT`. Import is the mirror image — `FilePicker.pickFiles(...)` at `import_data_usecase.dart:53` and `:193`, i.e. `ACTION_OPEN_DOCUMENT`. `file_picker` 11.0.2's own manifest (`~/.pub-cache/hosted/pub.dev/file_picker-11.0.2/android/src/main/AndroidManifest.xml`) declares **no** `uses-permission` — only a `<queries>` block for `GET_CONTENT` intent visibility. The user picks the destination in the system document UI; the app never gets, and never needs, broad filesystem access.
3. **Nothing else in the app takes storage either.** Photos come from `image_picker` (`ImageSource.gallery` / `ImageSource.camera` at `edit_meal_screen.dart:359-360`, `recipe_builder_screen.dart:167,171`, `profile_editor_screen.dart:76-77`), which on modern Android uses the Photo Picker and declares no storage permission of its own (`image_picker_android` contributes only an `ImagePickerFileProvider`). App data lives in `path_provider`'s app-private directories, which need no permission. `share_plus` is used only for the QR-code share sheet (`share_qr_dialog.dart:121`) and adds no permission.

Note the iOS text is a *little* better founded than the Android side: `NSPhotoLibraryUsageDescription`'s own wording says "and for exporting data", so on iOS there is at least a photo-library key in play. But a photo-library key is not a storage permission, and it is declared for the picker, not for the export.

### "Reminders permission"

A misnaming of the local-notification permission, not a false claim about the iOS Reminders app. Three pieces of evidence:

1. **The app calls the feature "Reminder" in its own UI.** `lib/l10n/intl_en.arb:997` — `"settingsNotificationsLabel": "Daily Reminder"`; `:998` — `"settingsNotificationsTimeLabel": "Reminder time: {time}"`; `:548` — `"notificationsDailyReminderChannelName": "Daily Reminders"`. A policy author reading the settings screen would naturally write "Reminders permission".
2. **The mechanism is notifications.** `flutter_local_notifications` 19.5.0, wrapped by `lib/core/utils/notification_service.dart`, with `POST_NOTIFICATIONS` declared in the app manifest under a `#312: Notification reminders` comment. Callers: onboarding (`onboarding_screen.dart:456`), settings (`settings_screen.dart:501`) and the fasting timer (`fasting_screen.dart:424`).
3. **No Reminders API is touched.** No `NSRemindersUsageDescription`, no EventKit in any plugin, no calendar permission in the merged manifest.

So the *capability* the entry gestures at is real and is genuinely user-consented; only the name is wrong. It is worth being precise about what the capability is, though: `POST_NOTIFICATIONS` lets the app *show* the user something. It is not a collection of personal data from the user, which is the list the entry currently sits in. The naming defect and the categorisation defect are separate problems.

## Does the answer differ on the feature branch?

**No.** `git diff --stat v2.0.2 6cc0efe8 -- android ios pubspec.yaml pubspec.lock` is empty: the AI-assisted-meal-logging work on `feat/own-server-settings` changes no native manifest, adds no plugin, and locks no new dependency. The camera/photo path the AI feature uses is the one that already exists at `v2.0.2` for barcode scanning and custom-meal photos, so it reuses `mobile_scanner`'s `CAMERA` and `image_picker`'s pickers rather than adding anything. The permission set above holds for both `v2.0.2` and the current feature-branch HEAD.

That is a finding in its own right for the map: the AI feature changes *where data goes*, not *what the OS lets the app take*. Nothing in this audit needs revisiting when it ships.

## What this means for the policy

**"Storage permission" — remove.** The evidence settles it. There is no declared storage permission in the merged manifest at either variant, no plugin injects one, `permission_handler` is not in the tree, and the export/import path deliberately uses SAF document pickers precisely so that none is needed. There is no reading under which the app holds a storage permission. Leaving the entry in tells users the app can read their files, which it cannot.

If the underlying intent was "the app writes an export file to a location you choose", that is a true statement about a user-initiated action and belongs in a purpose or user-rights clause (data portability), not in a list of personal data collected — and it should not be phrased as a permission.

**"Reminders permission" — rename, do not remove.** The capability is real; the label is wrong. The honest description is the notification permission (`POST_NOTIFICATIONS` on Android 13+, `UNUserNotificationCenter` authorization on iOS), used for the daily meal-logging reminder and the fasting timer. Deleting the entry outright would swing from overclaiming to underclaiming a permission the app does prompt for at onboarding.

One thing this audit does **not** settle: whether a notification permission belongs in the "personal data collected" list at all, versus a separate disclosure. `POST_NOTIFICATIONS` is an outbound capability — the app shows the user a message — and no personal data flows to the controller through it. Whether iubenda can express it as anything other than a collected-data category is a question for the expressiveness research, and whether Art.13 owes a disclosure for it at all is for the rendering pass. This ticket's finding is narrower and firm: **whatever the entry becomes, it must not be called "Reminders", because that names an OS API the app does not use.**

**Three underclaims found in passing.** `CAMERA`, `VIBRATE` and `ACCESS_NETWORK_STATE` are all in the released build's merged manifest and appear in neither policy. `CAMERA` is the significant one — it is a user-prompted, privacy-relevant permission backing barcode scanning and photo capture, and both iOS usage-description strings describe it, so the policy is silent about a capability the App Store listing already discloses. `VIBRATE` and `ACCESS_NETWORK_STATE` are normal-protection-level and arguably below the threshold of an Art.13 disclosure, but the rendering pass should decide that deliberately rather than by omission. Whether these belong in the policy is out of scope here; that they are missing is recorded as a finding.
