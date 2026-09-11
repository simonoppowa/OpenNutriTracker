// What both harnesses set up the same way: one session per provider (the
// real client behind a recorder, or the fake), the call budget a real run
// would spend, and the retry the old harness used.

import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:opennutritracker/features/add_meal/domain/meal_items_api.dart';

import 'cli.dart';
import 'fake_api.dart';
import 'providers.dart';

/// How many lines the stability probe re-asks, and how many times each.
const stabilitySampleSize = 20;
const stabilityRepeats = 3;

/// Passes over each photo of the fixed set.
const photoPasses = 3;

/// The fixed photo set, relative to the package root.
const photoSetDir = 'assets/demo/meals';

/// The text harness's default line count.
const defaultTextCount = 240;

class ProviderSession {
  final Provider provider;
  final String model;
  final bool fake;
  final MealItemsApi api;
  final RawReplySource raw;
  final http.Client? _client;

  ProviderSession._({
    required this.provider,
    required this.model,
    required this.fake,
    required this.api,
    required this.raw,
    required http.Client? client,
  }) : _client = client;

  String get label => fake ? '${provider.name} (fake)' : provider.name;

  void close() => _client?.close();
}

/// One session per requested provider. In a dry run every provider is the
/// fake; otherwise a provider whose key file is missing is skipped with a
/// line on stdout, never an error, so a maintainer holding two keys can run
/// two providers.
List<ProviderSession> openSessions(MeasurementOptions opts) {
  final sessions = <ProviderSession>[];
  for (final provider in opts.providers) {
    final model = defaultModelIds[provider]!;
    if (opts.dryRun) {
      final fake = FakeMealItemsApi();
      sessions.add(
        ProviderSession._(
          provider: provider,
          model: model,
          fake: true,
          api: fake,
          raw: fake,
          client: null,
        ),
      );
      continue;
    }
    final key = keyReaderFor(opts.keysDir, provider);
    if (key == null) {
      stdout.writeln('skipping ${provider.name}: no key file');
      continue;
    }
    final recorder = RecordingClient(http.Client());
    sessions.add(
      ProviderSession._(
        provider: provider,
        model: model,
        fake: false,
        api: buildApi(provider, recorder, key),
        raw: recorder,
        client: recorder,
      ),
    );
  }
  return sessions;
}

/// The photos of the fixed set, sorted so every provider sees the same order.
List<File> photoSet() {
  final dir = Directory(photoSetDir);
  if (!dir.existsSync()) return const [];
  final files = dir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.toLowerCase().endsWith('.jpg'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  return files;
}

/// The calls a real run makes, per provider and in total, for the report's
/// first section — so the spend can be confirmed before the first call.
String callBudget({required int textCount, required List<Provider> providers}) {
  final photos = photoSet().length;
  final stability = stabilitySampleSize * stabilityRepeats;
  final text = textCount + stability;
  final photo = photos * photoPasses;
  final perProvider = text + photo;
  final b = StringBuffer()
    ..writeln('## Calls a real run makes')
    ..writeln()
    ..writeln(
      'Per provider: **$textCount** text lines + **$stability** stability '
      '($stabilitySampleSize lines × $stabilityRepeats) = **$text** text '
      'calls; **$photos** photos × $photoPasses passes = **$photo** photo '
      'calls; **$perProvider** in all.',
    )
    ..writeln()
    ..writeln(
      'Providers: ${providers.map((p) => '`${p.name}` (`${defaultModelIds[p]}`)').join(', ')} '
      '— **${perProvider * providers.length}** calls across '
      '${providers.length}, of which ${text * providers.length} carry text '
      'and ${photo * providers.length} carry a photo.',
    );
  return b.toString();
}

/// The old harness's retry: transient failures get three more tries with a
/// widening pause; everything else is reported as it is.
Future<T> withRetry<T>(Future<T> Function() call) async {
  for (var attempt = 0; ; attempt++) {
    try {
      return await call();
    } on MealInterpreterException catch (e) {
      final transient = e.failure == MealInterpreterFailure.transient ||
          e.failure == MealInterpreterFailure.timeout;
      if (!transient || attempt >= 3) rethrow;
      await Future<void>.delayed(Duration(seconds: 2 * (attempt + 1)));
    }
  }
}
