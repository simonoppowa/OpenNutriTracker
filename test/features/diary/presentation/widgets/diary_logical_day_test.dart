import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/activity_vertial_list.dart';
import 'package:opennutritracker/features/diary/presentation/widgets/day_info_widget.dart';
import 'package:opennutritracker/features/diary/presentation/widgets/diary_table_calendar.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

// #586: the diary calendar has to agree with the rest of the app about which
// day is "today". DiaryBloc resolves that through the configured day-start
// offset, so between midnight and the offset the logical day is still
// yesterday's date. Left to its own devices table_calendar asks
// DateTime.now(), rings tomorrow, and the page then treats a tap on that ring
// as editing a future date.
class _FakeMealDetailBloc extends Fake implements MealDetailBloc {}

class _FakeHomeBloc extends Fake implements HomeBloc {}

void main() {
  setUpAll(() {
    final locator = GetIt.instance;
    locator.registerFactory<MealDetailBloc>(_FakeMealDetailBloc.new);
    locator.registerFactory<HomeBloc>(_FakeHomeBloc.new);
  });

  tearDownAll(() {
    GetIt.instance.reset();
  });

  Widget wrap(Widget child) {
    return ChangeNotifierProvider<EnergyUnitProvider>(
      create: (_) => EnergyUnitProvider(),
      child: MaterialApp(
        localizationsDelegates: const [S.delegate],
        supportedLocales: S.supportedLocales,
        home: Scaffold(body: child),
      ),
    );
  }

  Widget buildCalendar({
    required DateTime currentDate,
    required DateTime selectedDate,
    void Function(DateTime)? onSelected,
  }) {
    return wrap(
      DiaryTableCalendar(
        onDateSelected: (date, _) => onSelected?.call(date),
        calendarDurationDays: const Duration(days: 365),
        focusedDate: selectedDate,
        currentDate: currentDate,
        selectedDate: selectedDate,
        trackedDaysMap: const {},
      ),
    );
  }

  testWidgets(
    'the calendar marks the logical day as today, not the wall clock',
    (tester) async {
      // Someone on a 06:00 boundary, looking at the app at 02:00 on the 21st:
      // their day is still the 20th.
      final logicalToday = DateTime(2026, 8, 20);

      await tester.pumpWidget(
        buildCalendar(currentDate: logicalToday, selectedDate: logicalToday),
      );

      // TableCalendar is generic, so match it by predicate rather than by
      // raw type and read the field back off the built widget.
      final calendar = tester.widget(
        find.byWidgetPredicate((widget) => widget is TableCalendar),
      );
      final currentDay = (calendar as dynamic).currentDay as DateTime?;

      expect(currentDay, logicalToday);
      expect(
        isSameDay(currentDay, DateTime.now()),
        isFalse,
        reason: 'the fixture must not accidentally sit on the real today',
      );
    },
  );

  testWidgets('the calendar stays selectable up to the logical day', (
    tester,
  ) async {
    final logicalToday = DateTime(2026, 8, 20);
    DateTime? tapped;

    await tester.pumpWidget(
      buildCalendar(
        currentDate: logicalToday,
        selectedDate: logicalToday,
        onSelected: (date) => tapped = date,
      ),
    );

    await tester.tap(find.text('19').first);
    await tester.pumpAndSettle();

    expect(tapped, isNotNull);
    expect(isSameDay(tapped, DateTime(2026, 8, 19)), isTrue);
  });

  // The same disagreement decided whether the day you were looking at
  // offered "copy" or only "delete". Asking the wall clock meant that at
  // 02:00 on a 06:00 boundary the diary thought today was a past day and
  // offered to copy the entries you were in the middle of editing.
  Widget buildDayInfo({
    required DateTime selectedDay,
    required DateTime currentDay,
  }) {
    return wrap(
      SingleChildScrollView(
        child: DayInfoWidget(
          selectedDay: selectedDay,
          currentDay: currentDay,
          trackedDayEntity: null,
          userActivities: const [],
          breakfastIntake: const [],
          lunchIntake: const [],
          dinnerIntake: const [],
          snackIntake: const [],
          usesImperialUnits: false,
          onDeleteIntake: (_, _) {},
          onDeleteActivity: (_, _) {},
          onCopyIntake: (_, _, _) {},
          onCopyActivity: (_, _) {},
        ),
      ),
    );
  }

  Function(UserActivityEntity)? copyCallbackOf(WidgetTester tester) {
    final list = tester.widget<ActivityVerticalList>(
      find.byType(ActivityVerticalList),
    );
    return list.onCopyActivityCallback;
  }

  testWidgets('viewing the logical today offers delete rather than copy', (
    tester,
  ) async {
    final logicalToday = DateTime(2026, 8, 20);

    await tester.pumpWidget(
      buildDayInfo(selectedDay: logicalToday, currentDay: logicalToday),
    );

    expect(copyCallbackOf(tester), isNull);
  });

  testWidgets('viewing an earlier day still offers copy', (tester) async {
    final logicalToday = DateTime(2026, 8, 20);

    await tester.pumpWidget(
      buildDayInfo(
        selectedDay: DateTime(2026, 8, 19),
        currentDay: logicalToday,
      ),
    );

    expect(copyCallbackOf(tester), isNotNull);
  });
}
