# 2.5.0 run: which maintainer hand-offs adb can remove (Android 17, Pixel 6)

Research for [#1429](https://github.com/simonoppowa/OpenNutriTracker/issues/1429) on map [#1425](https://github.com/simonoppowa/OpenNutriTracker/issues/1425). Code read at `develop` `c293acff` (the frozen candidate). No device was attached: every command below comes from source and docs and has not been run on the phone. Each one says how to check that it worked, and the run's prep step should run those checks first.

**Answer.** Five of the seven hand-offs go away entirely over adb: Health Connect grants, notifications, the barcode lookup, the file picker and shared meal codes. Two need one preparation step before the run. The phone's screen lock has to be set to *None* by the maintainer, and the AI key has to sit in a file on the laptop. Two things can't be covered without a person or a second app, so they're skipped unless prepared: real workout data in Health Connect, which needs Google's Health Connect Toolbox installed and a session written before the run, and anything that needs the camera to see something (the preview, decoding a printed barcode or QR, the AI photo).

Constants used below:

```bash
ADB=~/Android/Sdk/platform-tools/adb
S=18101FDF60010M                                   # USB serial, never "first device"
PKG=com.opennutritracker.ont.opennutritracker      # the `full` flavour
```

## The table

| # | Hand-off | Mechanism | Verdict | Exact commands | Limits |
|---|---|---|---|---|---|
| 1a | Health Connect permission grant | Both health permissions are plain runtime (`dangerous`) permissions, so `pm grant` works. On API 34+ the plugin's request contract asks `RequestMultiplePermissions.getSynchronousResult` first, and that returns without any UI when everything is already granted. Turning Health sync on then never opens Health Connect. | **Removable** | `$ADB -s $S shell pm grant $PKG android.permission.health.READ_EXERCISE`<br>`$ADB -s $S shell pm grant $PKG android.permission.health.READ_TOTAL_CALORIES_BURNED`<br>check: `$ADB -s $S shell dumpsys package $PKG \| grep -E 'health\.READ_(EXERCISE\|TOTAL_CALORIES_BURNED).*granted=true'` | Only these two are declared, and `pm grant` refuses anything undeclared. Health Connect revokes health grants from an app that loses its `VIEW_PERMISSION_USAGE`/`HEALTH_PERMISSIONS` alias, which the manifest has. A fresh install or `pm clear` drops the grants, so grant again before first launch. A grant from the shell counts as the "first grant" for the 30-day history window. |
| 1b | Workout data for the import to read | Health Connect has no shell interface: AOSP HealthFitness has no shell command, and neither does ClipboardService. The app only reads, and it has no debug hook that writes. Google's documented test tool is the **Health Connect Toolbox**, a second app. | **Prepare once**, or **skip** the data part | Before the run, at setup: `$ADB -s $S install HealthConnectToolbox-<ver>.apk`, then `pm grant <toolbox-pkg> android.permission.health.WRITE_EXERCISE` and `…WRITE_TOTAL_CALORIES_BURNED`, then *Insert Health Record* → one exercise session plus one total-calories record covering it, dated within the last few days. | The Toolbox is a sideloaded APK, so the maintainer approves installing it. Entries must start inside the app's 30-day backfill and inside Health Connect's 30-day window before the first grant. Without the Toolbox the run can only cover the screen, the grant state and the "nothing new" import. The rationale screen can be opened without Health Connect: `$ADB -s $S shell am start -n $PKG/.MainActivity -a androidx.health.ACTION_SHOW_PERMISSIONS_RATIONALE` |
| 2 | Notifications and reminders | `POST_NOTIFICATIONS` is a runtime permission, so `pm grant` works. The app schedules **inexact** alarms (`AndroidScheduleMode.inexactAllowWhileIdle` → `setAndAllowWhileIdle`) and declares no exact-alarm permission, so there's nothing to set with `appops`. | **Removable** | `$ADB -s $S shell pm grant $PKG android.permission.POST_NOTIFICATIONS`<br>scheduled: `$ADB -s $S shell dumpsys alarm \| grep -A6 $PKG` (look for `origWhen`)<br>delivered: `$ADB -s $S shell dumpsys notification --noredact \| grep -A40 "pkg=$PKG" \| grep -E 'android.title\|android.text\|postTime'` | Delivery can't be forced: the receiver is `exported=false`, so the shell can't broadcast to it, and changing the clock is not recommended. AOSP lets an inexact alarm slip by at most 75 % of the lead time, capped at 1 h. A reminder set **2 min ahead fires within ~3.5 min** with the screen on and the phone charging. `pm revoke` kills the app process, so only use it between steps. |
| 3 | Barcode in front of the camera | *Code manuell eingeben* (`scanner-manual-entry-open` → `-field` → `-submit`) and a valid barcode typed into the add-meal search both send the **same** `ScannerLoadProductEvent` as a camera detection, so the same lookup runs. There's no intent or deep link for a barcode. | **Removable** for the lookup; **skip** the camera itself | `$ADB -s $S shell pm grant $PKG android.permission.CAMERA` (so the scanner screen opens without a dialog), then `st.sh tap id=scanner-manual-entry-open`, `st.sh type 4008400402222` (any code with a valid check digit), `st.sh tap id=scanner-manual-entry-submit` | Manual entry checks the check digit; the camera path doesn't. The camera preview, decoding a real code, and the camera-only routing of a scanned shared QR to the import screens are not covered. The live preview films the room, so take no screenshot while it's open. |
| 4 | System file picker (`com.google.android.documentsui`) | Export uses `ACTION_CREATE_DOCUMENT` and every import uses `ACTION_OPEN_DOCUMENT` (`android_file_picker` 2.1.0). DocumentsUI is an ordinary app that uiautomator can read. The save screen's filename field is `android:id/title` and Save is `android:id/button1` (AOSP `fragment_save.xml`, both layout variants). | **Removable**, if the guard allows DocumentsUI for those steps | push a fixture: `$ADB -s $S push fixture.zip /sdcard/Download/`<br>export: tap *Exportieren* → in DocumentsUI set `resource-id=android:id/title` → tap `resource-id=android:id/button1`<br>pull: `$ADB -s $S shell ls -t /sdcard/Download \| head -3`, then `$ADB -s $S pull /sdcard/Download/<file>` | The focus guard aborts as soon as focus leaves `$PKG`, so these steps need an explicit allowlist for `com.google.android.documentsui` only. Without it the hand-off is unavoidable. The UI is German ("Speichern", "Downloads"), so select by resource-id. If a pushed file doesn't show under *Downloads*, browse the device root → *Download*, which lists files directly. |
| 5 | Shared meal code import (#1329) | No intent filter and no deep link: `am start` **can't** deliver a code. Codes come in only through the camera QR or the paste dialog. The section menu has *Code einfügen* (`intake-import-meal-code`), which opens the dialog (`import-meal-code-input`, `import-meal-code-parse`, then `import-meal-preview-import`) without the camera. A code is `base64Url(gzip(json))`: ASCII only, no spaces. | **Removable** | either type a fixture code: `st.sh tap id=import-meal-code-input` + `st.sh type "$CODE"`<br>or round-trip in the app: section ⋮ → *Mahlzeit teilen* → *Code kopieren* → ⋮ → *Code einfügen* → long-press the field → *Einfügen* | Never tap *Code teilen*: it opens the Android share sheet and focus leaves the app. The camera QR path is not covered (see 3). The section ⋮ only offers *share* when the meal has kcal > 0. |
| 6 | The AI key | The key field (`ai-assist-key-field`) is `obscureText`. Flutter's semantics value is then `•` × length, so a uiautomator dump shows bullets. Type the key from **stdin**, so it never appears in a host argv, the host history, `st.sh`'s `run.log` or a dump. There's no shell clipboard on AOSP to use instead. | **Prepare once** (key file) + **removable** (typing) | at setup: `$ADB -s $S shell settings put system show_password 0` (stops Flutter showing each typed character briefly)<br>in the run: `st.sh tap id=ai-assist-provider-<p>`, `st.sh tap id=ai-assist-key-field`, then **without** `st.sh type`:<br>`$ADB -s $S shell 'read -r k; input text "$k"' < ~/.config/ont-run/ai-key`<br>then `st.sh tap id=ai-assist-save-key`. Take no screenshot between the field tap and Save. | The key is briefly in the device's `input` argv, which `hidepid` limits to shell and root. The bullet count shows its length. Safe for keys made of `[A-Za-z0-9_-]` (all three hosted providers). Providers: Anthropic (`claude-haiku-4-5` only), OpenRouter (Sonnet 5 default, Haiku 4.5, `gpt-5.6-luna`, `gpt-5.6-terra`), OpenAI (luna, terra), own server. Cheapest by the app's own label: **OpenRouter + `openai/gpt-5.6-luna`**. Cost is cents per run whichever you pick, so choose by coverage. |
| 7 | Phone usable unattended | `svc power stayon usb`, animation scales to 0, `adb` auth timeout off, wake before each step. The a11y tree can't be kept "warm": only one UiAutomation client may connect at a time, so a background `uiautomator events` would break `dump`. | **Removable**, except the screen lock (**prepare once**) | `$ADB -s $S shell svc power stayon usb`<br>`$ADB -s $S shell settings put global window_animation_scale 0` (and `transition_animation_scale`, `animator_duration_scale`)<br>`$ADB -s $S shell settings put global adb_allowed_connection_time 0`<br>before each step: `$ADB -s $S shell input keyevent KEYCODE_WAKEUP`<br>lock check: `$ADB -s $S shell locksettings get-disabled` | A PIN, pattern or password lock can't be removed from the shell without typing the credential, so the maintainer sets *None* at setup. `locksettings set-disabled true` only switches between Swipe and None. `transition_animation_scale 0` turns on Flutter's *disable animations* mode, so note that in the results. After a USB drop: `$ADB -s $S wait-for-device`, then re-run the idempotent prep (stay-on, wake, guard). Never fall back to the adb-tls serial. |

## Details per hand-off

### 1. Health Connect

**What the app requests.** The merged manifest declares exactly two health permissions, `android.permission.health.READ_EXERCISE` and `…READ_TOTAL_CALORIES_BURNED`. The manifest comment records why READ_STEPS, READ_DISTANCE and READ_BODY_FAT went. `HealthPackageService.requestPermissions` asks for `WORKOUT` and `TOTAL_CALORIES_BURNED` with READ access, and the `health` 13.3.2 plugin maps those to the same two strings (`preparePermissionsListInternal`). Sessions are then read by `HealthConnectWorkoutReader.kt` straight through `HealthConnectClient.readRecords(ExerciseSessionRecord)`, in the foreground, so `READ_HEALTH_DATA_IN_BACKGROUND` isn't involved.

**Why `pm grant` is enough.**
- Both constants are documented as *Protection level: dangerous* (`HealthPermissions.java`, API 34).
- `PermissionManagerServiceImpl.grantRuntimePermissionInternal` has no health-specific branch. It accepts any requested runtime permission from a caller holding `GRANT_RUNTIME_PERMISSIONS`, which the shell has. A third-party Health Connect project scripts its grants exactly this way.
- On API ≥ 34, `HealthPermissionsRequestContract` uses `HealthPermissionsRequestModuleContract` (checked by disassembling the cached `connect-client` 1.2.0-alpha02). Its `getSynchronousResult` hands off to `ActivityResultContracts.RequestMultiplePermissions.getSynchronousResult`, which returns straight away when all permissions are held. So after the grant, toggling *Health sync* in the app runs its in-app disclosure, never opens Health Connect, and comes back granted.
- The grant survives `adb install -r` (the upgrade path) but not uninstall or `pm clear`. Health Connect would revoke everything if the app stopped handling `VIEW_PERMISSION_USAGE` with category `HEALTH_PERMISSIONS` (`PermissionPackageChangesOrchestrator`), and the `ViewPermissionUsageActivity` alias covers that.

To exercise the "permission revoked" error path (`permission_denied` from the method channel): `pm revoke $PKG android.permission.health.READ_EXERCISE`. This kills the process, so relaunch afterwards.

**Putting data in.** Nothing on the device writes Health Connect records from a shell. The AOSP HealthFitness service has no shell command, the app is read-only by design (manifest comment, Play policy), and its debug build adds no hook. The only documented test path is the [Health Connect Toolbox](https://developer.android.com/health-and-fitness/health-connect/test/health-connect-toolbox), which "supports reading and writing all Health Connect data types" through its *Insert Health Record* UI. Since the run itself must not leave the package, write the data **before** the run:

1. The maintainer approves installing the Toolbox (`adb install HealthConnectToolbox-<ver>.apk`, from the zip at goo.gle/health-connect-toolbox) as part of the setup ticket.
2. Grant the Toolbox its writes with `pm grant` (find its package with `pm list packages | grep -i toolbox`).
3. Insert one *Exercise session*, for example a run yesterday from 18:00 to 18:30, and one *Total calories burned* record for the same interval. The app attributes kcal from the calorie records, because Health Connect sessions carry no energy of their own.
4. Before the run: `dumpsys package $PKG` shows both reads `granted=true`.

Either a person or the session can do step 3. If the session drives the Toolbox over uiautomator, that is a separate prep script with its own guard allowlist (the Toolbox package), run and finished before the release run starts.

Without the Toolbox, Health Connect is covered at "screen + grant + empty import" depth, and the results must say *skipped: no workout data source*.

### 2. Notifications

- `NotificationService` calls `zonedSchedule(..., androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle)` for both the daily reminder and the fasting ping. `flutter_local_notifications` 22.3.1 turns that into `AlarmManagerCompat.setAndAllowWhileIdle(RTC_WAKEUP, …)`. The manifest declares neither `SCHEDULE_EXACT_ALARM` nor `USE_EXACT_ALARM`, so `appops set … SCHEDULE_EXACT_ALARM` is meaningless here.
- AOSP `AlarmManagerService.maxTriggerTime`: the delivery window for a one-shot inexact alarm is `0.75 × (trigger − now)`, capped at one hour. Set the reminder time **2 minutes ahead** in Settings; it must be posted within 3.5 minutes. Read `dumpsys alarm` once right after saving (the alarm exists, `origWhen` = the chosen time), then poll `dumpsys notification --noredact` for `pkg=$PKG` every 15 s up to 5 min. `st.sh` already has `alarms` and `notif` for this.
- Changing the clock (`cmd alarm set-time`) would also shift the app's "logical day", Health Connect windows and tracked days. Don't.
- Pre-grant `POST_NOTIFICATIONS` **before the first launch** of a fresh install. Onboarding's reminder step (#1391) then gets `true` from `requestNotificationsPermission()` with no system dialog. The dialog belongs to `com.google.android.permissioncontroller`, so it would trip the focus guard.
- `adb install -g` grants every declared runtime permission at install, including CAMERA and both health reads. It's convenient for a fresh-install pass, but it leaves the state different from what a user has. Prefer the explicit `pm grant` lines.

### 3. Barcodes

- `ScannerScreen._showManualEntryDialog` → `isValidBarcodeCheckDigit` → `_scannerBloc.add(ScannerLoadProductEvent(barcode))`. That is the same bloc event as the camera's `onDetect` for `BarcodeType.product`, so it runs the same `SearchProductByBarcodeUseCase`, product screen and Add flow.
- A second keyboard path: typing a valid barcode into the add-meal search and submitting pushes the scanner route with `initialBarcode`, which fires the same event (`add_meal_screen.dart` `_onSearchSubmit`).
- Opening the scanner screen starts `MobileScanner`, which needs `android.permission.CAMERA` (declared by `mobile_scanner` 7.4.2). Grant it so no system dialog appears.
- **Not covered:** the preview, decoding a real barcode, the torch and camera switch, and shared-QR routing from the product scanner (`classifySharedPayload` runs only in `onDetect`). The AI **photo** path (`bulk-add-photo-camera`) calls `ImagePicker().pickImage(source: ImageSource.camera)`, which opens the system camera app and leaves the package. Skip it. The AI **text** path (`bulk-add-input` → `bulk-add-parse`) goes through the same `MealItemsApi.requestItems` and covers the provider transport.

### 4. Export and import through DocumentsUI

- `ExportDataUsecase` → `FilePicker.saveFile(type: custom, allowedExtensions: ['zip'])` → `ACTION_CREATE_DOCUMENT` with `EXTRA_TITLE` (the suggested filename). Every import (`ImportDataUsecase` with `FileType.any`, plus the CSV and JSON meal and recipe imports) → `FilePicker.pickFile` → `ACTION_OPEN_DOCUMENT` + `CATEGORY_OPENABLE`.
- In DocumentsUI's save screen the filename `EditText` is `@android:id/title` and Save is `@android:id/button1`, in both layout variants (material3 flag on and off). To pick a file, tap the row whose title is the filename. Select by `resource-id`/filename, never by German label text.
- Fixtures: `adb push` to `/sdcard/Download/`. Writes through the shell go through FUSE, so MediaProvider normally indexes them and they appear under *Downloads*. If one doesn't, the device's own storage root (ExternalStorageProvider) lists `Download/` straight from the filesystem.
- After an export: `adb shell ls -t /sdcard/Download | head -3`, then `adb pull`, check the zip with `unzip -l`. Delete nothing on the phone unless the step says so.
- **The guard change this needs.** While a picker step runs, `mCurrentFocus` is `com.google.android.documentsui/…PickActivity`, which today means exit 99. Add a scoped allowlist: `ST_ALLOW_PKG=com.google.android.documentsui` honoured only by the picker actions, cleared the moment focus returns to `$PKG`. Any other foreign package still aborts.

### 5. Shared meal codes (#1329)

- `AndroidManifest.xml` has only the launcher and Health rationale intent filters. Nothing handles `VIEW`, `SEND` or a URL scheme for codes, so `am start -d …` / `-a SEND --es android.intent.extra.TEXT …` reaches nothing.
- In-app entry points: the meal section's ⋮ menu → *Geteilte Mahlzeit importieren* opens the QR camera screen, which has a keyboard icon for the same paste dialog; ⋮ → *Code einfügen* (`intake-import-meal-code`) opens the paste dialog directly. Use the second.
- `SharedMealPayload.toJsonString()` is `base64Url.encode(gzip(utf8(json)))`. `input text` can type it as it stands (no spaces, no `%`, no non-ASCII), even though the meal names inside may have umlauts.
- Making a code with no fixture: log a meal → ⋮ → *Mahlzeit teilen* → *Code kopieren*. The app writes its own clipboard while in the foreground. Then ⋮ → *Code einfügen* → long-press `import-meal-code-input` → *Einfügen*. Android 13+ may show its clipboard preview chip briefly; that's a System UI overlay, not a focus change, and a meal code isn't a secret.

### 6. The AI key

- **Where it's typed.** Settings → AI assist dialog: provider row `ai-assist-provider-anthropic` / `-openrouter` / `-openai` / `-own-server`, key field `ai-assist-key-field` (`obscureText: true, autocorrect: false, enableSuggestions: false`), *Save* `ai-assist-save-key`, *Remove key* `ai-assist-remove-key`.
- **Why the dump is safe.** `RenderEditable.describeSemanticsConfiguration` sets the semantics value to `obscuringCharacter * plainText.length` when obscured, and the Android bridge marks the node `password`. A dump shows `••••…`.
- **Why a screenshot can leak a character, and the fix.** Flutter briefly shows the last typed character when `brieflyShowPassword` is on. That follows `Settings.System.TEXT_SHOW_PASSWORD`, and `input text` produces one-character updates. `settings put system show_password 0` turns it off. Take no screenshot during typing anyway.
- **Why stdin.** `st.sh type` writes `type '<text>'` into `run.log` in the evidence dir, and the key would also land in the host's argv and history. `adb shell 'read -r k; input text "$k"' < keyfile` keeps it out of all three. On the device it exists only as the `input` process's argv for about a second, readable by shell or root alone.
- **Why not the clipboard.** AOSP `ClipboardService` has no shell command, so `cmd clipboard` doesn't exist. Setting a clip from adb needs a helper app (Clipper or similar), and Android 13+ would show a preview of the clip in System UI.
- **Logs.** No `Logger` call in `lib/` logs a key or an auth header (grep for `apiKey|Authorization` in log calls finds nothing), and `input` logs no text.
- **Provider choice.** `AiModelCatalogue`: Anthropic direct = `claude-haiku-4-5` (about $0.0017 per photo in the catalogue's measurement). OpenRouter defaults to `anthropic/claude-sonnet-5` (about $0.0033 per photo), and `openai/gpt-5.6-luna` is labelled *cheapest* (about a tenth of Sonnet's per-token price). OpenAI direct defaults to luna and makes no pricing claim. A run's worth of text parses costs cents on any of them. A dedicated key with a low spending limit, revoked after the run, matters more than which provider it is. OpenRouter covers two vendors and the *Served by* rows with one key.

### 7. Keeping the phone usable

| Need | Command | Check |
|---|---|---|
| Screen stays on while on USB | `svc power stayon usb` (AOSP `PowerCommand`: `stayon [true\|false\|usb\|ac\|wireless\|dock]`) | `settings get global stay_on_while_plugged_in` → `2` |
| No lock screen | maintainer sets *Displaysperre: Keine* before the run | `locksettings get-disabled`; `dumpsys window \| grep -E 'mDreamingLockscreen\|isKeyguardShowing'` |
| Awake before each step | `input keyevent KEYCODE_WAKEUP` (no-op when already awake) | `dumpsys power \| grep mWakefulness=Awake` |
| Stable dumps | the three `*_animation_scale` settings to `0` | `settings get global window_animation_scale` |
| No adb re-auth after days idle | `settings put global adb_allowed_connection_time 0` | — |
| USB drop | `adb -s $S wait-for-device` (time-boxed), then re-run prep | guard passes |
| Restore afterwards | `svc power stayon false`; scales back to `1`; `settings put system show_password 1` | — |

The a11y tree: Flutter builds semantics only while an accessibility client is connected, and `UiAutomationManager` allows a single UiAutomation connection ("already registered!"). A permanent background `uiautomator events` would make every `uiautomator dump` fail. Keep `st.sh`'s retry on an incomplete dump and its wait-for-selector instead.

## Prepare before the run (for the setup ticket #1430)

1. Screen lock set to **None** (the only step that has to be done by hand on the phone).
2. Phone on USB to the laptop; the adb key accepted with "always allow".
3. The AI key in a file outside the repo (for example `~/.config/ont-run/ai-key`, mode 600), one line, ideally a dedicated low-limit key.
4. *Optional, decides Health Connect depth:* approve installing the Health Connect Toolbox, and write one exercise session plus a matching total-calories record dated within the last few days.
5. The session's idempotent prep script, before the first step: stay-on, animation scales, `show_password 0`, adb timeout off, `pm grant` for `POST_NOTIFICATIONS`, `CAMERA`, `health.READ_EXERCISE`, `health.READ_TOTAL_CALORIES_BURNED`, fixtures pushed to `/sdcard/Download/`, and every check from the table above.
6. Script change: a scoped focus-guard allowlist for `com.google.android.documentsui`, used only by the picker steps, and a `type_secret` action that reads stdin and never logs.

## Skipped, with reason

- **Camera preview, real barcode and QR decoding, shared-QR routing from the scanner:** no subject in front of the lens on an unattended phone.
- **AI photo:** `ImageSource.camera` opens the system camera app, which leaves the package. The AI text path covers the provider.
- **Health Connect import with real data:** only if the Toolbox step was not prepared.
- **The share sheet (*Code teilen*, any `SharePlus` path):** the system chooser leaves the package.
- **Wall-clock-exact reminders:** the app uses inexact alarms. The run checks that a reminder is scheduled and gets delivered within the documented bound, not that it arrives on the minute.

## Sources

Android and AOSP:
- [Test your integration with the Health Connect Toolbox](https://developer.android.com/health-and-fitness/health-connect/test/health-connect-toolbox): install with `adb install`, *Insert Health Record*, all data types.
- [Health Connect test cases](https://developer.android.com/health-and-fitness/guides/health-connect/test/test-cases): the Toolbox as the way to log test data; permissions granted through the Health Connect UI in the official flow.
- [Read raw data: restrictions](https://developer.android.com/health-and-fitness/health-connect/read-data): foreground reads, the 30-day limit before the first grant.
- [`HealthPermissions.java` (android-34 sources)](https://android.googlesource.com/platform/prebuilts/fullsdk/sources/+/refs/heads/androidx-media-release/android-34/android/health/connect/HealthPermissions.java): READ_EXERCISE and READ_TOTAL_CALORIES_BURNED are `dangerous`; the `VIEW_PERMISSION_USAGE` requirement.
- [`PermissionManagerServiceImpl.java`](https://android.googlesource.com/platform/frameworks/base/+/refs/heads/main/services/core/java/com/android/server/pm/permission/PermissionManagerServiceImpl.java): the runtime-permission grant path, with no health special case.
- [HealthFitness `PermissionPackageChangesOrchestrator.java`](https://android.googlesource.com/platform/packages/modules/HealthFitness/+/refs/heads/main/service/java/com/android/server/healthconnect/permission/PermissionPackageChangesOrchestrator.java) and [`HealthConnectServiceImpl.java`](https://android.googlesource.com/platform/packages/modules/HealthFitness/+/refs/heads/main/service/java/com/android/server/healthconnect/HealthConnectServiceImpl.java): revoke on a missing usage intent; no shell command.
- [Android Debug Bridge: `pm grant` / `am start`](https://developer.android.com/tools/adb).
- [`AlarmManagerService.java`](https://android.googlesource.com/platform/frameworks/base/+/refs/heads/main/apex/jobscheduler/service/java/com/android/server/alarm/AlarmManagerService.java): `maxTriggerTime` (0.75 × futurity, one-hour cap); `set-time` shell command.
- [`ClipboardService.java`](https://android.googlesource.com/platform/frameworks/base/+/refs/heads/main/services/core/java/com/android/server/clipboard/ClipboardService.java): no shell command.
- [`UiAutomationManager.java`](https://android.googlesource.com/platform/frameworks/base/+/refs/heads/main/services/accessibility/java/com/android/server/accessibility/UiAutomationManager.java): a single UiAutomation registration.
- [`svc` `PowerCommand.java`](https://android.googlesource.com/platform/frameworks/base/+/refs/heads/main/cmds/svc/src/com/android/commands/svc/PowerCommand.java): `stayon` modes.
- [`LockSettingsShellCommand.java`](https://android.googlesource.com/platform/frameworks/base/+/refs/heads/main/services/core/java/com/android/server/locksettings/LockSettingsShellCommand.java): `set-disabled` only switches Swipe and None.
- [DocumentsUI `fragment_save.xml`](https://android.googlesource.com/platform/packages/apps/DocumentsUI/+/refs/heads/main/res/): `android:id/title`, `android:id/button1`.
- Third-party evidence that health permissions can be granted from a terminal: [cycplus-m2-sync README](https://github.com/andrewkomkov/cycplus-m2-sync).

Libraries (pub cache and Gradle cache, versions from `pubspec.lock`):
- `health` 13.3.2: `HealthPlugin.kt` `requestAuthorization`, `HealthDataOperations.kt` `preparePermissionsListInternal`.
- `androidx.health.connect:connect-client` 1.2.0-alpha02: `HealthPermissionsRequestContract`, `HealthPermissionsRequestModuleContract.getSynchronousResult` (disassembled).
- `android_file_picker` 2.1.0 `FileUtils.kt`: `ACTION_OPEN_DOCUMENT`, `ACTION_CREATE_DOCUMENT`.
- `flutter_local_notifications` 22.3.1: `setAndAllowWhileIdle` for inexact modes.
- `mobile_scanner` 7.4.2 manifest: `CAMERA`.
- Flutter 3.44.6: `rendering/editable.dart` (obscured semantics value), `widgets/editable_text.dart` and `FlutterView.java` (`TEXT_SHOW_PASSWORD`), `AccessibilityBridge.java` (`setPassword`, animation-scale listener).

This repo at `c293acff`: `android/app/src/main/AndroidManifest.xml`, `MainActivity.kt`, `HealthConnectWorkoutReader.kt`, `lib/core/data/data_source/health/health_package_service.dart`, `lib/core/utils/notification_service.dart`, `lib/features/scanner/scanner_screen.dart`, `lib/features/add_meal/presentation/add_meal_screen.dart`, `lib/features/add_meal/presentation/screens/bulk_add_screen.dart`, `lib/features/home/presentation/widgets/{intake_vertical_list,shared_meal_import_dialogs}.dart`, `lib/features/home/domain/entity/shared_meal_payload.dart`, `lib/core/presentation/widgets/share_qr_dialog.dart`, `lib/features/settings/domain/usecase/{export_data,import_data}_usecase.dart`, `lib/features/settings/presentation/widgets/ai_assist_dialog.dart`, `lib/core/utils/{ai_credential_storage,ai_model_catalogue}.dart`.

Prior runs: `docs/settings-test/run-2026-10-11/notes.md` and `docs/settings-test/tools/st.sh` on `research/settings-pixel-test`, and `docs/release-tests/2.4.0/01-baseline.md` on `research/release-2.4.0-pixel-test`.
