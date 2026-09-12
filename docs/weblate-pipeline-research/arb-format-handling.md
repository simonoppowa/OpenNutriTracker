# Weblate "ARB file" format vs. `flutter gen-l10n`: round-trip behaviour and the settings that matter

Researched 2026-09-12. Weblate docs read at `/en/latest/` = "Weblate 2026.10 documentation". Weblate and translate-toolkit source read at `main`/`master` on that date. Flutter source read at tag `3.44.6` (the SDK pinned for this repo) and confirmed byte-identical to `master` for the `AppResourceBundle` class. Empirical checks were run against (a) the public git export of the OpenNutriTracker component on Hosted Weblate, (b) the Hosted Weblate REST API, and (c) `flutter gen-l10n` from `~/fvm/versions/3.44.6` on a synthetic ARB set.

## TL;DR for this repo

| Topic | Finding | Action |
|---|---|---|
| Monolingual | Yes. "ARB translations are monolingual"; `intl_en.arb` is the base. Template-for-new-translations stays empty. | Nothing to change. |
| `@key` metadata in translation files | Weblate parses the whole `@key` object into `unit.metadata` and writes it back verbatim (`"@key"` written right after `"key"`). When a translator first translates a key that is not yet in the locale file, Weblate shallow-copies the template unit, so the template's `@key` object (placeholders and any `description`) is copied into the locale file. Observed: all 50 `@key` blocks in the Weblate-written fr/hu/ru/es/sv files are byte-identical to the template's. Empty `{}` metadata is dropped on write (translate-toolkit >= 3.18.1). | gen-l10n accepts this (it reads `@key` in locale files as per-locale overrides, merged by name over the template). No action. |
| Indentation | Weblate re-serialises the entire file with `json.dumps(units, **dump_args)` every time it saves it. `json_indent` defaults to 4 and always overrides translate-toolkit's own ARB default of 2. Observed: every Weblate-touched file in the export is 4-space, every untouched one is 2-space. | Set `json_indent=2` (`json_indent_style=spaces`, `json_sort_keys=none`, `json_use_compact_separators=false`) on the component **before** merging Weblate's branch; then the first Weblate commit after that will re-indent fr/hu/ru/es/sv back to 2 spaces (one-time whole-file diff). Do not enable key sorting: Python's sort puts every `@…` key before every plain key. |
| Language code style | Component value `""` = "Default based on the file format"; ARB's format default is `posix`, so `pt_BR` -> `intl_pt_BR.arb`, `zh_Hans` -> `intl_zh_Hans.arb`. Weblate never writes `@@locale`. | Keep `""`/posix. Do **not** switch to a BCP (hyphen) style: gen-l10n would parse `intl_pt-BR.arb` as `pt_BR` too and then fail with "Multiple arb files with the same … locale". |
| gen-l10n fallback rule (**the real trap**) | gen-l10n exits 1 when a region/script locale exists without its base language: "Arb file for a fallback, pt, does not exist … Please create a {fileName}_pt.arb file." Weblate already created `lib/l10n/intl_pt_BR.arb` (currently `{}`) and the repo has no `intl_pt.arb`. Merging Weblate's branch as-is breaks `flutter gen-l10n` and CI. | Either add `intl_pt.arb` (can be a copy of pt_BR or empty `{}` — the check only looks at file existence/locale set) or drop the pt_BR file and restrict Weblate to base languages. Consider `new_lang=existing`/`contact` so translators cannot spawn `xx_YY` locales unsupervised. |
| `@@locale` | Weblate preserves an existing `@@…` header block but never adds one to new files. gen-l10n treats `@@locale` as optional and infers the locale from the filename; it only errors when both exist and disagree. | Nothing to do. |
| Empty strings | Weblate can leave `"key": ""` in a locale file (translator blanked it). gen-l10n counts `""` as translated (not listed in `l10n_untranslated.json`) and generates an empty getter. | Optionally install the "Remove blank strings" add-on (`weblate.cleanup.blank`). |
| Stale keys | Weblate never removes keys that vanished from the template; gen-l10n silently ignores keys not in the template. | Harmless. "Cleanup translation files" add-on (`weblate.cleanup.generic`) exists if wanted. |
| Placeholder checks | Weblate derives a `placeholders:` flag from the ARB `placeholders` object, but through the WebExtension code path, producing `$NAME$` + `case-insensitive` (verified live: `placeholders:$SOURCENAME$`). Since `$SOURCENAME$` never occurs in the source, the "Placeholders" check is inert for ARB. The check that actually validates `{name}` is "ICU MessageFormat", auto-enabled by the ARB format (`check_flags = ("icu-message-format",)`). It checks missing/extra placeholders and types, but has no access to ARB `type` hints (open issue #17269). | No `check_flags` needed. If the ICU type sub-check produces false positives on `int`/plural placeholders, add `icu-flags:-types` at component level rather than disabling the check. |

---

## 1. Weblate's ARB format: monolingual, and what happens to `@key` metadata

### Documentation (Weblate 2026.10)

- https://docs.weblate.org/en/latest/formats/arb.html
  - "ARB translations are monolingual, so it is recommended to specify a base file with (what is most often the) English strings."
  - Supported-features table: "Linguality — Both monolingual and bilingual", "Supports plural — Yes", "Supports descriptions — Yes", "Supports explanation — No", "Supports context — No", "Supports location — No", "Supports flags — No", "Supports read-only strings — No", "Supports removing obsolete strings — No", "Check flags added by this format — ICU MessageFormat", "API identifier — arb", "Added in version 4.1."
  - Typical component configuration: "File mask lib/l10n/intl_*.arb", "Monolingual base language file lib/l10n/intl_en.arb", "Template for new translations Empty", "File format ARB file".
  - The page says nothing about how `@key`/`@@locale` are treated; that had to come from source (below).
- https://docs.weblate.org/en/latest/formats.html (Bilingual and monolingual formats): "monolingual formats identify the string by ID, and each language file contains only the mapping of those to any given language."
- https://docs.weblate.org/en/latest/admin/projects.html#template-for-new-translations: "Keep this field empty for most of the monoligual formats. Those are typically able to start from an empty file."
- https://docs.weblate.org/en/latest/devel/translations.html#adding-translation: "When Template for new translations is empty and the file format supports it, an empty file is created where new strings are added once they are translated."
- https://docs.weblate.org/en/latest/devel/integration.html#updating-target-files: "It does not however perform any automatic cleanup of stale strings, as that might have unexpected results."

### Parser/serialiser (translate-toolkit, which Weblate wraps)

https://github.com/translate/translate/blob/master/translate/storage/jsonl10n.py (`ARBJsonUnit`, `ARBJsonFile`, `JsonFile.serialize`):

- `@@` header keys become one header unit and are written back:
  `metadata = {key: value for key, value in data.items() if key.startswith("@@")}` … `unit.setid("@")`
- Every other `@`-prefixed key is skipped as a unit: `if item.startswith("@"): continue`
- The full `@item` object is attached to the unit: `metadata = data.get(f"@{item}", {})`; `description` is also lifted into `notes`, `placeholders` into `unit.placeholders` (must be a dict, else `ParseError`).
- On write, key and metadata are emitted adjacently, metadata only if non-empty:
  `self.storevalue(output, self.target, override_key=identifier)` then `if self.metadata: self.storevalue(output, self.metadata, override_key=f"@{identifier}")`
- Whole-file rewrite: `out.write(json.dumps(units, **self.dump_args).encode(self.encoding))` followed by `out.write(b"\n")`.
- translate-toolkit's own ARB default is `"indent": 2` (in `ARBJsonFile.__init__`), and has been since the format was added in https://github.com/translate/translate/commit/28f6e3b553 (2020-06-03, "json: Add support for ARB files"). Weblate overrides it (section 2).
- https://github.com/translate/translate/pull/6014 (merged 2026-01-14, release 3.18.1): "empty metadata dictionaries are serialized as "@key": {} in ARB JSON output … store metadata only when self.metadata is non-empty". Before that, `"@key": {}` was always emitted. Note the repo template has one orphan `"@PHYSICAL_ACTIVITIES": {}` with no matching value key; Weblate skips it entirely (it never becomes a unit), so it would be lost if Weblate ever rewrote `intl_en.arb`.

### How metadata reaches translation files (Weblate)

- https://github.com/WeblateOrg/weblate/blob/main/weblate/formats/ttkit.py — `class ARBFormat(JSONFormat)`: `loader = ARBJsonFile`, `unit_class = PlaceholdersJSONUnit`, `check_flags = ("icu-message-format",)`, `supports_plural: bool = True`, `supports_descriptions = True`. `JSONFormat` has `empty_file_template = "{}\n"` — the content of a brand-new locale file when Template-for-new-translations is empty.
- https://github.com/WeblateOrg/weblate/blob/main/weblate/formats/base.py — `_find_unit_monolingual`: "# We always need copy of template unit to translate" → `result.clone_template()`; `clone_template`: `self.mainunit = self._unit = copy(self.template)` (a shallow copy, so the template unit's `metadata` dict and `placeholders` come along).
- https://github.com/WeblateOrg/weblate/blob/main/weblate/formats/ttkit.py — `TTKitUnit.clone_template`: "# do not copy notes from the template (#11133)" then `self.unit.removenotes()`. `removenotes` only clears `notes` (`self.notes = ""` in translate-toolkit `base.py`); the copied `metadata` dict still contains `description` if the template had one, and `storevalues` writes the whole dict. So in practice description *and* placeholders are copied. (Not empirically verified for `description` because this repo's template has zero descriptions; verified for placeholders, below.)
- Context for #11133: https://github.com/WeblateOrg/weblate/issues/11133 — nijel: "there is definitely no synchronization in place" for comments copied into translated files. I.e. a later edit of a `@key` block in `intl_en.arb` is **not** propagated to locale files that already carry the old copy. Harmless for gen-l10n unless the placeholder *names* change (then the stale per-locale block overrides by name — see section 5).

### Empirical: Hosted Weblate git export

`git clone https://hosted.weblate.org/git/opennutritracker/app/` (HEAD `afbad29`, 2026-09-07, on top of upstream `294debe`):

- Weblate-created files (`git log 294debe..HEAD -- <file>` > 0): es (5 commits), fr (7), hu (6), pt_BR (1), ru (2), sv (2). All start life as `{}` ("chore(l10n): add … translation") — `intl_pt_BR.arb` is still exactly `{}`.
- In fr/hu/ru: 900 keys, 50 `@key` blocks, all 50 with `placeholders`, all 50 `== intl_en.arb`'s; es: 227 keys / 24 blocks; sv: 10 keys / 1 block. Zero `@key` blocks without placeholders (the template has none with only `description`). No `@@locale` anywhere (template has none either).
- Key order in Weblate-created files is translation order, not template order (e.g. fr: `addLabel` is followed by `foodSourcesAlwaysEnabledLabel`), because new units are appended and `json_sort_keys=none`.

## 2. Indentation and the JSON file-format parameters

- The old add-on is gone: https://docs.weblate.org/en/latest/admin/addons.html — "Customize JSON output … Removed in version 5.13: Replaced by File format parameters."
- https://docs.weblate.org/en/latest/formats.html#file-format-params — "File format parameters provide a way to configure settings related to the file format. They are configured at component level". Parameters listed for `arb` (among others): `json_indent` "JSON indentation"; `json_indent_style` "Available choices: spaces Spaces / tabs Tabs"; `json_sort_keys` "none Do not sort / case_sensitive Case-sensitive sort / case_insensitive Case-insensitive sort"; `json_use_compact_separators` "Avoid spaces after separators". https://docs.weblate.org/en/latest/formats/json.html adds: "File format parameters with the pattern json_* can be used to configure the behavior of the JSON format."
- Source, https://github.com/WeblateOrg/weblate/blob/main/weblate/trans/file_format_params.py:
  - `class JSONOutputIndentation`: `name = "json_indent"`, `field_class = forms.IntegerField`, `default = 4`, `field_kwargs = {"min_value": 0}` → any non-negative integer, so **2 is allowed**.
  - `class JSONOutputIndentStyle.setup_store`: `indent = JSONOutputIndentation.get_value(file_format_params)` … `else: dump_args["indent"] = indent` — runs unconditionally, so Weblate's 4 always replaces translate-toolkit's ARB default of 2 unless you set the parameter.
  - `class JSONOutputSortKeys`: `default = "none"`; `case_sensitive` sets `dump_args["sort_keys"] = True`. With sorting on, `"@key"` entries would all sort ahead of plain keys (`'@'` < `'a'`), separating metadata from values; still valid ARB but noisy. Leave at `none`.
  - `JSONOutputCompactSeparators`: `default = False` → separators `(",", ": ")`, matching the repo.
  - Absent parameters fall back to the class default: https://github.com/WeblateOrg/weblate/blob/main/weblate/utils/params.py — `value = params.get(cls.name, cls.default)`.
- Whole-file rewrite on first commit: yes. `JsonFile.serialize` dumps the entire tree (section 1), and Weblate calls it whenever a unit in that file is saved. Observed in the export: `intl_es/fr/hu/ru/sv.arb` are 4-space (Weblate wrote them); `intl_cs/de/en/it/pl/sk/tr/uk/zh.arb` are still 2-space (Weblate never wrote them). The component currently has `json_indent=4` (given). Setting it to 2 means the *next* save of each of those five files re-indents it wholesale, once.
- Also relevant to diffs: `ensure_ascii=False` (non-ASCII kept raw), trailing `\n`, no key re-ordering.

## 3. Language code style and filenames

- https://docs.weblate.org/en/latest/admin/projects.html#language-code-style — "Customize language code used to generate the filename for translations created by Weblate." Note: "Weblate recognizes any of the language codes when parsing translation files, following settings only influences how new files are created." Options (verbatim labels): "Default based on the file format — Dependent on file format, for most of them POSIX is used."; "POSIX style using underscore as a separator — Typically used by gettext and related tools, produces language codes like pt_BR."; "POSIX style using underscore as a separator, lower cased"; "POSIX style using underscore as a separator, including country code — … (for example cs_CZ)"; "…, including country code, lower cased"; "BCP style using hyphen as a separator — Typically used on web platforms, produces language codes like pt-BR."; "BCP style using hyphen as a separator, including country code"; "BCP style using hyphen as a separator, legacy language codes — Uses legacy codes for Chinese and BCP style notation."; "BCP style using hyphen as a separator, lower cased"; plus Apple App Store, Google Play, Android, Linux styles.
- API values, https://github.com/WeblateOrg/weblate/blob/main/weblate/trans/inherited_settings.py `LANGUAGE_CODE_STYLE_CHOICES`: `""`, `"posix"`, `"posix_lowercase"`, `"bcp"`, `"posix_long"`, `"posix_long_lowercase"`, `"bcp_long"`, … Component default: https://github.com/WeblateOrg/weblate/blob/main/weblate/trans/models/component.py `language_code_style = models.CharField(… default="", blank=True …)`.
- What `""` means for ARB: https://github.com/WeblateOrg/weblate/blob/main/weblate/formats/base.py — `TranslationFormat.language_format: str = "posix"`; `get_language_posix`: `return code.replace("-", "_")`; `get_language_filename`: `return mask.replace("*", code)`. `ARBFormat` does not override `language_format` (only `I18NextFormat` sets `"bcp"`). Weblate's internal codes are already POSIX (`pt_BR`, `zh_Hans`), so `lib/l10n/intl_*.arb` → `lib/l10n/intl_pt_BR.arb`, `lib/l10n/intl_zh_Hans.arb`. Confirmed by the export: `intl_pt_BR.arb`.
- Parsing existing files: https://docs.weblate.org/en/latest/admin/languages.html#parsing-language-codes — steps include "Case insensitive lookups.", "Normalizing underscores and dashes.", "Ignoring the default country code for a given language—choosing cs instead of cs_CZ."

### What gen-l10n accepts (Flutter 3.44.6)

https://github.com/flutter/flutter/blob/3.44.6/packages/flutter_tools/lib/src/localizations/gen_l10n_types.dart, `AppResourceBundle` factory:

- `var localeString = resources['@@locale'] as String?;` then "// Try to parse a locale from the filename." — first `Locale.tryParse(fileName)` on the whole basename, else "// If that fails, look for underscores and try parsing after each one." with `parserResult.toString().replaceAll('-', '_')`.
- So `intl_pt_BR.arb` → `pt_BR`; `intl_zh_Hans.arb` → `zh_Hans`; and `intl_pt-BR.arb` also → `pt_BR` (the suffix after the first `_` is `pt-BR`, which `package:intl`'s `Locale.tryParse` accepts). The directory filter is `RegExp(r'(\w+)\.arb$')` with `hasMatch`, so hyphenated names are not excluded. Verified empirically: a file named `intl_pt-BR.arb` generated the `pt_BR` class.
- Consequence: a hyphenated and an underscored file for the same locale collide: "Multiple arb files with the same '${bundle.locale}' locale detected. \n Ensure that there is exactly one arb file for each locale."
- https://github.com/flutter/flutter/blob/3.44.6/packages/flutter_tools/lib/src/localizations/localizations_utils.dart `LocaleInfo.fromString`: `final List<String> codes = locale.split('_'); // [language, script, country]`.

### The fallback-language rule (empirically the only thing that breaks)

Same file, `AppResourceBundleCollection`:

```
if (!localeStrings.contains(language)) {
  throw L10nException(
    'Arb file for a fallback, $language, does not exist, even though \n'
    'the following locale(s) exist: $listOfCorrespondingLocales. \n'
    'When locales specify a script code or country code, a \n'
    'base locale (without the script code or country code) should \n'
    'exist as the fallback. Please create a {fileName}_$language.arb \n'
    'file.',
```

Empirical (`flutter gen-l10n`, SDK 3.44.6, synthetic project with `template-arb-file: intl_en.arb`):

| Files present | Result |
|---|---|
| `intl_en`, `intl_de`, `intl_pt-BR` (full), `intl_zh_Hans` | exit 1: "Arb file for a fallback, pt, does not exist, even though the following locale(s) exist: [pt_BR]." |
| same but `intl_pt-BR.arb` = `{}` (what Weblate has now) | exit 1, same message (the check is on the locale set, not content) |
| + `intl_pt.arb` | exit 1: "Arb file for a fallback, zh, does not exist … [zh_Hans]" |
| + `intl_zh.arb` | exit 0; `l10n_untranslated.json` lists `de/pt/zh/zh_Hans: ["bye"]` |

So Weblate's `new_lang=add` + a translator picking "Portuguese (Brazil)" has already produced a file that will make `flutter gen-l10n` (and therefore `just check_l10n`) fail the moment it is merged, unless `intl_pt.arb` is added alongside. The upstream repo has `intl_zh.arb` but no `intl_pt.arb`.

## 4. "Adding new translation" (`new_lang`) semantics

- https://docs.weblate.org/en/latest/admin/projects.html#adding-new-translation — "How to handle requests for creation of new languages. Available options:"
  - "Contact maintainers — User can select desired language and the project maintainers will receive a notification about this. It is up to them to add (or not) the language to the repository."
  - "Point to translation instructions URL — User is presented a link to page which describes process of starting new translations."
  - "Create new language file — User can select language and Weblate automatically creates the file for it and translation can begin."
  - "Create existing project languages; contact maintainers for new languages — Users can create translations for languages already used as target languages in another non-glossary component in the project. Other languages are requested from maintainers, who approve them by creating the first target translation."
  - "Disable adding new translations — There will be no option for user to start new translation."
  - Hint: "The project admins can add new translations even if it is disabled here when it is possible (either Template for new translations or the file format supports starting from an empty file)."
- API values, https://github.com/WeblateOrg/weblate/blob/main/weblate/trans/inherited_settings.py `NEW_LANG_CHOICES`: `("contact", "Contact maintainers")`, `("url", "Point to translation instructions URL")`, `("add", "Create new language file")`, `("existing", "Create existing project languages; contact maintainers for new languages")`, `("none", "Disable adding new translations")`. Model default: https://github.com/WeblateOrg/weblate/blob/main/weblate/trans/models/component.py `new_lang = models.CharField(… default="add" …)`.
- https://docs.weblate.org/en/latest/devel/translations.html#adding-translation — "New languages can be added right away when requested by a user in Weblate, or a notification will be sent to project admins for approval and manual addition." And: "If you add a language file in connected remote repository, respective translation is added to the component when Weblate updates local repository."
- Implication: with `add` (current), any registered Hosted Weblate user can create `intl_<any Weblate language code>.arb`, including region/script variants that trip gen-l10n's fallback rule. `contact`/`existing` keep that decision with maintainers; a maintainer can still add a base `intl_pt.arb` in git and Weblate will pick it up on the next update.

## 5. Does Weblate write anything gen-l10n rejects?

- `@@locale`: never added. New files are `"{}\n"` (`empty_file_template`), and only content units are cloned (`has_content` = `not self.mainunit.isheader()`), so the `@@` header unit is not copied. Existing `@@…` blocks are preserved. gen-l10n: `@@locale` is optional — the Flutter docs' own translation example is just `app_es.arb`: `{ "helloWorld": "¡Hola Mundo!" }` (https://docs.flutter.dev/ui/internationalization); the error path is only `'The locale specified in @@locale and the arb filename do not match.'` (verified: `intl_de.arb` with `"@@locale": "fr"` → exit 1).
- `@key` objects in locale files: gen-l10n reads them — `localePlaceholders[bundle.locale] = templateBundle.locale == bundle.locale ? templatePlaceholders : _placeholders(bundle.resources, resourceId, false)` and `getPlaceholders(locale)` returns `placeholders[templatePlaceholder.name] ?? templatePlaceholder`. Copies identical to the template are therefore no-ops. They must be maps: `'The resource attribute "@$resourceId" is not a properly formatted Map.'` (verified exit 1 with a string). Weblate always writes a dict, so fine. `required-resource-attributes` is off in this repo's `l10n.yaml` and the docs say "By default, simple messages won't require metadata", so a missing `@key` in a locale file is also fine.
- Extra/stale keys in locale files: gen-l10n only iterates the template — https://github.com/flutter/flutter/blob/3.44.6/packages/flutter_tools/lib/src/localizations/gen_l10n.dart `for (final String resourceId in _templateBundle.resourceIds)`; verified: a `staleKey` in `intl_pt-BR.arb` produced no error and no generated symbol.
- Empty values: Weblate's `untranslate` writes `""`; gen-l10n's `translationFor` returns the `""` (non-null) so the locale is *not* reported untranslated (verified: pt_BR `"bye": ""` absent from `l10n_untranslated.json`, generated `String get bye => '';`). "Remove blank strings" add-on: "Removes strings without a translation from translation files." (https://docs.weblate.org/en/latest/admin/addons.html, `weblate.cleanup.blank`).
- Invalid key names: only possible if "Manage strings" (`manage_units`, model default `False`) is enabled and someone adds a key that is not a Dart identifier (gen-l10n: "Resources names must be valid Dart method names"). Not verified for this component — see open questions.
- Dotted keys: were once written nested (https://github.com/WeblateOrg/weblate/issues/13037, fixed via translate/translate#5415 "use flat structure by default for ARB files", 2024-11-18, and #5462). Irrelevant here since gen-l10n forbids dots anyway.
- Formatting only: 4-space indent and translation-order keys are cosmetic for gen-l10n (verified exit 0 with a 4-space file).

## 6. Relevant WeblateOrg/weblate and translate/translate issues

- https://github.com/WeblateOrg/weblate/issues/2847 "ARB file support" (closed 2020-06-03, "Blocked by upstream"; fixed via translate/translate#4040).
- https://github.com/WeblateOrg/weblate/issues/7708 "Non-uppercase placeholders are not properly recognized" (closed 2022-06-01) — WofWca: "Also perhaps the same goes for ARB files?"; nijel: "I see no reason to have the code twice, PR: …/pull/7744".
- https://github.com/WeblateOrg/weblate/pull/7744 "formats: Share code for JSON placeholders" (merged 2022-06-06) — deleted `ARBJSONUnit` (which emitted `{KEY}`) and set `ARBFormat.unit_class = PlaceholdersJSONUnit`; since then ARB placeholders are flagged WebExtension-style (`$KEY$`). See section 7.
- https://github.com/WeblateOrg/weblate/issues/16619 "ICU check returns false error result on int placeholder for plural" (Flutter/FluffyChat, closed 2025-11-05; fix shipped in 5.14.1 but reporter says it only special-cases `count`). nijel: "Weblate doesn't see the ARB metadata as the underlying library does not parse it." (comment 2025-12-11).
- https://github.com/WeblateOrg/weblate/issues/17269 "External type hints for ICU Message Format checks" (**open**, 2025-12-11, "Waiting for: Demand") — "Some formats (at least ARB) provide type hints for ICU Message Format externally. There is currently no way for Weblate to understand this."
- https://github.com/WeblateOrg/weblate/issues/6919 "How to show Plurals view on ARB file" (closed 2021-12-15, duplicate of #2967) — nijel: "Weblate displays plurals for formats with separate strings for each plural." ICU `{n, plural, …}` strings are edited as one string.
- https://github.com/WeblateOrg/weblate/issues/13037 dotted ARB keys nested (closed 2025-01-07).
- https://github.com/WeblateOrg/weblate/issues/11133 template notes not synced into translations (closed 2024-03-04 as "put aside").
- https://github.com/translate/translate/pull/6014 empty `"@key": {}` no longer written (3.18.1, 2026-01).
- No issue found mentioning `gen-l10n` (search `repo:WeblateOrg/weblate gen-l10n` returns only an unrelated 2012 issue) and no open issue on `@@locale` handling for ARB.

## 7. Placeholder checks for ARB

- Format-derived flags: https://github.com/WeblateOrg/weblate/blob/main/weblate/formats/ttkit.py `PlaceholdersJSONUnit.flags`: for a dict (ARB, WebExtension) `placeholder_ids = [f"${key.upper()}$" for key in placeholders]` and `flags.merge("case-insensitive")`; the `{id}` form is used only for the list branch ("# golang placeholders"). ARB stores `placeholders` as a dict, so it takes the WebExtension branch.
- Live confirmation, https://hosted.weblate.org/api/translations/opennutritracker/app/sv/units/?q=key%3AadditionalInfoLabelSource — `source: "More Information at\n{sourceName}"`, `flags: "case-insensitive, placeholders:$SOURCENAME$"`, `has_failing_check: false`.
- Why it is inert: https://github.com/WeblateOrg/weblate/blob/main/weblate/checks/placeholders.py `check_target_params`: `expected = self.get_match_set(value, sources[0], unit)` — only placeholders actually found in the source are required in the target; `$SOURCENAME$` is never found, so `missing`/`extra` stay empty. Docs: "These are either extracted from the translation file or defined manually using placeholders flag" (https://docs.weblate.org/en/latest/user/checks.html#check-placeholders). So: yes, `placeholders` **is** derived automatically from `@key` metadata, but in a form that does not match ARB syntax; setting your own `placeholders:` flag would only duplicate what ICU already checks.
- What actually validates `{name}`: https://docs.weblate.org/en/latest/user/checks.html#check-icu-message-format — "Syntax errors and/or placeholder mismatches in ICU MessageFormat strings."; "File formats automatically enabling this check: ARB File, Format.JS JSON file"; flag `icu-message-format` (set by `ARBFormat.check_flags`). Sub-checks can be relaxed with `icu-flags:` — "-types Skip checking that placeholder types match the source.", "-extra …", "-missing …", "-submessage_selectors …", "-require_other …".
- Limitation: the ICU check infers types from the ICU syntax of the source only; ARB `"type": "int"` hints are not read (#16619, #17269). For a source like `Load {count} more participants` translated as `{count, plural, …}` the `-types`/selector sub-check may complain; the maintainer's advice is to write the source in ICU plural form.

## Open questions

1. Which Weblate and translate-toolkit versions Hosted Weblate is running today. `/about/` and `/api/` do not expose it anonymously; the observed behaviour (no `"@key": {}` in written files, `existing` new_lang option present in docs) is consistent with 2026.x / translate-toolkit >= 3.18.1, but not proven.
2. Whether `description` in `@key` is copied into locale files: the code path (shallow `copy()` + `removenotes()` clearing only `notes`) says yes; this repo's template has zero descriptions, so it could not be observed.
3. The `manage_units` ("Manage strings") value of the `app` component — it decides whether Weblate users can introduce keys gen-l10n would reject. Not in the given context and not checked.
4. Whether a `preferred-supported-locales`/`supportedLocales` change is wanted once `pt`/`pt_BR` exist (app-side decision, out of scope here).

## Verification

Fact-checked 2026-09-12 by an independent pass. Every cited URL was re-fetched (docs pages via HTTP; GitHub blob URLs as the identical raw file at the same ref; issues/PRs/commits via the GitHub API; the Hosted Weblate export by `git clone`; the Hosted Weblate API by HTTP). The three gen-l10n behaviours (fallback rule, hyphenated filename, duplicate locale) were re-run with `~/fvm/versions/3.44.6/bin/flutter gen-l10n` on a fresh synthetic project.

**Result: 43 of 44 claims supported; 1 overreaches (Flutter docs on resource attributes).**

| # | Claim (short) | Verdict | Note |
|---|---|---|---|
| 1 | ARB is monolingual, base file expected | supported | Verbatim on formats/arb.html. The features table on the same page says "Linguality: Both monolingual and bilingual"; the prose says translations are monolingual. |
| 2 | Feature table + typical config | supported | Table and config block match verbatim. |
| 3 | Docs recommend empty template for monolingual | supported | Quote is on devel/translations.html ("as is the case with most monolingual translation flows, you can start with empty files"); the explicit "Keep this field empty for most of the monoligual formats" is on admin/projects.html#template-for-new-translations. |
| 4 | ttk parser: `@@` header unit, skip `@key`, attach metadata | supported | jsonl10n.py master lines 1014–1044. |
| 5 | `@key` written after key only when non-empty | supported | `ARBJsonUnit.storevalues`. Also: `if self.notes: self.metadata["description"] = self.notes` runs first. |
| 6 | Whole-file `json.dumps` on save | supported | `JsonFile.serialize`, inherited unchanged by `ARBJsonFile`. |
| 7 | ttk ARB default indent 2 since 2020 | supported | Commit 28f6e3b553 (2020-06-03, "json: Add support for ARB files") adds `'indent': 2`; master still has it. |
| 8 | Empty `@key: {}` dropped since 3.18.1 | supported | PR 6014 merged 2026-01-14; merge commit is an ancestor of tag 3.18.1; release notes: "Store metadata in ARB only if present". |
| 9 | ARBFormat unit_class/check_flags/empty_file_template | supported | ttkit.py main. |
| 10 | Shallow copy of template unit copies metadata | supported | base.py `clone_template`: `copy(self.template)`; `MetadataTranslationUnit._metadata_dict` reference is shared. |
| 11 | Only `notes` stripped; metadata dict written | supported | ttkit.py `TTKitUnit.clone_template` → `removenotes()`; translate-toolkit `removenotes` only does `self.notes = ""`. |
| 12 | No sync of template notes (#11133) | supported | nijel 2024-03-07. Correction to the body above: the issue was closed 2024-07-29 (state_reason completed), not 2024-03-04. |
| 13 | No automatic stale-string cleanup | supported | devel/integration.html verbatim. |
| 14 | JSON add-on removed in 5.13 | supported | admin/addons.html verbatim. |
| 15 | json_* params apply to arb | supported | All four list `arb`; choices verbatim. |
| 16 | json_indent int, default 4, min 0 | supported | file_format_params.py. |
| 17 | Indent always overridden from json_indent | supported | `JSONOutputIndentStyle.setup_store` runs for every registered param of the format on load; `get_value` falls back to the class default. |
| 18 | Export: Weblate files 4-space, others 2-space, @key == template | supported | Re-cloned (HEAD afbad29): es/fr/hu/ru/sv indent 4; cs/de/en/it/pl/sk/tr/uk/zh indent 2; fr/hu/ru 50/50, es 24/24, sv 1/1 `@key` blocks identical to template; pt_BR is `{}`. **Correction to section 1:** `intl_zh.arb` (upstream, never touched by Weblate) does contain `"@@locale": "zh"`, so "No @@locale anywhere" is wrong; the point that Weblate never adds one stands. |
| 19 | Code style only affects new filenames | supported | Verbatim note. |
| 20 | POSIX pt_BR / BCP pt-BR / default per format | supported | Verbatim. |
| 21 | ARBFormat inherits `language_format = "posix"` | supported | base.py line 399; ARBFormat/JSONFormat do not override; `get_language_posix` and `get_language_filename` as quoted. |
| 22 | new_lang API values | supported | inherited_settings.py `NEW_LANG_CHOICES`. |
| 23 | new_lang semantics | supported | admin/projects.html verbatim. |
| 24 | Model defaults add / "" | supported | component.py lines 851–852, 865–867. |
| 25 | @@locale optional; filename parsing; hyphen→underscore | supported | gen_l10n_types.dart 636–676. Order: whole basename first, then substring after each `_`. |
| 26 | Error only on @@locale/filename mismatch | supported | Line 666. |
| 27 | Fallback rule; `{}` pt_BR without pt exits 1 | supported | Reproduced: exit 1, "Arb file for a fallback, pt, does not exist…"; adding `intl_pt.arb` → exit 0. |
| 28 | Duplicate locale rejected | supported | Reproduced with `intl_pt-BR.arb` + `intl_pt_BR.arb`: exit 1, "Multiple arb files with the same 'pt_BR' locale detected." `intl_pt-BR.arb` alone generates `AppLocalizationsPtBr`. |
| 29 | Per-locale @key placeholders merged by name | supported | Lines 373–375, 417–425. |
| 30 | Only template resource ids iterated | supported | gen_l10n.dart line 968. |
| 31 | Flutter docs: translation file w/o @key; attributes not required by default | **overreaches** | The `app_es.arb` example and the quote are on the page, but the same sentence continues: "Resource attributes are still required for plural messages." The claim's "resource attributes are not required by default" is only true for simple messages. |
| 32 | `LocaleInfo.fromString` splits on `_` | supported | localizations_utils.dart line 43. |
| 33 | WebExtension branch → `$NAME$` + case-insensitive | supported | ttkit.py `PlaceholdersJSONUnit.flags`. |
| 34 | Live flags `case-insensitive, placeholders:$SOURCENAME$` | supported | API re-queried 2026-09-12; `has_failing_check: false`. |
| 35 | Placeholders check only requires what the source contains | supported | `check_target_params`. Residual: an `extra` would fire if a target literally contained `$SOURCENAME$`. |
| 36 | Flag extracted from file or set manually | supported | user/checks.html verbatim. |
| 37 | ICU check auto-enabled for ARB; icu-flags sub-checks | supported | Verbatim. |
| 38 | PR 7744 removed `{KEY}` ARB unit | supported | Patch deletes `ARBJSONUnit` (`f"{{{key.upper()}}}"`) and sets `unit_class = PlaceholdersJSONUnit`; merged 2022-06-06. |
| 39 | ICU check can't see ARB type hints → false positives | supported | nijel 2025-12-11 verbatim. Nuance: nijel's 2025-11-05 comment says the trigger was the source string not being in plural form; the 5.14.1 fix only special-cases `count` (reporter, 2025-11-13). |
| 40 | #17269 open | supported | Open, "Waiting for: Demand". |
| 41 | No plural view for ARB (#6919) | supported | nijel 2021-12-14 verbatim. |
| 42 | Remove blank strings add-on | supported | Verbatim, `weblate.cleanup.blank`. |
| 43 | Cleanup translation files add-on | supported | Verbatim, `weblate.cleanup.generic`. |
| 44 | Underscore/dash normalisation | supported | admin/languages.html verbatim. |

### Gaps the research did not close with a source

- **`zh` vs `zh_Hans` in Weblate.** https://github.com/WeblateOrg/weblate/issues/5427 (closed 2021-02-15): Weblate maps `zh` and `zh_Hans` to the same language and raises the alert "The component contains several translation files mapped to a single language" when both files exist; the reporter's workaround was a language filter. This interacts directly with gen-l10n's fallback rule (which *requires* `intl_zh.arb` next to `intl_zh_Hans.arb`) and was not covered. Whether Weblate would even offer `zh_Hans` to a translator while `intl_zh.arb` exists is unanswered.
- Which Weblate / translate-toolkit versions Hosted Weblate runs (acknowledged in Open questions).
- Whether `description` is actually copied into locale files — inferred from code only, no observation (acknowledged).
- The component's `manage_units` value (acknowledged).
- "Weblate never writes `@@locale`" rests on code inference (`empty_file_template = "{}\n"`, header unit not cloned); no doc or issue states it.
