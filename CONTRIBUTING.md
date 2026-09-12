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

**The one exception: long-lived integration branches.** A feature too large for a single PR is staged on a `feature/**` branch, and its parts target *that* branch rather than `develop`; the branch itself then reaches `develop` as one PR. This is a maintainer arrangement — if you are contributing to one you will have been told, so target `develop` unless you have. Two things to know if you do work on one: CI is wired for `feature/**` in [`.github/workflows/default_workflow.yml`](.github/workflows/default_workflow.yml), so a PR targeting anything else gets **no checks at all while still reporting mergeable**; and issues do not auto-close on merge, because the closing keyword only fires against the default branch.

## Before you start

- Check the [public board](https://github.com/users/simonoppowa/projects/2) before picking something up — it shows what is already in progress, so you don't duplicate work that is underway.
- Create your branch from the latest `develop`:
  ```sh
  git fetch origin
  git checkout -b feature/<short-name> origin/develop
  ```
- Keep changes scoped. Smaller, focused PRs are easier to review and faster to merge than sweeping ones.
- If you are fixing or implementing an open issue, mention it in the PR description (e.g. `Closes #123`).

## Adding or changing localized strings

Source strings live in `lib/l10n/intl_en.arb`, with one ARB file per supported locale beside it. The Dart files under `lib/generated/` are produced from those ARBs by `flutter gen-l10n` (configured in `l10n.yaml`) — they are gitignored, and CI regenerates them from scratch on every run.

> [!IMPORTANT]
> Never hand-edit anything under `lib/generated/`. The directory is listed in `.gitignore`, so hand-edits are never committed, and the next `flutter gen-l10n` overwrites them locally — the work is lost silently. Edit the ARB files and regenerate.

When adding a new string key in the same PR you must:

1. **Add the key to every ARB file** under `lib/l10n/`. The currently supported locales are:

   | File | Language |
   | --- | --- |
   | `intl_en.arb` | English (source) |
   | `intl_de.arb` | German |
   | `intl_cs.arb` | Czech |
   | `intl_es.arb` | Spanish |
   | `intl_it.arb` | Italian |
   | `intl_pl.arb` | Polish |
   | `intl_sk.arb` | Slovak |
   | `intl_tr.arb` | Turkish |
   | `intl_uk.arb` | Ukrainian |
   | `intl_zh.arb` | Chinese (Simplified) |

   Provide a real translation for each locale — do not leave the English string in as a placeholder. If you only speak one of the languages, machine translation is acceptable as a starting point; native-speaker review is welcome post-merge.

   All ten files stay at the same key count. Placeholder metadata (`"@key": {"placeholders": ...}`) only needs to be declared in the template, `intl_en.arb`.

2. **Regenerate with `just gen_l10n`** (`flutter gen-l10n`). This rewrites `lib/generated/l10n.dart` and one `lib/generated/l10n_<locale>.dart` per locale, which is where your `S.of(context).yourNewKey` getter comes from. Nothing under `lib/generated/` belongs in the commit — the ARB files are the whole change.

3. **Leave no locale behind.** `flutter gen-l10n` exits 0 on a missing translation — it records the key in `l10n_untranslated.json` at the repo root (also gitignored) and the string falls back to English at runtime. `just check_l10n` is what turns that into a failure, and it is what CI runs; when it fails, that file names the locale and the key.

4. **Run `flutter analyze` and `just test`** before opening the PR — or `just ci` for the whole pre-flight in one go.

## Code generation

Some files are produced by `build_runner` (Hive type adapters and JSON serialization). Run `just build` after touching any `@HiveType`, `@HiveField`, or `@JsonSerializable` source file. See `AGENTS.md` for the full list of triggers.

## Code style and tests

- 80-character line width — `dart format`'s own default. `just format` passes no
  `--line-length`, and nothing in the repo configures one.
- Format with `just format` before committing — this targets only `lib/core`, `lib/features`, `lib/l10n`, and `test` and deliberately skips `lib/generated/`.
- Run `flutter analyze` and `just test` locally before opening the PR.
- `just ci` runs the full CI pipeline (install, format check, l10n generation and completeness, build, analyze, test) and is the closest thing to a one-shot pre-flight check.

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
