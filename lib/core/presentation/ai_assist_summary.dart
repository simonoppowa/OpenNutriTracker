import 'package:opennutritracker/core/utils/ai_credential_storage.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// What the AI meal assistance row says beneath its title, in one place.
///
/// Two screens show this row now — Settings and onboarding's Other options —
/// and it is the only place the destination is visible without opening the
/// dialog. A second hand-maintained copy would be a second place that can name
/// the wrong company, which is not hypothetical: the photo sheet once read
/// *"an Anthropic gesendet"* while OpenRouter was selected.
///
/// **The provider switch is exhaustive on purpose.** A wildcard would name
/// Anthropic for any provider added later and compile silently. Keeping one
/// exhaustive site means adding a fourth provider is a compile error exactly
/// once, rather than a compile error in one file and a wrong destination in
/// another. #728.
///
/// [hasKey] null means "not read yet", which renders no subtitle rather than
/// a wrong one.
/// [provider] is null when the stored name is one this build does not know.
/// That state can only reach the `false` arm — [AiAssistSummary] reports no
/// key without a provider to hold one — so the row says "not configured"
/// rather than naming a company the user never chose. #753.
String? aiAssistSubtitle(
  S s, {
  required bool? configured,
  required bool enabled,
  required AiProvider? provider,
  String? endpoint,
}) => switch (configured) {
  null => null,
  false => s.settingsAiAssistNotConfiguredLabel,
  true when enabled && provider != null =>
    // Brand names are not localized, and the em-dash slot is free in this
    // state.
    '${s.settingsAiAssistOnLabel} — ${switch (provider) {
      AiProvider.anthropic => 'Anthropic',
      AiProvider.openrouter => 'OpenRouter',
      AiProvider.openai => 'OpenAI',
      // No brand to print. #736: the row names where the data goes, and for a
      // server the user runs that is the address they typed.
      AiProvider.ownServer => endpoint ?? '',
    }}',
  true => s.settingsAiAssistPausedLabel,
};
