import 'dart:convert';

import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/utils/id_generator.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';

/// Result of parsing a pasted JSON blob. [intakes] holds the entries that
/// will be written; [errors] holds a one-line reason for each entry that
/// could not be parsed. A blob that fails JSON.decode at the top level
/// returns a result with an empty [intakes] list and a single entry in
/// [errors] describing the malformed JSON.
///
/// The JSON shape mirrors the CSV importer — see the doc comment on
/// [JsonMealImporter] for the accepted field set.
class JsonImportResult {
  final List<IntakeEntity> intakes;
  final List<String> errors;

  const JsonImportResult({required this.intakes, required this.errors});

  bool get hasErrors => errors.isNotEmpty;
}

/// Lenient JSON-paste importer for the diary. Accepts either a single
/// object or a JSON array of objects; the shape is:
///
/// ```
/// {
///   "name": "Apple",
///   "kcal": 95,
///   "protein": 0.5,
///   "carbs": 25,
///   "fat": 0.3,
///   "mealType": "snack",   // optional, default "snack"
///   "amount": 100,         // optional, default 100
///   "unit": "g",           // optional, default "g"
///   "date": "2026-05-13",  // optional, default today
///   "serving_size": 100    // optional — when set, the saved custom meal
///                          // defaults to 1 serving on re-log
/// }
/// ```
///
/// `name`, `kcal`, `protein`, `carbs`, and `fat` are required; everything
/// else has a sensible default. `kcal` / `protein` / `carbs` / `fat` are
/// the totals for the logged portion — the importer back-projects them to
/// per-100[g|ml] so the resulting MealEntity is consistent with how the
/// rest of the app stores nutriments. So pasting `{ "amount": 50, "kcal":
/// 100, ... }` records a 50 g entry whose underlying meal is 200 kcal /
/// 100 g, and the diary totals end up correct.
///
/// The importer never silently drops a malformed entry — every failure
/// produces a one-line message in [JsonImportResult.errors] referencing
/// the entry's index so the user can fix and retry.
class JsonMealImporter {
  static const _kName = 'name';
  static const _kKcal = 'kcal';
  static const _kProtein = 'protein';
  static const _kCarbs = 'carbs';
  static const _kFat = 'fat';
  static const _kMealType = 'mealType';
  static const _kAmount = 'amount';
  static const _kUnit = 'unit';
  static const _kDate = 'date';
  static const _kServingSize = 'serving_size';

  static const _requiredKeys = <String>[_kName, _kKcal, _kProtein, _kCarbs, _kFat];

  /// Pretty-printed JSON the "Sample meals (json)" button hands to the user. Three
  /// entries that between them show every supported field, including the
  /// optional ones (mealType, amount, unit, date). The shape mirrors the
  /// CSV sample so a user familiar with one path can read the other.
  static String sampleJson() {
    return '''[
  {
    "name": "Banana",
    "kcal": 89,
    "protein": 1.1,
    "carbs": 22.8,
    "fat": 0.3,
    "mealType": "snack",
    "amount": 100,
    "unit": "g"
  },
  {
    "name": "Porridge with milk",
    "kcal": 145,
    "protein": 6.5,
    "carbs": 17.2,
    "fat": 5.6,
    "mealType": "breakfast",
    "amount": 250,
    "unit": "g",
    "date": "2026-05-13"
  },
  {
    "name": "Greek salad",
    "kcal": 220,
    "protein": 7.0,
    "carbs": 12.0,
    "fat": 16.0,
    "mealType": "lunch",
    "serving_size": 250
  }
]
''';
  }

  /// Parse [jsonContent]. [now] is injectable for tests so we don't have
  /// to freeze time globally; production callers should leave it null and
  /// the importer uses [DateTime.now].
  static JsonImportResult parse(String jsonContent, {DateTime? now}) {
    final today = now ?? DateTime.now();

    final trimmed = jsonContent.trim();
    if (trimmed.isEmpty) {
      return const JsonImportResult(
        intakes: [],
        errors: ['JSON is empty'],
      );
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(trimmed);
    } on FormatException catch (e) {
      return JsonImportResult(
        intakes: const [],
        errors: ['Could not parse: ${e.message}'],
      );
    }

    final entries = <Map<String, dynamic>>[];
    if (decoded is Map) {
      entries.add(Map<String, dynamic>.from(decoded));
    } else if (decoded is List) {
      for (var i = 0; i < decoded.length; i++) {
        final item = decoded[i];
        if (item is Map) {
          entries.add(Map<String, dynamic>.from(item));
        } else {
          return JsonImportResult(
            intakes: const [],
            errors: [
              'Could not parse: entry #${i + 1} is not an object',
            ],
          );
        }
      }
    } else {
      return const JsonImportResult(
        intakes: [],
        errors: [
          'Could not parse: top-level JSON must be an object or an array of objects',
        ],
      );
    }

    final intakes = <IntakeEntity>[];
    final errors = <String>[];

    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final entryNum = i + 1;

      final missing = _requiredKeys.where((k) => entry[k] == null).toList();
      if (missing.isNotEmpty) {
        errors.add('Entry $entryNum: missing required field(s): ${missing.join(', ')}');
        continue;
      }

      final name = entry[_kName]?.toString().trim() ?? '';
      if (name.isEmpty) {
        errors.add('Entry $entryNum: name is empty');
        continue;
      }

      final kcalTotal = _asDouble(entry[_kKcal]);
      final proteinTotal = _asDouble(entry[_kProtein]);
      final carbsTotal = _asDouble(entry[_kCarbs]);
      final fatTotal = _asDouble(entry[_kFat]);
      if (kcalTotal == null || proteinTotal == null || carbsTotal == null || fatTotal == null) {
        errors.add('Entry $entryNum: kcal / protein / carbs / fat must all be numbers');
        continue;
      }

      final mealTypeRaw = (entry[_kMealType]?.toString().trim() ?? '').toLowerCase();
      final IntakeTypeEntity mealType;
      if (mealTypeRaw.isEmpty) {
        mealType = IntakeTypeEntity.snack;
      } else {
        final parsed = _parseMealType(mealTypeRaw);
        if (parsed == null) {
          errors.add(
            'Entry $entryNum: mealType must be one of breakfast, lunch, dinner, snack '
            '(got "$mealTypeRaw")',
          );
          continue;
        }
        mealType = parsed;
      }

      final amount = entry[_kAmount] == null ? 100.0 : _asDouble(entry[_kAmount]);
      if (amount == null || amount <= 0) {
        errors.add('Entry $entryNum: amount must be a positive number');
        continue;
      }

      final unit = (entry[_kUnit]?.toString().trim().isNotEmpty == true)
          ? entry[_kUnit].toString().trim()
          : 'g';

      // Optional serving_size: independent of `amount`. `amount` is what
      // was logged this time; `serving_size` describes what a serving
      // *generally* is, and once the meal is saved as a custom food the
      // meal-detail screen uses it to default re-logged quantities to
      // 1 serving instead of 100 g.
      double? servingQuantity;
      if (entry.containsKey(_kServingSize) && entry[_kServingSize] != null) {
        final parsed = _asDouble(entry[_kServingSize]);
        if (parsed == null || parsed <= 0) {
          errors.add('Entry $entryNum: serving_size must be a positive number');
          continue;
        }
        servingQuantity = parsed;
      }

      DateTime date;
      final dateRaw = entry[_kDate]?.toString().trim();
      if (dateRaw == null || dateRaw.isEmpty) {
        date = DateTime(today.year, today.month, today.day);
      } else {
        final parsedDate = DateTime.tryParse(dateRaw);
        if (parsedDate == null) {
          errors.add(
            'Entry $entryNum: date must be ISO-8601 (for example "2026-05-13"); '
            'got "$dateRaw"',
          );
          continue;
        }
        date = parsedDate;
      }

      // Back-project the totals to per-100[unit] values so the stored
      // MealEntity is consistent with the rest of the app's nutriments.
      // Both the energyPerUnit / *PerUnit getters and the diary's daily
      // sums multiply per-unit values by the logged amount, so this
      // keeps the displayed kcal/macros faithful to what was pasted.
      final factor = 100.0 / amount;
      final nutriments = MealNutrimentsEntity(
        energyKcal100: kcalTotal * factor,
        carbohydrates100: carbsTotal * factor,
        fat100: fatTotal * factor,
        proteins100: proteinTotal * factor,
        sugars100: null,
        saturatedFat100: null,
        fiber100: null,
      );

      final meal = MealEntity(
        code: null,
        name: name,
        url: null,
        mealQuantity: amount.toString(),
        mealUnit: unit,
        servingQuantity: servingQuantity,
        servingUnit: unit,
        servingSize: servingQuantity != null
            ? '${_formatNumber(servingQuantity)} $unit'
            : '$amount $unit',
        nutriments: nutriments,
        source: MealSourceEntity.custom,
      );

      intakes.add(
        IntakeEntity(
          id: IdGenerator.getUniqueID(),
          unit: unit,
          amount: amount,
          type: mealType,
          meal: meal,
          dateTime: date,
        ),
      );
    }

    return JsonImportResult(intakes: intakes, errors: errors);
  }

  static double? _asDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      return double.tryParse(trimmed.replaceAll(',', '.'));
    }
    return null;
  }

  static String _formatNumber(double n) {
    if (n == n.truncateToDouble()) return n.toInt().toString();
    return n.toString();
  }

  static IntakeTypeEntity? _parseMealType(String raw) {
    switch (raw) {
      case 'breakfast':
        return IntakeTypeEntity.breakfast;
      case 'lunch':
        return IntakeTypeEntity.lunch;
      case 'dinner':
        return IntakeTypeEntity.dinner;
      case 'snack':
        return IntakeTypeEntity.snack;
      default:
        return null;
    }
  }
}
