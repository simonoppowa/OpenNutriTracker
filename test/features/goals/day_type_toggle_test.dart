import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/goal_targets.dart';
import 'package:opennutritracker/core/domain/entity/training_plan.dart';
import 'package:opennutritracker/core/utils/goal_changes.dart';
import 'package:opennutritracker/features/goals/presentation/day_type_toggle.dart';
import 'package:opennutritracker/generated/l10n.dart';

import '../../helpers/test_l10n.dart';

void main() {
  final monday = DateTime(2026, 10, 19);
  const enabled = TrainingPlan(
    trainingTargets: GoalTargets(kcalMode: KcalGoalMode.fixed, fixedKcal: 2600),
    trainingWeekdays: {DateTime.monday},
  );

  late TrainingPlan plan;
  late List<(DateTime, DayType)> calls;
  late GoalChanges changes;

  Future<void> pumpToggle(WidgetTester tester, DateTime day) async {
    calls = [];
    changes = GoalChanges();
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
          body: DayTypeToggle(
            day: day,
            loadPlan: () async => plan,
            setDayType: (day, type) async {
              calls.add((day, type));
              plan = plan.withDayType(day, type);
            },
            changes: changes,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('hidden while training days have no goals', (tester) async {
    plan = const TrainingPlan(trainingWeekdays: {DateTime.monday});
    await pumpToggle(tester, monday);

    expect(find.bySemanticsIdentifier('day-type-toggle'), findsNothing);
  });

  testWidgets('shows the planned type and switches it', (tester) async {
    plan = enabled;
    await pumpToggle(tester, monday);

    expect(find.text(l10nEn.dayTypeTrainingLabel), findsOneWidget);
    await tester.tap(find.bySemanticsIdentifier('day-type-toggle'));
    await tester.pumpAndSettle();

    expect(calls, [(monday, DayType.rest)]);
    expect(find.text(l10nEn.dayTypeRestLabel), findsOneWidget);
  });

  testWidgets('appears once training goals are saved', (tester) async {
    plan = const TrainingPlan();
    await pumpToggle(tester, monday);
    expect(find.bySemanticsIdentifier('day-type-toggle'), findsNothing);

    plan = enabled;
    changes.notifyChanged();
    await tester.pumpAndSettle();

    expect(find.text(l10nEn.dayTypeTrainingLabel), findsOneWidget);
  });
}
