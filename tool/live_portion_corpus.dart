// Runs a generated corpus of meal lines — most of them naming a household
// measure — through `ModelMealTextInterpreter` on each hosted provider and
// reports what the model did with `portion` (#1160).
//
// For every item: was a key emitted; is it one of the eight steering words
// (#1158); is it English rather than the line's own word (#1157); does it
// match a row of the food the resolver lands on, via `matchPortionToQuery`
// against the food's *English* labels; when it matches, was the winner a
// tie or a hit on an inflection rather than the word as written (the
// false-match surface); when it misses, whether the row would raise
// `amountNeedsCheck` (#1159) — which needs a count and no match by the
// query words either, since `_initialUnit` tries those before defaulting.
// Plus the abbreviation cases (`tbsp` → `tablespoon`), the unit-substitution
// rule the prompt states, the old harness's invariants and its differential
// against `parseMealText`, and a stability probe.
//
//   dart run tool/live_portion_corpus.dart --keys <dir> --out <dir>
//   dart run tool/live_portion_corpus.dart --dry-run --out <dir>
//
// Keys are read from files, never printed. The only network use in a dry
// run is the two read-only backend RPCs the resolver makes. The reports are
// rewritten after every provider, so a run that dies on provider two still
// leaves provider one's replies on disk.

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:opennutritracker/features/add_meal/data/model_meal_text_interpreter.dart';
import 'package:opennutritracker/features/add_meal/domain/meal_items_api.dart';
import 'package:opennutritracker/features/add_meal/util/meal_text_parser.dart';

import 'portion_measurement/cli.dart';
import 'portion_measurement/corpus.dart';
import 'portion_measurement/metrics.dart';
import 'portion_measurement/prompts.dart';
import 'portion_measurement/providers.dart';
import 'portion_measurement/resolver.dart';
import 'portion_measurement/session.dart';

const corpusSeed = 20260911;

/// Everything recorded about one item of one reply.
class ItemRecord {
  final String provider;
  final Case line;
  final int index;
  final ParsedMealItem item;
  final RawItem? raw;
  final KeyLanguage? language;
  final bool? matchesExpectedKey;
  final bool unitSubstituted;
  final ResolvedFood? food;
  final String? resolvedVia;

  /// The backend did not answer for this item; nothing below is known.
  final String? backendFailure;
  final PortionMatch? match;

  /// What `_initialUnit`'s second try finds — the query words against the
  /// labels of the line's own locale — computed only when the key missed,
  /// because the app only reaches it then.
  final PortionMatch? queryMatch;
  final int latencyMs;

  const ItemRecord({
    required this.provider,
    required this.line,
    required this.index,
    required this.item,
    required this.raw,
    required this.language,
    required this.matchesExpectedKey,
    required this.unitSubstituted,
    required this.food,
    required this.resolvedVia,
    required this.backendFailure,
    required this.match,
    required this.queryMatch,
    required this.latencyMs,
  });

  String? get key => item.portion;
  bool get emitted => key != null;
  bool get steering =>
      key != null && steeringWords.contains(key!.trim().toLowerCase());
  bool get expectedByLine => index == 0 && line.expected != null;

  /// The key matched no row of a resolved food.
  bool get keyMiss => emitted && food != null && match == null;

  /// The row `amountNeedsCheck` would flag under #1159's rule, as the getter
  /// is gated: a count is present, the key matched nothing, and neither did
  /// the query words — a key miss whose query hits a row never reaches the
  /// bare-count rule, and a row with no count is outside the getter.
  bool get amountNeedsCheckFires =>
      keyMiss && item.quantity != null && queryMatch == null;

  /// How the line's abbreviation came back, when it carried one.
  String? get abbreviationOutcome {
    final e = line.expected;
    if (!expectedByLine || e == null || !e.abbreviation) return null;
    final k = key;
    if (k == null) return 'no key';
    if (k.trim().toLowerCase() == e.key) return 'expanded';
    if (isAbbreviationKey(k)) return 'kept as written';
    return 'other key';
  }

  Map<String, Object?> toJson() => {
    'provider': provider,
    'locale': line.locale,
    'input': line.input,
    'expected': line.expected?.toJson(),
    'index': index,
    'query': item.query,
    'quantity': item.quantity,
    'unit': item.unit,
    'portion': item.portion,
    'raw': raw?.json,
    'emitted': emitted,
    'steering': steering,
    'asciiLetters': key == null ? null : isAsciiLetters(key!),
    'keyLanguage': language?.name,
    'matchesExpectedKey': matchesExpectedKey,
    'abbreviationOutcome': abbreviationOutcome,
    'unitSubstituted': unitSubstituted,
    'resolvedVia': resolvedVia,
    'backendFailure': backendFailure,
    'food': food?.toJson(),
    'match': match?.toJson(),
    'queryMatch': queryMatch?.toJson(),
    'keyMiss': keyMiss,
    'amountNeedsCheckFires': amountNeedsCheckFires,
    'latencyMs': latencyMs,
  };
}

class ProviderRun {
  final ProviderSession session;
  final items = <ItemRecord>[];
  final failures = <String>[];
  final violations = <String>[];
  final disagreements = <String>[];
  final backendFailures = <String>[];
  final latencies = <int>[];
  final unstable = <String>[];
  final portionMoved = <String>[];
  var stabilityLines = 0;
  var emptyResults = 0;
  var linesDone = 0;

  /// Set when the session ended on something other than a provider or
  /// backend failure; what was recorded before it is still reported.
  String? aborted;

  ProviderRun(this.session);
}

Future<void> main(List<String> args) async {
  final opts = parseOptions(
    args,
    tool: 'live_portion_corpus.dart',
    defaultCount: defaultTextCount,
  );
  final corpus = buildCorpus(opts.count, corpusSeed);
  final access = readSupabaseAccess(opts.envPath);
  final backend = http.Client();
  final resolver = FoodResolver(backend, access);
  final prompts = readPromptsAsRun();
  final sessions = openSessions(opts);
  if (sessions.isEmpty) {
    stderr.writeln('no provider to run');
    exit(1);
  }
  opts.outDir.createSync(recursive: true);

  final runs = <ProviderRun>[];
  void write() {
    final stamp = DateTime.now().toUtc().toIso8601String();
    final report = _report(
      runs: runs,
      sessions: sessions,
      corpus: corpus,
      opts: opts,
      prompts: prompts,
      resolver: resolver,
      stamp: stamp,
    );
    File('${opts.outDir.path}/portion-corpus.md').writeAsStringSync(report);
    File('${opts.outDir.path}/portion-corpus.items.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        'generated': stamp,
        'dryRun': opts.dryRun,
        'seed': corpusSeed,
        'count': corpus.length,
        'corpus': [for (final c in corpus) c.toJson()],
        'items': [
          for (final run in runs)
            for (final i in run.items) i.toJson(),
        ],
        'failures': {for (final r in runs) r.session.label: r.failures},
        'backendFailures': {
          for (final r in runs) r.session.label: r.backendFailures,
        },
        'disagreements': {for (final r in runs) r.session.label: r.disagreements},
        'unstable': {for (final r in runs) r.session.label: r.unstable},
        'aborted': {for (final r in runs) r.session.label: r.aborted},
      }),
    );
  }

  for (final session in sessions) {
    stdout.writeln('${session.label}: ${corpus.length} lines');
    final run = ProviderRun(session);
    runs.add(run);
    try {
      await _runCorpus(run, corpus, resolver, opts.dryRun);
      await _runStability(run, corpus);
    } catch (e) {
      // Whatever it was, the replies already recorded are worth the file.
      // The message is the exception's type alone: nothing that could
      // carry a URL or a body reaches the report.
      run.aborted = e.runtimeType.toString();
      stderr.writeln('${session.label}: aborted by ${run.aborted}');
    } finally {
      session.close();
      write();
    }
  }
  backend.close();

  stdout.writeln(
    'wrote ${opts.outDir.path}/portion-corpus.md and '
    '${opts.outDir.path}/portion-corpus.items.json',
  );
  for (final run in runs) {
    final emitted = run.items.where((i) => i.expectedByLine && i.emitted).length;
    final expected = run.items.where((i) => i.expectedByLine).length;
    final matched = run.items.where((i) => i.match != null).length;
    stdout.writeln(
      '${run.session.label}: emitted ${ratio(emitted, expected)} on measure '
      'lines | matched $matched | key misses '
      '${run.items.where((i) => i.keyMiss).length} | amountNeedsCheck fires '
      '${run.items.where((i) => i.amountNeedsCheckFires).length} | '
      'failures ${run.failures.length} | backend failures '
      '${run.backendFailures.length} | violations ${run.violations.length} '
      '| disagreements ${run.disagreements.length} '
      '| unstable ${run.unstable.length}/${run.stabilityLines}'
      '${run.aborted == null ? '' : ' | ABORTED (${run.aborted})'}',
    );
  }
}

Future<void> _runCorpus(
  ProviderRun run,
  List<Case> corpus,
  FoodResolver resolver,
  bool dryRun,
) async {
  final interpreter = ModelMealTextInterpreter(run.session.api);

  Future<void> one(Case c) async {
    final started = DateTime.now();
    MealTextParseResult result;
    try {
      result = await withRetry(
        () => interpreter.interpret(c.input, localeCode: c.locale),
      );
    } on MealInterpreterException catch (e) {
      run.failures.add(
        '`${_oneLine(c.input)}` _${c.locale}_ — ${e.failure.name} '
        '(${e.statusCode ?? '-'})',
      );
      return;
    } finally {
      run.latencies.add(DateTime.now().difference(started).inMilliseconds);
      if (++run.linesDone % 25 == 0) {
        stdout.writeln('  ${run.linesDone}/${corpus.length}');
      }
    }
    final latency = run.latencies.last;
    if (result.items.isEmpty) run.emptyResults++;

    final bad = invariants(c.input, result);
    if (bad.isNotEmpty) {
      run.violations.add('`${_oneLine(c.input)}` _${c.locale}_ — ${bad.join('; ')}');
    }

    // The 503a4518 differential: where the deterministic parser is
    // confident — a number and a unit it knows — the model must not read
    // the same unit with a different number.
    final offline = parseMealText(c.input);
    if (offline.items.length == result.items.length && offline.items.isNotEmpty) {
      for (var i = 0; i < offline.items.length; i++) {
        final a = offline.items[i];
        final b = result.items[i];
        if (a.quantity != null &&
            b.quantity != null &&
            a.unit != null &&
            b.unit != null &&
            a.unit == b.unit &&
            (a.quantity! - b.quantity!).abs() > 0.001) {
          run.disagreements.add(
            '`${_oneLine(c.input)}` _${c.locale}_ item $i: parser '
            '${a.quantity}${a.unit}, model ${b.quantity}${b.unit}',
          );
        }
      }
    }

    final rawItems = run.session.raw.takeRawItems(textNeedle(c.input));
    for (final (index, item) in result.items.indexed) {
      // Raw items line up with validated ones only when nothing was dropped;
      // a dropped entry shifts the rest, so pair by query as a fallback.
      RawItem? raw;
      if (rawItems != null) {
        final byIndex = index < rawItems.length ? RawItem(rawItems[index]) : null;
        raw = byIndex != null && byIndex.query == item.query
            ? byIndex
            : rawItems
                  .map(RawItem.new)
                  .where((r) => r.query == item.query)
                  .firstOrNull;
      }
      final expected = index == 0 ? c.expected : null;
      final key = item.portion;

      // On an English line the line's own word *is* English, so only a
      // non-English line can fail #1157's test.
      final language = key == null
          ? null
          : keyLanguage(
              key,
              askedKey: expected?.key,
              inputMeasureForms: c.locale == 'en'
                  ? const []
                  : expected?.measureForms ?? const [],
            );
      final matchesExpected = expected == null || key == null
          ? null
          : key.trim().toLowerCase() == expected.key;
      // The prompt: "Do not substitute a unit from the list". A measure
      // line states no unit the parser knows, so any unit on the wire is
      // one the model put there. Validation drops it (#977); the raw reply
      // still shows it.
      final unitSubstituted =
          expected != null && (raw?.unit != null || item.unit != null);

      ResolvedFood? food;
      String? via;
      String? backendFailure;
      PortionMatch? match;
      PortionMatch? queryMatch;
      try {
        if (c.locale == 'en' || expected == null) {
          food = await resolver.resolve(item.query);
          via = 'query';
        } else {
          food = await resolver.resolve(expected.food.en);
          via = 'englishEquivalent';
        }
        if (key != null && food != null) {
          match = matchWithTie(key, food.portions);
          if (match == null) {
            // The app's second try, against the labels a user of this
            // locale receives — the English ones already fetched for
            // English, the locale's coalesced ones otherwise.
            final localized = c.locale == 'en'
                ? food.portions
                : await resolver.localizedPortions(food.foodId, c.locale);
            queryMatch = matchWithTie(item.query, localized);
          }
        }
      } on BackendException catch (e) {
        backendFailure = e.toString();
        run.backendFailures.add(
          '`${_oneLine(c.input)}` _${c.locale}_ `${item.query}` — $e',
        );
        food = null;
        via = null;
        match = null;
        queryMatch = null;
      }

      run.items.add(
        ItemRecord(
          provider: run.session.label,
          line: c,
          index: index,
          item: item,
          raw: raw,
          language: language,
          matchesExpectedKey: matchesExpected,
          unitSubstituted: unitSubstituted,
          food: food,
          resolvedVia: food == null ? null : via,
          backendFailure: backendFailure,
          match: match,
          queryMatch: queryMatch,
          latencyMs: latency,
        ),
      );
    }
  }

  // Bounded concurrency so a burst does not trip rate limits.
  final lanes = dryRun ? 8 : 4;
  for (var i = 0; i < corpus.length; i += lanes) {
    await Future.wait(corpus.skip(i).take(lanes).map(one));
  }
}

/// The same line asked three times. The signature includes the key, and a
/// line whose key moved while the rest held is counted separately, because
/// that is the instability this measurement is about.
Future<void> _runStability(ProviderRun run, List<Case> corpus) async {
  final interpreter = ModelMealTextInterpreter(run.session.api);
  final rng = Random(7);
  // Prefer measure lines: they are the ones with a key to move.
  final measureLines = corpus.where((c) => c.expected != null).toList();
  final pool = measureLines.length >= stabilitySampleSize ? measureLines : corpus;
  final sample = <Case>{};
  while (sample.length < min(stabilitySampleSize, pool.length)) {
    sample.add(pool[rng.nextInt(pool.length)]);
  }
  run.stabilityLines = sample.length;

  String sig(MealTextParseResult r, {bool withKey = true}) => r.items
      .map(
        (i) =>
            '${i.query}|${i.quantity}|${i.unit}${withKey ? '|${i.portion}' : ''}',
      )
      .join(' ~ ');

  for (final c in sample) {
    final answers = <MealTextParseResult>[];
    try {
      for (var i = 0; i < stabilityRepeats; i++) {
        answers.add(
          await withRetry(
            () => interpreter.interpret(c.input, localeCode: c.locale),
          ),
        );
        // Not needed for the numbers; taken so the store does not grow.
        run.session.raw.takeRawItems(textNeedle(c.input));
      }
    } on MealInterpreterException {
      continue; // counted in the corpus pass
    }
    final sigs = answers.map(sig).toSet();
    if (sigs.length > 1) {
      run.unstable.add(
        '`${_oneLine(c.input)}` _${c.locale}_\n${answers.map((a) => '  - ${sig(a)}').join('\n')}',
      );
      final withoutKey = answers.map((a) => sig(a, withKey: false)).toSet();
      if (withoutKey.length == 1) run.portionMoved.add(_oneLine(c.input));
    }
  }
}

String _oneLine(String s) => s.replaceAll('\n', ' / ');

String _report({
  required List<ProviderRun> runs,
  required List<ProviderSession> sessions,
  required List<Case> corpus,
  required MeasurementOptions opts,
  required PromptsAsRun prompts,
  required FoodResolver resolver,
  required String stamp,
}) {
  final b = StringBuffer();
  final measureLines = corpus.where((c) => c.expected != null).length;
  final byLocale = <String, int>{};
  final measureByLocale = <String, int>{};
  for (final c in corpus) {
    byLocale[c.locale] = (byLocale[c.locale] ?? 0) + 1;
    if (c.expected != null) {
      measureByLocale[c.locale] = (measureByLocale[c.locale] ?? 0) + 1;
    }
  }

  b
    ..writeln('# Live portion corpus — text path (#1160)')
    ..writeln()
    ..writeln(
      '${corpus.length} generated lines (seed `$corpusSeed`), $measureLines '
      'of them naming a household measure, across ${byLocale.length} '
      'locales; $stamp.',
    )
    ..writeln();
  if (opts.dryRun) {
    b
      ..writeln(
        '> **Dry run.** Every provider below is `FakeMealItemsApi`, a table '
        'built to exercise each branch of the pipeline — the English key, '
        'the own-language key, an abbreviation kept as written, a '
        'substituted unit, no key, a key on a plain line, one failed line, '
        'and two lines that move on repeat; no model was called. The '
        'backend *was* called — read-only `search_food_summary` and '
        '`portions_by_food_ids` — so the resolution, matching and tie '
        'columns are real.',
      )
      ..writeln();
  }
  if (runs.length < sessions.length) {
    b
      ..writeln(
        '> **Partial.** ${runs.length} of ${sessions.length} providers so '
        'far; this file is rewritten after each.',
      )
      ..writeln();
  }
  for (final run in runs.where((r) => r.aborted != null)) {
    b
      ..writeln(
        '> **${run.session.label} aborted** (${run.aborted}) after '
        '${run.linesDone} lines; what it recorded is counted below.',
      )
      ..writeln();
  }
  b.writeln(
    textCallBudget(
      textCount: corpus.length,
      stabilityLines: stabilityLinesFor(
        corpusLength: corpus.length,
        measureLines: measureLines,
      ),
      sessions: sessions,
    ),
  );

  b
    ..writeln('## The prompt sentences as run')
    ..writeln()
    ..writeln('Read from the sources at run time, not from a copy.')
    ..writeln()
    ..writeln('**Schema, `portion` description:**')
    ..writeln()
    ..writeln('> ${prompts.schemaPortionDescription}')
    ..writeln()
    ..writeln('**Text prompt, the portion bullet:**')
    ..writeln()
    ..writeln('> ${promptBullet(prompts.textSystemPrompt, 'If the user named a household measure')}')
    ..writeln()
    ..writeln('<details><summary>The whole text system prompt</summary>')
    ..writeln()
    ..writeln('```')
    ..writeln(prompts.textSystemPrompt.trimRight())
    ..writeln('```')
    ..writeln()
    ..writeln('</details>')
    ..writeln();

  b
    ..writeln('## How to read the columns')
    ..writeln()
    ..writeln(
      '- *Measure lines* are the lines a template generated with a '
      'household word, so the key the prompt asks for is known. Rates are '
      'over the first item of those lines.',
    )
    ..writeln(
      '- *English* counts a key that is one of the eight steering words, '
      'the English word the line\'s template asked for (`glass`, `bowl`, '
      '`handful`), or ASCII-lettered and not the line\'s own word; *own '
      'word* is a key equal to, or a short inflection of, any written form '
      'of the line\'s own words for that measure — "Scheibe" for a German '
      'line, and also "Glas" answered to a *Gläser* line or "tazza" to a '
      '*tazze* line — the failure #1157 names.',
    )
    ..writeln(
      '- *Resolved* is the top record of `search_food_summary` ranked by '
      '`textRelevanceScore`, portions fetched with `loc = en`. English lines '
      'resolve by the model\'s query; other locales resolve by the '
      'template\'s English food name, since the localized search is not '
      'called here.',
    )
    ..writeln(
      '- *Matched* is `matchPortionToQuery(key, portions) != null`; *tie* '
      'means another row scored the same and the earlier one won; *not '
      'literal* means the hit came through the matcher\'s two-letter '
      'inflection bound and no word of the key is a word of the winning '
      'label as written. Together those are the *false-match surface* '
      '#1160 asks for — the hits where a wrong row is possible; whether '
      'one *is* wrong is for the reader, and every one is listed with the '
      'row it picked.',
    )
    ..writeln(
      '- *Key miss* is a key on a resolved food that matched nothing. '
      '*amountNeedsCheck fires* is the subset #1159\'s rule would flag, as '
      'the getter is gated: the row has a count, and the query words miss '
      'too — `_initialUnit` tries `matchPortionToQuery(query, portions)` '
      'before defaulting, against the labels of the line\'s own locale, so '
      'a key miss whose query words hit a row is not flagged, and a row '
      'with no count is outside the getter. A key miss on a food with no '
      'rows always fires.',
    )
    ..writeln();

  b
    ..writeln('## Summary per provider')
    ..writeln();
  final summaryRows = <List<Object?>>[];
  for (final run in runs) {
    final all = run.items;
    final first = all.where((i) => i.expectedByLine).toList();
    final emitted = first.where((i) => i.emitted).toList();
    final keyed = all.where((i) => i.emitted).toList();
    final unchecked = keyed.where((i) => i.backendFailure != null).length;
    final resolvedKeyed = keyed.where((i) => i.food != null).toList();
    final matched = resolvedKeyed.where((i) => i.match != null).toList();
    final ties = matched.where((i) => i.match!.tie).length;
    final notLiteral = matched.where((i) => !i.match!.literal).length;
    final suspect = matched.where((i) => i.match!.suspect).length;
    final misses = resolvedKeyed.where((i) => i.keyMiss).toList();
    final missesNoRows = misses.where((i) => i.food!.portions.isEmpty).length;
    final missesRescued = misses.where((i) => i.queryMatch != null).length;
    final missesNoCount = misses.where((i) => i.item.quantity == null).length;
    final fires = misses.where((i) => i.amountNeedsCheckFires).length;
    final english = emitted
        .where((i) => englishKeyLanguages.contains(i.language))
        .length;
    final ownWord = emitted.where((i) => i.language == KeyLanguage.inputWord).length;
    final abbreviations = first.where((i) => i.line.expected!.abbreviation).toList();
    int outcome(String o) =>
        abbreviations.where((i) => i.abbreviationOutcome == o).length;
    final substitutions = first.where((i) => i.unitSubstituted).length;
    final unasked = all.where((i) => !i.expectedByLine && i.emitted).length;
    final sorted = run.latencies.toList()..sort();
    summaryRows.add([
      run.session.label,
      code(run.session.model),
      corpus.length,
      run.failures.length,
      run.emptyResults,
      first.length,
      ratio(emitted.length, first.length),
      ratio(emitted.where((i) => i.steering).length, emitted.length),
      ratio(english, emitted.length),
      ratio(ownWord, emitted.length),
      ratio(emitted.where((i) => i.matchesExpectedKey == true).length, emitted.length),
      '${ratio(resolvedKeyed.length, keyed.length)}'
          '${unchecked == 0 ? '' : ', $unchecked unchecked (backend)'}',
      ratio(matched.length, resolvedKeyed.length),
      ratio(ties, matched.length),
      ratio(notLiteral, matched.length),
      ratio(suspect, matched.length),
      ratio(misses.length, resolvedKeyed.length),
      ratio(missesNoRows, misses.length),
      ratio(missesRescued, misses.length),
      ratio(missesNoCount, misses.length),
      ratio(fires, resolvedKeyed.length),
      '${ratio(outcome('expanded'), abbreviations.length)} '
          '(kept ${outcome('kept as written')}, other ${outcome('other key')}, '
          'no key ${outcome('no key')})',
      substitutions,
      unasked,
      run.violations.length,
      run.disagreements.length,
      '${run.unstable.length}/${run.stabilityLines} (key alone: ${run.portionMoved.length})',
      sorted.isEmpty
          ? '–'
          : '${percentile(sorted, 0.5)} / ${percentile(sorted, 0.95)} / ${sorted.last} ms',
    ]);
  }
  b.writeln(
    table(
      [
        'provider', 'model', 'lines', 'failed', 'empty', 'measure lines',
        'key emitted', 'steering word', 'English', 'own word',
        'key = expected', 'resolved (of keyed)', 'matched (of resolved)',
        'tie (of matched)', 'not literal (of matched)',
        'false-match surface (of matched)', 'key miss (of resolved)',
        'of which: food has no rows', 'of which: query words hit a row',
        'of which: no count', 'amountNeedsCheck fires (of resolved)',
        'abbreviation expanded', 'unit substituted', 'key on plain line',
        'invariant violations', 'parser disagreements', 'unstable',
        'latency p50 / p95 / max',
      ],
      summaryRows,
    ),
  );

  b
    ..writeln('## Per locale')
    ..writeln();
  final localeRows = <List<Object?>>[];
  for (final run in runs) {
    for (final locale in localeWeights.keys) {
      final first = run.items
          .where((i) => i.expectedByLine && i.line.locale == locale)
          .toList();
      final emitted = first.where((i) => i.emitted).toList();
      final resolvedKeyed = emitted.where((i) => i.food != null).toList();
      final matched = resolvedKeyed.where((i) => i.match != null).length;
      localeRows.add([
        run.session.label,
        locale,
        byLocale[locale] ?? 0,
        first.length,
        ratio(emitted.length, first.length),
        ratio(emitted.where((i) => i.steering).length, emitted.length),
        ratio(
          emitted.where((i) => i.language == KeyLanguage.inputWord).length,
          emitted.length,
        ),
        ratio(emitted.where((i) => i.matchesExpectedKey == true).length, emitted.length),
        ratio(resolvedKeyed.length, emitted.length),
        ratio(matched, resolvedKeyed.length),
        ratio(resolvedKeyed.length - matched, resolvedKeyed.length),
        ratio(
          resolvedKeyed.where((i) => i.amountNeedsCheckFires).length,
          resolvedKeyed.length,
        ),
      ]);
    }
  }
  b.writeln(
    table(
      [
        'provider', 'locale', 'lines', 'measure lines', 'key emitted',
        'steering', 'own word', 'key = expected', 'resolved', 'matched',
        'key miss', 'amountNeedsCheck fires',
      ],
      localeRows,
    ),
  );

  b
    ..writeln('## What the line said and what the key was')
    ..writeln()
    ..writeln('Per provider, per measure word as written; keys with counts.')
    ..writeln();
  final saidRows = <List<Object?>>[];
  for (final run in runs) {
    final groups = <String, Map<String, int>>{};
    final expectedKeyOf = <String, String>{};
    for (final i in run.items.where((i) => i.expectedByLine)) {
      final e = i.line.expected!;
      final g = '${i.line.locale}|${e.measureWord}';
      expectedKeyOf[g] = e.key;
      final m = groups.putIfAbsent(g, () => {});
      final k = i.key == null ? '(none)' : '`${i.key!.trim()}`';
      m[k] = (m[k] ?? 0) + 1;
    }
    final keys = groups.keys.toList()..sort();
    for (final g in keys) {
      final parts = g.split('|');
      final seen = groups[g]!.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      saidRows.add([
        run.session.label,
        parts[0],
        parts[1],
        code(expectedKeyOf[g]),
        seen.map((e) => '${e.key} ×${e.value}').join(', '),
      ]);
    }
  }
  b.writeln(table(['provider', 'locale', 'line said', 'expected key', 'keys seen'], saidRows));

  _section(
    b,
    'Abbreviation cases',
    [
      for (final run in runs)
        for (final i in run.items.where((i) => i.abbreviationOutcome != null))
          '- ${run.session.label} `${_oneLine(i.line.input)}` → key ${code(i.key)}'
              ' ${i.abbreviationOutcome == 'expanded' ? 'expanded' : '**${i.abbreviationOutcome}**'}',
    ],
  );

  _section(
    b,
    'Unit substitutions (the prompt forbids them)',
    [
      for (final run in runs)
        for (final i in run.items.where((i) => i.unitSubstituted))
          '- ${run.session.label} `${_oneLine(i.line.input)}` → raw unit '
              '${code(i.raw?.unit)}, validated unit ${code(i.item.unit)}, '
              'quantity ${i.item.quantity}',
    ],
  );

  String hit(ItemRecord i) =>
      '- ${i.provider} `${_oneLine(i.line.input)}` key ${code(i.key)} '
      'on *${i.food!.name}* (${i.food!.foodId}) → '
      '`${i.match!.portion.label}` ${i.match!.portion.gramWeight} g'
      '${i.match!.tie ? '; **tie** with ${i.match!.tiedWith.map((p) => '`${p.label}` ${p.gramWeight} g').join(', ')}' : ''}'
      '${i.match!.literal ? '' : '; **not literal** — no word of the key is in the label'}';

  _section(
    b,
    'Ties (a hit decided by row order — #1162)',
    [
      for (final run in runs)
        for (final i in run.items.where((i) => i.match?.tie == true)) hit(i),
    ],
    limit: 80,
  );

  _section(
    b,
    'False-match surface — every hit decided by row order or by an inflection, with the row it picked (#1160)',
    [
      for (final run in runs)
        for (final i in run.items.where((i) => i.match?.suspect == true)) hit(i),
    ],
    limit: 120,
  );

  _section(
    b,
    'Key misses — a key on a resolved food that matched no row, and whether amountNeedsCheck fires (#1159)',
    [
      for (final run in runs)
        for (final i in run.items.where((i) => i.keyMiss))
          '- ${run.session.label} `${_oneLine(i.line.input)}` key ${code(i.key)} '
              'on *${i.food!.name}* (${i.food!.foodId}, ${i.food!.portions.length} rows: '
              '${i.food!.portions.take(6).map((p) => '`${p.label}`').join(', ')}'
              '${i.food!.portions.length > 6 ? ', …' : ''}) → '
              '${i.amountNeedsCheckFires ? '**fires**' : i.item.quantity == null ? 'quiet: no count' : 'quiet: query words hit `${i.queryMatch!.portion.label}` ${i.queryMatch!.portion.gramWeight} g'}',
    ],
    limit: 120,
  );

  _section(
    b,
    'Keys on lines that named no measure',
    [
      for (final run in runs)
        for (final i in run.items.where((i) => !i.expectedByLine && i.emitted))
          '- ${run.session.label} `${_oneLine(i.line.input)}` item ${i.index} '
              '`${i.item.query}` → key ${code(i.key)}',
    ],
  );

  _section(
    b,
    'Keys that could not be checked (food unresolved, or the backend did not answer)',
    [
      for (final run in runs)
        for (final i in run.items.where((i) => i.emitted && i.food == null))
          '- ${run.session.label} `${_oneLine(i.line.input)}` `${i.item.query}` '
              '→ key ${code(i.key)}'
              '${i.backendFailure == null ? '' : ' — ${i.backendFailure}'}',
    ],
  );

  _section(b, 'Call failures', [
    for (final run in runs)
      for (final f in run.failures) '- ${run.session.label} $f',
  ]);
  _section(b, 'Backend failures', [
    for (final run in runs)
      for (final f in run.backendFailures) '- ${run.session.label} $f',
  ]);
  _section(b, 'Invariant violations', [
    for (final run in runs)
      for (final v in run.violations) '- ${run.session.label} $v',
  ]);
  _section(b, 'Disagreements with the deterministic parser', [
    for (final run in runs)
      for (final d in run.disagreements) '- ${run.session.label} $d',
  ]);
  _section(b, 'Unstable on repeat', [
    for (final run in runs)
      for (final u in run.unstable) '- ${run.session.label} $u',
  ]);

  b
    ..writeln('## Backend')
    ..writeln()
    ..writeln(
      '${resolver.rpcCalls} read-only RPC calls for '
      '${resolver.distinctQueries} distinct queries; '
      '${resolver.backendFailures} failed.',
    )
    ..writeln()
    ..writeln('## Appendix')
    ..writeln()
    ..writeln(
      'Every item, raw reply included, is in `portion-corpus.items.json` '
      'beside this file.',
    );
  return b.toString();
}

void _section(StringBuffer b, String title, List<String> lines, {int limit = 60}) {
  b
    ..writeln('## $title (${lines.length})')
    ..writeln();
  if (lines.isEmpty) {
    b
      ..writeln('_none_')
      ..writeln();
    return;
  }
  b.writeAll(lines.take(limit), '\n');
  b.writeln();
  if (lines.length > limit) b.writeln('\n_… ${lines.length - limit} more in the JSON_');
  b.writeln();
}
