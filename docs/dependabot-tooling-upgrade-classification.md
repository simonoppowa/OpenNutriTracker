# Dependabot tooling upgrade classification

Research for [Classify Fastlane, Android json, and GitHub Actions upgrades](https://github.com/simonoppowa/OpenNutriTracker/issues/744), based on the proposed Dependabot versions rather than newer available versions.

## Decision

Fold the five effective upgrades into the single rollup PR. None requires a Fastfile, application-source, or workflow-input migration:

- Fastlane `2.238.0` for Android and iOS;
- `softprops/action-gh-release@v3`;
- `actions/setup-java@v5.6.0`;
- `dorny/paths-filter@v4`; and
- Android `json` `2.21.2`, **included through the Android Fastlane lockfile rather than by applying its separate PR**.

The rollup should not merge or cherry-pick [the standalone Android `json` PR](https://github.com/simonoppowa/OpenNutriTracker/pull/620). It targets `main`, while the rollup and the other proposals target `develop`, and its complete two-line semantic change is already present in [the Android Fastlane PR](https://github.com/simonoppowa/OpenNutriTracker/pull/692). Applying both creates avoidable same-file overlap without changing the resolved result. The iOS Fastlane lockfile independently resolves `json` to `2.21.2` as well.

This is migration-free but not release-test-free. Ordinary PR CI deliberately skips signed packaging, store deployment, and GitHub release creation, so the release-path preflight below remains required before promoting the rollup to a release.

## Classification by proposal

| Proposal | Fold into rollup? | Migration | Evidence and qualification |
| --- | --- | --- | --- |
| [Android Fastlane `2.237.0` → `2.238.0`](https://github.com/simonoppowa/OpenNutriTracker/pull/692) | Yes | No Fastfile changes | The lock regeneration is broad because Fastlane itself moves from Faraday 1 to Faraday 2 and updates Google API and terminal dependencies. The app has no Fastlane plugins or direct Faraday usage, and its Android lane only calls `upload_to_play_store` with documented parameters. The proposal also resolves `json` `2.21.2`, superseding the standalone Android lockfile PR. |
| [iOS Fastlane `2.237.0` → `2.238.0`](https://github.com/simonoppowa/OpenNutriTracker/pull/693) | Yes | No Fastfile changes | Upstream lists improvements rather than removals. Of the changed areas, this repo directly uses `setup_ci` and TestFlight upload; the `setup_ci` change is an additive option whose default preserves existing behavior, while `pilot` group matching is broadened. The repo does not use the changed `gym`, Catalyst, SPM, Crashlytics, or notarization paths. |
| [Android `json` `2.21.1` → `2.21.2`](https://github.com/simonoppowa/OpenNutriTracker/pull/620) | Yes, via Fastlane lock | No | Upstream says `2.21.2` only fixes a use-after-free in `JSON::ResumableParser`. It is a transitive Fastlane dependency, not an app dependency, and requires no call-site change. Do not apply this PR separately. |
| [`softprops/action-gh-release@v2` → `@v3`](https://github.com/simonoppowa/OpenNutriTracker/pull/607) | Yes | No workflow-input change | Version 3's breaking boundary is its Node 24 runtime. Its action metadata still defines the repo's `tag_name`, `name`, `generate_release_notes`, and newline-delimited `files` inputs. The repo uses only GitHub-hosted `ubuntu-latest` for this job, which is the upstream-recommended v3 environment. |
| [`actions/setup-java@v5` → `@v5.6.0`](https://github.com/simonoppowa/OpenNutriTracker/pull/606) | Yes | No | This is an exact tag within the already-adopted v5 major. `distribution` and `java-version` remain supported. Release `5.6.0` adds/backports matchers, cache output/handling, repeated-toolchain preservation, and JDK coverage; it does not announce an input migration. |
| [`dorny/paths-filter@v3` → `@v4`](https://github.com/simonoppowa/OpenNutriTracker/pull/605) | Yes | No workflow-input change | Upstream identifies the v4 breaking boundary as the move to Node 24. The v4 action metadata preserves `base` and `filters`, exactly the two inputs used here, and the repository uses a GitHub-hosted macOS runner. |

## Repository usage and overlap

The workflow uses `paths-filter` only in the PR-only iOS lockfile guard, with `base` plus an inline `filters` map ([workflow source](https://github.com/simonoppowa/OpenNutriTracker/blob/3f5f1a4541c7a5aa7dc9ef800fd37d17b43185fe/.github/workflows/default_workflow.yml#L88-L115)). It uses `setup-java` six times as identical Zulu-17 primary / Temurin-17 fallback pairs in Android build, integration, and package jobs ([build pair](https://github.com/simonoppowa/OpenNutriTracker/blob/3f5f1a4541c7a5aa7dc9ef800fd37d17b43185fe/.github/workflows/default_workflow.yml#L372-L397), [integration pair](https://github.com/simonoppowa/OpenNutriTracker/blob/3f5f1a4541c7a5aa7dc9ef800fd37d17b43185fe/.github/workflows/default_workflow.yml#L467-L484), [package pair](https://github.com/simonoppowa/OpenNutriTracker/blob/3f5f1a4541c7a5aa7dc9ef800fd37d17b43185fe/.github/workflows/default_workflow.yml#L747-L783)). All workflow runners in the repository are GitHub-hosted (`ubuntu-latest`, `macos-15`, or `macos-26`); there is no self-hosted runner fleet to migrate for Node 24.

Fastlane is used only in release-gated jobs. iOS invokes `ios build` for the signed IPA and `ios beta_from_ipa` for TestFlight; Android invokes `android internal` for the Play internal track ([workflow source](https://github.com/simonoppowa/OpenNutriTracker/blob/3f5f1a4541c7a5aa7dc9ef800fd37d17b43185fe/.github/workflows/default_workflow.yml#L583-L745), [Android deploy](https://github.com/simonoppowa/OpenNutriTracker/blob/3f5f1a4541c7a5aa7dc9ef800fd37d17b43185fe/.github/workflows/default_workflow.yml#L878-L915)). The [Android Fastfile](https://github.com/simonoppowa/OpenNutriTracker/blob/3f5f1a4541c7a5aa7dc9ef800fd37d17b43185fe/android/fastlane/Fastfile) contains only the Play upload lane. The [iOS Fastfile](https://github.com/simonoppowa/OpenNutriTracker/blob/3f5f1a4541c7a5aa7dc9ef800fd37d17b43185fe/ios/fastlane/Fastfile) uses stock Fastlane actions and has no plugins or direct HTTP-adapter dependency.

The GitHub release action is also release-gated and uses four inputs that v3 retains ([workflow source](https://github.com/simonoppowa/OpenNutriTracker/blob/3f5f1a4541c7a5aa7dc9ef800fd37d17b43185fe/.github/workflows/default_workflow.yml#L917-L970)). The three workflow PRs edit distinct lines of the same YAML file, so they are semantically composable even if mechanical cherry-picking needs normal same-file context resolution.

## Upstream compatibility findings

- [Fastlane 2.238.0's first-party release notes](https://github.com/fastlane/fastlane/releases/tag/2.238.0) enumerate improvements, including the internal Faraday 2 migration, an additive `setup_ci` option, broader `pilot` group matching, and Ruby 4 support. The [`setup_ci` source change](https://github.com/fastlane/fastlane/pull/30121) explicitly keeps `set_default_keychain: true` as the default, preserving this repo's parameterless `setup_ci` call. The [2.238.0 gemspec](https://github.com/fastlane/fastlane/blob/fastlane/2.238.0/fastlane.gemspec) retains Ruby `>= 3.0`, compatible with the workflow's Ruby `3.3`.
- [Ruby JSON 2.21.2's release](https://github.com/ruby/json/releases/tag/v2.21.2) contains the `JSON::ResumableParser` use-after-free fix and no API migration; the [first-party advisory](https://github.com/ruby/json/security/advisories/GHSA-9hj4-r449-hfvc) identifies `2.21.2` as the patched version.
- [`softprops/action-gh-release` 3.0.0](https://github.com/softprops/action-gh-release/releases/tag/v3.0.0) says the major release moves the runtime from Node 20 to Node 24 and directs GitHub-hosted users to v3. Its [v3 action metadata](https://github.com/softprops/action-gh-release/blob/v3/action.yml) retains all inputs used here and declares `node24`.
- [`actions/setup-java` 5.6.0](https://github.com/actions/setup-java/releases/tag/v5.6.0) is an additive/backport release inside v5. Its [action metadata](https://github.com/actions/setup-java/blob/v5.6.0/action.yml) retains `distribution` and `java-version`.
- [`dorny/paths-filter` 4.0.0](https://github.com/dorny/paths-filter/releases/tag/v4.0.0) changes the runtime to Node 24. Its [v4 action metadata](https://github.com/dorny/paths-filter/blob/v4/action.yml) retains `base` and `filters` and declares `node24`.
- GitHub's [Node 20 deprecation notice](https://github.blog/changelog/2025-09-19-deprecation-of-node-20-on-github-actions-runners/) confirms current GitHub-hosted runners support Node 24. Its runner-version warning applies to self-hosted fleets, which this repository does not use.

## CI evidence

The proposed [Android Fastlane run](https://github.com/simonoppowa/OpenNutriTracker/actions/runs/31975457627) and [iOS Fastlane run](https://github.com/simonoppowa/OpenNutriTracker/actions/runs/31975462995) passed Linux checks, both platform builds, and both integration suites. This is the strongest evidence for the effective Android `json` update too, because both regenerated Fastlane lockfiles resolve `json` `2.21.2`.

The [paths-filter run](https://github.com/simonoppowa/OpenNutriTracker/actions/runs/30769310433) and [action-gh-release run](https://github.com/simonoppowa/OpenNutriTracker/actions/runs/30769327409) passed all ordinary checks. The [setup-java run](https://github.com/simonoppowa/OpenNutriTracker/actions/runs/30769324477) passed both Android jobs (where the changed action executes); its iOS integration job was cancelled, which is unrelated to Java setup and should not be counted as positive evidence. The standalone [`json` run](https://github.com/simonoppowa/OpenNutriTracker/actions/runs/31317264334) likewise passed Android build/integration but had a cancelled iOS integration job; its evidence is superseded by the later, fully green Fastlane runs.

Every one of those PR runs skipped `ios-package`, `android-package`, `ios-deploy`, `android-deploy`, and `github-release`, because those jobs run only on a push to `main` or `workflow_dispatch` ([job conditions](https://github.com/simonoppowa/OpenNutriTracker/blob/3f5f1a4541c7a5aa7dc9ef800fd37d17b43185fe/.github/workflows/default_workflow.yml#L583-L586)). Green PR CI therefore proves compilation/integration and the normal Java/paths-filter action paths, but not the Fastlane lanes or release action.

## Required rollup and release-path verification

1. Build the rollup from the two Fastlane proposals, not from the standalone Android `json` proposal. Confirm both lockfiles contain Fastlane `2.238.0` and `json` `2.21.2`, and that Bundler remains `4.0.11` as recorded in the locks.
2. Run ordinary rollup PR CI. Because the rollup also changes `pubspec.yaml`/`pubspec.lock`, its iOS lockfile guard should exercise the positive `paths-filter` result, complementing the negative-path execution in the standalone workflow-only PR.
3. With Ruby `3.3` and Bundler `4.0.11`, run `bundle check` and `bundle exec fastlane lanes` once with `BUNDLE_GEMFILE=android/Gemfile` and once with `BUNDLE_GEMFILE=ios/Gemfile`. This verifies the regenerated dependency graphs load and both Fastfiles parse without touching stores.
4. Before promotion to `main`, perform a package-only iOS smoke using the release secrets and `bundle exec fastlane ios build`; verify the signed IPA artifact is produced. Android release packaging does not invoke Fastlane, but the rollup should still build the signed AAB/APK path with the pinned `setup-java@v5.6.0`.
5. Treat store uploads and GitHub release creation as a controlled canary, not a PR check: validate the exact `action-gh-release@v3` inputs with dummy assets in a disposable repository (or an explicitly disposable draft release), then monitor the next TestFlight and Play internal uploads. Do not use this repository's unrestricted `workflow_dispatch` merely as a smoke test: it runs both deployments and publishes the GitHub release after packaging.

No source migration ticket is needed. The implementation handoff is a single rollup with lockfile de-duplication and the release-path verification checklist above.
