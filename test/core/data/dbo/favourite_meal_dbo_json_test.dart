import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/dbo/favourite_meal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';

import '../../../fixture/meal_entity_fixtures.dart';

void main() {
  FavouriteMealDBO favourite(DateTime addedAt) => FavouriteMealDBO(
    meal: MealDBO.fromMealEntity(MealEntityFixtures.mealOne),
    addedAt: addedAt,
  );

  Map<String, dynamic> exported(FavouriteMealDBO dbo) =>
      jsonDecode(jsonEncode(dbo.toJson())) as Map<String, dynamic>;

  group('FavouriteMealDBO JSON', () {
    test('writes addedAt in UTC, with its offset', () {
      final addedAt = DateTime(2026, 10, 25, 2, 30);
      final json = exported(favourite(addedAt));

      expect(json['addedAt'], addedAt.toUtc().toIso8601String());
      expect(json['addedAt'], endsWith('Z'));
    });

    test('reads addedAt back as the same moment, in local time', () {
      final addedAt = DateTime(2026, 10, 25, 2, 30, 15, 250);
      final read = FavouriteMealDBO.fromJson(exported(favourite(addedAt)));

      expect(read.addedAt.isUtc, isFalse);
      expect(read.addedAt, addedAt);
      expect(read.addedAt.hour, addedAt.hour);
    });

    test('reads a file written without the offset as local time', () {
      final json = exported(favourite(DateTime(2026)));
      json['addedAt'] = '2026-03-29T02:30:00.000';

      final read = FavouriteMealDBO.fromJson(json);

      expect(read.addedAt.isUtc, isFalse);
      expect(read.addedAt, DateTime.parse('2026-03-29T02:30:00.000'));
    });
  });
}
