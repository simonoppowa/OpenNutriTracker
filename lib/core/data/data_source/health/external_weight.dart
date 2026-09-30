/// A single body weight reading as the platform health store reports it.
///
/// Plugin-shaped like [ExternalWorkout]: it carries what Health Connect /
/// Apple Health hand over, and the decisions about which reading a day keeps
/// and whether it may replace what is already logged are made one layer up.
class ExternalWeight {
  /// Stable platform record id. Used to recognise a reading on re-import and
  /// to remember one the user deleted.
  final String id;

  /// When the reading was taken.
  final DateTime measuredAt;

  final double weightKg;

  /// Name of the app that wrote the record — a scale's companion app, or an
  /// aggregator such as Health Sync. Provenance only.
  final String? sourceAppName;

  const ExternalWeight({
    required this.id,
    required this.measuredAt,
    required this.weightKg,
    this.sourceAppName,
  });

  @override
  String toString() =>
      'ExternalWeight($id, ${weightKg}kg at $measuredAt, from $sourceAppName)';
}
