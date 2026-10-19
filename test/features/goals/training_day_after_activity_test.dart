import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/training_plan.dart';
import 'package:opennutritracker/features/goals/domain/auto_training_day_usecase.dart';
import 'package:opennutritracker/features/goals/presentation/training_day_after_activity.dart';
import 'package:opennutritracker/generated/l10n.dart';

import '../../helpers/test_l10n.dart';

class _FakeAutoTrainingDay extends Fake implements AutoTrainingDayUsecase {
  AutoTrainingDayDecision decision;
  final switched = <DateTime>[];

  _FakeAutoTrainingDay(this.decision);

  @override
  Future<AutoTrainingDayDecision> decide(DateTime day) async => decision;

  @override
  Future<void> switchToTraining(DateTime day) async => switched.add(day);
}

void main() {
  final day = DateTime(2026, 10, 20);

  Future<void> offer(WidgetTester tester, _FakeAutoTrainingDay usecase) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => offerTrainingDayAfterActivity(
                usecase: usecase,
                messenger: ScaffoldMessenger.of(context),
                l10n: S.of(context),
                day: day,
              ),
              child: const Text('logged'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('logged'));
    await tester.pumpAndSettle();
  }

  testWidgets('asks, and the action switches the day', (tester) async {
    final usecase = _FakeAutoTrainingDay(AutoTrainingDayDecision.suggest);
    await offer(tester, usecase);

    expect(find.text(l10nEn.trainingDaySuggestion), findsOneWidget);
    expect(usecase.switched, isEmpty);
    await tester.tap(find.text(l10nEn.trainingDaySuggestionAction));
    await tester.pumpAndSettle();

    expect(usecase.switched, [day]);
  });

  testWidgets('switches by itself and says so', (tester) async {
    final usecase = _FakeAutoTrainingDay(
      AutoTrainingDayDecision.switchToTraining,
    );
    await offer(tester, usecase);

    expect(usecase.switched, [day]);
    expect(find.text(l10nEn.trainingDaySwitched), findsOneWidget);
  });

  testWidgets('stays quiet when nothing applies', (tester) async {
    final usecase = _FakeAutoTrainingDay(AutoTrainingDayDecision.none);
    await offer(tester, usecase);

    expect(usecase.switched, isEmpty);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('a day set by hand meanwhile is not switched', (tester) async {
    final usecase = _FakeAutoTrainingDay(AutoTrainingDayDecision.suggest);
    await offer(tester, usecase);

    usecase.decision = AutoTrainingDayDecision.none;
    await tester.tap(find.text(l10nEn.trainingDaySuggestionAction));
    await tester.pumpAndSettle();

    expect(usecase.switched, isEmpty);
  });
}
