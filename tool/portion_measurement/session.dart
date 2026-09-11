// What both harnesses set up the same way: one session per provider (the
// real client behind a recorder, or the fake), the call budget a real run
// would spend, and the retry the old harness used.

import 'dart:io';
import 'dart:math';

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

/// The model a session of [provider] runs: the catalogue default for the
/// hosted three, the one named on the command line for the user's own
/// server.
String modelFor(Provider provider, MeasurementOptions opts) =>
    provider == Provider.ownServer
        ? opts.ownServer!.model
        : defaultModelIds[provider]!;

/// One session per requested provider. In a dry run every provider is the
/// fake; otherwise a provider whose key file is missing is skipped with a
/// line on stdout, never an error, so a maintainer holding two keys can run
/// two providers. The own server is the exception: it may have no key.
List<ProviderSession> openSessions(MeasurementOptions opts) {
  final sessions = <ProviderSession>[];
  for (final provider in opts.providers) {
    final model = modelFor(provider, opts);
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
    if (key == null && provider != Provider.ownServer) {
      stdout.writeln('skipping ${provider.name}: no key file');
      continue;
    }
    final recorder = RecordingClient(http.Client());
    sessions.add(
      ProviderSession._(
        provider: provider,
        model: model,
        fake: false,
        api: buildApi(
          provider,
          recorder,
          key,
          model: model,
          endpoint: opts.ownServer?.endpoint,
        ),
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

/// How many lines the text harness's stability probe re-asks for a corpus
/// with [measureLines] measure lines: the sample size, or every measure
/// line when there are fewer (then padded from the plain lines up to the
/// corpus, which is how `_runStability` draws it).
int stabilityLinesFor({required int corpusLength, required int measureLines}) =>
    min(stabilitySampleSize, measureLines >= stabilitySampleSize ? measureLines : corpusLength);

/// The calls the text harness makes on a real run, per provider and in
/// total, for its report's first section — so the spend can be confirmed
/// before the first call. Text only: the photo harness is a separate run
/// with its own line, and one report must not bill for the other's calls.
String textCallBudget({
  required int textCount,
  required int stabilityLines,
  required List<ProviderSession> sessions,
}) {
  final stability = stabilityLines * stabilityRepeats;
  final perProvider = textCount + stability;
  return _budget(
    'Per provider: **$textCount** text lines + **$stability** stability '
    '($stabilityLines lines × $stabilityRepeats) = **$perProvider** calls, '
    'every one carrying text.',
    perProvider,
    sessions,
  );
}

/// The photo harness's counterpart, photo calls only.
String photoCallBudget({
  required int photos,
  required List<ProviderSession> sessions,
}) {
  final perProvider = photos * photoPasses;
  return _budget(
    'Per provider: **$photos** photos × $photoPasses passes = '
    '**$perProvider** calls, every one carrying a photo.',
    perProvider,
    sessions,
  );
}

String _budget(String perProviderLine, int perProvider, List<ProviderSession> sessions) {
  final b = StringBuffer()
    ..writeln('## Calls a real run of this harness makes')
    ..writeln()
    ..writeln(perProviderLine)
    ..writeln()
    ..writeln(
      'Providers: ${sessions.map((s) => '`${s.provider.name}` (`${s.model}`)').join(', ')} '
      '— **${perProvider * sessions.length}** calls across '
      '${sessions.length}. Retries are not counted here; a transient '
      'failure is retried up to three times.',
    );
  return b.toString();
}

/// The old harness's retry: transient failures get three more tries with a
/// widening pause; everything else is reported as it is. [onAttempt] is
/// told before every attempt, retries included, so a caller counting calls
/// counts what was actually sent.
Future<T> withRetry<T>(
  Future<T> Function() call, {
  void Function()? onAttempt,
}) async {
  for (var attempt = 0; ; attempt++) {
    try {
      onAttempt?.call();
      return await call();
    } on MealInterpreterException catch (e) {
      final transient = e.failure == MealInterpreterFailure.transient ||
          e.failure == MealInterpreterFailure.timeout;
      if (!transient || attempt >= 3) rethrow;
      await Future<void>.delayed(Duration(seconds: 2 * (attempt + 1)));
    }
  }
}
