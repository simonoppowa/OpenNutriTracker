import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/body_weight_unit_entity.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_water_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_weight_log_usecase.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/trends/presentation/bloc/trends_bloc.dart';
import 'package:opennutritracker/features/trends/presentation/trends_page.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

class _FakeGetTrackedDayUsecase extends Fake implements GetTrackedDayUsecase {}

class _FakeGetWeightLogUsecase extends Fake implements GetWeightLogUsecase {}

class _FakeGetUserUsecase extends Fake implements GetUserUsecase {}

class _FakeGetConfigUsecase extends Fake implements GetConfigUsecase {}

class _FakeGetWaterIntakeUsecase extends Fake
    implements GetWaterIntakeUsecase {}

/// A TrendsBloc pinned to one loaded state, so the test decides exactly
/// which days the Daily average card sees.
class _SeededTrendsBloc extends TrendsBloc {
  _SeededTrendsBloc(TrendsLoaded seeded)
    : super(
        _FakeGetTrackedDayUsecase(),
        _FakeGetWeightLogUsecase(),
        _FakeGetUserUsecase(),
        _FakeGetConfigUsecase(),
        _FakeGetWaterIntakeUsecase(),
      ) {
    emit(seeded);
  }

  @override
  void add(TrendsEvent event) {}
}

TrendsLoaded _week(List<TrackedDayEntity> days) => TrendsLoaded(
  rangeDays: 7,
  windowDays: 7,
  days: days,
  priorWeek: const [],
  weight: const [],
  bodyWeightUnit: BodyWeightUnit.kg,
  targetWeightKg: null,
  waterByDay: const {},
  waterGoalMl: 0,
);

TrackedDayEntity _day(
  int daysAgo, {
  required double carbs,
  required double carbsGoal,
}) {
  final now = DateTime.now();
  return TrackedDayEntity(
    day: DateTime(now.year, now.month, now.day - daysAgo),
    calorieGoal: 2000,
    caloriesTracked: 1800,
    carbsTracked: carbs,
    carbsGoal: carbsGoal,
    fatTracked: 70,
    fatGoal: 70,
    proteinTracked: 140,
    proteinGoal: 140,
  );
}

Future<void> _pumpTrends(WidgetTester tester, TrendsLoaded state) async {
  locator.registerSingleton<TrendsBloc>(_SeededTrendsBloc(state));
  addTearDown(locator.reset);
  // Tall enough that the list builds the Daily average card.
  tester.view.physicalSize = const Size(1080, 6000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => EnergyUnitProvider(),
      child: const MaterialApp(
        localizationsDelegates: [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.supportedLocales,
        home: Scaffold(body: TrendsPage()),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('a week with one day logged shows the whole goal', (
    tester,
  ) async {
    await _pumpTrends(tester, _week([_day(0, carbs: 252, carbsGoal: 250)]));

    // The intake is over the week's seven days, as before: 252 / 7 = 36.
    // The goal is the logged day's, not a seventh of it.
    expect(find.text('36 / 250 g'), findsOneWidget);
    expect(find.text('10 / 70 g'), findsOneWidget);
    expect(find.text('20 / 140 g'), findsOneWidget);
  });

  testWidgets('the goal is the mean of the days that have one', (tester) async {
    await _pumpTrends(
      tester,
      _week([
        _day(0, carbs: 210, carbsGoal: 200),
        _day(1, carbs: 210, carbsGoal: 300),
      ]),
    );

    expect(find.text('60 / 250 g'), findsOneWidget);
  });

  testWidgets('grams are rounded, not cut off', (tester) async {
    // 251.3 / 7 = 35.9, and (250.4 + 250.8) / 2 = 250.6.
    await _pumpTrends(
      tester,
      _week([
        _day(0, carbs: 125.3, carbsGoal: 250.4),
        _day(1, carbs: 126, carbsGoal: 250.8),
      ]),
    );

    expect(find.text('36 / 251 g'), findsOneWidget);
  });
}
