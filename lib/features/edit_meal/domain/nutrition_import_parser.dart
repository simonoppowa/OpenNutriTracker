import 'dart:convert';

import 'package:opennutritracker/core/utils/food_name_validator.dart';

/// Values are in the units printed on the label. Only [toPer100] scales them.
enum NutritionBasis { per100g, per100ml, serving, portion, package, unknown }

const nutritionFields = <String>[
  'name',
  'brand',
  'kcal',
  'kj',
  'protein',
  'carbs',
  'sugars',
  'fat',
  'saturatedFat',
  'fiber',
  'salt',
  'sodium',
  'calcium',
  'iron',
  'potassium',
  'magnesium',
  'vitaminD',
  'vitaminB12',
  'servingSize',
  'servingUnit',
];

class NutritionEntry {
  String name;
  String brand;
  NutritionBasis basis;
  double? servingSize;
  String? servingUnit;
  final Map<String, double?> values;
  final List<String> issues;

  NutritionEntry({
    this.name = '',
    this.brand = '',
    this.basis = NutritionBasis.unknown,
    this.servingSize,
    this.servingUnit,
    Map<String, double?>? values,
    List<String>? issues,
  }) : values = values ?? {},
       issues = issues ?? [];

  bool get hasNutrients => values.values.any((v) => v != null);

  /// Sodium is stored as milligrams. Salt is not stored separately by the app.
  Map<String, double?> toPer100() {
    if (basis == NutritionBasis.unknown) {
      throw const FormatException('Select a nutrition basis before importing.');
    }
    if (servingSize != null &&
        ((basis == NutritionBasis.per100g && servingUnit == 'ml') ||
            (basis == NutritionBasis.per100ml && servingUnit == 'g'))) {
      throw const FormatException(
        'Serving unit differs from the per-100 unit. Clear the serving size or supply an explicit conversion.',
      );
    }
    final quantity = switch (basis) {
      NutritionBasis.per100g || NutritionBasis.per100ml => 100.0,
      _ => servingSize,
    };
    if (quantity == null ||
        quantity <= 0 ||
        (basis != NutritionBasis.per100g &&
            basis != NutritionBasis.per100ml &&
            servingUnit != 'g' &&
            servingUnit != 'ml')) {
      throw const FormatException('A serving size in g or ml is required.');
    }
    final factor = 100 / quantity;
    final result = <String, double?>{};
    for (final field in values.keys) {
      final value = values[field];
      if (value != null) result[field] = value * factor;
    }
    if (result['kcal'] == null && result['kj'] != null) {
      result['kcal'] = result['kj']! / 4.184;
    }
    if (result['sodium'] == null && result['salt'] != null) {
      result['sodium'] = result['salt']! * 400;
    }
    return result;
  }
}

class NutritionFileResult {
  final List<NutritionEntry> entries;
  final List<String> errors;
  final List<String> headings;
  final Map<int, String> mapping;
  final List<List<String>> rows;
  NutritionFileResult(
    this.entries,
    this.errors, {
    this.headings = const [],
    this.mapping = const {},
    this.rows = const [],
  });
}

class NutritionBatchSelection {
  final List<NutritionEntry> entries;
  final int duplicates;
  final int invalid;
  const NutritionBatchSelection(this.entries, this.duplicates, this.invalid);
}

/// Keeps existing library entries intact and skips repeat names within a file.
NutritionBatchSelection selectNutritionBatch(
  List<NutritionEntry> entries,
  Iterable<String> existingNames,
) {
  final known = existingNames.map((name) => name.trim().toLowerCase()).toSet();
  final selected = <NutritionEntry>[];
  var duplicates = 0;
  var invalid = 0;
  for (final entry in entries) {
    final key = entry.name.trim().toLowerCase();
    if (!FoodNameValidator.isValid(entry.name) || !entry.hasNutrients) {
      invalid++;
      continue;
    }
    if (known.contains(key)) {
      duplicates++;
      continue;
    }
    try {
      entry.toPer100();
    } on FormatException {
      invalid++;
      continue;
    }
    known.add(key);
    selected.add(entry);
  }
  return NutritionBatchSelection(selected, duplicates, invalid);
}

class NutritionImportParser {
  static final _number = RegExp(r'(?<!\d)(-?\d+(?:[.,]\d+)?)(?!\d)');
  static final _nutrient = RegExp(
    r'(?<![a-z])(?:of\s+which\s+)?(?:energy|calories?|calcium|iron|potassium|magnesium|vitamin\s*d|vitamin\s*b12|total\s+carbohydrates?|carbohydrates?|carbs?|total\s+fat|fat|saturated\s+fat(?:ty\s+acids?)?|saturates?|total\s+sugars?|sugars?|dietary\s+fib(?:er|re)|fib(?:er|re)|proteins?|salt|sodium)\b',
    caseSensitive: false,
  );
  static final _unit = RegExp(
    r'^(kcal|kj|mg|g|ml|µg|μg|ug|mcg)\b',
    caseSensitive: false,
  );
  static final _serving = RegExp(
    r'(?:serving\s*size|portion\s*size|package\s*size|per\s+(?:serving|portion|package))\s*[:(]?\s*(\d+(?:[.,]\d+)?)\s*(g|ml)\b',
    caseSensitive: false,
  );
  static final _per100 = RegExp(
    r'\b(?:per|/|\b)\s*100\s*(g|ml)\b',
    caseSensitive: false,
  );

  static String? _selectedTableCell(
    List<String> lines,
    int lineIndex,
    List<String> cells,
    NutritionBasis basis,
    String label,
    List<String> issues,
  ) {
    List<String>? headings;
    for (var i = lineIndex - 1; i >= 0; i--) {
      final candidate = lines[i]
          .split('\t')
          .map((cell) => cell.trim())
          .toList();
      if (candidate.length > 1 &&
          candidate
              .skip(1)
              .any((cell) => _basis(cell) != NutritionBasis.unknown)) {
        headings = candidate;
        break;
      }
    }
    if (headings == null) {
      if (cells.length == 2) return cells[1];
      issues.add('Ambiguous columns for $label.');
      return null;
    }
    final matchingColumns = [
      for (var i = 1; i < headings.length; i++)
        if (_basis(headings[i]) == basis) i,
    ];
    if (matchingColumns.length != 1) {
      issues.add('Ambiguous columns for $label.');
      return null;
    }
    final column = matchingColumns.single;
    if (column >= cells.length) {
      issues.add('Cannot locate the selected column for $label.');
      return null;
    }
    return cells[column];
  }

  static double? parseNumber(String text) {
    final match = _number.firstMatch(text);
    if (match == null) return null;
    final parsed = double.tryParse(match[1]!.replaceAll(',', '.'));
    return parsed != null && parsed >= 0 ? parsed : null;
  }

  /// Parses several labels pasted together. A blank line separates foods;
  /// a single label still follows the normal table-aware parser path.
  static NutritionFileResult parseTextEntries(String text) {
    final blocks = text
        .trim()
        .split(RegExp(r'\r?\n\s*\r?\n+'))
        .map((block) => block.trim())
        .where((block) => block.isNotEmpty)
        .toList();
    if (blocks.length <= 1) {
      final entry = parseText(text);
      return NutritionFileResult(
        entry.hasNutrients ? [entry] : const [],
        entry.hasNutrients ? const [] : entry.issues,
      );
    }
    final entries = <NutritionEntry>[];
    final errors = <String>[];
    for (var i = 0; i < blocks.length; i++) {
      final entry = parseText(blocks[i]);
      if (entry.hasNutrients) {
        entries.add(entry);
      } else {
        errors.add('Item ${i + 1}: no nutritional values were recognised.');
      }
    }
    return NutritionFileResult(entries, errors);
  }

  static (String, double)? parseNutrientCell(String field, String raw) {
    final match = _number.firstMatch(raw);
    if (match == null) return null;
    final value = double.tryParse(match[1]!.replaceAll(',', '.'));
    if (value == null || !value.isFinite || value < 0) return null;
    final suffix = raw.substring(match.end).trimLeft();
    final unit = RegExp(
      r'^[a-zA-Zµ%]+',
    ).firstMatch(suffix)?.group(0)?.toLowerCase();
    if (unit == '%') return null;
    if (field == 'kcal' || field == 'kj') {
      if (unit == null) return (field, value);
      if (unit == 'kcal' || unit == 'kj') return (unit, value);
      return null;
    }
    if (field == 'sodium' ||
        field == 'calcium' ||
        field == 'iron' ||
        field == 'potassium' ||
        field == 'magnesium') {
      if (unit == 'g') return (field, value * 1000);
      if (unit == 'µg' || unit == 'μg' || unit == 'ug' || unit == 'mcg') {
        return (field, value / 1000);
      }
      if (unit == null || unit == 'mg') return (field, value);
      return null;
    }
    if (field == 'vitaminD' || field == 'vitaminB12') {
      if (unit == 'g') return (field, value * 1000000);
      if (unit == 'mg') return (field, value * 1000);
      if (unit == null ||
          unit == 'µg' ||
          unit == 'μg' ||
          unit == 'ug' ||
          unit == 'mcg') {
        return (field, value);
      }
      return null;
    }
    if (unit != null && unit != 'g') return null;
    return (field, value);
  }

  static String? fieldFor(String heading) {
    final s = heading.toLowerCase().replaceAll(RegExp(r'[_-]+'), ' ').trim();
    if (RegExp(r'%|\bdaily\s+value\b|\bdv\b').hasMatch(s)) return null;
    if (RegExp(r'\b(brand|manufacturer)\b').hasMatch(s)) return 'brand';
    if (RegExp(r'\b(serving|portion|package)\s*unit\b').hasMatch(s)) {
      return 'servingUnit';
    }
    if (RegExp(r'\b(name|food|product|description)\b').hasMatch(s) &&
        !_nutrient.hasMatch(s)) {
      return 'name';
    }
    if (RegExp(
          r'\b(serving|portion|package)\s*(size|quantity|amount)?\b',
        ).hasMatch(s) &&
        !_nutrient.hasMatch(s)) {
      return 'servingSize';
    }
    if (RegExp(r'\b(saturat|saturates)\w*\b').hasMatch(s)) {
      return 'saturatedFat';
    }
    if (RegExp(r'\b(sugar|sugars)\b').hasMatch(s)) return 'sugars';
    if (RegExp(r'\bcalcium\b').hasMatch(s)) return 'calcium';
    if (RegExp(r'\biron\b').hasMatch(s)) return 'iron';
    if (RegExp(r'\bpotassium\b').hasMatch(s)) return 'potassium';
    if (RegExp(r'\bmagnesium\b').hasMatch(s)) return 'magnesium';
    if (RegExp(r'\bvitamin\s*d\b').hasMatch(s)) return 'vitaminD';
    if (RegExp(r'\bvitamin\s*b12\b').hasMatch(s)) return 'vitaminB12';
    if (RegExp(r'\b(sodium)\b').hasMatch(s)) return 'sodium';
    if (RegExp(r'\b(salt)\b').hasMatch(s)) return 'salt';
    if (RegExp(r'\b(fibre|fiber)\b').hasMatch(s)) return 'fiber';
    if (RegExp(r'\b(protein|proteins)\b').hasMatch(s)) return 'protein';
    if (RegExp(r'\b(carbs?|carbohydrates?)\b').hasMatch(s)) return 'carbs';
    if (RegExp(r'\b(fat|lipids?)\b').hasMatch(s)) return 'fat';
    if (RegExp(r'\b(kilojoules?|kj)\b').hasMatch(s)) return 'kj';
    if (RegExp(r'\b(calories?|kcal|kilocalories?)\b').hasMatch(s)) {
      return 'kcal';
    }
    if (RegExp(r'\benergy\b').hasMatch(s)) {
      if (s.contains('kj')) return 'kj';
      return 'kcal';
    }
    return null;
  }

  static NutritionBasis _basis(String text) {
    final normalized = text.replaceAll('_', ' ').replaceAll('-', ' ');
    final hundred = _per100.firstMatch(normalized);
    if (hundred != null) {
      return hundred[1]!.toLowerCase() == 'ml'
          ? NutritionBasis.per100ml
          : NutritionBasis.per100g;
    }
    if (RegExp(
      r'\bper\s+serving\b',
      caseSensitive: false,
    ).hasMatch(normalized)) {
      return NutritionBasis.serving;
    }
    if (RegExp(
      r'\bper\s+portion\b',
      caseSensitive: false,
    ).hasMatch(normalized)) {
      return NutritionBasis.portion;
    }
    if (RegExp(
      r'\bper\s+package\b',
      caseSensitive: false,
    ).hasMatch(normalized)) {
      return NutritionBasis.package;
    }
    return NutritionBasis.unknown;
  }

  static NutritionEntry parseText(
    String text, {
    NutritionBasis? selectedBasis,
  }) {
    final entry = NutritionEntry();
    final lines = text
        .replaceAll('\r', '')
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .toList();
    final serving = _serving.firstMatch(text);
    if (serving != null) {
      entry.servingSize = parseNumber(serving[1]!);
      entry.servingUnit = serving[2]!.toLowerCase();
    } else {
      final labeledMetricSize = RegExp(
        r'^(?:serving|portion|package)\s*size\s*[:\t]\s*[^\r\n]*?(\d+(?:[.,]\d+)?)\s*(g|ml)\b',
        caseSensitive: false,
        multiLine: true,
      ).firstMatch(text);
      if (labeledMetricSize != null) {
        entry.servingSize = parseNumber(labeledMetricSize[1]!);
        entry.servingUnit = labeledMetricSize[2]!.toLowerCase();
      }
      final size = RegExp(
        r'^(?:serving|portion|package)\s*size\s*[:\t]\s*(\d+(?:[.,]\d+)?)\s*$',
        caseSensitive: false,
        multiLine: true,
      ).firstMatch(text);
      if (size != null && entry.servingSize == null) {
        entry.servingSize = parseNumber(size[1]!);
      }
    }
    final explicitUnit = RegExp(
      r'^(?:serving|portion|package)\s*unit\s*[:\t]\s*(g|ml)\s*$',
      caseSensitive: false,
      multiLine: true,
    ).firstMatch(text);
    if (explicitUnit != null) {
      entry.servingUnit = explicitUnit[1]!.toLowerCase();
    }
    final basisHints = <NutritionBasis>[];
    for (final line in lines) {
      for (final cell in line.split('\t')) {
        final b = _basis(cell);
        if (b != NutritionBasis.unknown && !basisHints.contains(b)) {
          basisHints.add(b);
        }
      }
    }
    final preferred =
        selectedBasis ??
        (basisHints.contains(NutritionBasis.per100g)
            ? NutritionBasis.per100g
            : basisHints.contains(NutritionBasis.per100ml)
            ? NutritionBasis.per100ml
            : basisHints.length == 1
            ? basisHints.first
            : NutritionBasis.unknown);
    entry.basis = preferred;
    if (selectedBasis != null &&
        basisHints.length == 1 &&
        selectedBasis != basisHints.first) {
      entry.issues.add('No values in the selected nutrition column.');
      return entry;
    }
    if (basisHints.length > 1 && preferred == NutritionBasis.unknown) {
      entry.issues.add('Choose a nutrition column before importing.');
    }
    if (preferred == NutritionBasis.unknown) {
      entry.issues.add(
        'Choose whether values are per 100 g, per 100 ml or per serving.',
      );
    }
    var activeBasis = NutritionBasis.unknown;
    for (var lineIndex = 0; lineIndex < lines.length; lineIndex++) {
      final line = lines[lineIndex];
      final lineBasis = _basis(line);
      if (!line.contains('\t') && lineBasis != NutritionBasis.unknown) {
        activeBasis = lineBasis;
      }
      final trimmed = line.trim();
      final brand = RegExp(
        r'^brand\s*[:\t]\s*(.+)$',
        caseSensitive: false,
      ).firstMatch(trimmed);
      if (brand != null) {
        entry.brand = brand[1]!.trim();
        continue;
      }
      final name = RegExp(
        r'^(?:food|product|name)\s*[:\t]\s*(.+)$',
        caseSensitive: false,
      ).firstMatch(trimmed);
      if (name != null) {
        entry.name = name[1]!.trim();
        continue;
      }
      final cells = line.split('\t').map((cell) => cell.trim()).toList();
      final matches = _nutrient.allMatches(cells.first).toList();
      if (!line.contains('\t') &&
          activeBasis != NutritionBasis.unknown &&
          activeBasis != preferred) {
        continue;
      }
      if (matches.isEmpty) {
        if (entry.name.isEmpty &&
            _basis(trimmed) == NutritionBasis.unknown &&
            !RegExp(
              r'\b(serving|portion|nutrition|amount|daily value|%dv)\b',
              caseSensitive: false,
            ).hasMatch(trimmed) &&
            !RegExp(r'^\d').hasMatch(trimmed)) {
          entry.name = trimmed;
        }
        continue;
      }
      // A copied table may have a heading row followed by nutrient rows.
      final selectedCell = cells.length > 1 && matches.isNotEmpty
          ? _selectedTableCell(
              lines,
              lineIndex,
              cells,
              preferred,
              matches.first.group(0)!,
              entry.issues,
            )
          : null;
      if (cells.length > 1 && selectedCell == null) continue;
      for (var i = 0; i < matches.length; i++) {
        final match = matches[i];
        final label = match.group(0)!;
        var field = fieldFor(label);
        final tail = cells.length > 1
            ? selectedCell!
            : line.substring(
                match.end,
                i + 1 < matches.length ? matches[i + 1].start : line.length,
              );
        if (field == 'kcal' &&
            RegExp(
              r'^\s*[:;]?\s*\d+(?:[.,]\d+)?\s*kj\b',
              caseSensitive: false,
            ).hasMatch(tail)) {
          field = 'kj';
        }
        final candidates = _number
            .allMatches(tail)
            .where(
              (number) =>
                  !RegExp(r'^\s*%').hasMatch(tail.substring(number.end)),
            )
            .toList();
        if (candidates.isEmpty || field == null) continue;
        if (candidates.length > 1 && (field == 'kcal' || field == 'kj')) {
          final energyValues = RegExp(
            r'(-?\d+(?:[.,]\d+)?)\s*(kcal|kj)\b',
            caseSensitive: false,
          ).allMatches(tail).toList();
          if (energyValues.length == 2 &&
              candidates.length == 2 &&
              energyValues[0][2]!.toLowerCase() !=
                  energyValues[1][2]!.toLowerCase()) {
            final values = [
              for (final energy in energyValues)
                double.tryParse(energy[1]!.replaceAll(',', '.')),
            ];
            if (values.any(
              (value) => value == null || !value.isFinite || value < 0,
            )) {
              entry.issues.add('Invalid value for $label.');
              continue;
            }
            for (
              var energyIndex = 0;
              energyIndex < energyValues.length;
              energyIndex++
            ) {
              entry.values[energyValues[energyIndex][2]!.toLowerCase()] =
                  values[energyIndex];
            }
            continue;
          }
        }
        if (candidates.length > 1) {
          entry.issues.add(
            'Ambiguous values for $label; enter the correct value in the preview.',
          );
          continue;
        }
        final candidate = candidates.single;
        final value = double.tryParse(candidate[1]!.replaceAll(',', '.'));
        if (value == null || !value.isFinite || value < 0) {
          entry.issues.add('Invalid value for $label.');
          continue;
        }
        final after = tail.substring(candidate.end).trimLeft();
        final unit = _unit.firstMatch(after)?.group(1)?.toLowerCase();
        if (unit == null && RegExp(r'^[a-zA-Zµ]+').hasMatch(after)) {
          entry.issues.add(
            'Unsupported unit for $label: ${RegExp(r'^[a-zA-Zµ]+').firstMatch(after)!.group(0)}.',
          );
          continue;
        }
        if (field == 'kcal' && unit == 'kj') field = 'kj';
        if (field == 'kj' && unit == 'kcal') field = 'kcal';
        if (field == 'sodium' ||
            field == 'calcium' ||
            field == 'iron' ||
            field == 'potassium' ||
            field == 'magnesium' ||
            field == 'vitaminD' ||
            field == 'vitaminB12') {
          final nutrient = parseNutrientCell(field, '$value ${unit ?? ''}');
          if (nutrient == null) {
            entry.issues.add('Unsupported unit for $label: $unit.');
          } else {
            entry.values[nutrient.$1] = nutrient.$2;
          }
        } else if (field == 'salt' || (field != 'kcal' && field != 'kj')) {
          if (unit != null && unit != 'g') {
            entry.issues.add('Unsupported unit for $label: $unit.');
          } else {
            entry.values[field] = value;
          }
        } else {
          entry.values[field] = value;
        }
      }
    }
    if (!entry.hasNutrients) {
      entry.issues.add('No nutritional values recognised.');
    }
    return entry;
  }

  static NutritionFileResult parseCsv(
    String text, {
    Map<int, String>? manualMapping,
    NutritionBasis? selectedBasis,
  }) {
    if (text.trim().isEmpty) {
      return NutritionFileResult([], ['The file is empty.']);
    }
    final delimiter = [',', ';', '\t'].reduce(
      (a, b) =>
          _csvRecords(text, a).first.length >= _csvRecords(text, b).first.length
          ? a
          : b,
    );
    final records = _csvRecords(text, delimiter);
    if (records.isEmpty) return NutritionFileResult([], ['The file is empty.']);
    final headings = records.first;
    final mapping = <int, String>{};
    for (var i = 0; i < headings.length; i++) {
      final field = manualMapping == null
          ? fieldFor(headings[i])
          : manualMapping[i];
      if (field != null) mapping[i] = field;
    }
    final errors = <String>[];
    if (!mapping.containsValue('name')) errors.add('Map a food name column.');
    if (!mapping.values.any(
      (f) => nutritionFields
          .skip(2)
          .takeWhile((field) => field != 'servingSize')
          .contains(f),
    )) {
      errors.add('Map at least one nutrient column.');
    }
    final entries = <NutritionEntry>[];
    for (var row = 1; row < records.length; row++) {
      final cells = records[row];
      final entry = NutritionEntry();
      final mappedBases = mapping.keys.map((i) => _basis(headings[i])).toSet();
      entry.basis =
          selectedBasis ??
          (mappedBases.contains(NutritionBasis.per100g)
              ? NutritionBasis.per100g
              : mappedBases.contains(NutritionBasis.per100ml)
              ? NutritionBasis.per100ml
              : mappedBases.contains(NutritionBasis.serving)
              ? NutritionBasis.serving
              : mappedBases.contains(NutritionBasis.portion)
              ? NutritionBasis.portion
              : mappedBases.contains(NutritionBasis.package)
              ? NutritionBasis.package
              : NutritionBasis.unknown);
      var badRow = false;
      for (final item in mapping.entries) {
        final columnBasis = _basis(headings[item.key]);
        if (columnBasis != NutritionBasis.unknown &&
            columnBasis != entry.basis) {
          continue;
        }
        if (item.key >= cells.length) continue;
        final raw = cells[item.key].trim();
        if (raw.isEmpty) continue;
        if (item.value == 'name') {
          entry.name = raw;
          continue;
        }
        if (item.value == 'brand') {
          entry.brand = raw;
          continue;
        }
        if (item.value == 'servingUnit') {
          entry.servingUnit =
              raw.toLowerCase() == 'g' || raw.toLowerCase() == 'ml'
              ? raw.toLowerCase()
              : null;
          continue;
        }
        if (item.value == 'servingSize') {
          entry.servingSize = parseNumber(raw);
          final detectedUnit =
              RegExp(r'\bml\b', caseSensitive: false).hasMatch(raw)
              ? 'ml'
              : RegExp(r'\bg\b', caseSensitive: false).hasMatch(raw)
              ? 'g'
              : null;
          entry.servingUnit = detectedUnit ?? entry.servingUnit;
          continue;
        }
        final nutrient = parseNutrientCell(item.value, raw);
        if (nutrient == null) {
          errors.add('Row ${row + 1}: invalid ${item.value}.');
          badRow = true;
          continue;
        }
        entry.values[nutrient.$1] = nutrient.$2;
      }
      if (entry.basis == NutritionBasis.unknown) {
        entry.basis = headings.any((h) => _basis(h) == NutritionBasis.per100ml)
            ? NutritionBasis.per100ml
            : headings.any((h) => _basis(h) == NutritionBasis.per100g)
            ? NutritionBasis.per100g
            : NutritionBasis.unknown;
      }
      if (badRow ||
          !FoodNameValidator.isValid(entry.name) ||
          !entry.hasNutrients) {
        errors.add(
          'Row ${row + 1}: a name and at least one nutrient are required.',
        );
      } else {
        entries.add(entry);
      }
    }
    return NutritionFileResult(
      entries,
      errors,
      headings: headings,
      mapping: mapping,
      rows: records,
    );
  }

  static List<List<String>> _csvRecords(String text, String delimiter) {
    final rows = <List<String>>[];
    var row = <String>[];
    var cell = StringBuffer();
    var quoted = false;
    for (var i = 0; i < text.length; i++) {
      final c = text[i];
      if (c == '"') {
        if (quoted && i + 1 < text.length && text[i + 1] == '"') {
          cell.write('"');
          i++;
        } else {
          quoted = !quoted;
        }
      } else if (!quoted && (c == delimiter || c == '\n' || c == '\r')) {
        row.add(cell.toString());
        cell = StringBuffer();
        if (c != delimiter) {
          if (row.any((x) => x.trim().isNotEmpty)) rows.add(row);
          row = [];
          if (c == '\r' && i + 1 < text.length && text[i + 1] == '\n') i++;
        }
      } else {
        cell.write(c);
      }
    }
    row.add(cell.toString());
    if (row.any((x) => x.trim().isNotEmpty)) rows.add(row);
    return rows;
  }

  static NutritionFileResult parseJson(
    String text, {
    NutritionBasis? selectedBasis,
    Map<int, String>? manualMapping,
  }) {
    dynamic decoded;
    try {
      decoded = jsonDecode(text);
    } catch (_) {
      return NutritionFileResult([], ['Invalid JSON.']);
    }
    final list = decoded is List
        ? decoded
        : decoded is Map && decoded['foods'] is List
        ? decoded['foods']
        : [decoded];
    final headings = <String>[];
    for (final value in list) {
      if (value is Map) {
        for (final key in value.keys) {
          if (key is String && !headings.contains(key)) headings.add(key);
        }
      }
    }
    final mapping = <int, String>{};
    for (var i = 0; i < headings.length; i++) {
      final field = manualMapping == null
          ? fieldFor(headings[i])
          : manualMapping[i];
      if (field != null) mapping[i] = field;
    }
    final entries = <NutritionEntry>[];
    final errors = <String>[];
    for (var i = 0; i < list.length; i++) {
      if (list[i] is! Map) {
        errors.add('Entry ${i + 1}: expected an object.');
        continue;
      }
      final object = Map<String, dynamic>.from(list[i] as Map);
      final entry = NutritionEntry();
      final keyedBases = object.keys.map(_basis).toSet();
      entry.basis =
          selectedBasis ??
          (keyedBases.contains(NutritionBasis.per100g)
              ? NutritionBasis.per100g
              : keyedBases.contains(NutritionBasis.per100ml)
              ? NutritionBasis.per100ml
              : keyedBases.contains(NutritionBasis.serving)
              ? NutritionBasis.serving
              : keyedBases.contains(NutritionBasis.portion)
              ? NutritionBasis.portion
              : keyedBases.contains(NutritionBasis.package)
              ? NutritionBasis.package
              : NutritionBasis.unknown);
      var badEntry = false;
      for (final item in object.entries) {
        if (item.key.toLowerCase() == 'basis') {
          if (entry.basis == NutritionBasis.unknown) {
            entry.basis = _basis(item.value.toString());
          }
          continue;
        }
        final columnBasis = _basis(item.key);
        if (columnBasis != NutritionBasis.unknown &&
            columnBasis != entry.basis) {
          continue;
        }
        final field = mapping[headings.indexOf(item.key)];
        if (field == null || item.value == null) continue;
        final value = item.value.toString();
        if (field == 'name') {
          entry.name = value;
        } else if (field == 'brand') {
          entry.brand = value;
        } else if (field == 'servingUnit') {
          entry.servingUnit =
              value.toLowerCase() == 'g' || value.toLowerCase() == 'ml'
              ? value.toLowerCase()
              : null;
        } else if (field == 'servingSize') {
          entry.servingSize = parseNumber(value);
          final detectedUnit =
              RegExp(r'\bml\b', caseSensitive: false).hasMatch(value)
              ? 'ml'
              : RegExp(r'\bg\b', caseSensitive: false).hasMatch(value)
              ? 'g'
              : null;
          entry.servingUnit = detectedUnit ?? entry.servingUnit;
        } else {
          final nutrient = parseNutrientCell(field, value);
          if (nutrient == null) {
            errors.add('Entry ${i + 1}: invalid $field.');
            badEntry = true;
          } else {
            entry.values[nutrient.$1] = nutrient.$2;
          }
        }
      }
      if (badEntry ||
          !FoodNameValidator.isValid(entry.name) ||
          !entry.hasNutrients) {
        errors.add(
          'Entry ${i + 1}: a name and at least one nutrient are required.',
        );
      } else {
        entries.add(entry);
      }
    }
    return NutritionFileResult(
      entries,
      errors,
      headings: headings,
      mapping: mapping,
    );
  }
}
