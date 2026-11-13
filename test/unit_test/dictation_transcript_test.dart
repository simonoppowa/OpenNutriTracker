import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/domain/voice/dictation_transcript.dart';

void main() {
  test('partials replace each other and a final commits the segment', () {
    final t = DictationTranscript()
      ..update('dos', isFinal: false)
      ..update('dos huevos', isFinal: false);
    expect(t.text, 'dos huevos');

    t.update('dos huevos', isFinal: true);
    t.update('y una', isFinal: false);
    expect(t.text, 'dos huevos y una');

    t.update('y una tostada', isFinal: true);
    expect(t.text, 'dos huevos y una tostada');
  });

  test('appends to what was already typed', () {
    final t = DictationTranscript(prefix: ' black coffee ')
      ..update('two eggs', isFinal: true);
    expect(t.text, 'black coffee two eggs');
    expect(t.spoken, 'two eggs');
  });

  test('a dangling partial survives commitPartial', () {
    final t = DictationTranscript()
      ..update('one apple', isFinal: true)
      ..update('and a banana', isFinal: false)
      ..commitPartial()
      ..commitPartial();
    expect(t.text, 'one apple and a banana');
  });

  test('silence is not speech', () {
    final t = DictationTranscript(prefix: 'toast')..update('  ', isFinal: true);
    expect(t.hasSpeech, isFalse);
    expect(t.text, 'toast');
  });
}
