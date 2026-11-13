import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/data/voice/speech_to_text_dictation_service.dart';
import 'package:opennutritracker/features/add_meal/domain/voice/dictation_service.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// The plugin, with its locale list held back and `listen` counted.
class _FakeSpeech extends Fake implements SpeechToText {
  final localesReply = Completer<List<LocaleName>>();
  int listens = 0;

  @override
  SpeechErrorListener? errorListener;

  @override
  SpeechStatusListener? statusListener;

  @override
  Future<List<LocaleName>> locales() => localesReply.future;

  @override
  Future<LocaleName?> systemLocale() async => null;

  @override
  Future<void> stop() async {}

  @override
  Future<void> cancel() async {}

  // `listen` has a long signature of deprecated parameters; counting the
  // call is all this needs.
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #listen) {
      listens++;
      return Future<void>.value();
    }
    return super.noSuchMethod(invocation);
  }
}

void main() {
  for (final (name, end) in [
    ('stop', (SpeechToTextDictationService s) => s.stop()),
    ('cancel', (SpeechToTextDictationService s) => s.cancel()),
  ]) {
    test('a $name while the language is looked up keeps the mic off', () async {
      final speech = _FakeSpeech();
      final service = SpeechToTextDictationService(speech);

      final starting = service.startSegment(
        language: DictationLanguage.english,
        onResult: (_) {},
        onSegmentEnd: () {},
      );
      await end(service);
      speech.localesReply.complete([LocaleName('en_US', 'English')]);
      await starting;

      expect(speech.listens, 0);
    });
  }

  test('without a stop the segment starts', () async {
    final speech = _FakeSpeech();
    final service = SpeechToTextDictationService(speech);

    final starting = service.startSegment(
      language: DictationLanguage.english,
      onResult: (_) {},
      onSegmentEnd: () {},
    );
    speech.localesReply.complete([LocaleName('en_US', 'English')]);
    await starting;

    expect(speech.listens, 1);
  });
}
