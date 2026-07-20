# Contributing to OpenNutriTracker

Thanks for taking an interest in contributing! This guide covers the conventions you need to follow so your pull request can be merged smoothly.

For environment setup (Flutter / Android SDK / IDE), see [GettingStarted.md](GettingStarted.md).

Looking for a small first contribution? See the seed list in
[docs/first-timer-backlog.md](docs/first-timer-backlog.md) — concrete
“good first issue” ideas with file paths and acceptance criteria. Agent and
architecture conventions live in [AGENTS.md](AGENTS.md).

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

Source strings live in `lib/l10n/intl_en.arb`. Translations live in a separate ARB file per supported locale. The Dart bindings under `lib/generated/` are produced by Flutter's built-in `gen-l10n` tool (configured in `l10n.yaml`) — they are **gitignored** and regenerated on every `flutter run`/`flutter build`, or on demand with `just gen_l10n`. Never edit generated files by hand or commit them.

When adding a new string key in the same PR you must:

1. **Add the key to `lib/l10n/intl_en.arb`** (the template file). If the message has placeholders, declare them with types in an accompanying `@key` metadata entry, e.g. `"@yearsLabel": {"placeholders": {"age": {"type": "int"}}}`.

2. **Add the key to every other ARB file** under `lib/l10n/`. The currently supported locales are:

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

3. **Run `just gen_l10n`** and use the new key via `S.of(context).yourNewKey`. Keys missing from a locale ARB fall back to the English source string at generation time and are listed in `l10n_untranslated.json` (gitignored), so a forgotten translation won't break the build — but see rule 2.

## Code generation

Some files are produced by `build_runner` (Hive type adapters and JSON serialization). Run `just build` after touching any `@HiveType`, `@HiveField`, or `@JsonSerializable` source file. See `AGENTS.md` for the full list of triggers.

## Code style and tests

- 120-character line width (configured in `analysis_options.yaml`).
- Format with `just format` before committing — this targets only `lib/core`, `lib/features`, `lib/l10n`, and `test` and deliberately skips `lib/generated/`.
- Run `flutter analyze` and `just test` locally before opening the PR.
- `just ci` runs the full CI pipeline (install, format check, l10n generation, build, analyze, test) and is the closest thing to a one-shot pre-flight check.

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
