import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/presentation/ai_assist_summary.dart';
import 'package:opennutritracker/core/utils/ai_credential_storage.dart';

import '../helpers/test_l10n.dart';

/// The one line that names the destination without opening the dialog.
///
/// Three of the four providers print a brand and have nothing to decide. The
/// fourth prints an address the user typed, which is the only value on this
/// row that can contain something they would not want on a screen.
void main() {
  String? subtitleFor(String? endpoint) => aiAssistSubtitle(
    l10nEn,
    configured: true,
    enabled: true,
    provider: AiProvider.ownServer,
    endpoint: endpoint,
  );

  test('names the machine, not the route it answers on', () {
    // The stored form carries `/v1/chat/completions`, which is on every one
    // of these addresses and tells them apart not at all.
    expect(
      subtitleFor('http://192.168.1.5:11434/v1/chat/completions'),
      contains('192.168.1.5:11434'),
    );
    expect(
      subtitleFor('http://192.168.1.5:11434/v1/chat/completions'),
      isNot(contains('chat/completions')),
    );
  });

  test('never prints a password from a basic-auth address', () {
    // `Uri.authority` is `userInfo@host:port`, and a reverse-proxied server
    // is an ordinary reason to have one. This row sits in Settings and in
    // onboarding, in an app that masks the API key so a stored credential is
    // not readable off a screen someone else can see.
    final subtitle = subtitleFor(
      'http://ollama:hunter2@192.168.1.5:11434/v1/chat/completions',
    );

    expect(subtitle, contains('192.168.1.5:11434'));
    expect(subtitle, isNot(contains('hunter2')));
    expect(subtitle, isNot(contains('ollama:')));
  });

  test('says nothing extra when there is no address to name', () {
    // Reachable only if the store ever holds something unnameable; the row
    // still has to render rather than throw.
    expect(subtitleFor(null), '${l10nEn.settingsAiAssistOnLabel} — ');
    expect(
      subtitleFor('not-an-address'),
      '${l10nEn.settingsAiAssistOnLabel} — ',
    );
  });

  test('the hosted three are unaffected', () {
    for (final (provider, brand) in [
      (AiProvider.anthropic, 'Anthropic'),
      (AiProvider.openrouter, 'OpenRouter'),
      (AiProvider.openai, 'OpenAI'),
    ]) {
      expect(
        aiAssistSubtitle(
          l10nEn,
          configured: true,
          enabled: true,
          provider: provider,
          endpoint: 'http://ollama:hunter2@192.168.1.5:11434',
        ),
        contains(brand),
        reason: '$provider prints a brand and ignores any endpoint',
      );
    }
  });
}
