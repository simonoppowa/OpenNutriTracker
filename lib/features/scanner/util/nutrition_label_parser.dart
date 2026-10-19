import 'package:opennutritracker/features/add_meal/domain/entity/energy_plausibility.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';

/// One piece of recognized text, as the iOS text recognizer hands it over:
/// normalized coordinates with the origin at the top left (see
/// `docs/nutrition-label-ocr.md`).
class OcrLine {
  final String text;
  final double x;
  final double y;
  final double width;
  final double height;
  final double confidence;

  const OcrLine({
    required this.text,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.confidence = 1,
  });

  double get centerY => y + height / 2;
}

/// What [parseNutritionLabel] read off a label, per 100 g (or 100 ml).
class NutritionLabelValues {
  static const fields = [
    'energyKcal',
    'fat',
    'saturatedFat',
    'carbohydrates',
    'sugars',
    'fiber',
    'protein',
    'salt',
  ];

  final Map<String, double> _values;

  /// `g` or `ml`: what the "per 100" column refers to.
  final String basis;

  /// Fields the user should look at before saving: corrected recognition
  /// errors, weakly recognized text, values that contradict each other.
  final Set<String> uncertain;

  /// Fields given as "< x" or "Spuren", read as 0.
  final Set<String> belowThreshold;

  const NutritionLabelValues._(
    this._values,
    this.basis,
    this.uncertain,
    this.belowThreshold,
  );

  double? valueOf(String field) => _values[field];
  double? get energyKcal => _values['energyKcal'];
  double? get fat => _values['fat'];
  double? get saturatedFat => _values['saturatedFat'];
  double? get carbohydrates => _values['carbohydrates'];
  double? get sugars => _values['sugars'];
  double? get fiber => _values['fiber'];
  double? get protein => _values['protein'];
  double? get salt => _values['salt'];

  /// Sodium in mg from the salt (salt = sodium × 2.5).
  double? get sodiumMg => salt == null ? null : salt! / 2.5 * 1000;

  bool get isEmpty => _values.isEmpty;
}

const _minConfidence = 0.5;
const _kjPerKcal = 4.184;

/// Field keywords, checked in order: "davon gesättigte Fettsäuren" has to
/// win over "Fett", "davon Zucker" over "Kohlenhydrate".
const _keywords = <(String, List<String>)>[
  ('saturatedFat', ['gesattigt', 'saturat']),
  ('sugars', ['zucker', 'sugar']),
  ('fiber', ['ballaststoff', 'fibre', 'fiber']),
  ('carbohydrates', ['kohlenhydrat', 'carbohydrate']),
  ('protein', ['eiweis', 'protein']),
  ('salt', ['salz', 'salt']),
  ('energyKcal', ['brennwert', 'energie', 'energy']),
  ('fat', ['fett', 'fat']),
];

final _number = RegExp(r'\d+(?:[.,]\d+)?');
final _kj = RegExp(r'(\d+(?:[.,]\d+)?)\s*kj', caseSensitive: false);
final _kcal = RegExp(r'(\d+(?:[.,]\d+)?)\s*kcal', caseSensitive: false);
final _belowThreshold = RegExp(r'^\s*<|spuren|trace', caseSensitive: false);

/// Reads the per-100 g values off the recognized lines of a German (or
/// English) nutrition table: energy (kJ and/or kcal), fat, saturated fat,
/// carbohydrate, sugars, fibre, protein and salt.
///
/// Lines are grouped into table rows by their height on the image; a row's
/// leftmost text names the field, the value comes from the column under the
/// "100 g"/"100 ml" header when there is one (a "pro Portion" column is
/// ignored), else from the first value of the row. Decimal commas, kJ and
/// kcal on one or two lines, "davon" rows, "< 0,5 g" and "Spuren" are
/// understood; recognition errors inside numbers (`O` for `0`, `l`/`I` for
/// `1`) are corrected and marked uncertain, as are weakly recognized lines
/// and values that contradict each other ([checkEnergyPlausibility]).
NutritionLabelValues parseNutritionLabel(List<OcrLine> lines) {
  final rows = _rows(lines);
  final header = _per100Header(lines);
  final values = <String, double>{};
  final uncertain = <String>{};
  final below = <String>{};
  String? lastField;

  for (final row in rows) {
    final label = _normalize(row.first.text);
    var field = _fieldOf(label);
    if (field == null && lastField == 'energyKcal' && _kcal.hasMatch(label)) {
      field = 'energyKcal';
    }
    if (field == null) continue;
    final cells = _valueCells(row, header?.x);
    for (final cell in cells) {
      final reading = _read(cell, field);
      if (reading == null) continue;
      if (field == 'energyKcal') {
        if (reading.kcal != null) {
          values['energyKcal'] = reading.kcal!;
        } else if (reading.kj != null && !values.containsKey('energyKcal')) {
          values['energyKcal'] = reading.kj! / _kjPerKcal;
        }
      } else if (!values.containsKey(field)) {
        values[field] = reading.value!;
      } else {
        continue;
      }
      if (reading.corrected || cell.confidence < _minConfidence) {
        uncertain.add(field);
      }
      if (reading.belowThreshold) below.add(field);
      break;
    }
    lastField = field;
  }

  _checkConsistency(values, uncertain);
  return NutritionLabelValues._(
    values,
    header?.basis ?? _basisFromText(lines),
    uncertain,
    below,
  );
}

void _checkConsistency(Map<String, double> values, Set<String> uncertain) {
  final issue = checkEnergyPlausibility(
    MealNutrimentsEntity(
      energyKcal100: values['energyKcal'],
      carbohydrates100: values['carbohydrates'],
      fat100: values['fat'],
      proteins100: values['protein'],
      sugars100: values['sugars'],
      saturatedFat100: values['saturatedFat'],
      fiber100: values['fiber'],
    ),
  );
  switch (issue?.rule) {
    case null:
      return;
    case 'energy_mismatch':
      uncertain.add('energyKcal');
    case 'sugars_exceed_carbs':
      uncertain.addAll(['sugars', 'carbohydrates']);
    case 'saturated_fat_exceeds_total_fat':
      uncertain.addAll(['saturatedFat', 'fat']);
    default:
      uncertain.addAll(['fat', 'carbohydrates', 'protein']);
  }
}

/// The value texts of a table row, the one closest to the per-100 header
/// first: the rest of the first line when it carries a value ("Fett 0,5 g",
/// or a kcal line continuing the energy row) and the row's other cells.
List<({String text, double confidence})> _valueCells(
  List<OcrLine> row,
  double? headerX,
) {
  final label = row.first;
  final inline = _afterLabel(label.text);
  final cells = [
    if (inline != null)
      (text: inline, confidence: label.confidence, x: label.x),
    for (final cell in row.skip(1))
      (text: cell.text, confidence: cell.confidence, x: cell.x),
  ];
  if (headerX != null) {
    cells.sort(
      (a, b) => (a.x - headerX).abs().compareTo((b.x - headerX).abs()),
    );
  }
  return [
    for (final cell in cells) (text: cell.text, confidence: cell.confidence),
  ];
}

/// The part of a single-line row after its field name, when it holds a
/// value: "Fett < 0,5 g" → "< 0,5 g".
String? _afterLabel(String text) {
  final match = RegExp(
    r'[<\d]|spuren',
    caseSensitive: false,
  ).firstMatch(_fixDigits(text).text);
  return match == null ? null : text.substring(match.start);
}

({
  double? value,
  double? kj,
  double? kcal,
  bool corrected,
  bool belowThreshold,
})?
_read(({String text, double confidence}) cell, String field) {
  final fixed = _fixDigits(cell.text);
  final text = fixed.text;
  if (field == 'energyKcal') {
    final kj = _kj.firstMatch(text);
    final kcal = _kcal.firstMatch(text);
    if (kj == null && kcal == null) return null;
    return (
      value: null,
      kj: kj == null ? null : _toDouble(kj.group(1)!),
      kcal: kcal == null ? null : _toDouble(kcal.group(1)!),
      corrected: fixed.corrected,
      belowThreshold: false,
    );
  }
  if (_belowThreshold.hasMatch(text)) {
    return (
      value: 0,
      kj: null,
      kcal: null,
      corrected: fixed.corrected,
      belowThreshold: true,
    );
  }
  final number = _number.firstMatch(text);
  if (number == null) return null;
  return (
    value: _toDouble(number.group(0)!),
    kj: null,
    kcal: null,
    corrected: fixed.corrected,
    belowThreshold: false,
  );
}

/// Replaces letters the recognizer mistakes for digits where they sit in a
/// number: "1O29" → "1029", "O,6" → "0,6", "l5" → "15".
({String text, bool corrected}) _fixDigits(String text) {
  final fixed = text.replaceAllMapped(
    RegExp(r'(?<=[\d,.])[OoIl]|[OoIl](?=[\d,.]\d|\d)'),
    (match) => switch (match.group(0)) {
      'O' || 'o' => '0',
      _ => '1',
    },
  );
  return (text: fixed, corrected: fixed != text);
}

double _toDouble(String number) => double.parse(number.replaceAll(',', '.'));

String? _fieldOf(String label) {
  if (label.contains('ungesattigt') || label.contains('unsaturat')) {
    return null;
  }
  for (final (field, keywords) in _keywords) {
    if (keywords.any(label.contains)) return field;
  }
  return null;
}

/// Groups lines into rows: lines whose vertical centres lie within half a
/// line height of each other, sorted left to right.
List<List<OcrLine>> _rows(List<OcrLine> lines) {
  final sorted = [...lines]..sort((a, b) => a.centerY.compareTo(b.centerY));
  final rows = <List<OcrLine>>[];
  for (final line in sorted) {
    final current = rows.isEmpty ? null : rows.last;
    final tolerance = line.height / 2;
    if (current != null &&
        (current.first.centerY - line.centerY).abs() <= tolerance) {
      current.add(line);
    } else {
      rows.add([line]);
    }
  }
  for (final row in rows) {
    row.sort((a, b) => a.x.compareTo(b.x));
  }
  return rows;
}

/// The column header naming the per-100 basis ("pro 100 g", "100 ml",
/// "je 100g"), and which basis it is.
({double x, String basis})? _per100Header(List<OcrLine> lines) {
  for (final line in lines) {
    final text = _normalize(line.text);
    final match = RegExp(r'100\s*(g|ml)\b').firstMatch(text);
    if (match == null) continue;
    final x = text.startsWith(RegExp(r'nahrwert|durchschnitt|naehrwert'))
        ? null
        : line.x;
    return x == null ? null : (x: x, basis: match.group(1)!);
  }
  return null;
}

String _basisFromText(List<OcrLine> lines) {
  for (final line in lines) {
    if (RegExp(r'100\s*ml\b').hasMatch(_normalize(line.text))) return 'ml';
  }
  return 'g';
}

String _normalize(String text) => text
    .toLowerCase()
    .replaceAll('ä', 'a')
    .replaceAll('ö', 'o')
    .replaceAll('ü', 'u')
    .replaceAll('ß', 's')
    .replaceAll('ss', 's');
