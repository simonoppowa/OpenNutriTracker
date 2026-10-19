import 'package:equatable/equatable.dart';

/// The circumferences a body measurement can hold, in centimetres.
enum BodyMeasureKind { waist, chest, arm, thigh, hip }

/// One body measurement of the profile (#43): the date and any of the
/// circumferences in centimetres, at least one of them.
class BodyMeasurement extends Equatable {
  static const minCm = 10.0;
  static const maxCm = 300.0;

  final String id;
  final DateTime date;
  final Map<BodyMeasureKind, double> valuesCm;
  final String? note;

  BodyMeasurement({
    required this.id,
    required this.date,
    required Map<BodyMeasureKind, double> valuesCm,
    this.note,
  }) : valuesCm = Map.unmodifiable(valuesCm) {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'must not be blank');
    }
    if (valuesCm.isEmpty) {
      throw ArgumentError.value(valuesCm, 'valuesCm', 'needs one measure');
    }
    for (final value in valuesCm.values) {
      if (!isValidCm(value)) {
        throw ArgumentError.value(value, 'valuesCm', 'out of range');
      }
    }
  }

  static bool isValidCm(double value) =>
      value.isFinite && value >= minCm && value <= maxCm;

  double? operator [](BodyMeasureKind kind) => valuesCm[kind];

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    for (final kind in BodyMeasureKind.values) '${kind.name}Cm': valuesCm[kind],
    'note': note,
  };

  /// Throws a [FormatException] for a measurement that is not one.
  factory BodyMeasurement.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final date = DateTime.tryParse(json['date'] as String? ?? '');
    final note = json['note'];
    final values = <BodyMeasureKind, double>{};
    for (final kind in BodyMeasureKind.values) {
      final value = json['${kind.name}Cm'];
      if (value == null) continue;
      if (value is! num || !isValidCm(value.toDouble())) {
        throw FormatException('invalid ${kind.name}Cm: $value');
      }
      values[kind] = value.toDouble();
    }
    if (id is! String ||
        id.trim().isEmpty ||
        date == null ||
        values.isEmpty ||
        note is! String?) {
      throw FormatException('invalid body measurement: $json');
    }
    return BodyMeasurement(id: id, date: date, valuesCm: values, note: note);
  }

  @override
  List<Object?> get props => [
    id,
    date,
    for (final kind in BodyMeasureKind.values) valuesCm[kind],
    note,
  ];
}
