// Kept free of Flutter and plugin imports so the accumulation rules can be
// unit tested on their own.

/// What has been heard so far in one dictation session.
///
/// Android's recognizer ends a segment after a short pause, so one spoken
/// meal ("dos huevos… y una tostada") arrives as several segments: the
/// session restarts the recognizer and keeps the earlier segments here.
/// Each segment reports partial results, which replace each other, and then
/// one final result, which is committed.
class DictationTranscript {
  /// Text that was in the field before dictation started. Dictation appends
  /// to it rather than replacing what the user typed.
  final String prefix;

  final List<String> _committed = [];
  String _partial = '';

  DictationTranscript({String prefix = ''}) : prefix = prefix.trim();

  /// Records a recognizer result for the current segment.
  void update(String words, {required bool isFinal}) {
    final trimmed = words.trim();
    if (isFinal) {
      if (trimmed.isNotEmpty) _committed.add(trimmed);
      _partial = '';
    } else {
      _partial = trimmed;
    }
  }

  /// Turns a dangling partial into a committed segment. Used when the
  /// session ends without the recognizer sending a final result for it, so
  /// the last words spoken are not lost.
  void commitPartial() => update(_partial, isFinal: true);

  /// Only what was dictated, without [prefix].
  String get spoken => [..._committed, _partial].where(_notEmpty).join(' ');

  bool get hasSpeech => spoken.isNotEmpty;

  /// What the text field should show.
  String get text => [prefix, spoken].where(_notEmpty).join(' ');

  static bool _notEmpty(String s) => s.isNotEmpty;
}
