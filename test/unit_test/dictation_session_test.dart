import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/domain/voice/dictation_service.dart';
import 'package:opennutritracker/features/add_meal/presentation/voice/dictation_session.dart';

/// A recognizer the test drives, whose readiness can be held back.
class _FakeService implements DictationService {
  Completer<void>? ready;
  int segments = 0;
  void Function(DictationResult)? _onResult;
  void Function()? _onEnd;

  @override
  Future<void> ensureReady() => ready?.future ?? Future.value();

  @override
  Future<void> startSegment({
    required DictationLanguage language,
    required void Function(DictationResult result) onResult,
    required void Function() onSegmentEnd,
  }) async {
    segments++;
    _onResult = onResult;
    _onEnd = onSegmentEnd;
  }

  void hear(String words, {bool isFinal = false}) =>
      _onResult!(DictationResult(words, isFinal: isFinal));

  void endSegment() {
    final end = _onEnd;
    _onEnd = null;
    end?.call();
  }

  @override
  Future<void> stop() async => endSegment();

  @override
  Future<void> cancel() async => _onEnd = null;
}

void main() {
  late _FakeService service;
  late List<String> completed;

  setUp(() {
    service = _FakeService();
    completed = [];
  });

  // testWidgets for its fake clock: the session runs on timers.
  testWidgets('words heard before a segment ends without a final result are '
      'kept across the restart', (tester) async {
    final session = DictationSession(service);
    addTearDown(session.dispose);
    await session.start(
      language: DictationLanguage.english,
      existingText: '',
      onComplete: completed.add,
    );

    service
      ..hear('two eggs')
      ..endSegment();
    await tester.pump(const Duration(milliseconds: 300));
    expect(service.segments, 2);

    service.hear('and toast', isFinal: true);
    expect(session.text, 'two eggs and toast');
    await session.stop();
    expect(completed, ['two eggs and toast']);
  });

  testWidgets('disposing while the recognizer gets ready starts nothing', (
    tester,
  ) async {
    service.ready = Completer<void>();
    final session = DictationSession(service);
    final starting = session.start(
      language: DictationLanguage.english,
      existingText: '',
      onComplete: completed.add,
    );

    session.dispose();
    service.ready!.complete();
    await starting;

    expect(service.segments, 0);
    expect(session.isListening, isFalse);
  });

  testWidgets('a second start while the first gets ready starts one session', (
    tester,
  ) async {
    service.ready = Completer<void>();
    final session = DictationSession(service);
    addTearDown(session.dispose);
    final first = session.start(
      language: DictationLanguage.english,
      existingText: '',
      onComplete: completed.add,
    );
    final second = session.start(
      language: DictationLanguage.english,
      existingText: '',
      onComplete: completed.add,
    );

    service.ready!.complete();
    await Future.wait([first, second]);

    expect(service.segments, 1);
    await session.stop();
  });

  testWidgets('cancel ends the session without reporting it', (tester) async {
    final session = DictationSession(service);
    addTearDown(session.dispose);
    await session.start(
      language: DictationLanguage.english,
      existingText: '',
      onComplete: completed.add,
    );
    service.hear('two eggs');

    await session.cancel();
    await tester.pump(const Duration(seconds: 10));

    expect(session.isListening, isFalse);
    expect(completed, isEmpty);
  });
}
