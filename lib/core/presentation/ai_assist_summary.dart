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
      // server the user runs that is the machine they pointed it at — host
      // and port, not the stored URL. That string carries the chat route,
      // which is on every one of these addresses and tells them apart not at
      // all, and it carries `userInfo` when the server sits behind basic
      // auth, which would put a password on the settings row.
      AiProvider.ownServer =>
        AiCredentialStorage.displayHost(endpoint ?? '') ?? '',
    }}',
  true => s.settingsAiAssistPausedLabel,
};


/// The paragraph naming where a user's typing and photos go for [provider].
///
/// Two surfaces state this: the settings dialog, where the feature is switched
/// on, and the agreement that stands in front of it. They must not be able to
/// disagree. This is the one text in the app whose entire job is to be right
/// about where data leaves to, so a second hand-maintained copy is not a
/// duplication problem, it is a correctness one — the same failure
/// [aiAssistSubtitle] exists to prevent, where the photo sheet once read
/// *"an Anthropic gesendet"* while OpenRouter was selected.
///
/// **Exhaustive for the same reason as [aiAssistSubtitle].** A wildcard would
/// hand a fifth provider Anthropic's paragraph and compile without complaint.
///
/// [typedEndpoint] is the address as it currently reads in the field, not the
/// one on file. #736: a user agreeing to this can check `192.168.1.5:11434`
/// on sight, where "the server you configured" is unverifiable — and naming
/// what is typed catches a stale address pointing somewhere they had
/// forgotten.
String aiDisclosureFor(
  S s, {
  required AiProvider provider,
  String typedEndpoint = '',
}) => switch (provider) {
  AiProvider.anthropic => s.aiAssistDisclosureAnthropic,
  AiProvider.openrouter => s.aiAssistDisclosureOpenRouter,
  AiProvider.openai => s.aiAssistDisclosureOpenAI,
  AiProvider.ownServer => _ownServerDisclosure(s, typedEndpoint),
};

/// Empty while no address is stored: there is no destination to name yet, and
/// a sentence naming nothing would be worse than none.
String _ownServerDisclosure(S s, String typedEndpoint) {
  final typed = typedEndpoint.trim();
  // Nothing to name yet, which half-typed text also counts as. It used to fall
  // back to echoing whatever was in the field, and that is a paragraph
  // rendering a credential the moment someone pastes an address with one in
  // it.
  final display = AiCredentialStorage.displayHost(typed);
  if (display == null) return '';
  // Which of the two this connection is, read off the scheme as typed, and
  // nothing beyond that. It deliberately does **not** say the address is
  // private: nothing checks that today — #758 may — and the string it picks
  // states what is true of any plaintext connection instead of claiming a
  // boundary has been enforced.
  return Uri.tryParse(typed)?.scheme == 'https'
      ? s.aiAssistDisclosureOwnServerSecure(display)
      : s.aiAssistDisclosureOwnServerPlaintext(display);
}
