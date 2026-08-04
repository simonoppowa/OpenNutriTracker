import 'package:opennutritracker/core/utils/food_name_validator.dart';

/// Upper bound for a parsed quantity, matching the manual-entry check in
/// meal_detail_bottom_sheet.dart.
const _maxQuantity = 10000;

/// The exact set of `UnitDropdownItem.toString()` values (meal_detail_bloc
/// .dart). [ParsedMealItem.unit] must always be `null` or one of these —
/// see the assert in [parseMealText] and the dedicated invariant test.
const _validUnits = {'g', 'ml', 'g/ml', 'oz', 'fl.oz', 'serving'};

/// One item extracted from a free-text meal description. [query] is what
/// gets handed to the existing food search; [quantity] and [unit] are
/// `null` when the input didn't state an amount, in which case the review
/// row downstream falls back to the defaults `MealDetailScreen
/// ._applyInitialSelection` already uses.
class ParsedMealItem {
  final String query;
  final double? quantity;
  final String? unit;

  const ParsedMealItem({required this.query, this.quantity, this.unit});

  @override
  String toString() =>
      'ParsedMealItem(query: $query, quantity: $quantity, unit: $unit)';
}

/// Result of [parseMealText]. [errors] holds a one-line, item-indexed
/// reason for each segment that could not be turned into a [ParsedMealItem]
/// — empty segments (e.g. a trailing comma) are skipped silently and never
/// produce an error.
class MealTextParseResult {
  final List<ParsedMealItem> items;
  final List<String> errors;

  const MealTextParseResult({required this.items, required this.errors});

  bool get hasErrors => errors.isNotEmpty;
}

/// Splits [input] on `,` / `;` / newline / `+`, subject to the comma rule
/// below, and returns the trimmed, non-empty pieces in order.
List<String> _segment(String input) {
  final normalized = _normalizeDecimalCommas(input);
  return normalized
      .split(RegExp(r'[,;+\n]'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
}

/// A comma with a digit immediately before it and a digit immediately
/// after it is a decimal point; every other comma is a separator. This
/// rewrites decimal commas to `.` in place so the later split on `,` only
/// ever cuts on separator commas.
///
/// `1,5 l milk` → `1.5 l milk` (digits on both sides, one item).
/// `100g toast, 2 eggs` → unchanged (space follows the comma, two items).
/// `toast,2 eggs` → unchanged (no digit before the comma, two items).
String _normalizeDecimalCommas(String input) {
  final buffer = StringBuffer();
  for (var i = 0; i < input.length; i++) {
    final char = input[i];
    if (char == ',') {
      final before = i > 0 ? input[i - 1] : '';
      final after = i < input.length - 1 ? input[i + 1] : '';
      final isDecimal = _isDigit(before) && _isDigit(after);
      buffer.write(isDecimal ? '.' : ',');
    } else {
      buffer.write(char);
    }
  }
  return buffer.toString();
}

bool _isDigit(String char) {
  if (char.isEmpty) return false;
  final code = char.codeUnitAt(0);
  return code >= 0x30 && code <= 0x39;
}

/// A quantity+unit token immediately before or after the food name, e.g.
/// `100g toast` or `toast 100g`. `\s*` (not `\s+`) between the number and
/// the unit letters is what lets `1.5 l milk` — number, space, unit — match
/// the same way as the no-space `100g toast` does.
final _leadingQuantity = RegExp(r'^(\d+(?:\.\d+)?)\s*([a-zA-Z]*)\s+(.+)$');
final _trailingQuantity = RegExp(r'^(.+?)\s+(\d+(?:\.\d+)?)\s*([a-zA-Z]*)\s*$');

/// The result of attempting to pull a quantity+unit out of one segment.
/// [unit] is the raw matched letters (not yet normalized/validated) or
/// `null` when no unit token was present.
class _Extracted {
  final String query;
  final double? quantity;
  final String? unit;

  const _Extracted({required this.query, this.quantity, this.unit});
}

/// Tries [_leadingQuantity] then [_trailingQuantity]. A unit token that
/// doesn't match a recognized symbol (see [_normalizeUnitSymbol]) is
/// treated as part of the food name instead of a unit, since a run of
/// letters glued to a number is more often a product code than a unit
/// this parser doesn't know — leaving it in the query keeps the segment
/// searchable rather than silently discarding it.
_Extracted _extractQuantityAndUnit(String segment) {
  final leading = _leadingQuantity.firstMatch(segment);
  if (leading != null) {
    final rawUnit = leading.group(2)!;
    final unit = rawUnit.isEmpty ? null : _normalizeUnitSymbol(rawUnit);
    if (rawUnit.isEmpty || unit != null) {
      return _Extracted(
        query: leading.group(3)!,
        quantity: double.parse(leading.group(1)!),
        unit: unit,
      );
    }
  }

  final trailing = _trailingQuantity.firstMatch(segment);
  if (trailing != null) {
    final rawUnit = trailing.group(3)!;
    final unit = rawUnit.isEmpty ? null : _normalizeUnitSymbol(rawUnit);
    if (rawUnit.isEmpty || unit != null) {
      return _Extracted(
        query: trailing.group(1)!,
        quantity: double.parse(trailing.group(2)!),
        unit: unit,
      );
    }
  }

  return _Extracted(query: segment);
}

/// `null` when [raw] (case-insensitive) isn't one of the five symbols this
/// parser recognizes as input. Deliberately just `g`/`kg`/`ml`/`l`/`oz` —
/// see the file doc comment for why word-based units are out of scope.
String? _normalizeUnitSymbol(String raw) {
  switch (raw.toLowerCase()) {
    case 'g':
    case 'kg':
    case 'ml':
    case 'l':
    case 'oz':
      return raw.toLowerCase();
    default:
      return null;
  }
}

/// The app's [UnitDropdownItem] (`meal_detail_bloc.dart`) has no `kg` or
/// `l` — its `fromString` falls through to `g/ml` for anything it doesn't
/// recognize, so emitting `kg`/`l` unchanged would silently turn `1,5 l
/// milk` into 1.5 g/ml instead of 1500 ml. Converting here, before the
/// value ever reaches that code, is what avoids the silent 1000x error.
(double, String) _normalizeUnitAndQuantity(double quantity, String unit) {
  switch (unit) {
    case 'kg':
      return (quantity * 1000, 'g');
    case 'l':
      return (quantity * 1000, 'ml');
    default:
      return (quantity, unit);
  }
}

/// Turns one line of free text into a list of search intents — the tier-0
/// half of #599's AI-assisted meal logging: a deterministic parser, no
/// model, so it ships free and runs offline. Pure and dependency-free: no
/// I/O, no UI, fully unit-testable.
///
/// ```
/// parseMealText('100g toast, 2 eggs; 1,5 l milk')
/// // -> items: [
/// //      ParsedMealItem(query: 'toast', quantity: 100, unit: 'g'),
/// //      ParsedMealItem(query: 'eggs', quantity: 2, unit: null),
/// //      ParsedMealItem(query: 'milk', quantity: 1500, unit: 'ml'),
/// //    ]
/// ```
///
/// Each `,` / `;` / newline / `+`-separated segment becomes one
/// [ParsedMealItem], resolved independently against the existing food
/// search downstream (this parser never invents nutrient estimates — see
/// #599 for why that constraint matters to the project's privacy/citation
/// claims). A segment with no recognizable quantity — `black coffee` —
/// still becomes an item, just with `quantity` and `unit` left `null` for
/// the review row to default. A segment that fails validation (no letters,
/// quantity out of bounds) produces an indexed entry in [errors] instead
/// and is dropped from [items]; it never silently disappears.
///
/// Locale-independent by construction: this keys off digits and the unit
/// symbols `g`/`kg`/`ml`/`l`/`oz`, never number-words, so it needs no
/// per-locale word list across the app's 9 supported locales. See the doc
/// comments on the private helpers below for the segmentation and
/// unit-normalization rules, and the class docs on [ParsedMealItem] and
/// [MealTextParseResult] for the result shape.
MealTextParseResult parseMealText(String input) {
  final segments = _segment(input.trim());

  final items = <ParsedMealItem>[];
  final errors = <String>[];

  // Numbers only the segments actually attempted, matching "empty segments
  // are skipped, not errors" — a trailing comma doesn't consume an index.
  var itemNum = 0;

  for (final segment in segments) {
    itemNum++;
    final extracted = _extractQuantityAndUnit(segment);
    final query = extracted.query.trim();

    if (!FoodNameValidator.isValid(query)) {
      errors.add('Item $itemNum: not a valid food name');
      continue;
    }

    var quantity = extracted.quantity;
    var unit = extracted.unit;
    if (quantity != null && unit != null) {
      (quantity, unit) = _normalizeUnitAndQuantity(quantity, unit);
    }

    // Bounds match meal_detail_bottom_sheet.dart's manual-entry check.
    // Applied after kg/l conversion, so '15 kg' is rejected as 15000 g
    // rather than silently becoming a valid-looking 15.
    if (quantity != null) {
      if (quantity <= 0) {
        errors.add('Item $itemNum: quantity must be greater than 0');
        continue;
      }
      if (quantity > _maxQuantity) {
        errors.add('Item $itemNum: quantity must be $_maxQuantity or less');
        continue;
      }
    }

    // This is the invariant that stops a future unit addition reintroducing
    // the silent kg/l coercion _normalizeUnitAndQuantity exists to prevent.
    assert(
      unit == null || _validUnits.contains(unit),
      'parseMealText emitted unrecognized unit "$unit"',
    );

    items.add(ParsedMealItem(query: query, quantity: quantity, unit: unit));
  }

  return MealTextParseResult(items: items, errors: errors);
}
