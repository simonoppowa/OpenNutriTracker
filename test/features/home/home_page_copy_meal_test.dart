import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:opennutritracker/core/domain/entity/body_weight_unit_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/entity/profile_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_gender_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_profiles_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/import_workouts_usecase.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_type.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/fasting/presentation/bloc/fasting_bloc.dart';
import 'package:opennutritracker/features/home/home_page.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

import '../../helpers/test_l10n.dart';

final _lunch = IntakeEntity(
  id: 'lunch-soup',
  unit: 'g',
  amount: 250,
  type: IntakeTypeEntity.lunch,
  dateTime: DateTime(2026, 6, 15, 12, 30),
  meal: MealEntity(
    code: 'soup',
    name: 'Lentil Soup',
    url: null,
    mealQuantity: '100',
    mealUnit: 'g',
    servingQuantity: null,
    servingUnit: 'g',
    servingSize: '100 g',
    nutriments: const MealNutrimentsEntity(
      energyKcal100: 80,
      carbohydrates100: 12,
      fat100: 1,
      proteins100: 5,
      sugars100: null,
      saturatedFat100: null,
      fiber100: null,
    ),
    source: MealSourceEntity.custom,
  ),
);

/// What a copy logged: the amount, the meal it went to and the food.
final _added = <(String, IntakeTypeEntity, MealEntity)>[];

class _FakeMealDetailBloc extends Fake implements MealDetailBloc {
  @override
  Future<void> addIntake(
    BuildContext context,
    String unit,
    String amountText,
    IntakeTypeEntity type,
    MealEntity meal,
    DateTime day,
  ) async => _added.add(('$amountText $unit', type, meal));
}

/// Home with today's lunch logged, and nothing else.
class _FakeHomeBloc extends Bloc<HomeEvent, HomeState> implements HomeBloc {
  _FakeHomeBloc()
    : super(
        HomeLoadedState(
          showDisclaimerDialog: false,
          totalKcalDaily: 2000,
          totalKcalLeft: 1800,
          totalKcalSupplied: 200,
          totalKcalBurned: 0,
          totalCarbsIntake: 30,
          totalFatsIntake: 2.5,
          totalProteinsIntake: 12.5,
          totalCarbsGoal: 250,
          totalFatsGoal: 70,
          totalProteinsGoal: 100,
          userActivityList: const [],
          breakfastIntakeList: const [],
          lunchIntakeList: [_lunch],
          dinnerIntakeList: const [],
          snackIntakeList: const [],
          usesImperialUnits: false,
          bodyWeightUnit: BodyWeightUnit.kg,
          userWeightKg: 70,
          breakfastKcalTarget: 600,
          lunchKcalTarget: 800,
          dinnerKcalTarget: 400,
          snackKcalTarget: 200,
          breakfastSharePct: 30,
          lunchSharePct: 40,
          dinnerSharePct: 20,
          snackSharePct: 10,
          userGender: UserGenderEntity.female,
          userCaloriesProfile: null,
          waterMlToday: 0,
          waterGoalMl: 2000,
          waterIntakes: const [],
          showActivityTracking: false,
        ),
      ) {
    on<HomeEvent>((_, _) {});
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _FakeFastingBloc extends Bloc<FastingEvent, FastingState>
    implements FastingBloc {
  _FakeFastingBloc() : super(const FastingInitial()) {
    on<FastingEvent>((_, _) {});
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _FakeDiaryBloc extends Fake implements DiaryBloc {
  @override
  void add(DiaryEvent event) {}
}

class _FakeCalendarDayBloc extends Fake implements CalendarDayBloc {
  @override
  void add(CalendarDayEvent event) {}
}

class _NoWorkouts extends Fake implements ImportWorkoutsUsecase {
  @override
  Future<int> importIfDue() async => 0;
}

class _SingleProfile extends Fake implements GetProfilesUsecase {
  static final _profile = ProfileEntity(
    id: 'p1',
    name: 'Me',
    createdAt: DateTime(2026, 1, 1),
    boxSuffix: '',
  );

  @override
  List<ProfileEntity> getProfiles() => [_profile];

  @override
  String get activeProfileId => 'p1';

  @override
  ProfileEntity? getActiveProfile() => _profile;
}

void main() {
  setUpAll(() {
    final locator = GetIt.instance;
    locator.registerLazySingleton<HomeBloc>(_FakeHomeBloc.new);
    locator.registerFactory<FastingBloc>(_FakeFastingBloc.new);
    locator.registerFactory<MealDetailBloc>(_FakeMealDetailBloc.new);
    locator.registerFactory<DiaryBloc>(_FakeDiaryBloc.new);
    locator.registerFactory<CalendarDayBloc>(_FakeCalendarDayBloc.new);
    locator.registerFactory<ImportWorkoutsUsecase>(_NoWorkouts.new);
    locator.registerFactory<GetProfilesUsecase>(_SingleProfile.new);
  });

  tearDownAll(() => GetIt.instance.reset());

  // #842: leftovers from lunch eaten for dinner are logged again from
  // Home's own meal menu.
  testWidgets('Home copies a meal into another meal of today', (
    WidgetTester tester,
  ) async {
    _added.clear();
    // Tall enough for every meal section to be built.
    tester.view.physicalSize = const Size(800, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ChangeNotifierProvider<EnergyUnitProvider>(
        create: (_) => EnergyUnitProvider(),
        child: MaterialApp(
          localizationsDelegates: const [S.delegate],
          supportedLocales: S.supportedLocales,
          home: const Scaffold(body: HomePage()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final lunchMenu = find.descendant(
      of: find.ancestor(
        of: find.text(l10nEn.lunchLabel),
        matching: find.byType(Row),
      ),
      matching: find.bySemanticsIdentifier('intake-section-menu'),
    );
    await tester.tap(lunchMenu.first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10nEn.dialogCopyLabel));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButton<AddMealType>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10nEn.dinnerLabel).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10nEn.dialogOKLabel));
    await tester.pumpAndSettle();

    expect(_added, [('250.0 g', IntakeTypeEntity.dinner, _lunch.meal)]);
  });
}
