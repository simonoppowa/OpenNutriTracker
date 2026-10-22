import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_tracked_day_usecase.dart';
import 'package:opennutritracker/core/utils/calc/day_boundary_calc.dart';
import 'package:opennutritracker/features/activity_detail/presentation/bloc/activity_detail_bloc.dart';
import 'package:opennutritracker/features/diary/diary_page.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/widgets/diary_table_calendar.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:table_calendar/table_calendar.dart';

/// #1360: the Diary's "today" is the logical day.
///
/// With "Day starts at" 22:00 and the clock at 20:40 on the 11th, food
/// logged now is filed under the 10th and Home counts it there. The Diary
/// opened on the 11th, with the today marker on it, and so showed an
/// empty day.

final _now = DateTime(2026, 10, 11, 20, 40);
final _logicalToday = DateTime(2026, 10, 10);
final _calendarToday = DateTime(2026, 10, 11);

class _Config extends Fake implements GetConfigUsecase {
  int dayStartOffsetHours = 22;

  @override
  Future<ConfigEntity> getConfig() async => ConfigEntity(
    true,
    true,
    false,
    AppThemeEntity.system,
    dayStartOffsetHours: dayStartOffsetHours,
  );
}

class _NoTrackedDays extends Fake implements GetTrackedDayUsecase {
  @override
  Future<List<TrackedDayEntity>> getTrackedDaysByRange(
    DateTime start,
    DateTime end,
  ) async => [];
}

/// Records which days the page asks for; the day view itself stays on
/// its loading state, which is all these tests need.
class _RecordingCalendarDayBloc extends Fake implements CalendarDayBloc {
  final List<DateTime> loadedDays = [];
  CalendarDayState _state = CalendarDayInitial();

  @override
  CalendarDayState get state => _state;

  @override
  Stream<CalendarDayState> get stream => const Stream.empty();

  @override
  void add(CalendarDayEvent event) {
    if (event is LoadCalendarDayEvent) loadedDays.add(event.day);
    _state = CalendarDayLoading();
  }
}

class _FakeMealDetailBloc extends Fake implements MealDetailBloc {}

class _FakeActivityDetailBloc extends Fake implements ActivityDetailBloc {}

void main() {
  final locator = GetIt.instance;
  late _Config config;
  late DiaryBloc diaryBloc;
  late _RecordingCalendarDayBloc calendarDayBloc;

  setUp(() {
    DayBoundaryCalc.clock = () => _now;
  });

  tearDown(() async {
    DayBoundaryCalc.clock = DateTime.now;
    await diaryBloc.close();
    await locator.reset();
  });

  // The day view shows a spinner while it loads, so pumpAndSettle would
  // never return; a few frames let the bloc's async load land.
  Future<void> pumpFrames(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 10));
    }
  }

  Future<void> pumpDiary(WidgetTester tester) async {
    // Built inside the test body, not in setUp: a bloc made outside the
    // test's fake-async zone resolves its futures on the real clock, and
    // pump() never sees its load finish.
    config = _Config();
    diaryBloc = DiaryBloc(_NoTrackedDays(), config);
    calendarDayBloc = _RecordingCalendarDayBloc();
    locator
      ..registerSingleton<DiaryBloc>(diaryBloc)
      ..registerSingleton<CalendarDayBloc>(calendarDayBloc)
      ..registerSingleton<MealDetailBloc>(_FakeMealDetailBloc())
      ..registerSingleton<ActivityDetailBloc>(_FakeActivityDetailBloc());
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: [S.delegate],
        supportedLocales: S.supportedLocales,
        home: Scaffold(body: DiaryPage()),
      ),
    );
    await pumpFrames(tester);
  }

  DiaryTableCalendar calendar(WidgetTester tester) =>
      tester.widget<DiaryTableCalendar>(find.byType(DiaryTableCalendar));

  Future<void> moveBoundaryTo(WidgetTester tester, int hours) async {
    config.dayStartOffsetHours = hours;
    // What the day-boundary dialog does on save.
    diaryBloc.add(const LoadDiaryYearEvent());
    await pumpFrames(tester);
  }

  testWidgets('opens on the logical day, with the today marker on it', (
    tester,
  ) async {
    await pumpDiary(tester);

    expect(calendar(tester).selectedDate, _logicalToday);
    expect(calendar(tester).currentDate, _logicalToday);
    final table = tester.widget<TableCalendar<dynamic>>(
      find.byWidgetPredicate((w) => w is TableCalendar),
    );
    expect(table.currentDay, _logicalToday);
    expect(calendarDayBloc.loadedDays, [_logicalToday]);
  });

  testWidgets('follows today when the boundary moves', (tester) async {
    await pumpDiary(tester);

    await moveBoundaryTo(tester, 0);

    expect(calendar(tester).currentDate, _calendarToday);
    expect(calendar(tester).selectedDate, _calendarToday);
    expect(calendarDayBloc.loadedDays.last, _calendarToday);
  });

  testWidgets('a picked day stays picked when the boundary moves', (
    tester,
  ) async {
    await pumpDiary(tester);
    final picked = DateTime.utc(2026, 10, 3);
    calendar(tester).onDateSelected(picked, const {});
    await pumpFrames(tester);
    final loadsBefore = calendarDayBloc.loadedDays.length;

    await moveBoundaryTo(tester, 0);

    expect(calendar(tester).currentDate, _calendarToday);
    expect(calendar(tester).selectedDate, picked);
    expect(calendarDayBloc.loadedDays.length, loadsBefore);
  });
}
