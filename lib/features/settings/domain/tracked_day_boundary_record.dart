import 'dart:convert';

/// The day boundary a backup's tracked-day rows are keyed by, as it
/// travels in the bundle (#1317): `tracked_day_boundary.json` in a JSON
/// bundle, `tracked_day_boundary.csv` in a CSV one.
///
/// A row is keyed by the day its entries are listed under, which depends
/// on the "Day starts at" boundary. A restore under another boundary has
/// to move the rows, and the activity credit in their goals, from the one
/// they were written under, so the bundle says which that was. A bundle
/// without the file predates it.
class TrackedDayBoundaryRecord {
  static const jsonFileName = 'tracked_day_boundary.json';
  static const csvFileName = 'tracked_day_boundary.csv';

  /// Bumped only for a change an older reader would misread. A reader
  /// that meets a newer version treats the boundary as unknown.
  static const formatVersion = 1;

  static const _jsonKey = 'dayStartOffsetMinutes';
  static const _csvHeader = 'day_start_offset_minutes';

  static String toJson(int offsetMinutes) =>
      jsonEncode({'version': formatVersion, _jsonKey: offsetMinutes});

  static String toCsv(int offsetMinutes) => '$_csvHeader\n$offsetMinutes\n';

  /// The boundary in [source], or null for a newer version. Throws a
  /// [FormatException] for anything else that is not a boundary.
  static int? fromJson(String source) {
    final json = jsonDecode(source);
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Not an object');
    }
    final version = json['version'];
    if (version is! int) throw const FormatException('No version');
    if (version > formatVersion) return null;
    return _checked(json[_jsonKey]);
  }

  /// The boundary in [source]. Throws a [FormatException] for anything
  /// that is not one.
  static int fromCsv(String source) {
    final lines = const LineSplitter()
        .convert(source.trim())
        .map((line) => line.trim())
        .toList();
    if (lines.length != 2 || lines[0] != _csvHeader) {
      throw const FormatException('Not a boundary record');
    }
    return _checked(int.tryParse(lines[1]));
  }

  static int _checked(Object? value) {
    if (value is! int || value < 0 || value >= 24 * 60) {
      throw FormatException('Not a day boundary in minutes', '$value');
    }
    return value;
  }
}
