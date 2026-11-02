import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:opennutritracker/features/add_meal/domain/voice/dictation_service.dart';
import 'package:opennutritracker/features/add_meal/domain/voice/dictation_transcript.dart';

/// Strings recognizer segments into one dictation the user experiences as a
/// single "tap, speak, pause" action.
///
/// The session ends when the user taps stop, when they have been quiet for
/// [silence] after speaking (or [initialSilence] before saying anything), or
/// when a fresh segment hears nothing at all. It then reports the whole
/// transcript once through [onComplete] — only if something was said.
///
/// Idea borrowed from fud-ai (MIT, © 2026 Apoorv Darshan): Android's
/// recognizer stops after every short pause, so the segments are kept and
/// the recognizer restarted until the user is actually done.
class DictationSession extends ChangeNotifier {
  final DictationService _service;
  final Duration silence;
  final Duration initialSilence;
  final Duration maxDuration;

  /// Time allowed between asking a segment to stop and it reporting its end.
  final Duration stopGrace;

  /// Gap before restarting the recognizer. Restarting immediately makes
  /// some Android recognizers report "busy".
  final Duration restartDelay;

  DictationSession(
    this._service, {
    this.silence = const Duration(milliseconds: 2500),
    this.initialSilence = const Duration(seconds: 8),
    this.maxDuration = const Duration(seconds: 90),
    this.stopGrace = const Duration(seconds: 2),
    this.restartDelay = const Duration(milliseconds: 250),
  });

  DictationTranscript? _transcript;
  bool _listening = false;
  bool _stopping = false;
  bool _segmentHeard = false;
  Timer? _silenceTimer;
  Timer? _maxTimer;
  Timer? _graceTimer;
  void Function(String text)? _onComplete;

  /// Increments per session so callbacks from an ended session (a late
  /// result, a delayed restart) are ignored.
  int _generation = 0;

  bool get isListening => _listening;

  /// What the text field should show while listening.
  String get text => _transcript?.text ?? '';

  /// Starts listening. Throws [DictationUnavailableException] when the
  /// recognizer cannot run; the caller tells the user why.
  Future<void> start({
    required DictationLanguage language,
    required String existingText,
    required void Function(String text) onComplete,
  }) async {
    if (_listening) return;
    await _service.ensureReady();
    final generation = ++_generation;
    _transcript = DictationTranscript(prefix: existingText);
    _onComplete = onComplete;
    _listening = true;
    _stopping = false;
    _maxTimer = Timer(maxDuration, stop);
    notifyListeners();
    await _startSegment(language, generation);
  }

  /// Ends the session as soon as the current segment has delivered what it
  /// heard.
  Future<void> stop() async {
    if (!_listening || _stopping) return;
    _stopping = true;
    _silenceTimer?.cancel();
    final generation = _generation;
    _graceTimer = Timer(stopGrace, () {
      if (generation == _generation) _finish();
    });
    await _service.stop();
  }

  Future<void> _startSegment(DictationLanguage language, int generation) async {
    _segmentHeard = false;
    _armSilence(_transcript!.hasSpeech ? silence : initialSilence);
    try {
      await _service.startSegment(
        language: language,
        onResult: (result) {
          if (generation != _generation) return;
          _transcript!.update(result.words, isFinal: result.isFinal);
          if (result.words.trim().isNotEmpty) {
            _segmentHeard = true;
            if (!_stopping) _armSilence(silence);
          }
          notifyListeners();
        },
        onSegmentEnd: () {
          if (generation != _generation) return;
          if (_stopping || !_segmentHeard) {
            _finish();
          } else {
            Timer(restartDelay, () {
              if (generation == _generation && !_stopping) {
                _startSegment(language, generation);
              }
            });
          }
        },
      );
    } catch (_) {
      if (generation == _generation) _finish();
    }
  }

  void _armSilence(Duration after) {
    _silenceTimer?.cancel();
    _silenceTimer = Timer(after, stop);
  }

  void _finish() {
    if (!_listening) return;
    _generation++;
    _listening = false;
    _stopping = false;
    _silenceTimer?.cancel();
    _maxTimer?.cancel();
    _graceTimer?.cancel();
    final transcript = _transcript!..commitPartial();
    final onComplete = _onComplete;
    _onComplete = null;
    notifyListeners();
    if (transcript.hasSpeech) onComplete?.call(transcript.text);
  }

  @override
  void dispose() {
    _generation++;
    _silenceTimer?.cancel();
    _maxTimer?.cancel();
    _graceTimer?.cancel();
    if (_listening) unawaited(_service.cancel());
    super.dispose();
  }
}
