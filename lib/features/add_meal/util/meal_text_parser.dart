import 'package:opennutritracker/core/utils/food_name_validator.dart';

const _maxQuantity = 10000;
const _validUnits = {'g', 'ml', 'g/ml', 'oz', 'fl.oz', 'serving'};
const _unitSymbol = r'(?:kg|ml|oz|g|l)';
const _number = r'-?\d+(?:[.,]\d+)?';

/// An item parsed from the Tier-0 multi-item entry field.
class ParsedMealItem {
  final String query;
  final double? quantity;
  final String? unit;

  const ParsedMealItem({required this.query, this.quantity, this.unit});
}

/// Parsed items plus validation errors for input segments that cannot be
/// safely passed to the existing food search.
class MealTextParseResult {
  final List<ParsedMealItem> items;
  final List<String> errors;

  const MealTextParseResult({required this.items, required this.errors});

  bool get hasErrors => errors.isNotEmpty;
}

/// Commas surrounded by digits are decimal marks; every other comma, plus
/// semicolons, newlines, and plus signs, separates meal items.
final _separator = RegExp(r'[;+\n]|(?<!\d),|,(?!\d)');
final _leadingQuantity = RegExp(
  '^($_number)\\s*($_unitSymbol)?\\s+(.+)$',
  caseSensitive: false,
);
final _trailingQuantity = RegExp(
  '^(.+?)\\s+($_number)\\s*($_unitSymbol)?\\s*$',
  caseSensitive: false,
);
final _quantityAndUnitOnly = RegExp(
  '^($_number)\\s*($_unitSymbol)\\s*$',
  caseSensitive: false,
);

class _ExtractedItem {
  final String query;
  final double? quantity;
  final String? unit;

  const _ExtractedItem({required this.query, this.quantity, this.unit});
}

double _parseQuantity(String value) => double.parse(value.replaceAll(',', '.'));

_ExtractedItem _extract(String segment) {
  final quantityOnly = _quantityAndUnitOnly.firstMatch(segment);
  if (quantityOnly != null) {
    return _ExtractedItem(
      query: '',
      quantity: _parseQuantity(quantityOnly.group(1)!),
      unit: quantityOnly.group(2)!.toLowerCase(),
    );
  }

  final leading = _leadingQuantity.firstMatch(segment);
  if (leading != null) {
    return _ExtractedItem(
      query: leading.group(3)!,
      quantity: _parseQuantity(leading.group(1)!),
      unit: leading.group(2)?.toLowerCase(),
    );
  }

  final trailing = _trailingQuantity.firstMatch(segment);
  if (trailing != null) {
    return _ExtractedItem(
      query: trailing.group(1)!,
      quantity: _parseQuantity(trailing.group(2)!),
      unit: trailing.group(3)?.toLowerCase(),
    );
  }

  return _ExtractedItem(query: segment, quantity: null, unit: null);
}

(double, String) _normalizeUnit(double quantity, String unit) {
  return switch (unit) {
    'kg' => (quantity * 1000, 'g'),
    'l' => (quantity * 1000, 'ml'),
    _ => (quantity, unit),
  };
}

/// Parses offline text such as `100g toast, 2 eggs; 1,5 l milk` into search
/// intents. It never estimates nutrition and emits only units accepted by the
/// existing meal-detail unit selector.
MealTextParseResult parseMealText(String input) {
  final segments = input
      .trim()
      .split(_separator)
      .map((segment) => segment.trim())
      .where((segment) => segment.isNotEmpty);
  final items = <ParsedMealItem>[];
  final errors = <String>[];
  var itemNumber = 0;

  for (final segment in segments) {
    itemNumber++;
    final extracted = _extract(segment);
    final query = extracted.query.trim();
    if (!FoodNameValidator.isValid(query)) {
      errors.add('Item $itemNumber: not a valid food name');
      continue;
    }

    var quantity = extracted.quantity;
    var unit = extracted.unit;
    if (quantity != null && unit != null) {
      (quantity, unit) = _normalizeUnit(quantity, unit);
    }

    if (quantity != null && quantity <= 0) {
      errors.add('Item $itemNumber: quantity must be greater than 0');
      continue;
    }
    if (quantity != null && quantity > _maxQuantity) {
      errors.add('Item $itemNumber: quantity must be $_maxQuantity or less');
      continue;
    }

    assert(unit == null || _validUnits.contains(unit));
    items.add(ParsedMealItem(query: query, quantity: quantity, unit: unit));
  }

  return MealTextParseResult(items: items, errors: errors);
}
