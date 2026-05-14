import 'package:opennutritracker/core/data/data_source/user_activity_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_type_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_nutriments_dbo.dart';
import 'package:opennutritracker/core/data/dbo/physical_activity_dbo.dart';
import 'package:opennutritracker/core/data/dbo/tracked_day_dbo.dart';
import 'package:opennutritracker/core/utils/csv_row_parser.dart';

/// Serializes the three exportable Hive datasets (intakes, user activities,
/// tracked days) to flat CSV alongside the existing JSON export. The same
/// utility offers a `parse...FromCsv` symmetry for each format so a round
/// trip (export -> import) lands at structurally-equal DBOs. The
/// `csv_meal_importer.dart` already in the codebase only knew how to
/// import *custom meals*; this module fills the missing leg for the
/// settings-screen export bundle.
///
/// Why CSV when JSON is already produced: see issues #40 and #132. A
/// plaintext column format is easier to inspect in a spreadsheet, easier
/// to diff under a Syncthing-style sync, and friendlier for the user
/// keeping a long-running backup outside the app's encrypted Hive box.
/// The JSON file remains the canonical export the app re-imports from;
/// the CSV sits next to it for human convenience and external tooling.
class CsvDataExporter {
  // Intake columns. Order matters for the generated CSV; the parser is
  // header-driven and tolerates re-ordering.
  static const intakeColumns = <String>[
    'id',
    'date_time',
    'type',
    'amount',
    'unit',
    'meal_code',
    'meal_name',
    'meal_brands',
    'meal_source',
    'meal_quantity',
    'meal_unit',
    'meal_serving_quantity',
    'meal_serving_unit',
    'meal_serving_size',
    'meal_thumbnail_url',
    'meal_main_image_url',
    'meal_url',
    'kcal_per_100g',
    'carbs_per_100g',
    'fat_per_100g',
    'protein_per_100g',
    'sugars_per_100g',
    'saturated_fat_per_100g',
    'fiber_per_100g',
    'monounsaturated_fat_per_100g',
    'polyunsaturated_fat_per_100g',
    'trans_fat_per_100g',
    'cholesterol_per_100g',
    'sodium_per_100g',
    'potassium_per_100g',
    'magnesium_per_100g',
    'calcium_per_100g',
    'iron_per_100g',
    'zinc_per_100g',
    'phosphorus_per_100g',
    'vitamin_a_per_100g',
    'vitamin_c_per_100g',
    'vitamin_d_per_100g',
    'vitamin_b6_per_100g',
    'vitamin_b12_per_100g',
    'niacin_per_100g',
  ];

  static const userActivityColumns = <String>[
    'id',
    'date',
    'duration',
    'burned_kcal',
    'activity_code',
    'specific_activity',
    'description',
    'mets',
    'tags',
    'type',
  ];

  static const trackedDayColumns = <String>[
    'day',
    'calorie_goal',
    'calories_tracked',
    'carbs_goal',
    'carbs_tracked',
    'fat_goal',
    'fat_tracked',
    'protein_goal',
    'protein_tracked',
  ];

  /// Build the intakes CSV string from a list of [IntakeDBO]. Each row
  /// flattens the embedded [MealDBO] and its nutriments so the file can
  /// be opened in a spreadsheet without further joins.
  static String intakesToCsv(List<IntakeDBO> intakes) {
    final buf = StringBuffer();
    buf.writeln(intakeColumns.join(','));
    for (final intake in intakes) {
      final meal = intake.meal;
      final n = meal.nutriments;
      final cells = <String>[
        _cell(intake.id),
        _cell(intake.dateTime.toIso8601String()),
        _cell(intake.type.name),
        _num(intake.amount),
        _cell(intake.unit),
        _cell(meal.code),
        _cell(meal.name),
        _cell(meal.brands),
        _cell(meal.source.name),
        _cell(meal.mealQuantity),
        _cell(meal.mealUnit),
        _num(meal.servingQuantity),
        _cell(meal.servingUnit),
        _cell(meal.servingSize),
        _cell(meal.thumbnailImageUrl),
        _cell(meal.mainImageUrl),
        _cell(meal.url),
        _num(n.energyKcal100),
        _num(n.carbohydrates100),
        _num(n.fat100),
        _num(n.proteins100),
        _num(n.sugars100),
        _num(n.saturatedFat100),
        _num(n.fiber100),
        _num(n.monounsaturatedFat100),
        _num(n.polyunsaturatedFat100),
        _num(n.transFat100),
        _num(n.cholesterol100),
        _num(n.sodium100),
        _num(n.potassium100),
        _num(n.magnesium100),
        _num(n.calcium100),
        _num(n.iron100),
        _num(n.zinc100),
        _num(n.phosphorus100),
        _num(n.vitaminA100),
        _num(n.vitaminC100),
        _num(n.vitaminD100),
        _num(n.vitaminB6100),
        _num(n.vitaminB12100),
        _num(n.niacin100),
      ];
      buf.writeln(cells.join(','));
    }
    return buf.toString();
  }

  /// Build the user_activities CSV string from a list of [UserActivityDBO].
  static String userActivitiesToCsv(List<UserActivityDBO> activities) {
    final buf = StringBuffer();
    buf.writeln(userActivityColumns.join(','));
    for (final activity in activities) {
      final pa = activity.physicalActivityDBO;
      // tags is a List<String>; serialize with a `|` separator so the
      // value sits inside a single CSV cell without needing nested
      // escaping. The parser splits on `|` and trims.
      final tagsCell = pa.tags.join('|');
      final cells = <String>[
        _cell(activity.id),
        _cell(activity.date.toIso8601String()),
        _num(activity.duration),
        _num(activity.burnedKcal),
        _cell(pa.code),
        _cell(pa.specificActivity),
        _cell(pa.description),
        _num(pa.mets),
        _cell(tagsCell),
        _cell(pa.type.name),
      ];
      buf.writeln(cells.join(','));
    }
    return buf.toString();
  }

  /// Build the tracked_days CSV string from a list of [TrackedDayDBO].
  static String trackedDaysToCsv(List<TrackedDayDBO> days) {
    final buf = StringBuffer();
    buf.writeln(trackedDayColumns.join(','));
    for (final d in days) {
      final cells = <String>[
        _cell(d.day.toIso8601String()),
        _num(d.calorieGoal),
        _num(d.caloriesTracked),
        _num(d.carbsGoal),
        _num(d.carbsTracked),
        _num(d.fatGoal),
        _num(d.fatTracked),
        _num(d.proteinGoal),
        _num(d.proteinTracked),
      ];
      buf.writeln(cells.join(','));
    }
    return buf.toString();
  }

  /// Parse an intakes CSV back into [IntakeDBO]s. Header-driven so column
  /// re-ordering is tolerated. Returns an empty list for an empty input.
  static List<IntakeDBO> parseIntakesFromCsv(String csv) {
    final rows = _parseRows(csv);
    if (rows.isEmpty) return const [];
    final header = rows.first;
    final out = <IntakeDBO>[];
    for (var i = 1; i < rows.length; i++) {
      final row = _zip(header, rows[i]);
      final nutriments = MealNutrimentsDBO(
        energyKcal100: CsvRowParser.parseDoubleOrNull(row['kcal_per_100g']),
        carbohydrates100: CsvRowParser.parseDoubleOrNull(row['carbs_per_100g']),
        fat100: CsvRowParser.parseDoubleOrNull(row['fat_per_100g']),
        proteins100: CsvRowParser.parseDoubleOrNull(row['protein_per_100g']),
        sugars100: CsvRowParser.parseDoubleOrNull(row['sugars_per_100g']),
        saturatedFat100:
            CsvRowParser.parseDoubleOrNull(row['saturated_fat_per_100g']),
        fiber100: CsvRowParser.parseDoubleOrNull(row['fiber_per_100g']),
        monounsaturatedFat100:
            CsvRowParser.parseDoubleOrNull(row['monounsaturated_fat_per_100g']),
        polyunsaturatedFat100:
            CsvRowParser.parseDoubleOrNull(row['polyunsaturated_fat_per_100g']),
        transFat100: CsvRowParser.parseDoubleOrNull(row['trans_fat_per_100g']),
        cholesterol100:
            CsvRowParser.parseDoubleOrNull(row['cholesterol_per_100g']),
        sodium100: CsvRowParser.parseDoubleOrNull(row['sodium_per_100g']),
        potassium100: CsvRowParser.parseDoubleOrNull(row['potassium_per_100g']),
        magnesium100: CsvRowParser.parseDoubleOrNull(row['magnesium_per_100g']),
        calcium100: CsvRowParser.parseDoubleOrNull(row['calcium_per_100g']),
        iron100: CsvRowParser.parseDoubleOrNull(row['iron_per_100g']),
        zinc100: CsvRowParser.parseDoubleOrNull(row['zinc_per_100g']),
        phosphorus100:
            CsvRowParser.parseDoubleOrNull(row['phosphorus_per_100g']),
        vitaminA100: CsvRowParser.parseDoubleOrNull(row['vitamin_a_per_100g']),
        vitaminC100: CsvRowParser.parseDoubleOrNull(row['vitamin_c_per_100g']),
        vitaminD100: CsvRowParser.parseDoubleOrNull(row['vitamin_d_per_100g']),
        vitaminB6100:
            CsvRowParser.parseDoubleOrNull(row['vitamin_b6_per_100g']),
        vitaminB12100:
            CsvRowParser.parseDoubleOrNull(row['vitamin_b12_per_100g']),
        niacin100: CsvRowParser.parseDoubleOrNull(row['niacin_per_100g']),
      );
      final meal = MealDBO(
        code: _nullable(row['meal_code']),
        name: _nullable(row['meal_name']),
        brands: _nullable(row['meal_brands']),
        thumbnailImageUrl: _nullable(row['meal_thumbnail_url']),
        mainImageUrl: _nullable(row['meal_main_image_url']),
        url: _nullable(row['meal_url']),
        mealQuantity: _nullable(row['meal_quantity']),
        mealUnit: _nullable(row['meal_unit']),
        servingQuantity:
            CsvRowParser.parseDoubleOrNull(row['meal_serving_quantity']),
        servingUnit: _nullable(row['meal_serving_unit']),
        servingSize: _nullable(row['meal_serving_size']),
        source: _parseMealSource(row['meal_source']),
        nutriments: nutriments,
      );
      out.add(
        IntakeDBO(
          id: row['id'] ?? '',
          unit: row['unit'] ?? '',
          amount: CsvRowParser.parseDoubleOrNull(row['amount']) ?? 0,
          type: _parseIntakeType(row['type']),
          meal: meal,
          dateTime: DateTime.parse(row['date_time'] ?? ''),
        ),
      );
    }
    return out;
  }

  /// Parse a user_activities CSV back into [UserActivityDBO]s.
  static List<UserActivityDBO> parseUserActivitiesFromCsv(String csv) {
    final rows = _parseRows(csv);
    if (rows.isEmpty) return const [];
    final header = rows.first;
    final out = <UserActivityDBO>[];
    for (var i = 1; i < rows.length; i++) {
      final row = _zip(header, rows[i]);
      final rawTags = row['tags'] ?? '';
      final tags = rawTags.isEmpty
          ? <String>[]
          : rawTags.split('|').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
      final pa = PhysicalActivityDBO(
        row['activity_code'] ?? '',
        row['specific_activity'] ?? '',
        row['description'] ?? '',
        CsvRowParser.parseDoubleOrNull(row['mets']) ?? 0,
        tags,
        _parsePhysicalActivityType(row['type']),
      );
      out.add(
        UserActivityDBO(
          row['id'] ?? '',
          CsvRowParser.parseDoubleOrNull(row['duration']) ?? 0,
          CsvRowParser.parseDoubleOrNull(row['burned_kcal']) ?? 0,
          DateTime.parse(row['date'] ?? ''),
          pa,
        ),
      );
    }
    return out;
  }

  /// Parse a tracked_days CSV back into [TrackedDayDBO]s.
  static List<TrackedDayDBO> parseTrackedDaysFromCsv(String csv) {
    final rows = _parseRows(csv);
    if (rows.isEmpty) return const [];
    final header = rows.first;
    final out = <TrackedDayDBO>[];
    for (var i = 1; i < rows.length; i++) {
      final row = _zip(header, rows[i]);
      out.add(
        TrackedDayDBO(
          day: DateTime.parse(row['day'] ?? ''),
          calorieGoal: CsvRowParser.parseDoubleOrNull(row['calorie_goal']) ?? 0,
          caloriesTracked:
              CsvRowParser.parseDoubleOrNull(row['calories_tracked']) ?? 0,
          carbsGoal: CsvRowParser.parseDoubleOrNull(row['carbs_goal']),
          carbsTracked: CsvRowParser.parseDoubleOrNull(row['carbs_tracked']),
          fatGoal: CsvRowParser.parseDoubleOrNull(row['fat_goal']),
          fatTracked: CsvRowParser.parseDoubleOrNull(row['fat_tracked']),
          proteinGoal: CsvRowParser.parseDoubleOrNull(row['protein_goal']),
          proteinTracked: CsvRowParser.parseDoubleOrNull(row['protein_tracked']),
        ),
      );
    }
    return out;
  }

  // --- Internals -----------------------------------------------------------

  static List<List<String>> _parseRows(String csv) {
    final lines = csv.split(RegExp(r'\r?\n')).where((l) => l.trim().isNotEmpty);
    return lines
        .map((l) => CsvRowParser.splitRow(l).map((c) => c.trim()).toList())
        .toList();
  }

  static Map<String, String> _zip(List<String> header, List<String> row) {
    final map = <String, String>{};
    for (var i = 0; i < header.length && i < row.length; i++) {
      map[header[i].toLowerCase()] = row[i];
    }
    return map;
  }

  /// Quote a cell when it contains a character that would break naive CSV
  /// parsing (`,`, `"`, `\n`, or `\r`). Embedded quotes are escaped by
  /// doubling, matching the convention `CsvRowParser` already understands.
  /// Null values render as an empty cell.
  static String _cell(String? value) {
    if (value == null || value.isEmpty) return '';
    final needsQuoting = value.contains(',') ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r');
    if (!needsQuoting) return value;
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  /// Render a nullable numeric cell. Null and NaN become empty so the
  /// importer can round-trip them back to null via parseDoubleOrNull.
  static String _num(double? value) {
    if (value == null || value.isNaN) return '';
    // Drop trailing `.0` for whole numbers so the CSV is easier to read
    // in a spreadsheet — `1.0` becomes `1` — without losing precision
    // (parseDoubleOrNull happily accepts either form).
    if (value == value.truncateToDouble() && value.abs() < 1e16) {
      return value.toInt().toString();
    }
    return value.toString();
  }

  static String? _nullable(String? cell) {
    if (cell == null) return null;
    if (cell.isEmpty) return null;
    return cell;
  }

  static IntakeTypeDBO _parseIntakeType(String? raw) {
    final name = (raw ?? '').toLowerCase().trim();
    for (final t in IntakeTypeDBO.values) {
      if (t.name == name) return t;
    }
    return IntakeTypeDBO.snack;
  }

  static MealSourceDBO _parseMealSource(String? raw) {
    final name = (raw ?? '').toLowerCase().trim();
    for (final s in MealSourceDBO.values) {
      if (s.name == name) return s;
    }
    return MealSourceDBO.unknown;
  }

  static PhysicalActivityTypeDBO _parsePhysicalActivityType(String? raw) {
    final name = (raw ?? '').toLowerCase().trim();
    for (final t in PhysicalActivityTypeDBO.values) {
      if (t.name == name) return t;
    }
    return PhysicalActivityTypeDBO.sport;
  }
}
