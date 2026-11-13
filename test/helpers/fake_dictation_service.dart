import 'package:opennutritracker/features/add_meal/domain/voice/dictation_service.dart';

/// Stands in for the platform recognizer. The test drives each segment.
class FakeDictationService implements DictationService {
  DictationUnavailable? unavailable;
  final languages = <DictationLanguage>[];
  int segments = 0;
  int cancels = 0;
  void Function(DictationResult)? _onResult;
  void Function()? _onEnd;

  @override
  Future<void> ensureReady() async {
    if (unavailable != null) throw DictationUnavailableException(unavailable!);
  }

  @override
  Future<void> startSegment({
    required DictationLanguage language,
    required void Function(DictationResult result) onResult,
    required void Function() onSegmentEnd,
  }) async {
    segments++;
    languages.add(language);
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
  Future<void> cancel() async {
    cancels++;
    _onEnd = null;
  }
}
