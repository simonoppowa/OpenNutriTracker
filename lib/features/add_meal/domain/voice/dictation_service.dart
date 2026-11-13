/// A language to dictate in, as an ISO 639-1 code.
///
/// Not an enum: the recognizer supports far more languages than the app has
/// reason to list, so the button offers whichever of the app language, the
/// device language and English apply, and this only has to carry the code.
class DictationLanguage {
  final String code;

  const DictationLanguage(this.code);

  static const english = DictationLanguage('en');

  /// Region tried when the device lists no recognizer locale for [code].
  static const _defaultRegions = {
    'cs': 'CZ',
    'da': 'DK',
    'de': 'DE',
    'en': 'US',
    'es': 'ES',
    'fi': 'FI',
    'fr': 'FR',
    'hu': 'HU',
    'it': 'IT',
    'nb': 'NO',
    'nl': 'NL',
    'pl': 'PL',
    'pt': 'BR',
    'ru': 'RU',
    'sk': 'SK',
    'sv': 'SE',
    'tr': 'TR',
    'uk': 'UA',
    'zh': 'CN',
  };

  /// Recognizer locale to use when the device does not list one for this
  /// language.
  String get fallbackLocaleId {
    final region = _defaultRegions[code];
    return region == null ? code : '${code}_$region';
  }

  @override
  bool operator ==(Object other) =>
      other is DictationLanguage && other.code == code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => 'DictationLanguage($code)';
}

/// Why a dictation session could not run at all. Errors inside a running
/// session (a pause with no speech, a recognizer hiccup) are not reported
/// this way; the session simply ends with whatever was heard.
enum DictationUnavailable {
  /// Microphone or speech permission denied.
  permission,

  /// No speech recognition service on this device.
  noRecognizer,
}

class DictationUnavailableException implements Exception {
  final DictationUnavailable reason;

  const DictationUnavailableException(this.reason);

  @override
  String toString() => 'DictationUnavailableException($reason)';
}

/// One recognizer result.
class DictationResult {
  final String words;
  final bool isFinal;

  const DictationResult(this.words, {required this.isFinal});
}

/// The platform speech recognizer, reduced to what the voice button needs.
///
/// A segment is one recognizer run. The session logic that strings segments
/// together lives in the widget's controller, not here, so this stays a thin
/// adapter that a test can replace.
abstract interface class DictationService {
  /// Prepares the recognizer and asks for permission on first use. Throws
  /// [DictationUnavailableException] when dictation cannot work.
  Future<void> ensureReady();

  /// Starts one segment. [onResult] receives partial and final results;
  /// [onSegmentEnd] is called exactly once when the segment ends for any
  /// reason (silence, error, [stop]).
  Future<void> startSegment({
    required DictationLanguage language,
    required void Function(DictationResult result) onResult,
    required void Function() onSegmentEnd,
  });

  /// Ends the current segment, delivering a final result if there is one.
  Future<void> stop();

  /// Ends the current segment and discards it.
  Future<void> cancel();
}
