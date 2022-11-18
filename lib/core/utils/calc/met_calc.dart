import 'package:opennutritracker/core/domain/entity/physical_activity_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';

class METCalc {
  /// Calculates total kcal with formula by the
  /// '2011 Compendium of Physical Activities'
  /// https://pubmed.ncbi.nlm.nih.gov/21681120/
  /// by Ainsworth et al.
  /// kcal = MET x weight in kg x duration in hours
  static double getTotalBurnedKcal(UserEntity userEntity,
      PhysicalActivityEntity physicalActivityEntity, double durationMin) {
    return physicalActivityEntity.mets * userEntity.weightKG * durationMin / 60;
  }
}
