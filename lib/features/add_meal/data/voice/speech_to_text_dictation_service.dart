import 'dart:ui' show PlatformDispatcher;

import 'package:logging/logging.dart';
import 'package:opennutritracker/features/add_meal/domain/voice/dictation_service.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// [DictationService] over the platform recognizer (Android
/// `SpeechRecognizer`, iOS `SFSpeechRecognizer`) via `speech_to_text`.
///
/// Nothing is recorded or sent by the app itself. Whether the platform
/// recognizes on the device or on its vendor's servers is the platform's
/// choice: `onDevice` is left off because forcing it fails outright on the
/// many Android devices without an offline model for the language.
class SpeechToTextDictationService implements DictationService {
  static final _log = Logger('SpeechToTextDictationService');

  final SpeechToText _speech;

  /// Recognizer locale per language, resolved once per app run.
  final _localeIds = <DictationLanguage, String>{};

  /// Ends the current segment. Cleared once called so that a segment that
  /// reports both an error and `done` ends exactly once.
  void Function()? _endSegment;

  SpeechToTextDictationService([SpeechToText? speech])
    : _speech = speech ?? SpeechToText();

  @override
  Future<void> ensureReady() async {
    // `initialize` caches its first answer, and its listeners are public
    // fields, so they are (re)assigned per segment instead of here.
    final bool ready;
    try {
      ready = await _speech.initialize(onError: _onError, onStatus: _onStatus);
    } catch (e, stackTrace) {
      _log.warning('Speech recognizer failed to initialise', e, stackTrace);
      throw const DictationUnavailableException(
        DictationUnavailable.noRecognizer,
      );
    }
    if (ready) return;
    throw DictationUnavailableException(
      await _speech.hasPermission
          ? DictationUnavailable.noRecognizer
          : DictationUnavailable.permission,
    );
  }

  @override
  Future<void> startSegment({
    required DictationLanguage language,
    required void Function(DictationResult result) onResult,
    required void Function() onSegmentEnd,
  }) async {
    _endSegment = onSegmentEnd;
    _speech
      ..errorListener = _onError
      ..statusListener = _onStatus;
    await _speech.listen(
      onResult: (result) => onResult(
        DictationResult(result.recognizedWords, isFinal: result.finalResult),
      ),
      listenOptions: SpeechListenOptions(
        localeId: await _localeIdFor(language),
        partialResults: true,
        listenMode: ListenMode.dictation,
        autoPunctuation: true,
        cancelOnError: true,
        // The platform ends a segment on its own after a pause; these are
        // ceilings, and the session decides when the user is done.
        listenFor: const Duration(seconds: 60),
        pauseFor: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Future<void> stop() => _speech.stop();

  @override
  Future<void> cancel() async {
    _endSegment = null;
    await _speech.cancel();
  }

  void _onStatus(String status) {
    if (status == SpeechToText.doneStatus) _finishSegment();
  }

  void _onError(SpeechRecognitionError error) {
    // `error_no_match` and `error_speech_timeout` are how a pause with no
    // speech ends a segment; they are not worth more than a debug line.
    _log.fine('Recognizer error: ${error.errorMsg}');
    if (error.permanent) _finishSegment();
  }

  void _finishSegment() {
    final end = _endSegment;
    _endSegment = null;
    end?.call();
  }

  /// The recognizer locale for [language], preferring the device's own
  /// region ("es_AR" on an Argentine phone) over a generic one.
  Future<String> _localeIdFor(DictationLanguage language) async {
    final cached = _localeIds[language];
    if (cached != null) return cached;

    var resolved = language.fallbackLocaleId;
    try {
      final available = (await _speech.locales())
          .map((l) => l.localeId.replaceAll('-', '_'))
          .toList();
      final country = PlatformDispatcher.instance.locale.countryCode;
      final regional = '${language.code}_$country';
      final system = (await _speech.systemLocale())?.localeId.replaceAll(
        '-',
        '_',
      );
      resolved =
          [if (country != null) regional, ?system, language.fallbackLocaleId]
              .where((id) => id.startsWith('${language.code}_'))
              .firstWhere(
                available.contains,
                orElse: () => available.firstWhere(
                  (id) => id.startsWith('${language.code}_'),
                  // Some Android recognizers list no locales at all but still
                  // honour a requested one.
                  orElse: () => resolved,
                ),
              );
    } catch (e) {
      _log.fine('Could not list recognizer locales: $e');
    }
    return _localeIds[language] = resolved;
  }
}
