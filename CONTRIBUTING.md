# Contributing to OpenNutriTracker

Thanks for taking an interest in contributing! This guide covers the conventions you need to follow so your pull request can be merged smoothly.

For environment setup (Flutter / Android SDK / IDE), see [GettingStarted.md](GettingStarted.md).

## Pull request target branch

**All pull requests must target the `develop` branch, not `main`.**

`main` is reserved for release merges only — it receives a single batched `develop → main` PR per release. If you open a PR against `main`, a maintainer will repoint it to `develop` before review.

## Before you start

- Create your branch from the latest `develop`:
  ```sh
  git fetch origin
  git checkout -b feature/<short-name> origin/develop
  ```
- Keep changes scoped. Smaller, focused PRs are easier to review and faster to merge than sweeping ones.
- If you are fixing or implementing an open issue, mention it in the PR description (e.g. `Closes #123`).

## Adding or changing localized strings

Source strings live in `lib/l10n/intl_en.arb`. Translations live in a separate ARB file per supported locale, plus manually-maintained Dart files under `lib/generated/`.

> [!IMPORTANT]
> **For now**, the files under `lib/generated/` carry a `// GENERATED CODE - DO NOT MODIFY BY HAND` header but are **maintained manually** in this project — the upstream generator's output conflicts with the repo's 120-character formatting and would fail CI. Until the generation pipeline is reconciled with the formatting rules, edit those files by hand. Do **not** run `intl_translation:generate_from_arb` — this caveat will go away once the generator output is fixed.

When adding a new string key in the same PR you must:

1. **Add the key to every ARB file** under `lib/l10n/`. The currently supported locales are:

   | File | Language |
   | --- | --- |
   | `intl_en.arb` | English (source) |
   | `intl_de.arb` | German |
   | `intl_cs.arb` | Czech |
   | `intl_it.arb` | Italian |
   | `intl_pl.arb` | Polish |
   | `intl_sk.arb` | Slovak |
   | `intl_tr.arb` | Turkish |
   | `intl_uk.arb` | Ukrainian |
   | `intl_zh.arb` | Chinese (Simplified) |

   Provide a real translation for each locale — do not leave the English string in as a placeholder. If you only speak one of the languages, machine translation is acceptable as a starting point; native-speaker review is welcome post-merge.

2. **Add a getter to `lib/generated/l10n.dart`**, following the existing style.

3. **Add a matching `MessageLookupByLibrary.simpleMessage(...)` entry to each `lib/generated/intl/messages_<locale>.dart` file**, one per locale.

4. **Verify with `just check_intl`** — this is what CI runs and will fail the PR if any of the above is missing or out of sync.

## Code generation

Some files are produced by `build_runner` (Hive type adapters and JSON serialization). Run `just build` after touching any `@HiveType`, `@HiveField`, or `@JsonSerializable` source file. See `CLAUDE.md` for the full list of triggers.

## Code style and tests

- 120-character line width (configured in `analysis_options.yaml`).
- Format with `just format` before committing — this targets only `lib/core`, `lib/features`, `lib/l10n`, and `test` and deliberately skips `lib/generated/`.
- Run `flutter analyze` and `just test` locally before opening the PR.
- `just ci` runs the full CI pipeline (install, format check, intl check, build, analyze, test) and is the closest thing to a one-shot pre-flight check.

## Commit messages

Use a short imperative subject line, optionally with a `type(scope):` prefix. Examples:

```
feat(activity): add high-intensity interval exercise
fix(home): correct kcal budget after onboarding
i18n(activity): wire HIIT codes 02210/02214 to translated strings
```

A body explaining the *why* is welcome but not required for small changes.

## Platform support

OpenNutriTracker ships on both iOS and Android. Any new dependency must support both platforms — check pub.dev before adding. Any platform-specific code must have a corresponding implementation for the other platform (or an explicit fallback). New runtime permissions on Android need a matching `Info.plist` entry on iOS, and vice versa.

## Questions

If you're unsure about anything, open a draft PR or an issue and ask — early feedback is much cheaper than reworking a finished change.
