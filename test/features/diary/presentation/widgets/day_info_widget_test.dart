import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/entity/profile_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_profiles_usecase.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/diary/presentation/widgets/day_info_widget.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';
import '../../../../helpers/test_l10n.dart';

class _FakeMealDetailBloc extends Fake implements MealDetailBloc {}

class _FakeHomeBloc extends Fake implements HomeBloc {}

class _SingleProfileGetProfilesUsecase implements GetProfilesUsecase {
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

IntakeEntity _intake(IntakeTypeEntity type, String name) {
  return IntakeEntity(
    id: 'intake-$name',
    unit: 'g',
    amount: 100,
    type: type,
    dateTime: DateTime(2026, 6, 15, 8),
    meal: MealEntity(
      code: 'meal-$name',
      name: name,
      url: null,
      mealQuantity: '100',
      mealUnit: 'g',
      servingQuantity: null,
      servingUnit: 'g',
      servingSize: '100 g',
      nutriments: MealNutrimentsEntity(
        energyKcal100: 200,
        carbohydrates100: 20,
        fat100: 10,
        proteins100: 5,
        sugars100: null,
        saturatedFat100: null,
        fiber100: null,
      ),
      source: MealSourceEntity.custom,
    ),
  );
}

void main() {
  setUpAll(() {
    final locator = GetIt.instance;
    locator.registerFactory<MealDetailBloc>(_FakeMealDetailBloc.new);
    locator.registerFactory<HomeBloc>(_FakeHomeBloc.new);
    locator.registerFactory<GetProfilesUsecase>(
      _SingleProfileGetProfilesUsecase.new,
    );
  });

  tearDownAll(() {
    GetIt.instance.reset();
  });

  // #1305: OMAD puts breakfast, lunch and snack at 0 %. Food that still lands
  // in breakfast must get a section, or it counts toward the day with no way
  // to see, edit or delete it. Empty 0 % sections stay hidden.
  testWidgets('a 0 % meal section with intakes is shown, an empty one is not',
      (WidgetTester tester) async {
    await tester.pumpWidget(ChangeNotifierProvider<EnergyUnitProvider>(
      create: (_) => EnergyUnitProvider(),
      child: MaterialApp(
        localizationsDelegates: const [S.delegate],
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: DayInfoWidget(
              selectedDay: DateTime(2026, 6, 15),
              trackedDayEntity: null,
              userActivities: const [],
              breakfastIntake: [
                _intake(IntakeTypeEntity.breakfast, 'Hidden Porridge'),
              ],
              lunchIntake: const [],
              dinnerIntake: [_intake(IntakeTypeEntity.dinner, 'Dinner Stew')],
              snackIntake: const [],
              usesImperialUnits: false,
              showActivityTracking: false,
              onDeleteIntake: (_, _) {},
              onDeleteActivity: (_, _) {},
              onCopyIntake: (_, _, _) {},
              onCopyActivity: (_, _) {},
              breakfastSharePct: 0,
              lunchSharePct: 0,
              dinnerSharePct: 100,
              snackSharePct: 0,
            ),
          ),
        ),
      ),
    ));
    await tester.pump();

    expect(find.text(l10nEn.breakfastLabel), findsOneWidget);
    expect(find.text('Hidden Porridge'), findsOneWidget);
    expect(find.text(l10nEn.dinnerLabel), findsOneWidget);
    expect(find.text(l10nEn.lunchLabel), findsNothing);
    expect(find.text(l10nEn.snackLabel), findsNothing);
  });
}
