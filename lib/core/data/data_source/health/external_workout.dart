/// A single workout record as the platform health store reports it.
///
/// Deliberately plugin-shaped rather than domain-shaped: it carries exactly
/// what Health Connect / Apple Health hand over, so every mapping decision
/// (which compendium activity, which calorie credit, which logical day) is
/// made one layer up where the user's config is available.
class ExternalWorkout {
  /// Stable platform record id. Used as the dedupe key on re-import.
  final String id;

  final DateTime start;
  final DateTime end;

  /// The plugin's activity-type enum name, e.g. `RUNNING`. Kept as a string
  /// so nothing above the data-source layer has to depend on the plugin.
  final String activityTypeName;

  /// Energy the exporting app or device attributed to the workout. Null when
  /// the record carries no energy at all, which is common for manually
  /// entered sessions — those are skipped rather than guessed at.
  final double? energyBurnedKcal;

  /// Name of the app that wrote the record (a watch companion, a running
  /// app, …). Provenance only; never used for matching.
  final String? sourceAppName;

  const ExternalWorkout({
    required this.id,
    required this.start,
    required this.end,
    required this.activityTypeName,
    this.energyBurnedKcal,
    this.sourceAppName,
  });

  @override
  String toString() =>
      'ExternalWorkout($id, $activityTypeName, $start-$end, '
      '${energyBurnedKcal}kcal, from $sourceAppName)';
}
