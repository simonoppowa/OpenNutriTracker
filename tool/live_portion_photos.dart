// Runs the fixed photo set through `ModelMealPhotoInterpreter` on each hosted
// provider, three passes per photo, and reports what arrived in `portion`
// and what the #1156 guard would do with it.
//
// Per item: the query, count, unit and key as the wire carried them; the
// guard's verdict — kept as a size on a whole count, or dropped because the
// key was a container word, a piece word, rode on no count, on a fraction,
// or beside a unit; and for the survivors, whether the size matches a row
// of the resolved food's English labels (a miss stays quiet on this path,
// #1159).
//
//   dart run tool/live_portion_photos.dart --keys <dir> --out <dir>
//   dart run tool/live_portion_photos.dart --dry-run --out <dir>

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:opennutritracker/features/add_meal/data/model_meal_photo_interpreter.dart';
import 'package:opennutritracker/features/add_meal/domain/meal_items_api.dart';
import 'package:opennutritracker/features/add_meal/domain/meal_photo_interpreter.dart';
import 'package:opennutritracker/features/add_meal/util/meal_text_parser.dart';

import 'portion_measurement/cli.dart';
import 'portion_measurement/metrics.dart';
import 'portion_measurement/prompts.dart';
import 'portion_measurement/providers.dart';
import 'portion_measurement/resolver.dart';
import 'portion_measurement/session.dart';

/// Photos are read in the user's app language; English here so the query
/// resolves against the English search.
const photoLocale = 'en';

class PhotoItemRecord {
  final String provider;
  final String photo;
  final int pass;
  final int index;
  final RawItem raw;

  /// After `validateParsedMealItems`, before any counts-only rule — what
  /// the app's guard sees.
  final ParsedMealItem validated;
  final PhotoGuardResult guard;

  /// What develop's `_countsOnly` returned for this item, for comparison.
  final ParsedMealItem? developOutput;
  final ResolvedFood? food;
  final PortionMatch? match;
  final int latencyMs;

  const PhotoItemRecord({
    required this.provider,
    required this.photo,
    required this.pass,
    required this.index,
    required this.raw,
    required this.validated,
    required this.guard,
    required this.developOutput,
    required this.food,
    required this.match,
    required this.latencyMs,
  });

  bool get arrived => raw.portion != null && raw.portion!.trim().isNotEmpty;
  bool get kept => guard.verdict == PhotoGuardVerdict.kept;

  Map<String, Object?> toJson() => {
    'provider': provider,
    'photo': photo,
    'pass': pass,
    'index': index,
    'raw': raw.json,
    'validated': {
      'query': validated.query,
      'quantity': validated.quantity,
      'unit': validated.unit,
      'portion': validated.portion,
    },
    'guard': {
      'verdict': guard.verdict.name,
      'quantity': guard.quantity,
      'portion': guard.portion,
    },
    'developOutput': developOutput == null
        ? null
        : {
            'quantity': developOutput!.quantity,
            'unit': developOutput!.unit,
            'portion': developOutput!.portion,
          },
    'food': food?.toJson(),
    'match': match?.toJson(),
    'latencyMs': latencyMs,
  };
}

class PhotoRun {
  final ProviderSession session;
  final items = <PhotoItemRecord>[];
  final failures = <String>[];
  final latencies = <int>[];
  final unstable = <String>[];
  var calls = 0;

  PhotoRun(this.session);
}

Future<void> main(List<String> args) async {
  final opts = parseOptions(
    args,
    tool: 'live_portion_photos.dart',
    defaultCount: defaultTextCount,
  );
  final photos = photoSet();
  if (photos.isEmpty) {
    stderr.writeln('no photos under $photoSetDir');
    exit(66);
  }
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

  final runs = <PhotoRun>[];
  for (final session in sessions) {
    stdout.writeln('${session.label}: ${photos.length} photos × $photoPasses');
    final run = PhotoRun(session);
    await _runPhotos(run, photos, resolver);
    runs.add(run);
    session.close();
  }
  backend.close();

  final stamp = DateTime.now().toUtc().toIso8601String();
  final report = _report(
    runs: runs,
    photos: photos,
    opts: opts,
    prompts: prompts,
    resolver: resolver,
    stamp: stamp,
  );
  final md = File('${opts.outDir.path}/portion-photos.md')
    ..writeAsStringSync(report);
  final json = File('${opts.outDir.path}/portion-photos.items.json')
    ..writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        'generated': stamp,
        'dryRun': opts.dryRun,
        'photos': [for (final p in photos) _name(p)],
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
    final arrived = run.items.where((i) => i.arrived).length;
    final kept = run.items.where((i) => i.kept).length;
    stdout.writeln(
      '${run.session.label}: items ${run.items.length} | key arrived $arrived '
      '| kept by guard $kept | failures ${run.failures.length} | unstable '
      '${run.unstable.length}/${photos.length}',
    );
  }
}

String _name(File f) => f.uri.pathSegments.last;

Future<void> _runPhotos(
  PhotoRun run,
  List<File> photos,
  FoodResolver resolver,
) async {
  final interpreter = ModelMealPhotoInterpreter(run.session.api);

  for (final file in photos) {
    final bytes = file.readAsBytesSync();
    final photo = MealPhoto(bytes: bytes, mediaType: 'image/jpeg');
    final needle = photoNeedle(base64Encode(bytes));
    final signatures = <String>[];

    for (var pass = 1; pass <= photoPasses; pass++) {
      final started = DateTime.now();
      MealTextParseResult result;
      try {
        run.calls++;
        result = await withRetry(
          () => interpreter.interpret(photo, localeCode: photoLocale),
        );
      } on MealInterpreterException catch (e) {
        run.failures.add(
          '${_name(file)} pass $pass — ${e.failure.name} (${e.statusCode ?? '-'})',
        );
        continue;
      } finally {
        run.latencies.add(DateTime.now().difference(started).inMilliseconds);
      }
      final latency = run.latencies.last;

      final rawItems = run.session.raw.takeRawItems(needle);
      if (rawItems == null) {
        run.failures.add('${_name(file)} pass $pass — no raw items recovered');
        continue;
      }
      // The two steps every client takes, re-run here on the raw items so
      // the guard sees the same `parsed` the app's guard would.
      final validated = validateParsedMealItems(mealItemsFromJson(rawItems));
      signatures.add(
        validated.items
            .map((i) => '${i.query}|${i.quantity}|${i.unit}|${i.portion}')
            .join(' ~ '),
      );

      for (final (index, item) in validated.items.indexed) {
        final raw = rawItems
            .map(RawItem.new)
            .where((r) => r.query == item.query)
            .firstOrNull;
        if (raw == null) continue;
        final guard = applyPhotoGuard(
          quantity: item.quantity,
          unit: item.unit,
          portion: item.portion,
        );
        final develop = result.items
            .where((i) => i.query == item.query)
            .firstOrNull;

        ResolvedFood? food;
        PortionMatch? match;
        if (guard.verdict == PhotoGuardVerdict.kept) {
          food = await resolver.resolve(item.query);
          if (food != null) match = matchWithTie(guard.portion!, food.portions);
        }

        run.items.add(
          PhotoItemRecord(
            provider: run.session.label,
            photo: _name(file),
            pass: pass,
            index: index,
            raw: raw,
            validated: item,
            guard: guard,
            developOutput: develop,
            food: food,
            match: match,
            latencyMs: latency,
          ),
        );
      }
    }
    if (signatures.toSet().length > 1) {
      run.unstable.add(
        '${_name(file)}\n${signatures.map((s) => '  - $s').join('\n')}',
      );
    }
    stdout.writeln('  ${_name(file)} done');
  }
}

String _report({
  required List<PhotoRun> runs,
  required List<File> photos,
  required MeasurementOptions opts,
  required PromptsAsRun prompts,
  required FoodResolver resolver,
  required String stamp,
}) {
  final b = StringBuffer()
    ..writeln('# Live portion corpus — photo path (#1160)')
    ..writeln()
    ..writeln(
      '${photos.length} photographs from `$photoSetDir`, $photoPasses passes '
      'each, app language `$photoLocale`; $stamp.',
    )
    ..writeln();
  if (opts.dryRun) {
    b
      ..writeln(
        '> **Dry run.** Every provider below is `FakeMealItemsApi`, which '
        'answers one canned plate per photo so that every branch of the '
        'guard is exercised; no model was called. The backend *was* called '
        '(read-only) for the survivors, so the match columns are real.',
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
    ..writeln('**Schema, `portion` description:**')
    ..writeln()
    ..writeln('> ${prompts.schemaPortionDescription}')
    ..writeln()
    ..writeln('**Photo prompt, the portion bullet:**')
    ..writeln()
    ..writeln('> ${promptBullet(prompts.photoSystemPrompt, 'If you counted items')}')
    ..writeln()
    ..writeln('<details><summary>The whole photo system prompt</summary>')
    ..writeln()
    ..writeln('```')
    ..writeln(prompts.photoSystemPrompt.trimRight())
    ..writeln('```')
    ..writeln()
    ..writeln('</details>')
    ..writeln()
    ..writeln('## The guard, as decided (#1156)')
    ..writeln()
    ..writeln(
      'Applied to each item after `validateParsedMealItems`: a `unit` strips '
      'the count and the key with it; a fraction strips both too; a key with '
      'no count is dropped; a whole count keeps the key only when, trimmed '
      'and lower-cased, it is exactly `small`, `medium` or `large`; any '
      'other word is dropped and the count stays. *develop* is what the '
      'current `_countsOnly` returned for the same item, which has no key '
      'rule yet.',
    )
    ..writeln();

  b
    ..writeln('## Summary per provider')
    ..writeln();
  final rows = <List<Object?>>[];
  for (final run in runs) {
    final all = run.items;
    final arrived = all.where((i) => i.arrived).toList();
    final kept = all.where((i) => i.kept).toList();
    final resolved = kept.where((i) => i.food != null).toList();
    final matched = resolved.where((i) => i.match != null).toList();
    int verdict(PhotoGuardVerdict v) =>
        all.where((i) => i.guard.verdict == v).length;
    final sorted = run.latencies.toList()..sort();
    rows.add([
      run.session.label,
      code(run.session.model),
      run.calls,
      run.failures.length,
      all.length,
      ratio(arrived.length, all.length),
      ratio(
        arrived.where((i) => photoSizeWords.contains(i.raw.portion!.trim().toLowerCase())).length,
        arrived.length,
      ),
      ratio(kept.length, arrived.length),
      verdict(PhotoGuardVerdict.containerWord),
      verdict(PhotoGuardVerdict.pieceWord),
      verdict(PhotoGuardVerdict.sizeLikeNotOneOfThree),
      verdict(PhotoGuardVerdict.otherWord),
      verdict(PhotoGuardVerdict.noCount),
      verdict(PhotoGuardVerdict.fraction),
      verdict(PhotoGuardVerdict.unit),
      ratio(resolved.length, kept.length),
      ratio(matched.length, resolved.length),
      matched.where((i) => i.match!.tie).length,
      resolved.length - matched.length,
      '${run.unstable.length}/${photos.length}',
      sorted.isEmpty
          ? '–'
          : '${percentile(sorted, 0.5)} / ${percentile(sorted, 0.95)} / ${sorted.last} ms',
    ]);
  }
  b.writeln(
    table(
      [
        'provider', 'model', 'calls', 'failed', 'items', 'key arrived',
        'arrived as a size word', 'kept by guard', 'dropped: container',
        'dropped: piece', 'dropped: size-like, not one of three',
        'dropped: other', 'dropped: no count', 'dropped: fraction',
        'dropped: unit', 'resolved (of kept)', 'matched (of resolved)',
        'ties', 'quiet misses', 'unstable photos', 'latency p50 / p95 / max',
      ],
      rows,
    ),
  );

  b
    ..writeln('## Every item')
    ..writeln();
  b.writeln(
    table(
      [
        'provider', 'photo', 'pass', 'query', 'raw qty', 'raw unit', 'raw key',
        'validated qty/unit', 'guard', 'kept key', 'develop qty/key',
        'resolved', 'match',
      ],
      [
        for (final run in runs)
          for (final i in run.items)
            [
              run.session.label,
              i.photo.substring(0, 10),
              i.pass,
              i.validated.query,
              i.raw.quantity,
              i.raw.unit,
              i.raw.portion == null ? null : '`${i.raw.portion}`',
              '${i.validated.quantity ?? '–'} / ${i.validated.unit ?? '–'}',
              i.guard.verdict.name,
              i.guard.portion,
              i.developOutput == null
                  ? '–'
                  : '${i.developOutput!.quantity ?? '–'} / ${i.developOutput!.portion ?? '–'}',
              i.food == null
                  ? (i.kept ? 'unresolved' : '')
                  : '${i.food!.name} (${i.food!.portions.length} rows)',
              i.match == null
                  ? (i.food == null ? '' : 'miss (quiet)')
                  : '`${i.match!.portion.label}` ${i.match!.portion.gramWeight} g'
                        '${i.match!.tie ? ' **tie** with ${i.match!.tiedWith.map((p) => '`${p.label}`').join(', ')}' : ''}',
            ],
      ],
    ),
  );

  void section(String title, List<String> lines) {
    b
      ..writeln('## $title (${lines.length})')
      ..writeln();
    if (lines.isEmpty) {
      b
        ..writeln('_none_')
        ..writeln();
      return;
    }
    b.writeAll(lines, '\n');
    b
      ..writeln()
      ..writeln();
  }

  section('Container and piece words that arrived (the case #1156 forbids)', [
    for (final run in runs)
      for (final i in run.items.where(
        (i) =>
            i.guard.verdict == PhotoGuardVerdict.containerWord ||
            i.guard.verdict == PhotoGuardVerdict.pieceWord,
      ))
        '- ${run.session.label} ${i.photo} pass ${i.pass}: `${i.validated.query}` '
            '${i.raw.quantity ?? '–'} × `${i.raw.portion}` → ${i.guard.verdict.name}, '
            'count ${i.guard.quantity ?? 'dropped'}',
  ]);
  section('Call failures', [
    for (final run in runs)
      for (final f in run.failures) '- ${run.session.label} $f',
  ]);
  section('Unstable across passes', [
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
      'Every item, raw reply included, is in `portion-photos.items.json` '
      'beside this file.',
    );
  return b.toString();
}

