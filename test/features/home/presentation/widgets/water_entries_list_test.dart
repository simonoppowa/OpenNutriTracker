import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/repository/water_intake_repository.dart';
import 'package:opennutritracker/core/domain/entity/water_intake_entity.dart';
import 'package:opennutritracker/core/domain/usecase/delete_water_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_water_intake_usecase.dart';
import 'package:opennutritracker/features/home/domain/day_water_log.dart';
import 'package:opennutritracker/features/home/presentation/widgets/water_entries_list.dart';
import 'package:opennutritracker/generated/l10n.dart';

import '../../../../helpers/test_l10n.dart';

class _FakeRepository implements WaterIntakeRepository {
  final entries = <WaterIntakeEntity>[
    WaterIntakeEntity(
      id: 'morning',
      dateTime: DateTime(2026, 10, 19, 8, 5),
      amountMl: 250,
    ),
    WaterIntakeEntity(
      id: 'noon',
      dateTime: DateTime(2026, 10, 19, 12, 30),
      amountMl: 500,
    ),
    WaterIntakeEntity(
      id: 'evening',
      dateTime: DateTime(2026, 10, 19, 19, 45),
      amountMl: 330,
    ),
  ];

  @override
  Future<List<WaterIntakeEntity>> getEntriesInRange(
    DateTime from,
    DateTime to,
  ) async => [
    for (final e in entries)
      if (!e.dateTime.isBefore(from) && e.dateTime.isBefore(to)) e,
  ];

  @override
  Future<void> deleteEntry(String id) async =>
      entries.removeWhere((e) => e.id == id);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

void main() {
  late _FakeRepository repository;
  late DayWaterLog log;

  setUp(() {
    repository = _FakeRepository();
    log = DayWaterLog(
      GetWaterIntakeUsecase(repository),
      DeleteWaterIntakeUsecase(repository),
      dayStartOffsetMinutes: () async => 0,
      onChanged: () {},
    );
  });

  Future<void> pumpList(WidgetTester tester, DateTime day) async {
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
          body: WaterEntriesList(log: log, day: day, showTitle: true),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows each entry with time and amount, and the total', (
    tester,
  ) async {
    await pumpList(tester, DateTime(2026, 10, 19));

    expect(find.text('08:05 · 250 ml'), findsOneWidget);
    expect(find.text('12:30 · 500 ml'), findsOneWidget);
    expect(find.text('19:45 · 330 ml'), findsOneWidget);
    expect(find.text('1080 ml'), findsOneWidget);
  });

  testWidgets('deleting the middle entry removes only that one', (
    tester,
  ) async {
    await pumpList(tester, DateTime(2026, 10, 19));

    await tester.tap(find.bySemanticsIdentifier('water-entry-delete-1'));
    await tester.pumpAndSettle();
    expect(find.text(l10nEn.waterEntryDeleteContent(500, '12:30')), findsOne);
    await tester.tap(find.text(l10nEn.dialogDeleteLabel));
    await tester.pumpAndSettle();

    expect(repository.entries.map((e) => e.id), ['morning', 'evening']);
    expect(find.text('12:30 · 500 ml'), findsNothing);
    expect(find.text('580 ml'), findsOneWidget);
  });

  testWidgets('cancelling the confirmation keeps the entry', (tester) async {
    await pumpList(tester, DateTime(2026, 10, 19));

    await tester.tap(find.bySemanticsIdentifier('water-entry-delete-0'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10nEn.dialogCancelLabel));
    await tester.pumpAndSettle();

    expect(repository.entries, hasLength(3));
  });

  testWidgets('a day without water shows nothing', (tester) async {
    await pumpList(tester, DateTime(2026, 10, 18));

    expect(find.text(l10nEn.waterEntriesTitle), findsNothing);
  });

  testWidgets('an entry logged elsewhere appears after the change', (
    tester,
  ) async {
    await pumpList(tester, DateTime(2026, 10, 19));

    repository.entries.add(
      WaterIntakeEntity(
        id: 'late',
        dateTime: DateTime(2026, 10, 19, 22),
        amountMl: 200,
      ),
    );
    log.markChanged();
    await tester.pumpAndSettle();

    expect(find.text('22:00 · 200 ml'), findsOneWidget);
  });
}
