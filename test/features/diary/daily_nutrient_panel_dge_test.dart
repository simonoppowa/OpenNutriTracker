import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/data/dbo/app_theme_dbo.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/diary/presentation/widgets/daily_nutrient_panel.dart';
import 'package:opennutritracker/features/settings/domain/nutrient_reference_setting.dart';
import 'package:opennutritracker/generated/l10n.dart';

import '../../helpers/test_l10n.dart';

class _FakeConfigDataSource implements ConfigDataSource {
  ConfigDBO config = ConfigDBO(false, false, false, AppThemeDBO.system);

  @override
  Future<ConfigDBO> getConfig() async => config;

  @override
  Future<void> addConfig(ConfigDBO configDBO) async => config = configDBO;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

final _intake = IntakeEntity(
  id: 'a',
  unit: 'g',
  amount: 100,
  type: IntakeTypeEntity.breakfast,
  dateTime: DateTime(2026, 10, 19),
  meal: MealEntity(
    code: 'a',
    name: 'a',
    url: null,
    mealQuantity: null,
    mealUnit: 'g',
    servingQuantity: null,
    servingUnit: 'g',
    servingSize: null,
    source: MealSourceEntity.custom,
    nutriments: const MealNutrimentsEntity(
      energyKcal100: 100,
      carbohydrates100: 10,
      fat100: 2,
      proteins100: 5,
      sugars100: 4,
      saturatedFat100: 1,
      fiber100: 2,
      sodium100: 500,
    ),
  ),
);

Future<void> _openPanel(WidgetTester tester, {TrackedDayEntity? day}) async {
  await tester.binding.setSurfaceSize(const Size(500, 4000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
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
        body: SingleChildScrollView(
          child: DailyNutrientPanel(intakes: [_intake], trackedDay: day),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byType(ExpansionTile));
  await tester.pumpAndSettle();
}

void main() {
  late NutrientReferenceSetting setting;

  setUp(() {
    setting = NutrientReferenceSetting(_FakeConfigDataSource());
    locator.registerSingleton<NutrientReferenceSetting>(setting);
  });

  tearDown(() => locator.unregister<NutrientReferenceSetting>());

  testWidgets('the panel switches to DGE values right away', (tester) async {
    await _openPanel(tester);
    expect(find.text('500 / 2300mg'), findsOneWidget);
    expect(find.text(l10nEn.nutrientReferenceFallbackTag), findsNothing);

    await setting.save(NutrientReferenceStandard.dge);
    await tester.pumpAndSettle();

    expect(find.text('500 / 2400mg'), findsOneWidget);
    expect(find.text('2.0 / 30mg'), findsNothing);
    expect(find.text('2.0 / 30g'), findsOneWidget);
  });

  testWidgets('a nutrient the DGE has no value for is marked', (tester) async {
    await setting.save(NutrientReferenceStandard.dge);
    await _openPanel(tester);

    final satFat = find.ancestor(
      of: find.text(l10nEn.saturatedFatLabel),
      matching: find.byType(Row),
    );
    final sodium = find.ancestor(
      of: find.text(l10nEn.sodiumLabel),
      matching: find.byType(Row),
    );
    expect(
      find.descendant(
        of: satFat.first,
        matching: find.text(l10nEn.nutrientReferenceFallbackTag),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: sodium.first,
        matching: find.text(l10nEn.nutrientReferenceFallbackTag),
      ),
      findsNothing,
    );
  });

  testWidgets('an own goal beats the DGE value and is not marked', (
    tester,
  ) async {
    await setting.save(NutrientReferenceStandard.dge);
    await _openPanel(
      tester,
      day: TrackedDayEntity(
        day: DateTime(2026, 10, 19),
        calorieGoal: 2000,
        caloriesTracked: 100,
        sodiumGoal: 1800,
        satFatGoal: 15,
      ),
    );

    expect(find.text('500 / 1800mg'), findsOneWidget);
    expect(find.text('1.0 / 15g'), findsOneWidget);
    final satFat = find.ancestor(
      of: find.text(l10nEn.saturatedFatLabel),
      matching: find.byType(Row),
    );
    expect(
      find.descendant(
        of: satFat.first,
        matching: find.text(l10nEn.nutrientReferenceFallbackTag),
      ),
      findsNothing,
    );
  });
}
