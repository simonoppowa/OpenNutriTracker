// Runs a generated corpus of meal lines — most of them naming a household
// measure — through `ModelMealTextInterpreter` on each hosted provider and
// reports what the model did with `portion` (#1160).
//
// For every item: was a key emitted; is it one of the eight steering words
// (#1158); is it English rather than the line's own word (#1157); does it
// match a row of the food the resolver lands on, via `matchPortionToQuery`
// against the food's *English* labels; when it matches, was the winner a
// tie; when it misses, the row would raise `amountNeedsCheck` (#1159). Plus
// the abbreviation cases (`tbsp` → `tablespoon`), the unit-substitution rule
// the prompt states, the old harness's invariants, and a stability probe.
//
//   dart run tool/live_portion_corpus.dart --keys <dir> --out <dir>
//   dart run tool/live_portion_corpus.dart --dry-run --out <dir>
//
// Keys are read from files, never printed. The only network use in a dry
// run is the two read-only backend RPCs the resolver makes.

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
  final bool? abbreviationExpanded;
  final bool unitSubstituted;
  final ResolvedFood? food;
  final String? resolvedVia;
  final PortionMatch? match;
  final int latencyMs;

  const ItemRecord({
    required this.provider,
    required this.line,
    required this.index,
    required this.item,
    required this.raw,
    required this.language,
    required this.matchesExpectedKey,
    required this.abbreviationExpanded,
    required this.unitSubstituted,
    required this.food,
    required this.resolvedVia,
    required this.match,
    required this.latencyMs,
  });

  String? get key => item.portion;
  bool get emitted => key != null;
  bool get steering =>
      key != null && steeringWords.contains(key!.trim().toLowerCase());
  bool get expectedByLine => index == 0 && line.expected != null;
  bool get wouldRaiseAmountNeedsCheck =>
      emitted && food != null && match == null;

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
    'abbreviationExpanded': abbreviationExpanded,
    'unitSubstituted': unitSubstituted,
    'resolvedVia': resolvedVia,
    'food': food?.toJson(),
    'match': match?.toJson(),
    'wouldRaiseAmountNeedsCheck': wouldRaiseAmountNeedsCheck,
    'latencyMs': latencyMs,
  };
}

class ProviderRun {
  final ProviderSession session;
  final items = <ItemRecord>[];
  final failures = <String>[];
  final violations = <String>[];
  final latencies = <int>[];
  final unstable = <String>[];
  final portionMoved = <String>[];
  var stabilityLines = 0;
  var emptyResults = 0;
  var linesDone = 0;

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
  for (final session in sessions) {
    stdout.writeln('${session.label}: ${corpus.length} lines');
    final run = ProviderRun(session);
    await _runCorpus(run, corpus, resolver, opts.dryRun);
    await _runStability(run, corpus);
    runs.add(run);
    session.close();
  }
  backend.close();

  final stamp = DateTime.now().toUtc().toIso8601String();
  final report = _report(
    runs: runs,
    corpus: corpus,
    opts: opts,
    prompts: prompts,
    resolver: resolver,
    stamp: stamp,
  );
  final md = File('${opts.outDir.path}/portion-corpus.md')
    ..writeAsStringSync(report);
  final json = File('${opts.outDir.path}/portion-corpus.items.json')
    ..writeAsStringSync(
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
        'unstable': {for (final r in runs) r.session.label: r.unstable},
      }),
    );
  stdout.writeln('wrote ${md.path} and ${json.path}');
  for (final run in runs) {
    final emitted = run.items.where((i) => i.expectedByLine && i.emitted).length;
    final expected = run.items.where((i) => i.expectedByLine).length;
    final matched = run.items.where((i) => i.match != null).length;
    stdout.writeln(
      '${run.session.label}: emitted ${ratio(emitted, expected)} on measure '
      'lines | matched $matched | misses '
      '${run.items.where((i) => i.wouldRaiseAmountNeedsCheck).length} | '
      'failures ${run.failures.length} | violations ${run.violations.length} '
      '| unstable ${run.unstable.length}/${run.stabilityLines}',
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
              inputMeasureWord: c.locale == 'en' ? null : expected?.measureWord,
            );
      final matchesExpected = expected == null || key == null
          ? null
          : key.trim().toLowerCase() == expected.key;
      final abbreviationExpanded = expected == null || !expected.abbreviation
          ? null
          : key != null && key.trim().toLowerCase() == expected.key;
      // The prompt: "Do not substitute a unit from the list". A measure
      // line states no unit the parser knows, so any unit on the wire is
      // one the model put there. Validation drops it (#977); the raw reply
      // still shows it.
      final unitSubstituted =
          expected != null && (raw?.unit != null || item.unit != null);

      ResolvedFood? food;
      String? via;
      if (c.locale == 'en' || expected == null) {
        food = await resolver.resolve(item.query);
        via = 'query';
      } else {
        food = await resolver.resolve(expected.food.en);
        via = 'englishEquivalent';
      }
      final match = key == null || food == null
          ? null
          : matchWithTie(key, food.portions);

      run.items.add(
        ItemRecord(
          provider: run.session.label,
          line: c,
          index: index,
          item: item,
          raw: raw,
          language: language,
          matchesExpectedKey: matchesExpected,
          abbreviationExpanded: abbreviationExpanded,
          unitSubstituted: unitSubstituted,
          food: food,
          resolvedVia: food == null ? null : via,
          match: match,
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
        'that exercises each branch of the pipeline; no model was called. '
        'The backend *was* called — read-only `search_food_summary` and '
        '`portions_by_food_ids` — so the resolution, matching and tie '
        'columns are real.',
      )
      ..writeln();
  }
  b.writeln(
    callBudget(
      textCount: opts.count,
      providers: [for (final r in runs) r.session.provider],
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
      '- *English* counts a key that is one of the eight steering words or '
      'ASCII-lettered and not the line\'s own word; *own word* is the key '
      'equal to (or an inflection of) the measure word the line carried — '
      '"Scheibe" for a German line, the failure #1157 names.',
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
      'means another row scored the same and the earlier one won; *miss* is '
      'a key on a resolved food that matched nothing — the row that raises '
      '`amountNeedsCheck` (#1159).',
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
    final resolvedKeyed = keyed.where((i) => i.food != null).toList();
    final matched = resolvedKeyed.where((i) => i.match != null).toList();
    final ties = matched.where((i) => i.match!.tie).length;
    final misses = resolvedKeyed.where((i) => i.match == null).toList();
    final missesNoRows = misses.where((i) => i.food!.portions.isEmpty).length;
    final english = emitted
        .where(
          (i) =>
              i.language == KeyLanguage.steering ||
              i.language == KeyLanguage.asciiOther,
        )
        .length;
    final ownWord = emitted.where((i) => i.language == KeyLanguage.inputWord).length;
    final abbreviations = first.where((i) => i.line.expected!.abbreviation).toList();
    final abbreviationsOk = abbreviations.where((i) => i.abbreviationExpanded == true).length;
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
      ratio(resolvedKeyed.length, keyed.length),
      ratio(matched.length, resolvedKeyed.length),
      ratio(ties, matched.length),
      ratio(misses.length, resolvedKeyed.length),
      ratio(missesNoRows, misses.length),
      ratio(abbreviationsOk, abbreviations.length),
      substitutions,
      unasked,
      run.violations.length,
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
        'tie (of matched)', 'miss → amountNeedsCheck', 'of which: food has no rows',
        'abbreviation expanded',
        'unit substituted', 'key on plain line', 'invariant violations',
        'unstable', 'latency p50 / p95 / max',
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
      ]);
    }
  }
  b.writeln(
    table(
      [
        'provider', 'locale', 'lines', 'measure lines', 'key emitted',
        'steering', 'own word', 'key = expected', 'resolved', 'matched',
        'miss',
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
        for (final i in run.items.where(
          (i) => i.expectedByLine && i.line.expected!.abbreviation,
        ))
          '- ${run.session.label} `${_oneLine(i.line.input)}` → key ${code(i.key)}'
              ' ${i.abbreviationExpanded == true ? 'expanded' : '**not expanded**'}',
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

  _section(
    b,
    'Ties (a hit decided by row order — #1162)',
    [
      for (final run in runs)
        for (final i in run.items.where((i) => i.match?.tie == true))
          '- ${run.session.label} `${_oneLine(i.line.input)}` key ${code(i.key)} '
              'on *${i.food!.name}* (${i.food!.foodId}) → won '
              '`${i.match!.portion.label}` ${i.match!.portion.gramWeight} g; '
              'tied: ${i.match!.tiedWith.map((p) => '`${p.label}` ${p.gramWeight} g').join(', ')}',
    ],
    limit: 80,
  );

  _section(
    b,
    'Misses — a key on a resolved food that matched no row (would raise amountNeedsCheck)',
    [
      for (final run in runs)
        for (final i in run.items.where((i) => i.wouldRaiseAmountNeedsCheck))
          '- ${run.session.label} `${_oneLine(i.line.input)}` key ${code(i.key)} '
              'on *${i.food!.name}* (${i.food!.foodId}, ${i.food!.portions.length} rows: '
              '${i.food!.portions.take(6).map((p) => '`${p.label}`').join(', ')}'
              '${i.food!.portions.length > 6 ? ', …' : ''})',
    ],
    limit: 80,
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
    'Keys that could not be checked (food unresolved)',
    [
      for (final run in runs)
        for (final i in run.items.where((i) => i.emitted && i.food == null))
          '- ${run.session.label} `${_oneLine(i.line.input)}` `${i.item.query}` '
              '→ key ${code(i.key)}',
    ],
  );

  _section(b, 'Call failures', [
    for (final run in runs)
      for (final f in run.failures) '- ${run.session.label} $f',
  ]);
  _section(b, 'Invariant violations', [
    for (final run in runs)
      for (final v in run.violations) '- ${run.session.label} $v',
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
      '${resolver.distinctQueries} distinct queries.',
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

