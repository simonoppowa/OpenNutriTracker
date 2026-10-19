import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/data/repository/user_activity_repository.dart';
import 'package:opennutritracker/core/data/repository/user_repository.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/goal_targets.dart';
import 'package:opennutritracker/core/domain/entity/training_plan.dart';
import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_gender_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_pal_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_goal_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_macro_goal_usecase.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/features/goals/domain/own_goals_summary.dart';
import 'package:opennutritracker/features/goals/presentation/own_goals_note.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

import '../../fixture/physical_activity_entity_fixtures.dart';
import '../../helpers/test_l10n.dart';

class _FakeConfigRepository extends Fake implements ConfigRepository {
  final ConfigEntity config;

  _FakeConfigRepository(this.config);

  @override
  Future<ConfigEntity> getConfig() async => config;
}

class _FakeUserRepository extends Fake implements UserRepository {
  @override
  Future<UserEntity> getUserData() async => UserEntity(
    birthday: DateTime(1990),
    heightCM: 180,
    weightKG: 80,
    gender: UserGenderEntity.male,
    goal: UserWeightGoalEntity.maintainWeight,
    pal: UserPALEntity.active,
  );
}

class _FakeUserActivityRepository extends Fake
    implements UserActivityRepository {
  @override
  Future<List<UserActivityEntity>> getAllUserActivityByDate(
    DateTime dateTime, {
    int dayStartOffsetHours = 0,
    int dayStartOffsetMinutes = 0,
  }) async => [
    UserActivityEntity(
      'a',
      40,
      350,
      dateTime,
      PhysicalActivityFixtures.moderateBicycling,
    ),
  ];
}

void main() {
  Future<(OwnGoalsSummary?, double, GetMacroGoalUsecase)> load(
    GoalTargets targets, {
    TrainingPlan plan = const TrainingPlan(),
  }) async {
    final config = _FakeConfigRepository(
      ConfigEntity(
        false,
        false,
        false,
        AppThemeEntity.system,
        goalTargets: targets,
        trainingPlan: plan,
      ),
    );
    final kcal = GetKcalGoalUsecase(
      _FakeUserRepository(),
      config,
      _FakeUserActivityRepository(),
    );
    final macros = GetMacroGoalUsecase(config);
    final summary = await OwnGoalsSummary.load(
      configRepository: config,
      getKcalGoalUsecase: kcal,
      getMacroGoalUsecase: macros,
    );
    return (summary, await kcal.getKcalGoal(), macros);
  }

  test('nothing to say while the calculated goals apply', () async {
    final (summary, _, _) = await load(const GoalTargets());

    expect(summary, isNull);
  });

  test('a fixed goal plus activity adds up to the goal Home shows', () async {
    final (summary, homeGoal, _) = await load(
      const GoalTargets(kcalMode: KcalGoalMode.fixed, fixedKcal: 2000),
    );

    expect(summary!.fixedKcal, 2000);
    expect(summary.kcalGoal, homeGoal);
    expect(homeGoal, 2350);
    expect(summary.gramGoals, isNull);
  });

  test('gram goals equal the macro goals Home shows', () async {
    final (summary, homeGoal, macros) = await load(
      const GoalTargets(
        macroMode: MacroGoalMode.grams,
        carbsG: 220,
        fatG: 70,
        proteinG: 160,
      ),
    );

    expect(summary!.fixedKcal, isNull);
    expect(summary.gramGoals!.carbsG, await macros.getCarbsGoal(homeGoal));
    expect(summary.gramGoals!.proteinG, await macros.getProteinsGoal(homeGoal));
  });

  test('on a training day the training goals are named', () async {
    final (summary, _, _) = await load(
      const GoalTargets(),
      plan: const TrainingPlan(
        trainingTargets: GoalTargets(
          kcalMode: KcalGoalMode.fixed,
          fixedKcal: 2600,
        ),
        trainingWeekdays: {1, 2, 3, 4, 5, 6, 7},
      ),
    );

    expect(summary!.isTrainingDay, isTrue);
    expect(summary.kcalGoal, 2950);
  });

  testWidgets('the card shows the fixed goal, the activity and the total', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => EnergyUnitProvider(usesKilojoules: false),
        child: MaterialApp(
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          home: Scaffold(
            body: OwnGoalsNote(
              load: () async => const OwnGoalsSummary(
                isTrainingDay: false,
                fixedKcal: 2000,
                kcalGoal: 2350,
                gramGoals: (carbsG: 220, fatG: 70, proteinG: 160),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10nEn.ownGoalsNoteTitle), findsOneWidget);
    expect(find.text(l10nEn.ownGoalsNoteFixedKcal), findsOneWidget);
    expect(find.textContaining('2350'), findsOneWidget);
    expect(find.textContaining('350'), findsWidgets);
    expect(find.text('160 g'), findsOneWidget);
    expect(find.text(l10nEn.ownGoalsNoteBody), findsOneWidget);
  });

  testWidgets('with gram macros only the calculation still sets the kcal', (
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
        supportedLocales: const [Locale('en')],
        home: Scaffold(
          body: OwnGoalsNote(
            load: () async => const OwnGoalsSummary(
              isTrainingDay: false,
              fixedKcal: null,
              kcalGoal: 2500,
              gramGoals: (carbsG: 220, fatG: 70, proteinG: 160),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10nEn.ownGoalsNoteGramsOnlyBody), findsOneWidget);
    expect(find.text(l10nEn.ownGoalsNoteFixedKcal), findsNothing);
  });

  testWidgets('no card without own goals', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: OwnGoalsNote(load: () async => null)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsIdentifier('kcal-info-own-goals'), findsNothing);
  });
}
