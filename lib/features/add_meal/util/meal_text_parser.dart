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

/// A comma with a digit immediately before it *and* immediately after it
/// is a decimal point; every other comma separates items. The lookarounds
/// express that as "a comma not preceded by a digit, or not followed by
/// one", so a decimal comma is simply never matched as a separator.
///
/// `1,5 l milk` → one segment (digits on both sides).
/// `100g toast, 2 eggs` → two segments (a space follows the comma).
/// `toast,2 eggs` → two segments (no digit precedes the comma).
///
/// Splitting rather than rewriting matters: an earlier version replaced
/// every decimal comma with `.` across the whole input before splitting,
/// which also rewrote commas inside food names — `yoghurt 3,5% fat` and
/// `Omega 3,6,9 capsules` reached the food search with characters the user
/// never typed. The decimal comma is now converted only inside the number
/// actually parsed, in [_parseQuantity].
final _separator = RegExp(r'[;+\n]|(?<!\d),|,(?!\d)');

/// Splits [input] into trimmed, non-empty pieces on `,` / `;` / newline /
/// `+`, subject to the comma rule on [_separator].
List<String> _segment(String input) => input
    .split(_separator)
    .map((s) => s.trim())
    .where((s) => s.isNotEmpty)
    .toList();

/// The five unit symbols this parser recognizes as *input*, longest-first
/// so a two-character symbol is never shadowed by its first letter. Naming
/// them explicitly (rather than matching any run of letters) is what lets
/// the regex engine backtrack to the no-unit reading when the word after
/// the number simply belongs to the food name — see [_leadingQuantity].
const _unitSymbol = r'(?:kg|ml|oz|g|l)';

/// A number, accepting either decimal separator. `JsonMealImporter` takes
/// both the same way; [_parseQuantity] does the conversion.
///
/// The leading `-` is matched deliberately even though a negative quantity
/// is never valid. Refusing it here does not reject the input — it just
/// stops the number being recognized as a quantity at all, so `-5g sugar`
/// would fall through to the food search as a literal query and the user
/// would silently get the default amount instead of the bounds error that
/// `0g water` produces. Matching it lets the `> 0` check below do its job.
const _number = r'-?\d+(?:[.,]\d+)?';

/// A quantity+unit token immediately before or after the food name, e.g.
/// `100g toast` or `toast 100g`. `\s*` (not `\s+`) between the number and
/// the unit is what lets `1.5 l milk` — number, space, unit — match the
/// same way as the no-space `100g toast` does.
///
/// The unit group is optional *and* restricted to [_unitSymbol]. Both
/// halves matter: with a bare `([a-zA-Z]*)` the group greedily swallowed
/// the first word of a multi-word food, and because that word is not a
/// unit the whole match was then discarded — so `2 chicken breasts` lost
/// its quantity entirely while `2 eggs` kept it, purely because a single
/// trailing word forced the engine to backtrack. Restricting the group
/// makes the engine find the no-unit reading itself.
final _leadingQuantity = RegExp(
  '^($_number)\\s*($_unitSymbol)?\\s+(.+)\$',
  caseSensitive: false,
);
final _trailingQuantity = RegExp(
  '^(.+?)\\s+($_number)\\s*($_unitSymbol)?\\s*\$',
  caseSensitive: false,
);
final _quantityAndUnitOnly = RegExp(
  '^($_number)\\s*($_unitSymbol)\\s*\$',
  caseSensitive: false,
);

/// Both decimal separators reach here; `double.parse` only accepts `.`.
double _parseQuantity(String raw) => double.parse(raw.replaceAll(',', '.'));

/// The result of attempting to pull a quantity+unit out of one segment.
/// [unit] is one of the [_unitSymbol] symbols, lower-cased, or `null` when
/// the segment stated no unit.
class _Extracted {
  final String query;
  final double? quantity;
  final String? unit;

  const _Extracted({required this.query, this.quantity, this.unit});
}

/// Tries [_leadingQuantity] then [_trailingQuantity]. Because the unit
/// group only ever matches a known symbol, a letter run that is not a unit
/// stays in the food name instead of being mistaken for one — `2 chicken
/// breasts` keeps its quantity, and `100xyz toast` (letters glued to the
/// number, more often a product code than anything else) is left whole for
/// the search rather than silently losing the `100xyz`.
_Extracted _extractQuantityAndUnit(String segment) {
  final quantityOnly = _quantityAndUnitOnly.firstMatch(segment);
  if (quantityOnly != null) {
    return _Extracted(
      query: '',
      quantity: _parseQuantity(quantityOnly.group(1)!),
      unit: quantityOnly.group(2)!.toLowerCase(),
    );
  }

  final leading = _leadingQuantity.firstMatch(segment);
  if (leading != null) {
    return _Extracted(
      query: leading.group(3)!,
      quantity: _parseQuantity(leading.group(1)!),
      unit: leading.group(2)?.toLowerCase(),
    );
  }

  final trailing = _trailingQuantity.firstMatch(segment);
  if (trailing != null) {
    return _Extracted(
      query: trailing.group(1)!,
      quantity: _parseQuantity(trailing.group(2)!),
      unit: trailing.group(3)?.toLowerCase(),
    );
  }

  return _Extracted(query: segment);
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
