import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/presentation/voice/voice_input_button.dart';
import 'package:opennutritracker/features/add_meal/presentation/widgets/add_food_methods.dart';
import 'package:opennutritracker/generated/l10n.dart';

import '../../../helpers/fake_dictation_service.dart';

Future<void> _pump(WidgetTester tester, List<String> found) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.supportedLocales,
      home: Scaffold(body: DescribeMealPanel(onFindFoods: found.add)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  late FakeDictationService service;

  setUp(() {
    service = FakeDictationService();
    VoiceInputButton.debugServiceOverride = service;
  });

  tearDown(() => VoiceInputButton.debugServiceOverride = null);

  testWidgets('Find foods turns on as dictation fills an empty field', (
    tester,
  ) async {
    final found = <String>[];
    await _pump(tester, found);
    FilledButton submit() => tester.widget<FilledButton>(
      find.descendant(
        of: find.bySemanticsIdentifier('add-meal-describe-submit'),
        matching: find.byWidgetPredicate((w) => w is FilledButton),
      ),
    );
    expect(submit().onPressed, isNull);

    await tester.tap(find.byIcon(Icons.mic_rounded));
    await tester.pump();
    service.hear('two eggs');
    await tester.pump();

    expect(submit().onPressed, isNotNull);
    await tester.tap(find.bySemanticsIdentifier('add-meal-describe-submit'));
    await tester.pump();
    expect(found, ['two eggs']);
  });

  testWidgets('Find foods mid-dictation submits once and ends dictation', (
    tester,
  ) async {
    final found = <String>[];
    await _pump(tester, found);
    await tester.enterText(find.byType(TextField), 'black coffee');
    await tester.pump();

    await tester.tap(find.byIcon(Icons.mic_rounded));
    await tester.pump();
    service.hear('two eggs');
    await tester.pump();

    await tester.tap(find.bySemanticsIdentifier('add-meal-describe-submit'));
    await tester.pump();
    // The session's own pause timeout would have submitted a second time.
    await tester.pump(const Duration(seconds: 10));

    expect(found, ['black coffee two eggs']);
    expect(service.cancels, 1);
  });
}
