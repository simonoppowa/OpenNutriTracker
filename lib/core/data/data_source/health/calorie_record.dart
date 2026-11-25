/// One Health Connect TOTAL_CALORIES_BURNED record, as the app's own channel
/// reports it.
///
/// Android only. Health Connect keeps a workout's energy in separate calorie
/// records rather than on the session, and the writers disagree about their
/// shape: a gym app writes one record per session, Fitbit and Google Fit
/// write 15-minute basal+activity buckets, and some writers keep one record
/// per day. [HealthPackageService.androidWorkoutEnergyKcal] attributes them
/// to a session whatever their length.
class CalorieRecord {
  final DateTime start;
  final DateTime end;

  /// Energy in kilocalories. The platform side converts, so there is no unit
  /// to carry.
  final double kcal;

  /// Package name of the app that wrote the record.
  final String sourceName;

  const CalorieRecord({
    required this.start,
    required this.end,
    required this.kcal,
    required this.sourceName,
  });

  @override
  String toString() => 'CalorieRecord($start-$end, ${kcal}kcal, $sourceName)';
}
