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
    if (rawUnit.isEmpty || _normalizeUnitSymbol(rawUnit) != null) {
      return _Extracted(
        query: leading.group(3)!,
        quantity: double.parse(leading.group(1)!),
        unit: rawUnit.isEmpty ? null : rawUnit.toLowerCase(),
      );
    }
  }

  final trailing = _trailingQuantity.firstMatch(segment);
  if (trailing != null) {
    final rawUnit = trailing.group(3)!;
    if (rawUnit.isEmpty || _normalizeUnitSymbol(rawUnit) != null) {
      return _Extracted(
        query: trailing.group(1)!,
        quantity: double.parse(trailing.group(2)!),
        unit: rawUnit.isEmpty ? null : rawUnit.toLowerCase(),
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

/// Turns one line of free text into a list of search intents. Pure and
/// dependency-free: no I/O, no UI. See the class docs on [ParsedMealItem]
/// and [MealTextParseResult] for the shape, and the doc comments on the
/// private helpers below for the segmentation and unit-normalization rules.
MealTextParseResult parseMealText(String input) {
  final segments = _segment(input.trim());

  final items = <ParsedMealItem>[];
  final errors = <String>[];

  for (var i = 0; i < segments.length; i++) {
    final extracted = _extractQuantityAndUnit(segments[i]);
    items.add(
      ParsedMealItem(
        query: extracted.query.trim(),
        quantity: extracted.quantity,
        unit: extracted.unit,
      ),
    );
  }

  return MealTextParseResult(items: items, errors: errors);
}
