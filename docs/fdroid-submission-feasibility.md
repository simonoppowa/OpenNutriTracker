# F-Droid submission: feasibility review of issue #575

Research notes for [#575](https://github.com/simonoppowa/OpenNutriTracker/issues/575) ("Submit OpenNutriTracker to the F-Droid repository") and its parent [#126](https://github.com/simonoppowa/OpenNutriTracker/issues/126). Written against `feat/onboarding-rework` at version `2.0.2+61`, and against a shallow clone of [`fdroid/fdroiddata`](https://gitlab.com/fdroid/fdroiddata) at commit `b3626a167c61d17211c3be8e41a61a97c807ed5c` (2026-08-05). Every fdroiddata path below is relative to that repo.

## Verdict

**Blocked — but not on the thing the issue thread is worried about.**

The `fdcApiKey` that surfaced in the #575 discussion is a nuisance, not a blocker. F-Droid's Inclusion Policy has an explicit line for it, there is a working precedent in the repo for the exact same USDA API, and — as it turns out — the key is wired to dead code in this app anyway.

The actual blocker is **`mobile_scanner`**, which links `com.google.mlkit:barcode-scanning`. ML Kit is on F-Droid's non-free signature list with `"license": "NonFree"`, and fdroiddata's CI runs a binary scanner over the built APK that fails the pipeline when those classes are found. Barcode scanning is a headline feature of this app — it appears in `full_description.txt`, in the recipe builder, and in three separate import screens — so removing it is a product decision, not a packaging detail. That decision belongs to the maintainer, and #575 cannot be completed until it is made.

A second, smaller decision is also maintainer-only: the Supabase project URL and anon key must be published in the clear in fdroiddata, or the F-Droid build ships with a food-search backend that does not work.

Everything else — Flutter buildability, release identity, metadata reuse — is routine and well-precedented.

---

## 1. Inclusion Policy fit

The [current Inclusion Policy](https://f-droid.org/docs/Inclusion_Policy/) has four relevant clauses. Quoting the ones that bite:

> All binary dependencies including JAR files must originate either from source compilation or Debian repository downloads. Prebuilt binaries should only come from authorized trusted sources.

> The implementation of proprietary tracking or advertising libraries and analytics tools such as Google Play Services and Firebase and Crashlytics and proprietary ad/tracking SDKs are strictly forbidden in all applications. Upstream developers must implement either a FLOSS alternative or a build flavour that does not require these dependencies when such features become necessary.

> Non-functional assets including artwork and fonts can utilize less restrictive licenses which include game art specific to the project but must allow redistribution when using non-commercial licenses.

> The application should be functional and implement all the features described in the description.

I enumerated every hosted package in `pubspec.lock` (212 entries), resolved each against the local pub cache, and grepped its `android/**/*.gradle*` and `AndroidManifest.xml` files for Google/Firebase/GMS coordinates. Then I tested each hit against F-Droid's actual scanner signature database, [SUSS](https://fdroid.gitlab.io/fdroid-suss/suss.json), which `fdroidserver/scanner.py` loads at runtime (`scanner.py:553`).

| Finding | Where | Verdict |
| --- | --- | --- |
| `mobile_scanner` 7.2.0 → `com.google.mlkit:barcode-scanning:17.3.0` | `pubspec.yaml`, `pubspec.lock:983`; [`mobile_scanner@v7.2.0 android/build.gradle:60`](https://github.com/juliansteenbakker/mobile_scanner/blob/v7.2.0/android/build.gradle#L60) | **Hard blocker** |
| `sentry_flutter` → sentry.io crash reporting | `pubspec.yaml`, `lib/main.dart:152` | Anti-feature discussion (`Tracking`) |
| `supabase_flutter` → maintainer's managed Supabase project | `lib/core/utils/locator.dart:142-146` | Anti-feature flag (`NonFreeNet` and/or `TetheredNet`) |
| Bundled Unsplash demo photos | `assets/demo/`, `lib/core/utils/demo/unsplash_attribution.dart` | Anti-feature risk (`NonFreeAssets`) |
| `dynamic_color` → `com.google.android.material` | pub cache scan | Pass (Apache-2.0, not in SUSS) |
| `flutter_local_notifications` → `com.google.code.gson` | pub cache scan | Pass (Apache-2.0, not in SUSS) |
| `flutter_secure_storage` → `com.google.crypto.tink:tink-android` | pub cache scan | Pass (Apache-2.0, not in SUSS) |
| `image_picker_android` manifest `com.google.android.gms.metadata.ModuleDependencies` | pub cache scan | Probably pass — see below |
| No Firebase, no Crashlytics, no Play Services SDK, no ad SDK anywhere in the tree | full pub cache scan | Pass |
| Android manifest permissions: `INTERNET`, `RECEIVE_BOOT_COMPLETED`, `POST_NOTIFICATIONS` (+ `CAMERA` merged in from `mobile_scanner`) | `android/app/src/main/AndroidManifest.xml` | Pass — fdroiddata CI reports permissions at `info` severity only |
| License GPL-3.0, `LICENSE` at repo root, fonts under `fonts/OFL.txt` | `LICENSE`, `README.md:253` | Pass |

### The ML Kit blocker in detail

SUSS carries an entry for ML Kit:

```json
"com.google.mlkit": {
  "code_signatures": ["com/google/mlkit"],
  "gradle_signatures": ["com.google.mlkit", "io.github.g00fy2.quickie"],
  "license": "NonFree",
  "name": "ML Kit"
}
```

That signature is loaded into `err_gradle_signatures` and `err_code_signatures` (`fdroidserver/scanner.py:624-638`). The gradle half fires during `scan_source` on any `.gradle`/`.gradle.kts` file (`scanner.py:1067`) — which the plugin's own `android/build.gradle` inside `.pub-cache` would trip. That half can technically be worked around with `scandelete`. The code half cannot: `scan_binary` walks the built APK's dex classes and has no ignore mechanism at all (`scanner.py:665-680`), and fdroiddata's own pipeline runs it with `--exit-code` and turns every found class into a `critical` code-quality report:

```yaml
fdroid scanner --verbose --exit-code $file 2>&1 | tee result || {
  export EXITVALUE=1;
  for class in $(sed -n "s/.*DEBUG: Problem: found class '\(.*\)'/\1/p" result); do
    printf "\x1b[31mERROR Found $class in $file\x1b[0m\n";
```

(`fdroiddata/.gitlab-ci.yml`, "binary scanner" section.)

Two apps in fdroiddata use `mobile_scanner` upstream, and **both** strip it for F-Droid rather than shipping it:

- `metadata/info.zverev.ilya.every_door.yml:375` — `sed -i -e 's/^#f\|^ *mobile_scanner.*$//' pubspec.yaml`, then `mv lib/fields/helpers/qr_code.dart.fdroid lib/fields/helpers/qr_code.dart`. The `.fdroid` variant file is shipped by *upstream* (it exists in `Zverik/every_door` at `lib/fields/helpers/qr_code.dart.fdroid`).
- `metadata/com.nfcarchiver.banana_split.yml:28` — `sed -i -e '/mobile_scanner/d' pubspec.yaml`, then `mv lib/widgets/shard_scanner.dart.fdroid lib/widgets/shard_scanner.dart`, plus a separate `pubspec.lock.fdroid`.

So the established pattern is: upstream ships a parallel `.fdroid` source file and a stripped lockfile, and the recipe swaps them in. This app would need the same, across every scanner entry point — `lib/features/scanner/scanner_screen.dart`, `lib/features/recipes/presentation/screens/import_recipe_scanner_screen.dart`, `lib/features/home/presentation/screens/import_meal_scanner_screen.dart`, and `lib/features/home/presentation/screens/import_activity_scanner_screen.dart`.

That is not a trivial `sed`. It touches the QR-import path for meals, activities, and recipes, which is a documented export/import feature, and the barcode path, which `full_description.txt` advertises in two bullets ("Search, scan, or add straight as a number" and the whole "📷 Barcode scanner" line). The Inclusion Policy's quality bar — "The application should be functional and implement all the features described in the description" — means the F-Droid description would have to be trimmed to match a scanner-less build.

**The alternative is to replace `mobile_scanner` with a FOSS scanner for all builds.** `flutter_zxing` is MIT-licensed, wraps the ZXing C++ library through FFI/CMake, and pulls no Google dependency ([LICENSE](https://github.com/khoren93/flutter_zxing/blob/main/LICENSE), [android/build.gradle](https://github.com/khoren93/flutter_zxing/blob/main/android/build.gradle) — CMake `externalNativeBuild`, no `implementation 'com.google...'` line). It already builds in fdroiddata: `metadata/business.braid.polycule.yml:50` uses it, with one reproducibility workaround worth copying (`add_link_options("LINKER:--build-id=none")` injected into its `CMakeLists.txt`). Swapping the dependency wholesale is more work up front but removes the fork-maintenance burden of `.fdroid` variant files forever, and it would let the F-Droid listing carry the same feature set and the same description as everywhere else.

### The lesser flags

**Sentry.** `sentry_flutter` is itself FLOSS and is not in SUSS, so the scanner will not object. But `sentry.io` is a proprietary network service and F-Droid routinely attaches `Tracking` for it — `metadata/com.infomaniak.drive.yml:1-6` reads:

```yaml
AntiFeatures:
  Tracking:
    en-US: Uses Sentry for analytics, which is enabled by default.
```

This app is in a better position than kDrive: Sentry only initialises when `kReleaseMode && hasAcceptedAnonymousData` (`lib/main.dart:114-120`), so it is opt-in and default-off. A reviewer may accept that without a flag; I could not find a policy sentence that settles it either way, so expect a conversation. If it becomes contentious, the clean fix is the same one kDrive uses — strip Sentry in the recipe (`sed -i -e '/sentry/d'`) and ship the F-Droid build without crash reporting.

**Supabase.** The app initialises Supabase unconditionally at startup and routes the entire "Food" search tab through it (`lib/features/add_meal/data/data_sources/sp_food_data_source.dart`). The backend code is open (`OpenNutriTracker-Backend`) but the instance is a single managed Supabase cloud project run by the maintainer — see `docs/supabase-self-hosting.md`. That maps to `TetheredNet` ("depends entirely on a certain instance of a network service") and arguably `NonFreeNet` per the [Anti-Features list](https://f-droid.org/docs/Anti-Features/). `metadata/info.zverev.ilya.every_door.yml:1-7` carries both for less than this. Expect at least one of them. It is a label, not a rejection.

**Unsplash demo assets.** `assets/demo/meals/` and `assets/demo/alex_demo_avatar.jpg` ship JPEGs under the [Unsplash License](https://unsplash.com/license), which grants copy/modify/distribute rights but adds a field-of-use carve-out: "This license does not include the right to compile images from Unsplash to replicate a similar or competing service." A field-of-use restriction fails DFSG §6 and OSD §6, so these are not free assets. The Inclusion Policy is lenient here — non-functional assets only "must allow redistribution" — so this is unlikely to block inclusion, but it is a plausible `NonFreeAssets` flag and the reviewer will ask. Worth pre-empting in the MR description.

**`image_picker_android`.** Its manifest declares `<meta-data android:name="com.google.android.gms.metadata.ModuleDependencies">` for the Android Photo Picker module. SUSS's `com.google.android.gms` entry would match that string, but the gradle scan only reads `.gradle`/`.gradle.kts` files and only lines that look like Gradle dependency declarations (`scanner.py:1067`, `is_used_by_gradle_without_catalog`), and the binary scan matches dex *class* names, not manifest attributes. I believe this is a non-issue; I did not find a fdroiddata app that had to strip `image_picker` for it, which supports that reading, but I have not verified it against an actual scanner run.

---

## 2. The API key problem

Short answer: **the API key is not the blocker, and for `FDC_API_KEY` specifically it is not even needed at runtime.**

### Where the key enters the build

`lib/core/utils/env.dart` declares four compile-time secrets through [`envied`](https://pub.dev/packages/envied):

```dart
@Envied(path: '.env')
abstract class Env {
  @EnviedField(varName: 'FDC_API_KEY', obfuscate: true)
  static final String fdcApiKey = _Env.fdcApiKey;
  @EnviedField(varName: 'SENTRY_DNS', obfuscate: true)
  static final String sentryDns = _Env.sentryDns;
  @EnviedField(varName: 'SUPABASE_PROJECT_URL', obfuscate: true)
  static final String supabaseProjectUrl = _Env.supabaseProjectUrl;
  @EnviedField(varName: 'SUPABASE_PROJECT_ANON_KEY', obfuscate: true)
  static final String supabaseProjectAnonKey = _Env.supabaseProjectAnonKey;
}
```

`env.g.dart` is gitignored (`.gitignore`, "# API Keys" block), so `dart run build_runner build` must regenerate it, and it needs a `.env`. That is exactly what the contributor hit.

The failure mode is worth being precise about, because it determines the fix. `requireEnvFile` defaults to `false` (`envied_generator-1.3.8/lib/src/generator.dart:93-94`), so a *missing* `.env` is silently tolerated. What actually throws is `allowOptionalFields` also defaulting to false: any field whose variable resolves to null raises `Environment variable not found for field ...` (`envied_generator-1.3.8/lib/src/generate_field.dart:28-33`). So the build needs a `.env` containing all four keys with *some* value. It does not need real ones to compile.

The repo already knows this. `.github/workflows/default_workflow.yml:40-47` writes a stub for every CI job:

```yaml
- name: Generate stub .env for CI
  uses: ./.github/actions/write-env-file
  with:
    fdc_api_key: ci-stub
    sentry_dns: https://stub@sentry.io/0
    supabase_project_url: https://stub.supabase.co
    supabase_project_anon_key: ci-stub
```

### What F-Droid does about secrets

The Inclusion Policy is explicit:

> F-Droid does not sign up for any API keys. Even if provided by a third party, we include them in both binary and source code releases.

So there is no secret store, no CI variable, no mechanism. Either the upstream developer supplies the value and it is committed in the clear to the public `fdroiddata` metadata, or the build gets a dummy. There is nothing in between.

That is not theoretical. **`metadata/com.flasskamp.energize.yml` — a Flutter nutrition tracker already in F-Droid, using the same USDA FoodData Central API — writes a literal USDA key into `.env` inside the recipe** (`metadata/com.flasskamp.energize.yml:470`, repeated in every one of its 33 build blocks):

```yaml
build:
  - export PUB_CACHE=$(pwd)/.pub-cache
  - echo "API_KEY_USDA='...'" > .env
  - echo "COPYRIGHT_NAME='Christian Flaßkamp'" >> .env
  ...
  - submodules/flutter/bin/flutter pub run build_runner build --delete-conflicting-outputs
  - submodules/flutter/bin/flutter build apk --split-per-abi --target-platform="android-arm"
```

This is the precedent to point the contributor at. It is a near-exact template for OpenNutriTracker's problem, from the same domain.

Note also that `obfuscate: true` gives no protection here. `envied`'s obfuscation is a compile-time XOR against a generated key list, both of which are embedded in `env.g.dart` and therefore in the APK. Anyone who wants the values from an existing Play Store or GitHub build already has them.

### Does the key matter at runtime?

**`FDC_API_KEY`: no.** The direct FoodData Central client is dead code in 2.x. `FDCDataSource.fetchSearchWordResults` is the only reader of `Env.fdcApiKey` (`lib/features/add_meal/data/data_sources/fdc_data_source.dart:19`). It is reached only via `ProductsRepository.getFDCFoodsByString` (`lib/features/add_meal/data/repository/products_repository.dart:105`), and a repo-wide grep finds **zero callers** of that method. The FDC tab now goes through Supabase — `SearchProductsUseCase.searchFDCFoodByString` calls `_productsRepository.getSupabaseFoodsByString` (`lib/features/add_meal/domain/usecase/search_products_usecase.dart:71-86`). `FDCDataSource` is still registered in the locator (`lib/core/utils/locator.dart:527`) and injected into `ProductsRepository`, which is why it still compiles and still forces the key.

A stub `FDC_API_KEY` therefore costs the F-Droid build nothing. (Separately: this looks like genuine dead code that could just be deleted, which would remove the whole question. That is out of scope for #575 but worth raising.)

**`SUPABASE_PROJECT_URL` / `SUPABASE_PROJECT_ANON_KEY`: yes, critically.** `Supabase.initialize` runs unconditionally during `initLocator` (`lib/core/utils/locator.dart:142-146`), and the entire multi-source food database — USDA, BLS, and the localized translation table — is served from it. With stub values, the "Food" tab returns nothing on every query. Open Food Facts still works: `OFFDataSource` sends only a User-Agent and no key (`lib/features/add_meal/data/data_sources/off_data_source.dart:90`). So a stubbed F-Droid build degrades to *OFF-only search* — usable, but visibly worse than the Play/GitHub build, and half of what `full_description.txt` promises.

Failure is graceful, at least: `SearchProductsUseCase._safeRemoteCall` catches and returns an empty list, and `SpFoodDataSource` retries and then errors into the same path. The app will not crash; it will just find nothing.

**`SENTRY_DNS`: no.** A stub DSN is fine — the Sentry client is only constructed under opt-in consent, and a build with a dud DSN simply drops events.

### So the decision is

The maintainer must choose, and only the maintainer can:

1. **Publish the Supabase URL + anon key in the fdroiddata recipe.** Both are already in every shipped APK, and the anon key is designed to be public (row-level security is the boundary, not secrecy). This is what Energize did with its USDA key. Cost: the values become greppable in a public GitLab repo, which raises the odds of scripted abuse against the free-tier Supabase project.
2. **Ship stubs and accept an OFF-only F-Droid build.** Cost: a materially worse app on F-Droid, plus a description that has to be rewritten to match.

Option 1 is the right call, but it is a hosting-cost and abuse-surface question, not an engineering one.

---

## 3. Flutter buildability in fdroiddata

F-Droid builds a lot of Flutter — 482 of the 8,987 metadata files mention it. There is no magic; recipes are hand-written `prebuild:`/`build:` shell.

### How the Flutter SDK gets in

Two conventions, both in wide use:

- **`srclibs: - flutter@<ref>`.** `srclibs/flutter.yml` is one line — `RepoType: git` / `Repo: https://github.com/flutter/flutter.git` — and the ref after `@` is checked out. Across fdroiddata: `flutter@stable` appears 3,434 times, with pinned tags (`flutter@3.3.2`, `flutter@3.10.6`, …) making up most of the rest. The SDK is then referenced as `$$flutter$$/bin/flutter`.
- **An upstream git submodule**, with `submodules: true`. This is what the contributor's example and Energize do.

The contributor named `metadata/studip_uni_passau.femtopedia.de.unipassaustudip.yml`. Its structure, quoted in full for the build section:

```yaml
Builds:
  - versionName: 2.1.3
    versionCode: 213
    commit: 9dd94328ca0d4df137c826a11e7d6db43c924c41
    submodules: true
    sudo:
      - mkdir -p /home/runner/work/studipassau
      - chown -R vagrant /home/runner
    output: build/app/outputs/flutter-apk/app-release.apk
    rm:
      - ios
    prebuild:
      - export repo=/home/runner/work/studipassau/studipassau
      - cd ..
      - mv studip_uni_passau.femtopedia.de.unipassaustudip $repo
      - pushd $repo
      - export PUB_CACHE=$(pwd)/.pub-cache
      - .flutter/bin/flutter config --no-analytics
      - .flutter/bin/flutter pub get --enforce-lockfile
      - popd
      - mv $repo studip_uni_passau.femtopedia.de.unipassaustudip
    scanignore:
      - .flutter/bin/cache
    scandelete:
      - .flutter
      - .pub-cache
    build:
      - export repo=/home/runner/work/studipassau/studipassau
      - cd ..
      - mv studip_uni_passau.femtopedia.de.unipassaustudip $repo
      - pushd $repo
      - export PUB_CACHE=$(pwd)/.pub-cache
      - .flutter/bin/dart run intl_utils:generate
      - .flutter/bin/dart run build_runner build
      - .flutter/bin/flutter build apk --release
      - popd
      - mv $repo studip_uni_passau.femtopedia.de.unipassaustudip

AllowedAPKSigningKeys: f17448cfb1bd29bc4b29932de068feab87175654dfac0e1a48605f2aeecebaef
AutoUpdateMode: Version
UpdateCheckMode: Tags
UpdateCheckData: pubspec.yaml|version:\s.+\+(\d+)|.|version:\s(.+)\+
```

Three things to read out of it. The `.flutter` submodule is upstream's SDK pin. The `mv`-into-`/home/runner/work/...`-and-back dance exists purely to make the build path match upstream's GitHub Actions working directory — [Reproducible Builds](https://f-droid.org/docs/Reproducible_Builds/) names this explicitly: "Embedded build paths are a source of reproducibility issues affecting apps built with e.g. Flutter". And it runs `dart run build_runner build`, so codegen in the recipe is normal and expected.

Note this app has **no** Flutter submodule. `.fvmrc` pins `{"flutter": "3.44.6"}`, which FVM understands and F-Droid does not. Tag `3.44.6` does exist in `flutter/flutter` (`ee80f08bbf97172ec030b8751ceab557177a34a6`), so `srclibs: - flutter@3.44.6` is the right translation. Keeping it in sync with `.fvmrc` is manual, per release.

The Inclusion Policy blesses the prebuilt SDK explicitly: "The Android SDK, Flutter SDK and Hermes have permission to use official prebuilt binaries until Debian provides alternative solutions" — which is why `scanignore: <flutter>/bin/cache` is the standard incantation.

### What makes this repo's build non-trivial

**Flavors.** `android/app/build.gradle` defines a `version` dimension with `develop` (`applicationIdSuffix ".develop"`) and `full` (no suffix). There is no default, so the recipe must pass `--flavor full` — which is what the release job does (`.github/workflows/default_workflow.yml:850`). This also changes the output path: Gradle writes `build/app/outputs/apk/full/release/app-release.apk` (renamed by the `applicationVariants.all` block), while Flutter's post-build copy lands at `build/app/outputs/flutter-apk/app-full-release.apk`. The CI comment at `default_workflow.yml:864-872` spells this out. Either path works as `output:`; the Gradle one is more stable.

**The signing config is unconditional.** `android/app/build.gradle` reads `android/key.properties` and then sets `buildTypes.release.signingConfig = signingConfigs.release` with no guard. F-Droid has no keystore. The repo's own CI confirms the consequence — `default_workflow.yml:427` says "`--release` would need a keystore which CI doesn't have; `--debug` …" and the non-release Android job builds `--debug` for that reason. The recipe will need to strip it, the way `metadata/app.simple.peri.yml:648` does (`sed -i -e '/signingConfigs/,+1d' build.gradle`). This should be verified by an actual build rather than taken on faith.

**Codegen.** `dart run build_runner build` is mandatory — it produces `env.g.dart`, Hive adapters, and JSON serializers — and `flutter gen-l10n` is mandatory too, since `lib/generated/` is gitignored (`justfile`, `gen_l10n` recipe; `.gitignore`). Both are ordinary recipe steps (Energize and studip both do exactly this).

**NDK.** `android/app/build.gradle` sets `ndkVersion flutter.ndkVersion`, which for 3.44.6 resolves to `28.2.13676358` (`flutter_tools/gradle/src/main/kotlin/FlutterExtension.kt:42`). `fdroidserver` supports this through the `ndk:` build field and `auto_install_ndk()` (`fdroidserver/common.py`), so it is a one-line addition, not a blocker.

**Java.** `compileOptions` and `kotlinOptions` want JVM 17; AGP is 8.11.1 and Gradle 8.14 (`android/settings.gradle`, `android/gradle/wrapper/gradle-wrapper.properties`). The buildserver installs `default-jdk-headless` and selects the highest available (`buildserver/provision-apt-get-install`), which on current Debian is 21 — fine for `sourceCompatibility 17`. If it is not, a `sudo:` block pinning a JDK is the standard fix; 5,357 build blocks in fdroiddata already do it for 17.

**APK size.** The published universal APK is ~100 MB (`gh release view v2.0.2`). I found no documented size limit in `fdroidserver`. Most Flutter recipes use `--split-per-abi` with `VercodeOperation` anyway (Energize: `10 * %c + 1/2/3`). Careful: Flutter sets `versionCodeOverride = abiVersionCode * 1000 + base` when splitting (`FlutterPlugin.kt:669-671`), *and* this repo's `applicationVariants.all` rename block forces every `full`-flavor output to the same filename `app-release.apk`, which would collide across ABI splits. Splitting is possible but needs that block neutered. A universal APK is the simpler first submission.

**Native deps.** None beyond what Flutter itself ships — no plugin in the tree has an `externalNativeBuild`. (That changes if `flutter_zxing` replaces `mobile_scanner`; it builds ZXing C++ via CMake, hence polycule's `--build-id=none` workaround.)

---

## 4. Release identity

| Field | Value | Source |
| --- | --- | --- |
| Latest stable tag | `v2.0.2` (2026-08-02) | `gh release list` |
| `versionName` | `2.0.2` | `pubspec.yaml:19` |
| `versionCode` | `61` | `pubspec.yaml:19` |
| `applicationId` | `com.opennutritracker.ont.opennutritracker` | `android/app/build.gradle` (`full` flavor, no suffix) |
| Release APK asset | `app-release.apk`, ~100 MB, at `.../releases/download/v2.0.2/app-release.apk` | `gh release view v2.0.2` |
| Signing cert SHA-256 | `84e86074ec7edabb10f2017986ddf09e531caf7a73080ac1172b80c49c620827` | `README.md:157`, `docs/site/release-info.json` |
| Tag objects | Lightweight commits, **not** annotated or GPG-signed | `git cat-file -t v2.0.2` → `commit` |

Version codes are monotonic across the tags that matter — I checked `pubspec.yaml` at every 1.3+ tag and got 49, 50, 56, 57, 58, 59, 60, 61 in order. (The GitHub *release titles* for v1.4.0/v1.4.1 say "build 701"/"build 703", which contradicts `pubspec.yaml`'s 56/57 and the release workflow's lack of `--build-number`. I did not download those APKs to settle it; it does not affect anything going forward.)

Tag naming is historically inconsistent (`v.1.3.0`, `v1.3.2+53-build.629`) but has been clean `vX.Y.Z` since v1.4.0.

**Recommendation:**

```yaml
UpdateCheckMode: Tags
UpdateCheckData: pubspec.yaml|version:\s.+\+(\d+)|.|version:\s(.+)\+
AutoUpdateMode: Version
CurrentVersion: 2.0.2
CurrentVersionCode: 61
```

That `UpdateCheckData` is the literal example the [Build Metadata Reference](https://f-droid.org/docs/Build_Metadata_Reference/) gives for "Flutter app with the pubspec.yaml in the repo root", and it is what both Energize and studip use. `AutoUpdateMode: Version` with no pattern is correct here because with `UpdateCheckMode: Tags` "the checked tag is used directly", so the historic `v.1.3.x` oddities do not matter.

**On reproducible builds / `Binaries`:** do not attempt this for the first submission. Verified builds would require (a) the exact same four `.env` values as the release build, byte for byte, (b) mirroring GitHub Actions' `/home/runner/work/OpenNutriTracker/OpenNutriTracker` working directory to defeat Flutter's embedded build paths, and (c) matching the AGP/NDK/apksigner versions. The `AllowedAPKSigningKeys` value is available if it is ever wanted, but the pragmatic path is an F-Droid-signed build. The cost of that is real and should be stated in #575: **F-Droid-signed APKs cannot upgrade an existing Play Store or GitHub install** — users switching have to uninstall and lose local data unless they export first.

Category: `Diet` and `Sports & Health` both exist in `config/categories.yml`; Energize uses both.

---

## 5. Metadata reuse

F-Droid reads `fastlane/metadata/android/<locale>/` straight out of the app's source repo — it is one of the two supported structures, and the docs actively prefer it ("strongly encouraged", and "the only way to provide images"). It checks out the latest release tag and scans at that state. So the existing directory is usable as-is, with gaps.

Against the [documented requirements](https://f-droid.org/docs/All_About_Descriptions_Graphics_and_Screenshots/):

| Requirement | Present | Status |
| --- | --- | --- |
| `short_description.txt`, max 80 chars, mandatory | 76 chars | Pass |
| `full_description.txt`, max 4000 chars, mandatory | 3,570 chars | Pass |
| `title.txt`, max 50 chars | 16 chars | Pass |
| `images/icon.png` | 512×512 | Pass |
| `images/featureGraphic.png` | 512×250 | Works; half the documented "usually 1024×500" |
| `images/phoneScreenshots/*.png` | 6 × 1432×2856 | Pass (well under `Image.MAX_IMAGE_PIXELS` = 4096×4096, `update.py:72`) |
| `changelogs/<versionCode>.txt`, max 500 chars | only `12.txt` | **Gap** |
| At least one locale beyond en-US | none | **Gap** for the Latest tab |
| No prohibited HTML tags in description | plain text + emoji only | Pass |

Two concrete problems:

**The changelog is eight years of releases stale.** `fastlane/metadata/android/en-US/changelogs/12.txt` contains ` * Initial Fdroid release` — someone started this work long ago. Current `versionCode` is 61. F-Droid names changelog files by version code "literally, no padding", so it will find nothing for the shipping release. This also costs the Latest tab, whose criteria are: Name, Icon, Summary, Description, License, "a What's New entry for at least one release", at least one graphic, **and at least one of the above translated**. With only `en-US` and only `12.txt`, the app fails two of eight.

Fix: add `61.txt` (and keep adding one per release — this belongs in `RELEASE.md`), and add at least one translated locale directory. The app already ships many locales in `lib/l10n/`, so a translated `short_description.txt` + `full_description.txt` + `changelogs/61.txt` for, say, `de` would clear it.

**`playstore_banner.png` and `appstore_banner.png` are ignored.** `update.py:111` recognises only `featureGraphic`, `icon`, `promoGraphic`, `tvBanner`. Harmless, just dead weight in F-Droid's eyes.

One thing #575 gets right and is worth repeating: do **not** commit F-Droid build metadata to this repo. The `fastlane/` directory is the correct and only place this repo participates.

---

## 6. Verdict on #575 as written

**Scoping: mostly good. The acceptance criteria are in the right order and the "don't commit fdroiddata metadata here" note is correct.** But the issue is mislabelled as a good first issue, and the checklist has three problems.

**It omits the ML Kit blocker entirely.** Criterion 1 says "document any blockers in this issue", which technically covers it, but a first-time contributor reading the list would reasonably expect that step to be a paperwork exercise. It is not — it terminates the task. Every subsequent checkbox is unreachable until the maintainer decides what happens to barcode scanning. This should be hoisted to the top of the issue as a stated precondition.

**It assumes an MR is the entry point.** `fdroiddata/CONTRIBUTING.md` says: "If you are a 'first time' contributor, consider opening an issue at [RFP (Request for Packaging)]". More to the point, **[RFP #2540 for OpenNutriTracker already exists](https://gitlab.com/fdroid/rfp/-/issues/2540)**, filed 2023-09-11, still open, and untouched since the day it was created (`updated_at` is 5 minutes after `created_at`; the only activity is `fdroid-bot`'s auto-labelling: `flutter`, `dart`, `gradle`, `kotlin`, `fastlane`, `in-google-play`, `insecure-gradlew`, `license`). The issue should reference it. Reviving that RFP is a cheaper and more socially correct first move than a cold MR, and it is where a maintainer's "yes, we want this" carries weight.

**"Configure the Flutter build and automatic update checks using stable release tags" understates the build work.** Between the flavor, the unconditional signing config, two codegen steps, an unpinned SDK (`.fvmrc` means nothing to F-Droid), the NDK pin, and a 100 MB universal APK, this is several hours of iteration against fdroiddata CI even once the dependency question is settled.

**What #575 gets right:** reusing `fastlane/metadata/android/`, keeping F-Droid metadata out of this repo, running `fdroid lint`/`rewritemeta`, and linking back to #126.

**The decisions only the maintainer can make:**

1. **Barcode scanning.** Replace `mobile_scanner` with `flutter_zxing` everywhere (my recommendation — one dependency swap, no permanent fork, F-Droid gets feature parity), or maintain `.fdroid` source variants and ship a scanner-less F-Droid build with a trimmed description. There is no third option that keeps ML Kit.
2. **The Supabase credentials.** Publish the project URL and anon key in public fdroiddata metadata (following Energize's precedent), or ship stubs and accept an Open-Food-Facts-only F-Droid build.
3. **Sentry**, if a reviewer objects: accept a `Tracking` anti-feature, or strip it from the F-Droid build.
4. **Signing stance**: F-Droid-signed (simple, but no upgrade path from existing installs) versus reproducible/`Binaries` (preserves the signature, but Flutter build-path reproducibility is a project of its own).

---

## Recommended next steps

1. **Decide #1 and #2 above.** Nothing else is worth starting first.
2. **Delete the dead FDC client** — `FDCDataSource`, `ProductsRepository.getFDCFoodsByString`, the `FDC_API_KEY` field in `Env`, and its locator registration. It has no callers, and removing it retires one of the four build-time secrets outright. Separate PR in this repo.
3. **Fix the fastlane gaps** in this repo: add `changelogs/61.txt`, add a translated locale, and add "write the changelog file" to `RELEASE.md` so it does not drift again. Separate PR.
4. **Revive [RFP #2540](https://gitlab.com/fdroid/rfp/-/issues/2540)** with a current status comment, rather than opening a cold MR.
5. **Prototype the recipe locally** with `fdroid build --test`, starting from `metadata/com.flasskamp.energize.yml` as the shape and `metadata/studip_uni_passau.femtopedia.de.unipassaustudip.yml` as the Flutter-idiom reference. Sketch:

   ```yaml
   Builds:
     - versionName: 2.0.2
       versionCode: 61
       commit: <full sha of v2.0.2>
       srclibs:
         - flutter@3.44.6
       ndk: '28.2.13676358'
       output: build/app/outputs/apk/full/release/app-release.apk
       rm:
         - ios
         - integration_test
       prebuild:
         - sed -i -e '/signingConfig signingConfigs.release/d' android/app/build.gradle
         - export PUB_CACHE=$(pwd)/.pub-cache
         - $$flutter$$/bin/flutter config --no-analytics
         - $$flutter$$/bin/flutter pub get --enforce-lockfile
       scanignore:
         - $$flutter$$/bin/cache
       scandelete:
         - .pub-cache
       build:
         - export PUB_CACHE=$(pwd)/.pub-cache
         - echo "FDC_API_KEY='...'" > .env
         - echo "SENTRY_DNS='...'" >> .env
         - echo "SUPABASE_PROJECT_URL='...'" >> .env
         - echo "SUPABASE_PROJECT_ANON_KEY='...'" >> .env
         - $$flutter$$/bin/flutter gen-l10n
         - $$flutter$$/bin/dart run build_runner build --delete-conflicting-outputs
         - $$flutter$$/bin/flutter build apk --release --flavor full
   ```

   This is a starting point, not a working recipe — in particular the `signingConfig` sed, the `scanignore` path form for a srclib, and the `output:` path all need to be confirmed by an actual build.
6. **Re-scope #575** with the ML Kit precondition at the top, a pointer to RFP #2540, and the maintainer decisions listed as blockers. Consider dropping the good-first-issue label until decisions 1 and 2 are made; after that, the remaining work genuinely is approachable.

---

## Open questions / unverified

- **I did not run a build.** Every claim about what the recipe needs to patch — the `signingConfig` strip in particular — is inferred from reading `android/app/build.gradle` and the repo's own CI comment at `default_workflow.yml:427`, not from a failing build log. AGP's exact behaviour with a `signingConfig` whose `storeFile` is null was not tested.
- **`image_picker_android`'s GMS manifest metadata.** My reading of `scanner.py` says manifest attributes are not scanned by either the gradle or the binary signature path, so it should pass. Not confirmed against a real scanner run.
- **Whether Sentry draws a `Tracking` flag when it is opt-in and default-off.** kDrive's flag text explicitly says "enabled by default", implying default-off might be treated differently, but I found no policy text or counter-example that settles it.
- **Whether `NonFreeAssets` gets applied to the bundled Unsplash photos.** The policy's non-functional-assets clause is lenient enough that it may not; the license's field-of-use restriction is real either way.
- **RFP #2540's discussion.** The GitLab notes API returned `401 Unauthorized` for an anonymous request, so I could only read the issue body and its `updated_at`. The timestamps strongly suggest there is no human discussion on it, but I have not read the comments.
- **`CustomIcons.ttf` provenance.** `fonts/OFL.txt` covers Poppins and Nunito. I could not determine where `fonts/CustomIcons.ttf` came from or under what licence. Worth pinning down before a reviewer asks.
- **The v1.4.x versionCode discrepancy** (release titles say 701/703, `pubspec.yaml` says 56/57). Not resolved; irrelevant going forward but noted in case someone trips over it.
- **APK size limits.** I found none documented in `fdroidserver` or `fdroiddata/.gitlab-ci.yml`. A 100 MB APK may still draw a reviewer comment.
- **Flutter 3.44.6's exact `flutter build apk` behaviour with two flavors and no `--flavor`.** I assumed it fails or is ambiguous based on the repo always passing `--flavor full`; not tested.
