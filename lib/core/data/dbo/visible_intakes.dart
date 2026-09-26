import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';

/// Replacement ingredients are pending while their recipe row still exists.
/// Once that row is removed, they become the active diary entries.
List<IntakeDBO> visibleIntakes(Iterable<IntakeDBO> intakes) {
  final all = intakes.toList();
  final ids = all.map((intake) => intake.id).toSet();
  return all.where((intake) {
    final parentId = intake.conversionParentId;
    return parentId == null || !ids.contains(parentId);
  }).toList();
}
