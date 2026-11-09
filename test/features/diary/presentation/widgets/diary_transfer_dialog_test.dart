import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/utils/calc/day_boundary_calc.dart';
import 'package:opennutritracker/features/diary/presentation/widgets/diary_transfer_dialog.dart';
import 'package:opennutritracker/generated/l10n.dart';

void main() {
  testWidgets('copy returns the selected destination and meal', (tester) async {
    DiaryTransferChoice? result;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showDialog<DiaryTransferChoice>(
                  context: context,
                  builder: (_) => DiaryTransferDialog(
                    initialDate: DateTime(2026, 10, 28),
                    initialMealType: IntakeTypeEntity.lunch,
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsIdentifier('diary-transfer-meal'), findsOneWidget);
    await tester.tap(find.text('Lunch').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dinner').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copy'));
    await tester.pumpAndSettle();
    expect(result?.move, false);
    expect(result?.mealType, IntakeTypeEntity.dinner);
    expect(result?.date, DateTime(2026, 10, 28));
  });

  // PR #1491 review: a copy was stamped a minute after the day start, which
  // with a 23:59 start is midnight of the next date.
  test('a copied entry lands on the chosen day for any day start', () {
    final choice = DiaryTransferChoice(
      DateTime(2026, 10, 28, 15, 30),
      null,
      false,
    );
    for (final offset in [0, 240, 1320, 1439]) {
      expect(
        DayBoundaryCalc.dayKeyOf(choice.entryTime, offset),
        '2026-10-28',
        reason: 'day starts at minute $offset',
      );
    }
  });

  testWidgets('copy and move have stable semantics identifiers', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: DiaryTransferDialog(initialDate: DateTime(2026, 10, 28)),
        ),
      ),
    );
    expect(find.bySemanticsIdentifier('diary-transfer-copy'), findsOneWidget);
    expect(find.bySemanticsIdentifier('diary-transfer-move'), findsOneWidget);
  });
}
