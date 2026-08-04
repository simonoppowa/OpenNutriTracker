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

/// Turns one line of free text into a list of search intents. Pure and
/// dependency-free: no I/O, no UI. See the class docs on [ParsedMealItem]
/// and [MealTextParseResult] for the shape, and the doc comments on the
/// private helpers below for the segmentation and unit-normalization rules.
MealTextParseResult parseMealText(String input) {
  final segments = _segment(input.trim());

  final items = <ParsedMealItem>[];
  final errors = <String>[];

  for (var i = 0; i < segments.length; i++) {
    items.add(ParsedMealItem(query: segments[i]));
  }

  return MealTextParseResult(items: items, errors: errors);
}
