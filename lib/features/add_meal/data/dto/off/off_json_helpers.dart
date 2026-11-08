import 'package:logging/logging.dart';
import 'package:opennutritracker/features/add_meal/data/dto/off/off_product_dto.dart';

final _log = Logger('OFFJsonHelpers');

/// Reads an OFF numeric field that usually arrives as a number but
/// occasionally as a string (`"12.5"`, `"12,5"`). Anything unparseable or
/// non-finite becomes null instead of throwing a TypeError.
num? offNumFromJson(dynamic value) {
  if (value is num) return value;
  if (value is String) {
    final parsed = num.tryParse(value.trim().replaceAll(',', '.'));
    if (parsed != null && parsed.isFinite) return parsed;
  }
  return null;
}

int? offIntFromJson(dynamic value) => offNumFromJson(value)?.toInt();

/// Returns the map, or null for a missing or non-object value, so a nested
/// object that OFF sends as null (or as a string/list) reads as absent.
Map<String, dynamic>? offMapFromJson(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : null;

List<String>? offStringListFromJson(dynamic value) =>
    value is List ? value.whereType<String>().toList() : null;

/// Parses a list of OFF products, skipping (and logging) any entry that is
/// not an object or fails to parse, so one malformed product does not fail
/// the whole search result.
List<OFFProductDTO> offProductsFromJson(dynamic value) {
  if (value is! List) return const [];
  final products = <OFFProductDTO>[];
  for (final entry in value) {
    try {
      final map = offMapFromJson(entry);
      if (map == null) {
        throw FormatException('expected an object, got ${entry.runtimeType}');
      }
      products.add(OFFProductDTO.fromJson(map));
    } catch (error) {
      _log.warning('Skipping malformed OFF product: $error');
    }
  }
  return products;
}
