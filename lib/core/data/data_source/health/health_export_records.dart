/// A logged meal as the platform health store takes it: nutrients in grams,
/// energy in kilocalories, and a time inside the diary day it belongs to.
class ExportedMeal {
  final ExportedMealSlot slot;
  final DateTime time;
  final String? name;
  final double? energyKcal;
  final double? carbsGram;
  final double? proteinGram;
  final double? fatGram;
  final double? fiberGram;
  final double? sugarGram;
  final double? saturatedFatGram;
  final double? sodiumGram;

  const ExportedMeal({
    required this.slot,
    required this.time,
    this.name,
    this.energyKcal,
    this.carbsGram,
    this.proteinGram,
    this.fatGram,
    this.fiberGram,
    this.sugarGram,
    this.saturatedFatGram,
    this.sodiumGram,
  });

  /// Everything the store is told, in a fixed order, for change detection.
  List<Object?> get fields => [
    slot.name,
    time.toIso8601String(),
    name,
    energyKcal,
    carbsGram,
    proteinGram,
    fatGram,
    fiberGram,
    sugarGram,
    saturatedFatGram,
    sodiumGram,
  ];
}

enum ExportedMealSlot { breakfast, lunch, dinner, snack }

class ExportedWater {
  final DateTime time;
  final int millilitres;

  const ExportedWater({required this.time, required this.millilitres});

  List<Object?> get fields => [time.toIso8601String(), millilitres];
}
