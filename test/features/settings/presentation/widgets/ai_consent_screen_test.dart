import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/ai_credential_storage.dart';
import 'package:opennutritracker/features/settings/presentation/widgets/ai_consent_screen.dart';
import 'package:opennutritracker/generated/l10n.dart';

import '../../../../helpers/test_l10n.dart';

Widget _app(AiProvider provider, {String endpoint = 'http://192.168.1.5:11434'}) =>
    MaterialApp(
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.supportedLocales,
      home: AiConsentScreen(provider: provider, typedEndpoint: endpoint),
    );

void main() {
  group('what the consent screen promises about sending (#985)', () {
    // The screen used to tell every user "nothing is sent until you use the
    // feature". For a server they run that was false three times over: the
    // address field's model-list request fires on focus loss — before this
    // screen has even been shown — and a valid save starts a setup check that
    // sends a fixed line and a bundled photograph. None of it is the user's
    // own data, which is what the qualifier below now says, and what the
    // own-server paragraph makes concrete.

    testWidgets('a server the user runs is told about the setup check', (
      tester,
    ) async {
      await tester.pumpWidget(_app(AiProvider.ownServer));
      await tester.pumpAndSettle();

      expect(find.text(l10nEn.aiConsentOwnServerCheckNote), findsOneWidget);
    });

    testWidgets('a hosted provider is not — it would be false for them', (
      tester,
    ) async {
      // The three hosted providers have a curated catalogue and no probe, so
      // they really are sent nothing until a meal is read. Showing them a
      // note about checks would be a new inaccuracy, not a fix for the old one.
      for (final provider in [
        AiProvider.anthropic,
        AiProvider.openai,
        AiProvider.openrouter,
      ]) {
        await tester.pumpWidget(_app(provider));
        await tester.pumpAndSettle();

        expect(
          find.text(l10nEn.aiConsentOwnServerCheckNote),
          findsNothing,
          reason: '$provider sends nothing before use',
        );
      }
    });

    testWidgets('the general note keeps its qualifier', (tester) async {
      // The bug was one dropped qualifier, so this pins the qualifier rather
      // than the whole sentence: copy may be reworded, but it may not go back
      // to promising that *nothing* is sent.
      await tester.pumpWidget(_app(AiProvider.anthropic));
      await tester.pumpAndSettle();

      final note = l10nEn.aiConsentChangeProviderNote;
      expect(
        note.contains('you type or photograph'),
        isTrue,
        reason: 'an unqualified "nothing is sent" is false for a user-run '
            'server — see #985',
      );
      expect(find.text(note), findsOneWidget);
    });
  });

  test('every locale carries the own-server note', () {
    // The same shape as the l10n parity check, and here for the same reason:
    // a re-translation that drops the key would leave that locale silently
    // showing nothing at all on the one screen that has to be accurate.
    final dir = Directory('lib/l10n');
    final arbs = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.arb'))
        .toList();
    expect(arbs, isNotEmpty, reason: 'no ARB files found');

    for (final file in arbs) {
      final map = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final value = map['aiConsentOwnServerCheckNote'];
      expect(
        value,
        isA<String>(),
        reason: '${file.uri.pathSegments.last} is missing the note',
      );
      expect(
        (value as String).trim(),
        isNotEmpty,
        reason: '${file.uri.pathSegments.last} has it empty',
      );
    }
  });
}
