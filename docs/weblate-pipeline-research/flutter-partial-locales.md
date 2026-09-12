# Flutter gen-l10n with partially translated ARBs, and what a new locale needs beyond the ARB

Researched 2026-09-12 against the Flutter SDK this repo pins (3.44.6, `~/fvm/versions/3.44.6`; every source line below was checked on the `3.44.6` tag on GitHub and matches the local SDK), docs.flutter.dev, api.flutter.dev, docs.weblate.org (2026.10 docs, `/en/latest/`), hosted.weblate.org's public API, and the surveyed repos' own files. Where I ran an experiment, the project lives in `scratchpad/l10nexp/` and the exact ARB inputs are described inline.

Conventions: `G` = `packages/flutter_tools/lib/src/localizations/gen_l10n.dart`, `T` = `.../gen_l10n_types.dart`, `U` = `.../localizations_utils.dart`, `P` = `.../gen_l10n_templates.dart`, all at https://github.com/flutter/flutter/blob/3.44.6/.

---

## TL;DR for the Weblate situation in this repo

1. **A partial ARB does not break `flutter gen-l10n`.** Generation exits 0, every missing key gets the **English (template) string compiled into the locale's class**, and the key is listed under that locale in `l10n_untranslated.json`. `just check_l10n` is the only thing that turns that into a failure. (G L1036-1037, experiment 1.)
2. **Two Weblate outputs *do* break gen-l10n outright**, and both are in Weblate's current export for this project:
   - `intl_pt_BR.arb` with no `intl_pt.arb` beside it -> `L10nException: Arb file for a fallback, pt, does not exist` (T L755-760, experiment 2). Weblate's export has exactly this: `lib/l10n/intl_pt_BR.arb` containing `{}` and no `intl_pt.arb`.
   - Any language whose code is not in gen-l10n's ISO-639 set (e.g. `nap`) and whose file lacks `@@locale` -> `The following .arb file's locale could not be determined` (T L681-684, experiment 3). Weblate's exported ARBs carry **no `@@locale` key** (checked on fr/es/sv/hu/ru), so this is live risk for any 3-letter code Weblate lets a translator add (`fil` happens to be in the set; `nap` is not).
3. **An empty-string value is "translated"** to gen-l10n: it is not listed in `l10n_untranslated.json` and the generated getter returns `''`, i.e. a blank label at runtime (experiment 4). Weblate produces both shapes in the wild: omitted keys (ONT's own export, FluffyChat, Every Door) and `"key": ""` for every untranslated unit (musicpod, 644 of 771 in `app_nl.arb`). FluffyChat's CI greps ARBs for `": ""` and fails on it for exactly this reason.
4. **A partial locale is always in `supportedLocales`** (G L1016) and the delegate's `isSupported` matches on `languageCode` alone (P L233). So a 1%-translated `intl_sv.arb` makes Swedish a first-class, selectable, App-Store-advertised language showing 99% English.
5. **Beyond the ARB, this repo needs four more edits per new locale**, and has tests/guards for only one of them: `ios/Runner/Info.plist` `CFBundleLocalizations` (guarded by `test/unit_test/ios_localizations_drift_test.dart`), `android/app/src/main/res/xml/locales_config.xml` (not guarded), the `_supportedLocales` name map in `lib/features/settings/settings_screen.dart` (not guarded), and CONTRIBUTING's locale list. wger ships a `tool/check_locales.dart` that checks all three from the ARB filenames; FluffyChat generates `locale_config.xml` from the ARB directory in CI and fails on drift.
6. **Every surveyed project merges partial translations**; none gates on `untranslated-messages-file`. They rely on the English fallback and, at most, check for empty strings / unused keys / locale-list drift. The only completeness policy found is Sanmill's wiki: "at least 70% complete to be included in a final release".
7. **Weblate's `json_indent=4` on this component vs the repo's 2-space ARBs** means the first Weblate commit that touches an existing file (e.g. `intl_de.arb`) will re-indent the whole file. Weblate's new files (fr/hu/ru/es/sv) are already 4-space.
8. Note on 3.44.6 specifically: for a *regional* file (`pt_BR`) the pinned SDK lists a key as untranslated for `pt_BR` even when `intl_pt.arb` has it (experiment 2 output). That is flutter/flutter#176020, fixed by PR #187950 (merged 2026-06-13) which is **not** in 3.44.6 (the fix's "inheritance chain" comment is absent from the pinned `gen_l10n.dart`). So with `check_l10n` as written, a `pt` + `pt_BR` pair could only pass if `pt_BR` duplicated every key.

---

## 1. gen-l10n with a translation ARB that is missing keys

### 1a. Generation succeeds; missing keys fall back to the template locale at generation time

Source, `G` L1027-1037 (`_generateBaseClassFile`):

```dart
final Iterable<String> methods = _allMessages.map((Message message) {
  var localeWithFallback = locale;
  if (message.messages[locale] == null) {
    _addUnimplementedMessage(locale, message.resourceId);
    localeWithFallback = _templateArbLocale;
  }
  ...
  return _generateMethod(message, localeWithFallback);
});
```
https://github.com/flutter/flutter/blob/3.44.6/packages/flutter_tools/lib/src/localizations/gen_l10n.dart#L1036-L1037 -- quote: `localeWithFallback = _templateArbLocale;`

The fallback is baked into the generated Dart, not resolved at runtime: the locale class gets a concrete getter containing the English text. There is no runtime exception, no null, no empty string for a *missing* key.

Experiment 1 (3.44.6, `l10n.yaml` copied from this repo; `intl_en.arb` = `appTitle`, `hello {name}`, `onlyInEnglish`; `intl_fr.arb` = only `appTitle`):

```
exit=0
l10n_untranslated.json:
{
  "fr": [
    "hello",
    "onlyInEnglish"
  ]
}
lib/generated/l10n_fr.dart:
class SFr extends S {
  SFr([String locale = 'fr']) : super(locale);
  @override String get appTitle => 'OpenNutriTracker FR';
  @override String hello(String name) { return 'Hello $name'; }
  @override String get onlyInEnglish => 'Only in English';
}
```

CONTRIBUTING.md in this repo already states this correctly (line 60): "`flutter gen-l10n` exits 0 on a missing translation — it records the key in `l10n_untranslated.json` ... and the string falls back to English at runtime."

### 1b. What goes into `untranslated-messages-file`

Docs (docs.flutter.dev, "Configuring the l10n.yaml file" table, row `untranslated-messages-file`): "The location of a file that describes the localization messages haven't been translated yet." and "Using this option creates a JSON file at the target location, in the following format: `"locale": ["message_1", "message_2" ... "message_n"]`" and "If this option is not specified, a summary of the messages that haven't been translated are printed on the command line."
https://docs.flutter.dev/ui/accessibility-and-internationalization/internationalization#configuring-the-l10n-yaml-file

Source: when there is nothing untranslated the file is written as literally `{}` -- `G` L1494 `untranslatedMessagesFile.writeAsStringSync('{}');` (this is what `just check_l10n` compares against). Without the option, the CLI prints `'"$locale": ${messages.length} untranslated message(s).'` (`G` L1450). The path is resolved relative to the project directory, not `arb-dir`, on this version (`G` L899-911, `projectDirectory.childFile(...)`) -- the `U` doc comment saying "relative to [arbDir]" is stale.

### 1c. Empty string is NOT "untranslated"

The check is `message.messages[locale] == null` (`G` L1035). `T` L701 `translationFor` returns the raw JSON value, so `""` is a present translation.

Experiment 4: `intl_fr.arb` with `"onlyInEnglish": ""` -> exit 0, `l10n_untranslated.json` lists only `hello` for fr, and `l10n_fr.dart` contains `String get onlyInEnglish => '';`. The UI would render a blank.

### 1d. Regional subclasses on 3.44.6

`_generateSubclass` (`G` L1057-1075) marks a key untranslated for `pt_BR` whenever `message.messages[pt_BR] == null`, regardless of `pt`. The generated `SPtBr extends SPt` only overrides keys present in `intl_pt_BR.arb`, so at runtime it inherits `pt`, which inherits English -- correct behaviour, misleading report. Fixed upstream by https://github.com/flutter/flutter/pull/187950 ("[gen_l10n] Exclude inherited keys from untranslated-messages-file", merged 2026-06-13) for https://github.com/flutter/flutter/issues/176020; not present in 3.44.6 (`grep -c "inheritance chain"` on the pinned `gen_l10n.dart` = 0; master has the comment "Only mark a message as unimplemented/untranslated if it is missing from every locale in the subclass's inheritance chain").

Experiment 2 output on 3.44.6 with `intl_pt.arb` = {`hello`} and `intl_pt_BR.arb` = {`appTitle`}:
```
"pt": ["appTitle", "onlyInEnglish"],
"pt_BR": ["hello", "onlyInEnglish"]      <- "hello" is inherited from pt, still reported
```

## 2. Is a partial locale still in `supportedLocales`? Yes, unconditionally

`G` L995-1016 `loadResources()`:
```dart
final allLocales = List<LocaleInfo>.from(_allBundles.locales);
... (preferred-supported-locales reordering) ...
supportedLocales.addAll(allLocales);
```
https://github.com/flutter/flutter/blob/3.44.6/packages/flutter_tools/lib/src/localizations/gen_l10n.dart#L1016 -- quote: `supportedLocales.addAll(allLocales);`

`_allBundles.locales` is every `*.arb` in `arb-dir` (`T` L723 `final filenameRE = RegExp(r'(\w+)\.arb$');`). Nothing looks at completeness. Experiment 5: an `intl_sv.arb` containing just `{}` (the shape of Weblate's `intl_pt_BR.arb`) generates fine, lists all keys under `"sv"` in the untranslated file, and emits `Locale('sv')` into `S.supportedLocales`.

Runtime: the generated delegate accepts any locale whose *language code* has a bundle -- `P` L233: `bool isSupported(Locale locale) => <String>[@(supportedLanguageCodes)].contains(locale.languageCode);`. Docs: "The `AppLocalizations` class also provides an auto-generated `supportedLocales` list. You can use it instead of providing the locales manually." (https://docs.flutter.dev/ui/accessibility-and-internationalization/internationalization#add-your-own-localized-messages). This repo passes `S.supportedLocales` straight to `MaterialApp` (`lib/main.dart:94,298`), and also uses it for the in-app picker reconciliation (`lib/core/utils/app_locale_sync.dart`).

## 3. ARB filename patterns for country/script locales, and how the Locale is derived

### Filename -> locale

`T` L639-660 (`AppResourceBundle` factory): the basename without extension is tried as a whole with `Locale.tryParse`; if that fails, the tool tries the substring after each `_`, accepting the first parse whose language code is in `_iso639Languages` (`T` L793, "A set containing all the ISO630-1 languages ... pulled from https://datahub.io/core/language-codes"). The parsed BCP-47 tag has `-` replaced by `_` (`T` L647, L655). Then `LocaleInfo.fromString` (`U` L42-56) splits on `_`: with two parts, a 4+ char second part is the script, shorter is the country (`U` L51 `scriptCode = codes[1].length >= 4 ? codes[1] : null;`); with three parts the longer of the two is the script.

So `intl_pt_BR.arb` -> `pt_BR` (language+country), `intl_zh_Hans.arb` -> `zh_Hans` (language+script), `intl_zh_Hant_TW.arb` -> `zh_Hant_TW`. Experiment (3.44.6) generated:
```dart
Locale('pt'),
Locale('pt', 'BR'),
Locale('zh'),
Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
Locale.fromSubtags(languageCode: 'zh', countryCode: 'TW', scriptCode: 'Hant'),
```
and classes `SPtBr extends SPt`, `SZhHans extends SZh`, `SZhHantTw extends SZh` (`G` L1057-1059: base class name is derived from `locale.languageCode` only on this version).

`@@locale`, if present, must agree with the filename or generation throws `The locale specified in @@locale and the arb filename do not match.` (`T` L666). If the filename yields nothing and there is no `@@locale`: `The following .arb file's locale could not be determined` (`T` L681). Experiment 3: `intl_nap.arb` without `@@locale` fails; with `"@@locale": "nap"` it generates `Locale('nap')`. `intl_fil.arb` works either way because `fil` is in the set (`T` L839).

### Hard rule: a regional/script file requires its base-language file

`T` L750-762:
```
'Arb file for a fallback, $language, does not exist, even though \n'
'the following locale(s) exist: $listOfCorrespondingLocales. \n'
'When locales specify a script code or country code, a \n'
'base locale (without the script code or country code) should \n'
'exist as the fallback. Please create a {fileName}_$language.arb \n'
'file.'
```
https://github.com/flutter/flutter/blob/3.44.6/packages/flutter_tools/lib/src/localizations/gen_l10n_types.dart#L755 -- quote: `Arb file for a fallback, $language, does not exist`

Experiment 2: `intl_pt_BR.arb` alone -> exit 1 with exactly that message; adding `intl_pt.arb` (even `{}` would do) -> exit 0. Every Door hit this with Weblate-created `app_zh_Hans.arb`/`app_zh_Hant.arb` and no `app_zh.arb`: their build workflow runs `echo '{}' > lib/l10n/app_zh.arb` before `flutter pub get` and `.gitignore` lists `lib/l10n/app_zh.arb` (https://github.com/Zverik/every_door/blob/main/.github/workflows/build-apk.yml#L21, added 2023-05-10 in commit 02651962). The same workflow does `rm -f lib/l10n/app_nap.arb` (commit 7dd19c75, 2025-04-01, "Remove nap translation when building") -- a 3-letter code Weblate happily created.

Docs on script variants: "Some languages with multiple variants require more than just a language code to properly differentiate." and the docs recommend "The full `Locale.fromSubtags` constructor is preferred as it supports `scriptCode`" (https://docs.flutter.dev/ui/accessibility-and-internationalization/internationalization#advanced-locale-definition). The docs page does not spell out the `app_zh_Hans.arb` filename convention; the source above is the authority.

Also `T` L740: two files resolving to the same locale -> `Multiple arb files with the same '...' locale detected.`

## 4. iOS `CFBundleLocalizations` and the Android equivalent

### iOS

docs.flutter.dev, "Localizing for iOS: Updating the iOS app bundle": "Although the localizations are handled by Flutter, you need to add the supported languages in the Xcode project. This ensures your entry in the App Store correctly displays the supported languages." ... "Xcode automatically creates empty `.strings` files and updates the `ios/Runner.xcodeproj/project.pbxproj` file. These files are used by the App Store to determine which languages and regions your app supports."
https://docs.flutter.dev/ui/accessibility-and-internationalization/internationalization#localizing-for-ios-updating-the-ios-app-bundle

The docs describe the Xcode-UI route (which edits `knownRegions` in `project.pbxproj`); this repo instead declares `CFBundleLocalizations` in `ios/Runner/Info.plist` (lines 27-38: en, de, cs, it, pl, sk, tr, uk, zh) while `project.pbxproj` `knownRegions` is still `(en, Base)`. `test/unit_test/ios_localizations_drift_test.dart` fails if any `intl_*.arb` locale is missing from `CFBundleLocalizations`; its header comment records the motivation: "iOS uses that array to decide which languages to surface in Settings -> app language picker ... (The pre-existing miss caused 6 locales to be invisible on iOS.)". I did not find a docs.flutter.dev sentence naming `CFBundleLocalizations`; the Apple-side semantics are outside the allowed source list, so the claim "Info.plist `CFBundleLocalizations` is what iOS uses" rests on this repo's test comment and on wger/FluffyChat doing the same thing -- flagged as an open question below.

### Android

developer.android.com (vendor primary source, outside the allowed list but the only authority): "You can manually set up your app to ensure its languages are configurable in system settings on devices running Android 13 or higher. To do this, create a locale_config XML file and add it to your app's manifest using the android:localeConfig attribute." and "Omitting the android:localeConfig manifest entry signals that users shouldn't be able to..." (set the language per app). Alternative: AGP 8.1+ `androidResources { generateLocaleConfig = true }` derives it from `res/values-*` -- which a Flutter app does not have, so Flutter apps keep the manual XML. `resourceConfigurations` in Gradle is about stripping library resources, not about declaring app languages: "the build system only includes language resources in the APK for these specified languages".
https://developer.android.com/guide/topics/resources/app-languages

This repo: `android/app/src/main/AndroidManifest.xml:50` `android:localeConfig="@xml/locales_config"`, and `android/app/src/main/res/xml/locales_config.xml` lists the same nine codes with a comment "Keep this list in step with lib/l10n/intl_*.arb and with the in-app picker in settings_screen.dart". No test guards it. No `resConfigs`/`resourceConfigurations` in `android/`.

### Everything a new locale touches in this repo today

| Where | Guarded by |
|---|---|
| `lib/l10n/intl_<code>.arb` (complete, per `check_l10n`) | `just check_l10n` in CI |
| `ios/Runner/Info.plist` `CFBundleLocalizations` | `test/unit_test/ios_localizations_drift_test.dart` |
| `android/app/src/main/res/xml/locales_config.xml` | nothing |
| `lib/features/settings/settings_screen.dart` `_supportedLocales` name map (in-app picker) | nothing |
| `CONTRIBUTING.md` "currently supported locales" list | nothing |
| (if the code has a script/country) a base `intl_<lang>.arb` | gen-l10n itself (hard failure) |

## 5. `basicLocaleListResolution` and `preferred-supported-locales`

api.flutter.dev `basicLocaleListResolution`: "This algorithm will resolve to the earliest preferred locale that matches the most fields, prioritizing in the order of perfect match, languageCode+countryCode, languageCode+scriptCode, languageCode-only." ... "When no match at all is found, the first (default) locale in supportedLocales will be returned." and the implementation's first lines: `if (preferredLocales == null || preferredLocales.isEmpty) { return supportedLocales.first; }`
https://api.flutter.dev/flutter/widgets/basicLocaleListResolution.html

Order of resolution (api.flutter.dev `WidgetsApp.localeListResolutionCallback`): "localeListResolutionCallback is attempted. localeResolutionCallback is attempted. Flutter's basic resolution algorithm, as described in supportedLocales, is attempted last."
https://api.flutter.dev/flutter/widgets/WidgetsApp/localeListResolutionCallback.html

docs.flutter.dev, "Specifying the app's supportedLocales parameter": "If an exact match for the device locale isn't found, then the first supported locale with a matching languageCode is used. If that fails, then the first element of the supportedLocales list is used."
https://docs.flutter.dev/ui/accessibility-and-internationalization/internationalization#specifying-the-apps-supportedlocales-parameter

`preferred-supported-locales` (docs table): "The list of preferred supported locales for the application. By default, the tool generates the supported locales list in alphabetical order. Use this flag to default to a different locale. For example, pass in `[ en_US ]` to default to American English if a device supports it." Source `G` L996-1015: each preferred locale is removed from its alphabetical position and the preferred list is inserted at index 0; a preferred locale with no ARB throws `The preferred supported locale, '$preferredLocale', cannot be added.` (`G` L1007). This repo sets `[en]` so that `supportedLocales.first` (the fallback of last resort) is English -- the comment in `l10n.yaml` says exactly this. Consequence for partial locales: resolution is by language code, so a device set to Swedish gets the 1%-Swedish class, never English, as long as `intl_sv.arb` exists.

The runtime `lookupS` switch (`P` L247-256) throws `FlutterError('S.delegate failed to load unsupported locale ...')` only for a locale that is not in the generated tables, which `main.dart:109-111` already guards by resolving through `basicLocaleListResolution` first.

## 6. `nullable-getter`

Docs table: "Specifies whether the localizations class getter is nullable. By default, this value is true so that `Localizations.of(context)` returns a nullable value for backwards compatibility. If this value is false, then a null check is performed on the returned value of `Localizations.of(context)`, removing the need for null checking in user code."
https://docs.flutter.dev/ui/accessibility-and-internationalization/internationalization#configuring-the-l10n-yaml-file

Source: `U` L355 `nullableGetter = nullableGetter ?? true,`; `G` L1212-1213 `.replaceAll('@(canBeNullable)', usesNullableGetter ? '?' : '')` / `.replaceAll('@(needsNullCheck)', usesNullableGetter ? '' : '!')`; template `P` L79-80 `static @(class)@(canBeNullable) of(BuildContext context) { return Localizations.of<@(class)>(context, @(class))@(needsNullCheck); }`.

**It has no effect on missing translations.** It only changes whether `S.of(context)` is typed `S?` or `S` (with a `!` on the `Localizations.of` result, which is null only when there is no `S` delegate above the widget). Per-key getters are always non-nullable `String` and, per section 1a, always have a body. This repo sets `nullable-getter: false`.

## 7. Survey: Flutter apps translated on Hosted Weblate

Component metadata is from the public API `https://hosted.weblate.org/api/projects/<slug>/components/` (fields `vcs`, `repo`, `push`, `branch`, `push_branch`, `filemask`, `new_lang`), read 2026-09-12. The Weblate docs' push-options table (https://docs.weblate.org/en/latest/admin/continuous.html#pushing-changes-from-weblate) maps these: "No push: Git, empty, empty"; "Push to separate branch: Git, SSH URL, Branch name"; "GitHub pull request from fork: GitHub pull requests, empty, empty"; "GitHub pull request from branch: GitHub pull requests, SSH URL, Branch name". The GitHub backend "creates pull requests" instead of pushing (https://docs.weblate.org/en/latest/admin/code-hosting.html#github-pull-requests: "Git pushes changes directly to a repository, while the GitHub backend creates pull requests.").

| Project (Flutter, ARB) | Weblate component | vcs / push / push_branch -> mode | Branch tracked | How translations land | Partial-translation gate in CI | New languages |
|---|---|---|---|---|---|---|
| **FluffyChat** krille-chan/fluffychat | fluffychat/translations, `lib/l10n/intl_*.arb` | `github` / SSH URL / "" -> **PR from Weblate's fork**, head `weblate-fluffychat-translations` | `main` | PRs merged roughly daily (#3580 merged 2026-09-11, #3568, #3561, #3556, #3550) | None on completeness. `integrate.yaml`: `if grep -rn '": ""' lib/l10n/*.arb; then ... exit 1` ("Check for empty translations"); `dart run dart_code_linter:metrics check-unused-l10n lib`; `sweeper check` for unused keys. `l10n.yaml` has no `untranslated-messages-file`; `az` has 8/784 keys, `ia` 14. | `new_lang: add` (translators self-serve). CI runs `./scripts/generate-locale-config.sh` (writes `android/.../locale_config.xml` from `intl_*.arb` filenames) then `git diff --exit-code`, so a PR adding an ARB without the regenerated XML fails. No `CFBundleLocalizations` in `ios/Runner/Info.plist`. Ships `intl_pt.arb` + `intl_pt_BR.arb` + `intl_pt_PT.arb`, `intl_zh.arb` + `intl_zh_Hant.arb`. |
| **wger** wger-project/flutter | wger/mobile, `lib/l10n/app_*.arb` | `github` / SSH URL / `feature/weblate` -> **PR from a branch in the upstream repo** | `master` | PRs `master <- feature/weblate` (#1334 merged 2026-08-28, #1333, #1328; #1346 open) | None on completeness (`app_ta.arb` 297/559 merged). `analyze.yml` runs `dart run tool/check_locales.dart`, which "Verifies that every place which enumerates the app's supported locales agrees with the canonical list derived from `lib/l10n/app_*.arb` filenames" -- `ios/Runner/Info.plist`, `android/.../locales_config.xml`, `languageNativeNames`; `--fix` rewrites the first two. | `new_lang: add`. `lib/l10n/README.md`: "When adding a new language ... please ensure that the new locale is also registered in `android/app/src/main/res/xml/locales_config.xml`". Ships `app_pt.arb`, `app_pt_BR.arb`, `app_pt_PT.arb`. |
| **Finamp** jmshrv/finamp (now finamp-app) | finamp/finamp, `lib/l10n/app_*.arb` | `github` / "" / "" -> **PR from fork** `weblate/finamp`, head `weblate-finamp-finamp` | **`redesign`** (their dev branch, not `main`) | PRs `redesign <- weblate-finamp-finamp` (#1737 merged 2026-08-30, #1731, #1703, #1702; #1753 open) | None. `pr-healthchecks.yml` runs `dart format lib/l10n/` and a code-generation check; no untranslated gate. `sw`, `ro`, `en_GB` at 0%. | `new_lang: add`; CONTRIBUTING.md: "Feel free to add new languages if yours isn't there yet." Android `locales_config.xml` maintained by hand; no `ios/Runner/Info.plist` in the tree. |
| **Every Door** Zverik/every_door | every-door/app, `lib/l10n/app_*.arb` | `github` / "" / "" -> **PR from fork**, head `weblate-every-door-app` | `main` | PRs `main <- weblate-every-door-app` (#996 merged 2026-01-27, #985, #982; #1021 open) | None (`cy` 0.2%, `ko` 84/340 keys merged). Build workflows patch around gen-l10n's hard failures instead: `echo '{}' > lib/l10n/app_zh.arb` (base file for Weblate-created `app_zh_Hans`/`app_zh_Hant`; `app_zh.arb` is gitignored) and `rm -f lib/l10n/app_nap.arb`. | `new_lang: add`; no CONTRIBUTING; README just says "translate the app". No `CFBundleLocalizations`. |
| **MusicPod** ubuntu-flutter-community/musicpod | musicpod/app, `lib/l10n/app_*.arb` | `github` / "" / "" -> **PR from fork**, head `weblate-musicpod-app` | `main` | PRs `main <- weblate-musicpod-app` (#1668 merged 2026-09-12, #1663, #1661, #1656), then a **nightly workflow** (`.github/workflows/nightly.yml`, cron `0 3 * * *`) runs `flutter gen-l10n` and opens "chore: Auto-generate L10n files" PRs (#1669) because generated `lib/l10n/app_localizations_*.dart` are committed. | None (`kk` 0%, `nl` 16%). Their ARBs carry `""` for every untranslated key (`app_nl.arb`: 771 keys, 644 empty; `app_kk.arb` went from `{}` to 771 empties in Weblate commit e46f03a1 "Translated using Weblate (Kazakh) ... 0.0% (0 of 771 strings)"). Nothing in CI catches that; those keys render blank. | `new_lang: add`. No Info.plist/locales_config guard. |
| **FOSS Warn** nucleus-ffm/foss_warn | foss-warn/foss-warn-app, `lib/l10n/app_*.arb` | `git` / SSH URL / `weblate` -> **direct push to a `weblate` branch** in the upstream repo | `main` | Maintainer opens "Update translations" PRs `main <- weblate` (#313 merged 2026-08-27, #310, #290, #281) | None; `ci.yml` runs `flutter gen-l10n` then `flutter analyze` / `flutter test`. | `new_lang: add`. README: "We are using Weblate to translate FOSS Warn." |
| **Sanmill** calcitem/Sanmill | sanmill/flutter, `src/ui/flutter_app/lib/l10n/intl_*.arb` | `github` / SSH URL / `weblate/flutter` -> **PR from branch** | `master` | Weblate PRs `master <- weblate/flutter` (#1051 open; #1026, #983 closed unmerged, i.e. the branch is merged by hand) | `l10n.yaml` sets `untranslated-messages-file: untranslated-messages-file.txt` as a report only; no CI gate found. Written policy in the wiki: "a translation must be at least 70% complete to be included in a final release. We try to contain all translations for alpha releases, no matter how incomplete." | `new_lang: add`; wiki "Adding a new language": "Anyone can create a new language via Weblate", and "if you consider adding a country-specific language (e.g., de-AT), first make sure that the primary language is well maintained (e.g., de)". |
| **Canonical firmware-updater** canonical/firmware-updater (bonus, Ubuntu desktop Flutter) | ubuntu-desktop-translations/firmware-updater, `apps/firmware_updater/lib/l10n/app_*.arb` | `github` / "" / "" -> **PR from fork** | `main` | Weblate PRs; `.github/workflows/weblate-l10n.yaml` (`pull_request_target`, gated on `github.event.pull_request.user.login == 'weblate'` and head repo owner `weblate`) runs `melos gen-l10n` and commits regenerated files back onto Weblate's PR branch via `canonical/desktop-engineering/gh-actions/flutter/weblate-l10n` ("Regenerates derived localization files and commits them to a trusted Weblate PR branch"). | None found. | `new_lang: contact` -- translators must ask; maintainers add the language. |
| (excluded) Saber saber-notes/saber | has `.weblate` but uses `slang` YAML (`lib/i18n/*.i18n.yaml`), not ARB | | | | | |

Also checked: LocalSend, Butterfly, Mindful, Ente, Immich -- none of the first three have `.weblate`/`l10n.yaml` at the root and Ente/Immich are not ARB+Weblate in the same way; not surveyed further. AnkiDroid is not Flutter.

### Patterns worth copying

- **Nobody gates on completeness.** All eight merge partial ARBs and let gen-l10n's English fallback do its job; the only completeness *policy* is Sanmill's 70%-for-release, enforced by hand.
- **Guard the locale lists, not the strings**: wger's `tool/check_locales.dart` (Info.plist + locales_config.xml + native-name map from ARB filenames, with `--fix`) and FluffyChat's generate-then-`git diff --exit-code` are the two mechanisms; this repo has the iOS half as a test.
- **Guard against `""`**: FluffyChat's one-line grep. Given musicpod's files, Weblate can and does emit empty strings.
- **Base-language file for regional/script codes**: Every Door's `echo '{}' > app_zh.arb` shows the failure is real; the cleaner fix is committing the base file (FluffyChat/wger commit `intl_pt.arb` + `intl_pt_BR.arb`).
- **Keep generated Dart out of the diff** (this repo already gitignores `lib/generated/`), or you need musicpod's nightly regenerate PR / Canonical's regenerate-onto-the-Weblate-branch action.
- **`new_lang: contact`** (Canonical, mhabit) is how a project stops translators from creating `nap`/`pt_BR`-without-`pt` files unattended; every other surveyed project uses `add`.

## 8. What Weblate's current export for this repo would do to `flutter gen-l10n` and `check_l10n`

From `git clone https://hosted.weblate.org/git/opennutritracker/app/` (HEAD afbad29 "chore(l10n): update Swedish translation"):

| File | Keys (non-`@`) | Notes |
|---|---|---|
| intl_fr.arb, intl_hu.arb, intl_ru.arb | 900 | complete against Weblate's July template (900); upstream `intl_en.arb` now has 1044, so 144 keys short of `check_l10n` |
| intl_es.arb | 227 | |
| intl_sv.arb | 10 | |
| intl_pt_BR.arb | 0 (`{}`) | **no `intl_pt.arb` -> gen-l10n throws** (section 3) |
| all Weblate files | | no `@@locale`; 4-space indent (`json_indent=4`) vs 2-space in the repo; `@key` metadata partially carried over (fr 50, es 24, sv 1 entries) |

So: merging Weblate's branch as-is fails `flutter gen-l10n` (pt_BR) before `check_l10n` even runs; after adding `intl_pt.arb`, `check_l10n` fails for every one of fr/hu/ru/es/sv/pt/pt_BR. `just check_l10n` (justfile L25-40) compares `l10n_untranslated.json` to `{}` with no per-locale allowance.

---

## Open questions

1. Mechanism behind Weblate writing `""` for every untranslated unit (musicpod) versus omitting keys (this project's export, FluffyChat, Every Door). Both components have `addons: []` and `file_format: arb`. Not resolved from docs.weblate.org; the JSON docs' example file does show `"": ""` entries for untranslated strings. Worth asking before deciding whether a `": ""` grep is needed here.
2. No docs.flutter.dev sentence names `CFBundleLocalizations`; the docs describe the Xcode "Localizations" UI (which edits `project.pbxproj` `knownRegions`). Whether App Store / iOS Settings read `CFBundleLocalizations` from Info.plist is an Apple question outside the allowed sources; this repo's `ios_localizations_drift_test.dart` comment and wger's `check_locales.dart` both assume yes.
3. Whether Weblate's `new_lang: add` on this component can be switched to `contact` without losing the five already-created languages -- Weblate-side, not covered here.
4. `_iso639Languages` in gen-l10n (`T` L793) is a hand-copied set, not the IANA registry that `describeLocale` uses; I did not enumerate which of Weblate's language codes fall outside it beyond `nap` (fails) and `fil` (passes).
5. Whether this repo wants to ship the 3.44.6 regional-subclass over-reporting (flutter/flutter#176020) as a constraint ("no `pt`+`pt_BR` pairs until the SDK bump") or work around it in `check_l10n`.

## Verification

Fact-checked 2026-09-12. Method: every cited URL was fetched; GitHub `blob` pages for the Flutter SDK truncate at 1000 lines, so the raw file at the `3.44.6` tag was fetched too and line numbers were checked against the local `~/fvm/versions/3.44.6` checkout (`git describe` = `3.44.6`, HEAD `ee80f08b`). All nine gen-l10n experiments were re-run from scratch in `scratchpad/l10nverify/` on 3.44.6. Weblate component metadata was re-read from `hosted.weblate.org/api/components/<slug>/`, PR numbers/branches/merge dates via `gh pr view`, and the Weblate git export was re-cloned (HEAD `afbad29`).

Result: 35 of 39 claims supported; 4 not supported as written (three are overreach beyond the cited page, one is a real behavioural nuance the research missed). Nothing in the TL;DR is wrong.

### Not supported as written

| # | Claim | Problem | Corrected |
|---|---|---|---|
| 17 | Android `localeConfig` / AGP `generateLocaleConfig` "does not fit Flutter apps" / `resourceConfigurations` "only strips resources" | https://developer.android.com/guide/topics/resources/app-languages says the manual route is a `locale_config` XML + `android:localeConfig` for Android 13+, that AGP 8.1+ "uses the resources in the `res` folders of your app modules and any library module dependencies to determine the locales", and that with `resourceConfigurations` "the build system only includes language resources in the APK for these specified languages". It never mentions Flutter; "does not fit Flutter apps" is the researcher's inference, and the page actually presents `resourceConfigurations` as a companion step to `locale_config`, not as an alternative that "does not declare app languages". | Keep the mechanism; drop the Flutter sentence or label it as inference. |
| 20 | `preferred-supported-locales` docs row + "a preferred locale with no ARB throws" | The docs row is quoted correctly, but the docs page says nothing about throwing; that clause comes from `gen_l10n.dart`, and see #21. | Split: docs describe reordering only. |
| 21 | "A preferred locale that has no corresponding ARB makes gen-l10n throw." | The throw exists at `gen_l10n.dart` L1004-1011, **but** the loop calls `allLocales.insertAll(0, preferredSupportedLocales)` inside the `for`, so once any earlier preferred locale is found, every later preferred locale is already in the list and the check passes. Re-run on 3.44.6: `preferred-supported-locales: [en, xx]` with no `intl_xx.arb` -> exit 0 and `Locale('xx')` in `S.supportedLocales`; `[de]` alone -> exit 1 with the quoted message. | gen-l10n throws only when the missing preferred locale precedes every existing one in the list; otherwise it silently emits a bogus `Locale` (3.44.6). Irrelevant for this repo's `[en]`, but do not rely on the check. |
| 24 | Weblate push-options table cited at `continuous.html#pushing-changes-from-weblate` | That section only links onward; the table lives at https://docs.weblate.org/en/latest/admin/code-hosting.html#code-hosting-push-options (rows verified there: No push = Git/empty/empty; Push directly = Git/SSH/empty; Push to separate branch = Git/SSH/branch; GitHub PR from fork = GitHub/empty/empty; GitHub PR from branch = GitHub/SSH/branch). Note FluffyChat's actual combo (GitHub VCS + SSH push URL + empty branch) is not a table row; the same page says of push branch "if not set, the project is forked and changes are pushed through a fork". | Same content, cite code-hosting.html. |

### Supported (with notes where the cited page carries only part of the claim)

- #1, #2, #4, #5, #6, #7, #23: `gen_l10n.dart` lines 1035-1037, 1027-1044, 1494, 1450, 1035, 1016, 1212-1213 all match on the 3.44.6 tag (raw fetch + local checkout). Experiments 1 (fr 1/3 keys -> exit 0, two keys under `fr`, `String get onlyInEnglish => 'Only in English';`), 4 (`""` -> `=> '';`, not reported), 5 (`{}` -> `Locale('sv')`), and the no-file CLI summary (`"fr": 2 untranslated message(s).`) reproduced.
- #3, #9, #16, #22: docs.flutter.dev quotes verbatim; the page has no sentence about missing-key behaviour and no `CFBundleLocalizations`. #22's "no bearing on missing translations" is not on the docs page but follows from #1/#23 and experiment 1 (`nullable-getter: false` only yields `static S of(BuildContext context) { return Localizations.of<S>(context, S)!; }`).
- #8: `gen_l10n_templates.dart` L233 verbatim.
- #10, #11, #12, #13, #14: `gen_l10n_types.dart` L645-656 / L664-672 / L679-685 / L750-762 and `localizations_utils.dart` L42-56 verbatim; `fil` in `_iso639Languages`, `nap` not. Re-run: `intl_pt_BR.arb` alone -> exit 1 "Arb file for a fallback, pt, does not exist"; `intl_nap.arb` fails without `@@locale`, passes with it; `intl_fil.arb` passes; `@@locale: de` in `intl_fr.arb` -> "do not match"; `zh`/`zh_Hans`/`zh_Hant_TW` -> `Locale.fromSubtags(...)` and `SZhHans extends SZh`, `SZhHantTw extends SZh`. Weblate export: `intl_pt_BR.arb` = `{}`, no `intl_pt.arb`, no `@@locale` anywhere.
- #15: PR #187950 title verbatim, merged 2026-06-13, fixes #176020; `grep -c "inheritance chain"` on pinned `gen_l10n.dart` = 0; re-run of pt + pt_BR reports `"pt_BR": ["hello", "onlyInEnglish"]` although `intl_pt.arb` has `hello`.
- #18: test header quote verbatim on `main`; `locales_config.xml`, `AndroidManifest.xml:50 android:localeConfig`, and `settings_screen.dart` `_supportedLocales` exist on `main` and no file under `test/` references either -> "unguarded" holds.
- #19, and the resolution-order claim: api.flutter.dev quotes verbatim.
- #25, #38: docs.weblate.org quotes verbatim.
- #26-#35 (survey): cited files contain the quoted lines. The Weblate API fields (`vcs`, `push`, `push_branch`, `branch`, `new_lang`) and PRs #3580 (main <- weblate:weblate-fluffychat-translations, merged 2026-09-11; five more Weblate PRs merged 09-01..09-05), #1334 (master <- feature/weblate, 2026-08-28), #1737 (redesign <- weblate:weblate-finamp-finamp, 2026-08-30), #1668 (main <- weblate:weblate-musicpod-app, 2026-09-12) + #1669 (`chore/update-l10n` by github-actions), #313 (main <- weblate by nucleus-ffm, "Update translations", 2026-08-27), Sanmill #1051 (master <- weblate/flutter, open) all check out. Key counts: wger `app_ta.arb` 297/559; musicpod `app_nl.arb` 644 of 771 empty, `app_kk.arb` 771 of 771 empty. wger `analyze.yml` step "Check locale lists are in sync: dart run tool/check_locales.dart". Sanmill: `untranslated-messages-file` referenced only in `l10n.yaml`, no workflow reads it.
- #36, #37: re-clone of `hosted.weblate.org/git/opennutritracker/app/` at `afbad29 chore(l10n): update Swedish translation`: fr/hu/ru 900 keys, es 227, sv 10, pt_BR `{}`, no `intl_pt.arb`, no `@@locale`, 4-space indent; upstream `intl_en.arb` 1044 keys, 2-space. Statistics API: pt_BR 0.0, sv 1.1, es 25.1, fr/hu/ru 100.0, total 900 (the "quote" in #37 is a tuple rendering of the JSON, not page text).

### Gaps against the original question

1. **iOS `CFBundleLocalizations`**: no Apple source. The claim that Info.plist `CFBundleLocalizations` drives the iOS Settings language picker / App Store listing rests on this repo's test comment and wger's tool; the Flutter docs only describe the Xcode-UI route (`knownRegions` in `project.pbxproj`). Needs developer.apple.com (Information Property List -> `CFBundleLocalizations`).
2. **Links to `.weblate` and `l10n.yaml` per surveyed project**: the question asked for the actual files; component settings were taken from the Weblate API and only FluffyChat's/Sanmill's `l10n.yaml` contents are described, without URLs. None of the surveyed repos' `.weblate` files are linked.
3. **The named example apps** (Saber, LocalSend, Butterfly, Mindful, Ente, Immich) were excluded with one-line notes and no links showing why (e.g. Saber's `slang` setup, absence of `.weblate`/ARB in the others).
4. **Weblate `""` vs omitted keys**: why musicpod's ARBs carry `""` for untranslated units while this repo's export omits keys is unresolved (no Weblate doc cited).
5. **Runtime `lookupS` behaviour** for a locale in `supportedLocales` whose class exists is sourced; what iOS/Android *show* for a 1%-translated locale (i.e. that the OS picker lists it) is inferred from `isSupported`/`supportedLocales`, not demonstrated on a device.
