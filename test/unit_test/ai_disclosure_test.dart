import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/presentation/ai_assist_summary.dart';
import 'package:opennutritracker/core/utils/ai_credential_storage.dart';
import 'package:opennutritracker/core/utils/gemini_endpoint.dart';
import 'package:opennutritracker/features/add_meal/data/meal_items_api_factory.dart';
import 'package:opennutritracker/features/add_meal/data/openai_compatible_meal_items_api.dart';
import 'package:opennutritracker/generated/l10n.dart';

void main() {
  group('the paragraph that names where a user\'s data goes', () {
    test('every provider gets its own, and no two are the same', () {
      final s = lookupS(const Locale('en'));
      final byProvider = {
        for (final provider in AiProvider.values)
          provider: aiDisclosureFor(
            s,
            provider: provider,
            typedEndpoint: 'https://box.local:11434',
          ),
      };

      for (final entry in byProvider.entries) {
        expect(
          entry.value,
          isNotEmpty,
          reason: '${entry.key.name} has no paragraph, so enabling it would '
              'say nothing about where the data goes',
        );
      }
      // The collapse this test exists to prevent: an edit that hands two
      // providers the same sentence, naming the wrong company for one of them.
      expect(
        byProvider.values.toSet(),
        hasLength(AiProvider.values.length),
        reason: 'two providers share a paragraph, so one of them names a '
            'destination that is not where the data is going',
      );
    });

    test('every destination is told that photos go there too', () {
      final s = lookupS(const Locale('en'));
      for (final provider in AiProvider.values) {
        expect(
          aiDisclosureFor(
            s,
            provider: provider,
            typedEndpoint: 'https://box.local:11434',
          ),
          contains('photo'),
          // The own-server paragraphs named only the typed text, while the
          // camera is offered for that provider too once its photo probe
          // passes. An agreement that lists what leaves the device has to
          // list the photo, whichever destination is chosen.
          reason: '${provider.name} does not mention the photo it sends',
        );
      }
    });

    test('each hosted provider gets the paragraph written for it', () {
      final s = lookupS(const Locale('en'));
      expect(
        aiDisclosureFor(s, provider: AiProvider.anthropic),
        s.aiAssistDisclosureAnthropic,
      );
      expect(
        aiDisclosureFor(s, provider: AiProvider.openrouter),
        s.aiAssistDisclosureOpenRouter,
      );
      expect(
        aiDisclosureFor(s, provider: AiProvider.openai),
        s.aiAssistDisclosureOpenAI,
      );
    });

    test('a server the user runs is named by the address as typed', () {
      final s = lookupS(const Locale('en'));
      final secure = aiDisclosureFor(
        s,
        provider: AiProvider.ownServer,
        typedEndpoint: 'https://box.local:11434',
      );
      final plaintext = aiDisclosureFor(
        s,
        provider: AiProvider.ownServer,
        typedEndpoint: 'http://box.local:11434',
      );

      // #736: an address the user can check on sight, rather than "the server
      // you configured", which they cannot.
      expect(secure, contains('box.local:11434'));
      expect(plaintext, contains('box.local:11434'));
      // Whether the connection is encrypted is read off the scheme, and the
      // two cases must not read alike.
      expect(secure, isNot(equals(plaintext)));
    });

    test('it says nothing while there is no address to name', () {
      final s = lookupS(const Locale('en'));
      for (final typed in ['', '   ', 'ht']) {
        expect(
          aiDisclosureFor(
            s,
            provider: AiProvider.ownServer,
            typedEndpoint: typed,
          ),
          isEmpty,
          reason: 'a sentence naming nothing is worse than no sentence',
        );
      }
    });

    test('a credential pasted into the address never reaches the paragraph',
        () {
      final s = lookupS(const Locale('en'));
      final rendered = aiDisclosureFor(
        s,
        provider: AiProvider.ownServer,
        typedEndpoint: 'http://someone:hunter2@box.local:11434',
      );

      expect(
        rendered,
        isNot(contains('hunter2')),
        reason: 'the paragraph would be rendering the password on screen',
      );
      expect(rendered, contains('box.local:11434'));
    });
  });

  group('Google\'s Gemini API reached as "your own server"', () {
    // #1257: the address is Google's hosted service, not a machine the user
    // runs, so "a server you run" and "No third party receives it" would be
    // false on the screen that asks for consent.
    const gemini =
        'https://generativelanguage.googleapis.com/v1beta/openai/chat/completions';

    test('names Google, not a server the user runs', () {
      final s = lookupS(const Locale('en'));
      final rendered = aiDisclosureFor(
        s,
        provider: AiProvider.ownServer,
        typedEndpoint: gemini,
      );

      expect(
        rendered,
        s.aiAssistDisclosureOwnServerGemini(
          'generativelanguage.googleapis.com',
        ),
      );
      expect(rendered, contains('Google'));
      expect(rendered, contains('photo'));
      expect(rendered, isNot(contains('No third party')));
      expect(rendered, isNot(contains('a server you run.')));
    });

    test('however the host is capitalised or the address is typed', () {
      final s = lookupS(const Locale('en'));
      final expected = s.aiAssistDisclosureOwnServerGemini(
        'generativelanguage.googleapis.com',
      );
      for (final typed in [
        'https://GenerativeLanguage.GoogleApis.com/v1beta/openai/',
        '  https://generativelanguage.googleapis.com/v1beta/openai/  ',
        'https://generativelanguage.googleapis.com:443/v1beta/openai/',
      ]) {
        expect(
          aiDisclosureFor(
            s,
            provider: AiProvider.ownServer,
            typedEndpoint: typed,
          ),
          expected,
          reason: typed,
        );
      }
    });

    test('other hosts keep the own-server paragraph', () {
      final s = lookupS(const Locale('en'));
      for (final typed in [
        'https://box.local:11434/v1',
        'http://192.168.1.5:8080/v1',
        'https://generativelanguage.googleapis.com.example.org/v1',
      ]) {
        final rendered = aiDisclosureFor(
          s,
          provider: AiProvider.ownServer,
          typedEndpoint: typed,
        );
        expect(rendered, contains('a server you run'), reason: typed);
        expect(rendered, isNot(contains('Gemini')), reason: typed);
      }
    });

    test('the paragraph and the request agree on who is Google', () {
      // One check decides both, so a look-alike cannot get the Gemini
      // request shape while being described as the user's own machine, or
      // the reverse.
      expect(isGeminiEndpoint(Uri.parse(gemini)), isTrue);
      expect(
        ownServerToolChoice(Uri.parse(gemini)),
        ToolChoiceMode.namedFunction,
      );
      expect(
        isGeminiEndpoint(Uri.parse('https://googleapis.com/v1')),
        isFalse,
      );
    });
  });
}
