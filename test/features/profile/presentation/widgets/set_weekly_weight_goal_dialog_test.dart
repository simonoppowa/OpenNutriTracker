import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/body_weight_unit_entity.dart';
import 'package:opennutritracker/features/profile/presentation/widgets/set_weekly_weight_goal_dialog.dart';
import 'package:opennutritracker/generated/l10n.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: S.delegate.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  group('SetWeeklyWeightGoalDialog', () {
    testWidgets('Cancel returns WeeklyWeightGoalCancelled',
        (tester) async {
      WeeklyWeightGoalResult? captured;
      await tester.pumpWidget(_wrap(Builder(builder: (context) {
        return Center(
          child: ElevatedButton(
            onPressed: () async {
              captured = await showDialog<WeeklyWeightGoalResult>(
                context: context,
                builder: (_) => const SetWeeklyWeightGoalDialog(
                  currentGoalKg: null,
                  bodyWeightUnit: BodyWeightUnit.kg,
                ),
              );
            },
            child: const Text('Open'),
          ),
        );
      })));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(S.current.dialogCancelLabel));
      await tester.pumpAndSettle();
      expect(captured, isA<WeeklyWeightGoalCancelled>());
    });

    testWidgets('Reset returns WeeklyWeightGoalCleared', (tester) async {
      WeeklyWeightGoalResult? captured;
      await tester.pumpWidget(_wrap(Builder(builder: (context) {
        return Center(
          child: ElevatedButton(
            onPressed: () async {
              captured = await showDialog<WeeklyWeightGoalResult>(
                context: context,
                builder: (_) => const SetWeeklyWeightGoalDialog(
                  currentGoalKg: 0.5,
                  bodyWeightUnit: BodyWeightUnit.kg,
                ),
              );
            },
            child: const Text('Open'),
          ),
        );
      })));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(S.current.buttonResetLabel));
      await tester.pumpAndSettle();
      expect(captured, isA<WeeklyWeightGoalCleared>());
    });

    testWidgets('OK returns WeeklyWeightGoalSet with the slider value',
        (tester) async {
      WeeklyWeightGoalResult? captured;
      await tester.pumpWidget(_wrap(Builder(builder: (context) {
        return Center(
          child: ElevatedButton(
            onPressed: () async {
              captured = await showDialog<WeeklyWeightGoalResult>(
                context: context,
                builder: (_) => const SetWeeklyWeightGoalDialog(
                  currentGoalKg: -0.25,
                  bodyWeightUnit: BodyWeightUnit.kg,
                ),
              );
            },
            child: const Text('Open'),
          ),
        );
      })));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(S.current.dialogOKLabel));
      await tester.pumpAndSettle();
      expect(captured, isA<WeeklyWeightGoalSet>());
      expect((captured as WeeklyWeightGoalSet).kgPerWeek, -0.25);
    });
  });
}
