import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/utils/secure_app_storage_provider.dart';
import 'package:opennutritracker/features/add_meal/data/voice/speech_to_text_dictation_service.dart';
import 'package:opennutritracker/features/add_meal/domain/voice/dictation_service.dart';
import 'package:opennutritracker/features/add_meal/presentation/voice/dictation_session.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// A language chip and a microphone for a meal-description field.
///
/// Tap the mic, say the meal, pause: the transcript is written into
/// [controller] as it is heard, and [onDictated] runs once with the full
/// text so the screen can match it straight away. What was already typed is
/// kept, and dictation appends to it.
///
/// The chip offers the app language, the device languages and English, so a
/// bilingual user can switch without changing either setting. The choice is
/// remembered.
///
/// Meant as a `TextField.suffixIcon`.
class VoiceInputButton extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onDictated;

  /// Replaced in tests. Defaults to the platform recognizer.
  final DictationService? service;

  const VoiceInputButton({
    super.key,
    required this.controller,
    required this.onDictated,
    this.service,
  });

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton> {
  static final _log = Logger('VoiceInputButton');
  static const _languageKey = 'VoiceInputLanguage';

  /// One per app run: the platform recognizer is a singleton anyway, and
  /// the adapter caches resolved locales.
  static final _defaultService = SpeechToTextDictationService();

  late final DictationSession _session = DictationSession(
    widget.service ?? _defaultService,
  )..addListener(_onSessionChanged);

  DictationLanguage? _language;

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  @override
  void dispose() {
    _session
      ..removeListener(_onSessionChanged)
      ..dispose();
    super.dispose();
  }

  Future<void> _loadLanguage() async {
    String? stored;
    try {
      stored = await SecureAppStorageProvider.secureAppStorage.read(
        key: _languageKey,
      );
    } catch (e) {
      _log.fine('Could not read the dictation language: $e');
    }
    if (!mounted) return;
    if (stored == null || stored.isEmpty) return;
    setState(() => _language = DictationLanguage(stored!));
  }

  /// The app language, every language in the device's preference list,
  /// and English, without repeats.
  ///
  /// The whole list rather than the first entry: a phone set to "English,
  /// Spanish" is exactly the bilingual user this chip is for, and reading
  /// only the first language left them with nothing to switch to.
  List<DictationLanguage> _offered(BuildContext context) => {
    DictationLanguage(Localizations.localeOf(context).languageCode),
    for (final locale in WidgetsBinding.instance.platformDispatcher.locales)
      DictationLanguage(locale.languageCode),
    DictationLanguage.english,
  }.toList();

  /// The stored choice while it is still on offer, else the app language.
  DictationLanguage _effectiveLanguage(BuildContext context) {
    final offered = _offered(context);
    final stored = _language;
    return stored != null && offered.contains(stored) ? stored : offered.first;
  }

  Future<void> _toggleLanguage() async {
    final offered = _offered(context);
    final next =
        offered[(offered.indexOf(_effectiveLanguage(context)) + 1) %
            offered.length];
    setState(() => _language = next);
    try {
      await SecureAppStorageProvider.secureAppStorage.write(
        key: _languageKey,
        value: next.code,
      );
    } catch (e) {
      _log.fine('Could not store the dictation language: $e');
    }
  }

  void _onSessionChanged() {
    if (!mounted) return;
    if (_session.isListening) {
      final text = _session.text;
      widget.controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
    setState(() {});
  }

  Future<void> _onMicPressed() async {
    if (_session.isListening) {
      await _session.stop();
      return;
    }
    FocusScope.of(context).unfocus();
    final s = S.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _session.start(
        language: _effectiveLanguage(context),
        existingText: widget.controller.text,
        onComplete: (text) {
          if (!mounted) return;
          widget.controller.value = TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: text.length),
          );
          widget.onDictated(text);
        },
      );
    } on DictationUnavailableException catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(switch (e.reason) {
            DictationUnavailable.permission => s.voiceInputPermissionDenied,
            DictationUnavailable.noRecognizer => s.voiceInputUnavailable,
          }),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final colors = Theme.of(context).colorScheme;
    final language = _effectiveLanguage(context);
    final listening = _session.isListening;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          identifier: 'voice-input-language',
          child: TextButton(
            onPressed: listening ? null : _toggleLanguage,
            style: TextButton.styleFrom(
              minimumSize: const Size(40, 40),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              visualDensity: VisualDensity.compact,
            ),
            child: Tooltip(
              message: s.voiceInputLanguageTooltip(language.code.toUpperCase()),
              child: Text(language.code.toUpperCase()),
            ),
          ),
        ),
        Semantics(
          identifier: 'voice-input-mic',
          child: IconButton(
            onPressed: _onMicPressed,
            tooltip: listening
                ? s.voiceInputStopTooltip
                : s.voiceInputStartTooltip,
            isSelected: listening,
            style: listening
                ? IconButton.styleFrom(
                    backgroundColor: colors.error,
                    foregroundColor: colors.onError,
                  )
                : null,
            icon: Icon(listening ? Icons.stop_rounded : Icons.mic_rounded),
          ),
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}
