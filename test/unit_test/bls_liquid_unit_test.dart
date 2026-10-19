import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/local_bls_catalog.dart';
import 'package:opennutritracker/features/add_meal/data/dto/sp/sp_const.dart';
import 'package:opennutritracker/features/add_meal/data/dto/sp/sp_food_dto.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';

MealEntity _bls(String code, {String name = 'x'}) => MealEntity.fromSpFood(
  SpFoodDTO(
    foodId: 1,
    name: name,
    source: SPConst.blsSourceCode,
    sourceCode: code,
  ),
);

void main() {
  group('BLS foods measured in millilitres (#104)', () {
    for (final (code, name) in [
      ('F603600', 'Orangensaft'),
      ('F516600', 'Mangosaft'),
      ('F508700', 'Maracujanektar'),
      ('F032600', 'Smoothie'),
      ('C660000', 'Haferdrink'),
      ('H841100', 'Sojadrink'),
      ('H800000', 'Mandeldrink'),
      ('M111300', 'Vollmilch'),
      ('M113200', 'H-Milch fettarm'),
      ('M150000', 'Buttermilch'),
      ('M130300', 'Kefir'),
      ('M1A5200', 'H-Milch fettarm, laktosefrei'),
      ('M161000', 'Süßmolke'),
      ('M182500', 'Kondensmilch'),
      ('C650000', 'Reisdrink'),
      ('H842400', 'Sojadrink gesüßt'),
      ('N110000', 'Getränk (Gruppe N)'),
      ('P100000', 'alkoholisches Getränk (Gruppe P)'),
    ]) {
      test('$name ($code) is in ml', () {
        final meal = _bls(code);
        expect(meal.mealUnit, 'ml');
        expect(meal.servingUnit, 'ml');
      });
    }
  });

  group('solid BLS foods stay in grams', () {
    for (final (code, name) in [
      ('F110100', 'Apfel'),
      ('F202100', 'Nektarine'),
      ('F602300', 'Limettensaft Konzentrat'),
      ('M882000', 'Vollmilchpulver'),
      ('M141300', 'Joghurt'),
      ('M052000', 'Salzlakenkäse aus Kuhmilch'),
      ('H844000', 'Soja-Joghurtalternative'),
      ('C130000', 'Haferflocken'),
    ]) {
      test('$name ($code) is in g', () {
        expect(_bls(code).mealUnit, 'g');
      });
    }
  });

  test('milk drinks of subgroup M2 are in ml, its yoghurts in g', () {
    expect(_bls('M200200', name: 'Milk drink 1.5 % fat').mealUnit, 'ml');
    expect(
      _bls('M200200', name: 'Milchmischgetränk 1,5 % Fett').mealUnit,
      'ml',
    );
    expect(_bls('M2H2300', name: 'Milkshake 3.5 % fat').mealUnit, 'ml');
    expect(_bls('M2S8300', name: 'Ayran, yogurt drink, salted').mealUnit, 'ml');
    expect(
      _bls('M241300', name: 'Joghurt mild, mit Fruchtzubereitung').mealUnit,
      'g',
    );
    expect(_bls('M2N6400', name: 'Cream yogurt sweetened').mealUnit, 'g');
  });

  test('in the shipped BLS, every food called liquid is one', () {
    final catalog = LocalBlsCatalog.decode(
      File('assets/bls/bls_4_0.json.gz').readAsBytesSync(),
    );
    final liquidWords = RegExp(
      'saft|nektar|smoothie|milch|kefir|molke|drink|getränk|shake|ayran|'
      'trinkjoghurt',
    );
    final wrong = [
      for (final food in catalog.foods)
        if (!SPConst.blsBeverageGroups.contains(food.code[0]) &&
            SPConst.isBlsLiquid(food.code, names: [food.nameDe, food.nameEn]) &&
            !liquidWords.hasMatch(food.nameDe.toLowerCase()))
          '${food.code} ${food.nameDe}',
    ];

    expect(wrong, isEmpty);
  });

  test('the per-100 basis stays the same for liquids', () {
    final meal = MealEntity.fromSpFood(
      SpFoodDTO(
        foodId: 1,
        name: 'Orangensaft',
        source: SPConst.blsSourceCode,
        sourceCode: 'F603600',
        energyKcal100: 45,
      ),
    );

    expect(meal.nutriments.energyKcal100, 45);
  });

  test('other sources are not judged by BLS codes', () {
    expect(
      MealEntity.fromSpFood(
        SpFoodDTO(foodId: 1, name: 'x', source: 'fdc', sourceCode: 'F603600'),
      ).mealUnit,
      'g',
    );
  });
}
