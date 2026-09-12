# Weblate add-ons and settings for an English-source Flutter ARB project with a strict `check_l10n` CI

Researched 2026-09-12. Docs pinned to `https://docs.weblate.org/en/latest/` which identifies itself as
"Weblate 2026.10 documentation"; Hosted Weblate reports `weblate-2026.9.1-81-g5f28605969` on
https://hosted.weblate.org/about/ so `latest` matches what the project actually runs.
Older names used in the question ("needs editing", "Language consistency") are cross-referenced to
pinned older docs versions.

Current live component/project state (public API, https://hosted.weblate.org/api/components/opennutritracker/app/
and https://hosted.weblate.org/api/projects/opennutritracker/, fetched today): `addons=[]`,
`check_flags=""`, `enforced_checks=[]`, `language_regex="^[^.]+$"`, `allow_translation_propagation=true`,
`new_lang="add"`, `restricted=false`, `push_branch=""`, project `commit_policy=0`,
`translation_review=false`, `source_review=false`. The project has two components: `app` (arb) and
`glossary` (tbx, is_glossary).

## The one fact that governs everything: Weblate omits untranslated ARB keys

Weblate's own git export of this component (`git clone --depth 20 https://hosted.weblate.org/git/opennutritracker/app/`)
shows, per file (non-`@` keys vs 900 in `intl_en.arb`):

| file | keys | missing vs en |
|---|---|---|
| intl_es.arb | 227 | 673 |
| intl_sv.arb | 10 | 890 |
| intl_pt_BR.arb | 0 (`{}`) | 900 |
| intl_ru.arb, hu, fr, ... | 900 | 0 |

`git show c486673:lib/l10n/intl_ru.arb` (the "chore(l10n): add Russian translation" commit) is literally `{}`.
Source confirmation: `weblate/formats/ttkit.py` `JSONFormat` has `empty_file_template = "{}\n"`
(https://github.com/WeblateOrg/weblate/blob/main/weblate/formats/ttkit.py), and `ARBFormat(JSONFormat)`
inherits it. No file in the export contains an empty-string value (0 across all 15 files), i.e. untranslated
keys are simply absent, not written as `""`.

Consequence: any language that is not 100 % translated in Weblate, once pushed to `main`, makes
`flutter gen-l10n` list untranslated messages and `just check_l10n` fails. Every recommendation below is
judged against that.

Also visible in the export: Weblate writes 4-space indentation (`json_indent=4`) while the repo uses 2 spaces,
so any Weblate push reformats every touched file (already known from context; noted only because the
"Squash" and "Cleanup" add-ons both commit).

---

## (1) "Automatic translation" add-on and MT engines on Hosted Weblate

**Exact name / ID:** "Automatic translation", `weblate.autotranslate.autotranslate`.
Source: https://docs.weblate.org/en/latest/admin/addons.html#automatic-translation
> "Automatically translates strings using machine translation or other components."

Configuration (verbatim option labels from the same page):
- `mode` "Automatic translation mode": `suggest` "Add as suggestion", `translate` "Add as translation",
  `fuzzy` "Add as “Needing edit”", `approved` "Add as approved translation".
- `q` "Query", with the warning: > "Please note that translating all strings will discard all existing translations."
- `auto_source`: `others` "Other translation components" / `mt` "Machine translation".
- `engines` "Machine translation engines", `threshold` "Score threshold".
- Triggers: > "Add-on installation, Component update, Daily, Event change"

Defaults from source (https://github.com/WeblateOrg/weblate/blob/main/weblate/addons/autotranslate.py):
`DEFAULT_AUTO_SOURCE = "others"`, `DEFAULT_AUTO_TRANSLATE_MODE = "suggest"`,
`DEFAULT_AUTO_TRANSLATE_QUERY = "state:<translated"`, `DEFAULT_AUTO_TRANSLATE_THRESHOLD = 80`.

CI relevance: only `translate`/`fuzzy`/`approved` modes write into the ARB files (and thus can make a
locale complete); `suggest` stores suggestions in Weblate only
(https://docs.weblate.org/en/latest/workflows.html#translation-states:
> "Suggestions are stored in Weblate only and not in the translation file.").

**Which engines, and whose keys.** https://docs.weblate.org/en/latest/admin/machine.html:
> "Each service can be turned on by the administrator for whole site (under Automatic suggestions in Management interface) or at the project settings"

> "Weblate Translation Memory matches with 100% score take priority over machine translation services."

Services that need no key/config (docs say "This service has no configuration."): "Weblate" (`weblate`,
exact matches of existing strings), "Weblate Translation Memory" (`weblate-translation-memory`,
> "Use Translation Memory as a machine translation service."), and `tmserver`.

Services that need a project-supplied (or site-supplied) key:
- DeepL (`deepl`): > "DeepL is a paid service providing good machine translation for a few languages. You need to purchase DeepL API subscription."
- Google Cloud Translation Basic (`google-translate`): > "you need to obtain an API key and turn on billing in the Google API console."
- MyMemory (`mymemory`): > "Free, anonymous usage is currently limited to 100 requests/day, or to 1000 requests/day when you provide a contact e-mail address"
- Glosbe (`glosbe`): > "The API is gratis to use, but usage of the translations is subject to the license of the used data source."
- LibreTranslate (`libretranslate`): > "The public instance requires an API key, but LibreTranslate can be self-hosted"

Project-level keys are optional in the sense that site-wide services are inherited: `Project.get_machinery_settings()`
starts from the site-wide `Setting` MT dict and overlays the project's `machinery_settings`; a `None` value
removes a site-wide service for that project
(https://github.com/WeblateOrg/weblate/blob/main/weblate/trans/models/project.py, `get_machinery_settings`).
The API surface is `GET/POST /api/projects/(project)/machinery_settings/` ("Added in version 5.9",
https://docs.weblate.org/en/latest/api.html).

**Hosted Weblate availability.** https://weblate.org/en/hosting/:
> "All plans include all Weblate features."
> "It has the same limits as the 160k plan, and is only for public projects." (Libre plan)

Circumstantial evidence that DeepL is operated site-wide on Hosted Weblate: maintainer nijel on
https://github.com/WeblateOrg/weblate/issues/13467 (2025-01-10):
> "We see the error on Hosted Weblate as well, and it started to happen on 8th of January."
(the error was a DeepL API 400). The project's own roster is at
https://hosted.weblate.org/machinery/opennutritracker/ which returns HTTP 403 anonymously — it can only be
read by a project admin. **I could not find a primary source listing which engines Hosted Weblate enables
site-wide for Libre projects; treat that as an open question to be answered by opening that page.**

---

## (2) Flag add-ons ("needs editing" family) — current names

All four are component add-ons, "This add-on has no configuration.", trigger "Unit pre-create" except the last.
Source: https://docs.weblate.org/en/latest/admin/addons.html

| Current name (2026.10) | ID | What it does (verbatim) |
|---|---|---|
| Flag new source strings as “Needs checking” | `weblate.flags.source_edit` | "Whenever a new source string is imported from the VCS, it is flagged as needing checking in Weblate." |
| Flag new translations as “Needs rewriting” | `weblate.flags.target_edit` | "Whenever a new translatable string is imported from the VCS, it is flagged as needing rewriting in Weblate." |
| Flag unchanged translations as “Needs rewriting” | `weblate.flags.same_edit` | "Whenever a new translatable string is imported from the VCS and it matches a source string, it is flagged as needing rewriting" |
| Flag updated translations from repository as “Needs rewriting” | `weblate.flags.target_repo_update` (trigger "Unit post-sync") | "Whenever a string translation is changed from the VCS, it is flagged as needing rewriting in Weblate." |

Naming history: the 5.14 docs (https://docs.weblate.org/en/weblate-5.14/admin/addons.html) list them as
"Flag new source strings as “Needs editing”", "Flag new translations as “Needs editing”",
"Flag unchanged translations as “Needs editing”"; the IDs are unchanged.

The sub-states (https://docs.weblate.org/en/latest/workflows.html#translation-states):
> "Needs rewriting — Translation needs to be rewritten because of a source string change."
> "Needs checking — State used for source/template strings that need developer review."
Bulk-edit state codes on the add-ons page: `10` Needs editing, `11` "Needs editing (Needs rewriting)",
`12` "Needs editing (Needs checking)".

`same_edit` hint on the add-ons page:
> "You might also want to tighthen the Unchanged translation check by adding strict-same flag to Translation flags."

Fit for this project:
- `source_edit` is the one that matches "developers add English only": it marks new English strings for a
  developer/maintainer pass in Weblate and never touches target files. Safe for CI under the current
  `commit_policy=0`.
- `target_edit` and `same_edit` only fire on translations imported from VCS. `same_edit` would flag the
  52–75 per-file strings that are identical to English (brand names, "OK", etc.) as needs rewriting.
- **CI interplay:** ARB stores no state ("Supports read-only strings: No", no state column in
  https://docs.weblate.org/en/latest/formats/arb.html), so the flag lives in Weblate only — but
  > "The Translation quality filter determines which translation states are stored in the file."
  (workflows.html). If the project ever switches `commit_policy` to "Skip translations marked as needing
  editing", every string these add-ons flagged is dropped from the ARB on the next commit and CI goes red.
  Keep `commit_policy=0` if any of these add-ons is installed.

---

## (3) "Squash Git commits"

**ID:** `weblate.git.squash`. Source: https://docs.weblate.org/en/latest/admin/addons.html#squash-git-commits
> "Squash Git commits prior to pushing changes."

Modes (`squash` "Commit squashing"): `all` "All commits into one", `language` "Per language",
`file` "Per file", `author` "Per author". Other options: `append_trailers` "Append trailers to squashed
commit message", `commit_message` "Commit message" (> "This commit message will be used instead of the combined commit messages from the squashed commits.").
Triggers: > "Add-on installation, Repository post-commit"

> "Original commit messages are kept, but authorship is lost unless Per author is selected, or the commit message is customized to include it."

> "To avoid unnecessary conflicts, it is recommended to configure automatic receiving of upstream changes by webhooks or API"

Fit: with `push=""` today nothing is pushed, so squash has no visible effect until a push URL exists. Once it
does, `author` mode keeps translator attribution in git; `all` collapses a day's `chore(l10n): update X`
commits into one. Not a CI lever.

---

## (4) "Cleanup translation files"

**ID:** `weblate.cleanup.generic`, no configuration.
Source: https://docs.weblate.org/en/latest/admin/addons.html#cleanup-translation-files
> "Update all translation files to match the monolingual base file. For most file formats, this means removing stale translation keys no longer present in the base file."
Triggers: > "Add-on installation, Repository post-update, Repository pre-commit"
> "For a one-time cleanup of a single translation file, use Cleanup unused in Repository maintenance on that translation instead of installing the add-on."

Why it matters here: https://docs.weblate.org/en/latest/devel/integration.html#updating-target-language-files
> "It does not however perform any automatic cleanup of stale strings, as that might have unexpected results."
So without it, a key removed from `intl_en.arb` lingers in every other ARB. Flutter gen-l10n tolerates extra
keys, so this is hygiene, not CI.

Related sibling: "Remove blank strings" `weblate.cleanup.blank`
> "Removes strings without a translation from translation files."
Not needed for ARB — the export shows Weblate already writes no empty strings for this format.

Note: the ARB format table says "Supports removing obsolete strings: No"; that refers to gettext-style
obsolete entries (https://docs.weblate.org/en/latest/formats.html#removing-obsolete-strings:
> "Some file formats can store obsolete strings. Weblate can remove these obsolete strings from formats that support this operation."),
not to the Cleanup add-on, which the ARB page itself links to under "See also".

---

## (5) "Language consistency" and (6) "Add missing languages" — the same add-on

**Current name:** "Add missing languages", **ID:** `weblate.consistency.languages`.
Source: https://docs.weblate.org/en/latest/admin/addons.html#add-missing-languages
> "Ensures a consistent set of languages is used for all components within a project."
> "Unlike most others, this add-on affects the whole project."
> "Missing languages are checked once every 24 hours, and when new languages are added in Weblate."
Triggers: > "Add-on installation, Daily, Repository post-add"

Old name: the 3.11.3 docs (https://docs.weblate.org/en/weblate-3.11.3/admin/addons.html) call it
"Language consistency":
> "Ensure that all components within one project have translation to same languages. It will create empty translations for languages which are not present."
By 4.18.2 (https://docs.weblate.org/en/weblate-4.18.2/admin/addons.html) it is already "Add missing languages" with the same ID.

Source behaviour (https://github.com/WeblateOrg/weblate/blob/main/weblate/addons/consistency.py and
https://github.com/WeblateOrg/weblate/blob/main/weblate/addons/tasks.py): `can_install` returns
`component is None` (project/category level only); for every language present in any component of the
project and missing in another, it calls `component.add_new_language(...)` then
`component.create_translations_immediate()`.

**CI verdict: do not install.** This project has a `glossary` component alongside `app`. Any language
that exists only in the glossary would be added to `app` as `{}` — the exact file shape that makes
`check_l10n` fail. It is the opposite of what this project wants.

---

## (7) "Pseudolocale generation"

**ID:** `weblate.generate.pseudolocale`, "Added in version 4.5."
Source: https://docs.weblate.org/en/latest/admin/addons.html#pseudolocale-generation
> "Generates a translation by adding prefix and suffix to source strings automatically."
Options: `source` "Source strings", `target` "Target translation" (> "All strings in this translation will be overwritten"),
`prefix`, `var_prefix`, `suffix`, `var_suffix`, `var_multiplier`, `include_readonly`.
Triggers: > "Add-on installation, Component update, Daily"
> "there are dedicated pseudolocales available in Weblate - en_XA and ar_XB."

Second documented use, bootstrapping a sibling locale:
> "If you have fr and want to start fr_CA translation, simply set fr as the source, fr_CA as the target, and leave the prefix and suffix blank."
> "Uninstall the add-on once you have the new translation filled"

Fit: the generated target is always complete (every source string is rewritten), so it cannot break
`check_l10n` on its own. But it commits a real `lib/l10n/intl_en_XA.arb` (or similar) into the repo, which
Flutter would treat as a shipping locale. Only useful if the team wants a layout-stress locale in the app.

---

## (8) Push only complete languages / hold a language back until complete — nothing does this

Plain answer: **Weblate has no per-language completeness threshold for committing or pushing.** What exists:

1. **Component "Language filter"** (`language_regex`, currently the default `^[^.]+$`).
   https://docs.weblate.org/en/latest/admin/projects.html#language-filter
   > "Regular expression used to filter the translation when scanning for file mask. It can be used to limit the list of languages managed by Weblate."
   > "The filter also applies when creating a new translation file."
   Examples on that page: `^(cs|de|es)$` "Selected languages only", `^(?!(it|fr)$).+$` "Exclude languages".
   https://docs.weblate.org/en/latest/workflows.html#limiting-translation-languages
   > "Language filters are configured per component, with no project-wide language allowlist."
   An excluded language is invisible to Weblate — not translatable, not committed. It is an allowlist of
   languages the maintainer has decided are shippable, not a threshold; a maintainer flips the regex when a
   language is judged complete. This is the closest thing to "exclude from VCS until complete".

2. **Project "Translation quality filter"** (`commit_policy`, "Added in version 5.13", currently `0`).
   https://docs.weblate.org/en/latest/admin/projects.html#translation-quality-filter
   > "The commit policy determines which translations are included when committing changes to the version control system."
   Options: "Commit all translations regardless of quality", "Skip translations marked as needing editing",
   "Only include approved translations" (> "This option requires Enable reviews to be enabled.").
   It is per **string state**, not per language completeness, and for ARB any excluded string means a
   missing key — so the non-default options make CI *worse* here.

3. **"Restricted access"** (`restricted`) is access control, not commit control.
   https://docs.weblate.org/en/latest/admin/projects.html#restricted-access
   > "On Hosted Weblate, this requires a billing plan which permits private projects."
   Not applicable (Libre plan is always Public: https://docs.weblate.org/en/latest/admin/access.html
   > "Projects running the gratis Libre plan on Hosted Weblate are always Public.").

4. **"Adding new translation"** (`new_lang`, currently `add` = "Create new language file"). Setting it to
   "Contact maintainers" or "Disable adding new translations" stops translators from creating a fresh `{}`
   language that would land on `main`. https://docs.weblate.org/en/latest/admin/projects.html#adding-new-translation
   > "Disable adding new translations — There will be no option for user to start new translation."
   > "The project admins can add new translations even if it is disabled here"

5. **"Push branch"** (`push_branch`) https://docs.weblate.org/en/latest/admin/projects.html#push-branch
   > "Branch for pushing changes, leave empty to use Repository branch."
   Pushing to a `weblate` branch (or the GitHub pull-request VCS) lets CI gate the merge instead of trusting
   Weblate; it does not filter by completeness either.

6. **"Prefill translation with source"** `weblate.generate.prefill` ("Added in version 4.11.")
   https://docs.weblate.org/en/latest/admin/addons.html#prefill-translation-with-source
   > "All untranslated strings in the component will be filled with the source string, and marked as needing edit. Use this when you can not have empty strings in the translation files."
   This is the only add-on that makes every ARB complete regardless of translator progress — CI stays green
   at the cost of English text being committed under other locales (which is also what Flutter shows at
   runtime for missing keys, so the app behaviour is unchanged). Requires `commit_policy=0`, otherwise the
   "needs edit" strings are filtered back out.

So the realistic choices are: language allowlist via `language_regex` (manual promotion), or Prefill
(automatic completeness), or a push branch with CI gating.

---

## (9) "Unchanged translation" check and silencing it

Source: https://docs.weblate.org/en/latest/user/checks.html#unchanged-translation
- Summary "Source and translation are identical." Scope "translated strings". Identifier `same`.
- > "This check is always enabled but can be ignored using a flag." Flag to ignore: `ignore-same`.
- > "Some strings commonly found across all languages are ignored, and various markups are stripped. This reduces the number of false positives."
- > "This list can be disabled by adding strict-same flag to a string or component."
- > "Changed in version 4.17: With check-glossary flag (see Does not follow glossary), the untranslatable glossary terms are excluded from the checking."

Where flags can be set (https://docs.weblate.org/en/latest/admin/checks.html#customizing-behavior-using-flags):
> "Source string additional flags", "Component configuration (Translation flags)", "Project configuration (Translation flags)"
plus > "The flags defined on a higher level can be discarded using the discard:NAME syntax."
ARB itself cannot carry flags ("Supports flags: No", https://docs.weblate.org/en/latest/formats/arb.html), so
per-string flags are stored in Weblate via "Additional info on source strings"
(https://docs.weblate.org/en/latest/admin/translating.html#additional-info-on-source-strings:
> "Access this directly from the translation interface by clicking the “Edit” icon next to Screenshot context or Flags.").

Options, narrowest first:
1. Per string: add `ignore-same` to the source string's flags in Weblate (or `read-only` for strings that
   must never change). The "Bulk edit" add-on `weblate.flags.bulk` can do it by query
   (documented example "Marking certain strings read-only", flags to add `read-only`, search query:

   ```
   source:r"^``[.a-zA-Z0-9_-]*``$" AND language:en
   ```
   )
2. Glossary route: mark brand names as "Untranslatable terms" in the glossary component
   (https://docs.weblate.org/en/latest/user/glossary.html#untranslatable-terms:
   > "Use this for brand names, product names, domains, technology names, or other terms that should not be changed in other languages.")
   and add `check-glossary` to component `check_flags`; since 4.17 those terms are excluded from Unchanged
   translation. Caveat on the same checks page: > "Checking each string against glossary is expensive".
3. Component-wide: `check_flags: ignore-same` silences it for every string — blunt; it also hides genuinely
   forgotten translations.
4. Translators can dismiss the check per string; that stays possible unless it is enforced, and the docs
   advise against enforcing it (see 11).

---

## (10) "Translation propagation" semantics

Component setting "Allow translation propagation" (`allow_translation_propagation`, currently `true`).
https://docs.weblate.org/en/latest/admin/continuous.html#translation-propagation
> "With Allow translation propagation enabled (what is the default, see Component configuration), all new translations are automatically done in all components with matching strings."
> "All components have to reside in a single project (linking component is not enough)."
> "The translation propagation requires the key to be match for monolingual translation formats"
> "The strings are propagated while translating, strings loaded from the repository are not propagated."

Component docs (https://docs.weblate.org/en/latest/admin/projects.html#allow-translation-propagation):
> "It’s usually a good idea to turn this off for monolingual translations, unless you are using the same IDs across the whole project."

Fit: with a single ARB component (plus the glossary), propagation has nothing to propagate to. Harmless either
way; turning it off is the documented default advice for monolingual formats.

---

## (11) `enforced_checks`

Component setting "Enforced checks" (`enforced_checks`, currently `[]`), API type "Enforced checks" list.
https://docs.weblate.org/en/latest/admin/projects.html#enforced-checks
> "List of checks which can not be dismissed."

https://docs.weblate.org/en/latest/admin/checks.html#enforcing-checks
> "The enforced checks cannot be dismissed and mark string as Needs editing (see Translation states). This prevents translators from hiding such checks."
> "Turning on check enforcing doesn’t enable it automatically. Some checks have to be turned on by adding the corresponding flag"
> "Using for style checks like Unchanged translation is not recommended because dismissal is sometimes a reasonable approach in these."
> "The Translation quality filter can then be used to exclude strings needing editing from being committed to the version control."

The natural candidate for ARB is the ICU check, which the format enables automatically
(https://docs.weblate.org/en/latest/user/checks.html#icu-messageformat: identifier `icu_message_format`,
"File formats automatically enabling this check: ARB File, Format.JS JSON file",
summary "Syntax errors and/or placeholder mismatches in ICU MessageFormat strings."). Enforcing it
(`enforced_checks: ["icu_message_format"]`) keeps a broken `{count, plural, ...}` from being marked
translated.

**CI interplay:** an enforced-check failure sets the string to Needs editing. Under `commit_policy=0` the
string is still written to the ARB (bad placeholder and all — gen-l10n will then reject it at build time).
Under `commit_policy=1` the key is omitted instead and `check_l10n` fails. Either way CI catches it; the
question is only which job turns red.

---

## Synthesis (my reading, not a sourced claim)

For "developers add English, translators fill the rest, CI must stay green":

- Keep `commit_policy=0` (default) — every non-default quality filter removes keys from ARB files.
- Do **not** install "Add missing languages"; the glossary component makes it a `{}`-file generator.
- Change `new_lang` from `add` to "Contact maintainers" so a new language cannot appear on `main` at 0 %.
- Pick one of: (a) `language_regex` allowlist of languages judged complete, promoted by hand; (b) the
  "Prefill translation with source" add-on so every file is always complete; (c) `push_branch` +
  PR so CI gates the merge.
- "Flag new source strings as “Needs checking”" is the add-on that matches the workflow; it never touches
  target files.
- "Squash Git commits" (`author` mode) and "Cleanup translation files" are hygiene, safe under
  `commit_policy=0`.
- For brand names: glossary "Untranslatable terms" + `check-glossary`, or per-string `ignore-same`; avoid
  enforcing the `same` check.
- "Automatic translation" only helps CI in `translate`/`fuzzy` mode, and which paid engines Hosted Weblate
  provides to this Libre project is only visible at https://hosted.weblate.org/machinery/opennutritracker/ (admin login).

## Open questions

1. Exact list of site-wide MT engines Hosted Weblate enables for Libre projects (DeepL/Google/etc.) — no
   primary source found; the project machinery page is 403 anonymously. Evidence that DeepL runs on Hosted
   Weblate is a maintainer comment on a bug report, not documentation.
2. Whether any built-in add-on in the list is hidden on Hosted Weblate — the add-ons docs carve out nothing
   except that the JS CDN add-on "is configured on Hosted Weblate" and `weblate.hosted.reset` exists; the
   component add-on page (https://hosted.weblate.org/addons/opennutritracker/app/) is 403 anonymously.
3. How Flutter gen-l10n treats an `intl_en_XA.arb` pseudolocale file (locale parsing / supportedLocales) —
   not checked against docs.flutter.dev; only relevant if the Pseudolocale add-on is adopted.
4. Whether the "Unchanged translation" check's "Scope: translated strings" excludes strings in the
   Needs-editing state that Prefill creates — the docs do not say; matters only for check noise, not CI.


## Verification

Fact-checked 2026-09-12 by re-fetching every cited page (docs converted to text and grepped for the
quoted sentence; hosted.weblate.org endpoints re-fetched with curl's default UA — the site serves an
Anubis bot-check to browser UAs; source files pulled from raw.githubusercontent.com; the Weblate git
export re-cloned independently). Verdicts: 36 supported, 2 not supported (#23, #28), several with
precision notes.

| # | Claim (short) | Verdict | Note |
|---|---|---|---|
| 1 | Git export: untranslated ARB keys absent, `intl_pt_BR.arb` is `{}`, `intl_sv.arb` 10/900 | supported | Independently re-cloned: pt_BR `{}`, sv 10 keys, es 227 keys, `c486673:lib/l10n/intl_ru.arb` is `{}`. Precision: es has 226 translated + 1 needs-editing per the API statistics and 227 keys in the file, so Weblate writes translated **and** needs-editing keys under `commit_policy=0`; only untranslated keys are omitted. |
| 2 | `JSONFormat.empty_file_template = "{}\n"`, inherited by `ARBFormat` | supported | ttkit.py line 2474; `class ARBFormat(JSONFormat)` at 2549 does not override it. |
| 3 | Automatic translation ID, four modes, "discard all existing translations" warning | supported | Verbatim on the add-ons page. |
| 4 | Autotranslate defaults others / suggest / `state:<translated` / 80 | supported | autotranslate.py lines 40–43. |
| 5 | Suggestions never reach the file | supported | Verbatim; "cannot make a locale complete" follows. |
| 6 | MT services enabled site-wide or per project | supported | Verbatim. |
| 7 | TM 100 % matches take priority; Weblate / Weblate TM "no configuration" | supported | Both verbatim. |
| 8 | DeepL paid subscription; Google key + billing | supported | Verbatim; "project-supplied unless the site provides them" follows from #6. |
| 9 | `get_machinery_settings` overlays project settings; `None` deletes a site-wide service | supported | project.py, code as quoted. |
| 10 | Libre plan = 160k limits, public only; all plans include all features | supported | Both sentences on weblate.org/en/hosting/. |
| 11 | DeepL runs on Hosted Weblate (nijel, issue #13467) | supported | Quote verbatim, 2025-01-10. It shows DeepL is configured somewhere on Hosted Weblate; it does not say whether Libre projects get it site-wide. The project machinery page is 403 and `/api/projects/opennutritracker/machinery_settings/` is 401 anonymously (re-checked). |
| 12 | `weblate.flags.source_edit` flags new VCS source strings as Needs checking | supported | Verbatim; page adds "filter and edit source strings written by the developers". |
| 13 | `weblate.flags.same_edit` + strict-same hint | supported | Verbatim (docs typo "tighthen" is real). |
| 14 | 5.14 names "… as “Needs editing”", same IDs | supported | All four headings and IDs match on the 5.14 page. |
| 15 | Quality filter decides which states are stored | supported | Verbatim. |
| 16 | Squash modes, post-commit trigger, authorship note | supported | Verbatim. |
| 17 | Cleanup add-on removes stale keys; nothing else removes them | supported | Verbatim; note the same page offers a one-off manual "Cleanup unused" in Repository maintenance, so "never" means "never automatically". |
| 18 | integration.html: no automatic cleanup of stale strings | supported | Verbatim, and the page explicitly points to the Cleanup add-on. |
| 19 | "Language consistency" (3.11) = "Add missing languages" = `weblate.consistency.languages` | supported | 3.11.3 page has the quoted description but no add-on IDs at all; identity is established by the same "24 hours … whole project" text under "Add missing languages / weblate.consistency.languages" on the 4.18.2 page. |
| 20 | Add missing languages: project-level only, daily + post-add, would add glossary-only languages to `app` | supported | Precision: `can_install` returns `component is None`, so it installs at project **or category** (or site-wide) scope, not "project only". Glossary inference confirmed in consistency.py: languages come from `Language.objects.filter(translation__component__project=project)` and components from `project.component_set` with no `is_glossary` exclusion. |
| 21 | Implementation calls `component.add_new_language` per inconsistent component | supported | tasks.py `enforce_language_consistency`. |
| 22 | Pseudolocale overwrites target from source + affixes; en_XA / ar_XB | supported | Verbatim. |
| 23 | No completeness threshold; Language filter is the **only** language-level control | **not supported** | The quoted sentence is verbatim, but the same section lists five language-limiting mechanisms: Adding new translation, Language filter, language-scoped teams, Restrict direct editing, suggestion voting. None is a completeness threshold, so the "nothing exists" conclusion stands; "only language-level control" does not. |
| 24 | Language filter limits discovered/created files, so excluded languages are not translated or committed | supported | Verbatim; workflows.html adds "it does not change permissions for translations that are already present" — a file already in the repo is simply left alone. |
| 25 | Quality filter (5.13+) is per-string, three options, not a threshold | supported | Verbatim; "can only remove keys" follows. Extra nuance on the page: the approved-only policy applies only to languages with reviews enabled. |
| 26 | Restricted access is access control, paid on Hosted; Libre always Public | supported | Two different settings: component "Restricted access" ("requires a billing plan which permits private projects", projects.html) and project "Access control" (the quoted Libre sentence, access.html). Both true. |
| 27 | new_lang Disable / Contact maintainers stops translator-created files; admins still can | supported | Verbatim (component-level entry on the same page). Not in the research: a fifth option "Create existing project languages; contact maintainers for new languages", and the caveat that disabling "does not stop discovery of translation files added to the repository". |
| 28 | Prefill fills untranslated with source as needs-edit; the **only** add-on keeping every ARB complete | **not supported** | First half verbatim. "Only" is not on the page: the same page documents Pseudolocale generation with blank prefix/suffix as a way to fill a whole target from another language, and Automatic translation in translate/fuzzy mode also writes strings. Prefill is the only one that does it for every language of a component without configuration. |
| 29 | Unchanged translation: always on, ignore-same, built-in list, strict-same, 4.17 check-glossary | supported | All verbatim. |
| 30 | Flags merge from source-string / component / project; `discard:NAME` | supported | Verbatim, but the list is incomplete: the page also names per-string file-format flags, translation flags and file-format-specific flags, and projects.html adds workspace flags. |
| 31 | ARB: Supports flags No, read-only No | supported | Both in the ARB capability table. |
| 32 | Glossary Untranslatable terms for brand names | supported | Verbatim; they are read-only glossary entries. |
| 33 | Propagation: default on, single project, key match, while translating only | supported | All verbatim. |
| 34 | Turn propagation off for monolingual formats | supported | Verbatim. |
| 35 | enforced_checks semantics | supported | All four statements verbatim. |
| 36 | ICU check auto-enabled for ARB | supported | Verbatim; `ARBFormat.check_flags = ("icu-message-format",)` in ttkit.py. "Natural candidate" is judgement, consistent with "best used with … Formatted strings". |
| 37 | Live component/project state | supported | Re-fetched: `addons=[]`, `check_flags=""`, `enforced_checks=[]`, `language_regex="^[^.]+$"`, propagation true, `new_lang="add"`, `restricted=false`, `push_branch=""`, `push=""`, `commit_policy=0`; components `app` (arb) + `glossary` (tbx, is_glossary). |
| 38 | Hosted runs `weblate-2026.9.1-81-g5f28605969`; latest docs = 2026.10 | supported | Both strings present. |

### Still unanswered with a source

1. Which MT engines Hosted Weblate enables site-wide for Libre projects — no public primary source
   exists; the only evidence is the maintainer comment in #13467, and the project's own roster
   (`/machinery/opennutritracker/`, 403; `/api/projects/opennutritracker/machinery_settings/`, 401)
   needs a project-admin login.
2. Whether Hosted Weblate hides or restricts any of the listed add-ons for Libre projects —
   `/addons/opennutritracker/app/` is 403 anonymously.
3. The "Create existing project languages; contact maintainers for new languages" option for
   Adding new translation, and the note that disabling new translations does not stop discovery of
   language files already committed to the repository — both on the cited pages, neither in the
   research text.
4. Whether the Unchanged translation check's "translated strings" scope skips Needs-editing strings
   (Prefill noise) — not documented.
5. Flutter gen-l10n handling of a committed `intl_en_XA.arb` pseudolocale — not checked.
