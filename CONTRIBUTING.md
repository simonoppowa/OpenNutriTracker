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

Source strings live in `lib/l10n/intl_en.arb`. Every other `lib/l10n/intl_<code>.arb` is written by translators on [Hosted Weblate](https://hosted.weblate.org/projects/opennutritracker/app/) and comes back into this repository as pull requests — a code PR does not edit those files. The Dart files under `lib/generated/` are produced from the ARBs by `flutter gen-l10n` (configured in `l10n.yaml`) — they are gitignored, and CI regenerates them from scratch on every run.

> [!IMPORTANT]
> Never hand-edit anything under `lib/generated/`. The directory is listed in `.gitignore`, so hand-edits are never committed, and the next `flutter gen-l10n` overwrites them locally — the work is lost silently. Edit the ARB files and regenerate.

When adding or changing a string in a code PR:

1. **Edit `intl_en.arb` only.** Add the key and its English text, plus `"@key": {"placeholders": ...}` metadata for any placeholder it uses. That is the whole localization change. Until translators fill the key on Weblate, the app shows the English text in every other language — expected, and CI does not fail on it.

2. **Regenerate with `just gen_l10n`** (`flutter gen-l10n`). This rewrites `lib/generated/l10n.dart` and one `lib/generated/l10n_<locale>.dart` per locale, which is where your `S.of(context).yourNewKey` getter comes from. Nothing under `lib/generated/` belongs in the commit.

3. **`just check_l10n`** is what CI runs. It fails only on what the English fallback cannot absorb: an ARB that `flutter gen-l10n` rejects (malformed JSON, a locale code it cannot parse, a region file without its base language, unparseable ICU syntax) or an empty (or whitespace-only) `""` translation, which would render as a blank label. Untranslated keys are listed per locale in the CI job summary as information, never as a failure.

4. **Run `flutter analyze` and `just test`** before opening the PR — or `just ci` for the whole pre-flight in one go.

### Which languages the app ships

An ARB in `lib/l10n/` is not a shipped language — Weblate lands files while they are still being translated. The app ships exactly the languages listed in [`lib/core/l10n/shipped_locales.dart`](lib/core/l10n/shipped_locales.dart): that map drives locale resolution, the in-app language picker and, through `tool/check_locales.dart`, the iOS and Android per-app language lists (`Info.plist`, `locales_config.xml`). A language that is present but not listed is compiled and inert; a device set to it sees English.

To ship a language once it is about 90 % translated on Weblate: add `'<code>': '<native name>'` to `shipped_locales.dart`, run `dart run tool/check_locales.dart --fix`, commit. Nothing else to edit — `just test` fails if any of the lists drift. Codes are bare language codes (`pt`, not `pt_BR`); Weblate is limited to base languages.

### Translating

Translators work on [Weblate](https://hosted.weblate.org/engage/opennutritracker/) — no Dart, no local setup — and anyone can start a language there. Weblate opens a pull request against `develop` with the accumulated translations about once a day, and the `Merge Weblate pull requests` workflow lands it with a merge commit as soon as the Default Workflow is green — nobody needs to press a button. (That workflow runs from its copy on `main`, so a change to it ships as a hotfix to `main` as well as to `develop`.) If you ever merge one by hand, **use a merge commit, never squash**: Weblate rebases its own commits onto `develop`, and after a squash that rebase conflicts and Weblate locks the component, shutting translators out. Recovery is on Weblate under *Operations → Repository maintenance → Reset and reapply* (never *Reset and discard* — it drops the pending strings the commit policy holds back). Machine-translation suggestions appear on Weblate for new strings; accepting one is a translator's decision, never automatic.

## Code generation

Some files are produced by `build_runner` (Hive type adapters and JSON serialization). Run `just build` after touching any `@HiveType`, `@HiveField`, or `@JsonSerializable` source file. See `AGENTS.md` for the full list of triggers.

## Code style and tests

- 80-character line width — `dart format`'s own default. `just format` passes no
  `--line-length`, and nothing in the repo configures one.
- Format with `just format` before committing — this targets only `lib/core`, `lib/features`, `lib/l10n`, and `test` and deliberately skips `lib/generated/`.
- Run `flutter analyze` and `just test` locally before opening the PR.
- `just ci` runs the full CI pipeline (install, format check, l10n generation and checks, build, analyze, test) and is the closest thing to a one-shot pre-flight check.

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
