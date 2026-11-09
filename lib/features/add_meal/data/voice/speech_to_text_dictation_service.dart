import 'dart:io' show Platform;
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/services.dart';
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
  static const _deviceChannel = MethodChannel('com.opennutritracker/device');

  final SpeechToText _speech;

  /// Whether the device has a microphone at all. The manifest declares one
  /// optional so Play keeps offering the app to tablets without one, and
  /// there Android still reports a recognizer as available: without this
  /// check the mic would light up and go off again with no explanation.
  final Future<bool> Function() _hasMicrophone;

  /// Recognizer locale per language, resolved once per app run.
  final _localeIds = <DictationLanguage, String>{};

  /// Ends the current segment. Cleared once called so that a segment that
  /// reports both an error and `done` ends exactly once.
  void Function()? _endSegment;

  /// Bumped by [stop] and [cancel], so a segment still resolving its locale
  /// when the user stops does not switch the mic on afterwards.
  int _segmentToken = 0;

  SpeechToTextDictationService([
    SpeechToText? speech,
    Future<bool> Function()? hasMicrophone,
  ]) : _speech = speech ?? SpeechToText(),
       _hasMicrophone = hasMicrophone ?? _platformHasMicrophone;

  /// Asks Android's package manager. Every iPhone and iPad has a
  /// microphone, and a failed lookup leaves dictation to try as before.
  static Future<bool> _platformHasMicrophone() async {
    if (!Platform.isAndroid) return true;
    try {
      return await _deviceChannel.invokeMethod<bool>('hasMicrophone') ?? true;
    } catch (e) {
      _log.fine('Could not ask whether there is a microphone: $e');
      return true;
    }
  }

  @override
  Future<void> ensureReady() async {
    // Checked first, so a device with no microphone is never asked for
    // microphone permission.
    if (!await _hasMicrophone()) {
      throw const DictationUnavailableException(
        DictationUnavailable.noRecognizer,
      );
    }
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
    final token = ++_segmentToken;
    _endSegment = onSegmentEnd;
    _speech
      ..errorListener = _onError
      ..statusListener = _onStatus;
    final localeId = await _localeIdFor(language);
    if (token != _segmentToken) return;
    await _speech.listen(
      onResult: (result) => onResult(
        DictationResult(result.recognizedWords, isFinal: result.finalResult),
      ),
      listenOptions: SpeechListenOptions(
        localeId: localeId,
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
  Future<void> stop() {
    _segmentToken++;
    return _speech.stop();
  }

  @override
  Future<void> cancel() async {
    _segmentToken++;
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

  /// The recognizer locale for [language], preferring the region the device
  /// lists for that language ("es_AR" on an Argentine phone) over a
  /// generic one.
  Future<String> _localeIdFor(DictationLanguage language) async {
    final cached = _localeIds[language];
    if (cached != null) return cached;

    var resolved = language.fallbackLocaleId;
    try {
      final available = (await _speech.locales())
          .map((l) => l.localeId.replaceAll('-', '_'))
          .toList();
      // The region the user pairs with this language on the device: a
      // phone set to "English (Germany), Spanish (US)" dictates Spanish as
      // es_US, not es_DE.
      final dispatcher = PlatformDispatcher.instance;
      final country =
          dispatcher.locales
              .where(
                (l) => l.languageCode == language.code && l.countryCode != null,
              )
              .map((l) => l.countryCode)
              .firstOrNull ??
          dispatcher.locale.countryCode;
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
