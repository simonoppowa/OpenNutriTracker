import 'package:opennutritracker/core/domain/entity/intake_entity.dart';

/// How a meal section should be sorted in the diary day view.
///
/// The default ([timeAdded]) preserves the order intakes were logged in,
/// which matches the rest of the app. The macro-based options sort high to
/// low so the entries driving the day's totals come first — handy when
/// someone is scanning the day and trying to figure out what tipped them
/// over a goal.
enum DiarySortType {
  timeAdded,
  kcal,
  protein,
  carbs,
  fat;

  /// Returns a sorted copy of [intakes] according to this sort type.
  /// Never mutates the source list.
  List<IntakeEntity> apply(List<IntakeEntity> intakes) {
    final copy = List<IntakeEntity>.of(intakes);
    switch (this) {
      case DiarySortType.timeAdded:
        // Preserve the order the bloc handed us. Intake repositories return
        // entries in insertion order, which is the historical behaviour.
        return copy;
      case DiarySortType.kcal:
        copy.sort((a, b) => b.totalKcal.compareTo(a.totalKcal));
        return copy;
      case DiarySortType.protein:
        copy.sort((a, b) => b.totalProteinsGram.compareTo(a.totalProteinsGram));
        return copy;
      case DiarySortType.carbs:
        copy.sort((a, b) => b.totalCarbsGram.compareTo(a.totalCarbsGram));
        return copy;
      case DiarySortType.fat:
        copy.sort((a, b) => b.totalFatsGram.compareTo(a.totalFatsGram));
        return copy;
    }
  }
}
