import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_gender_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_pal_entity.dart';

class PalCalc {
  ///
  /// Return the physical activity level (PAL) value fom the PAL category
  /// based on the IOM Physical Activity Recommendations 2004
  /// 'Chronicle of the Institute of Medicine physical activity recommendation:
  /// how a physical activity recommendation came to be among dietary
  /// recommendations'
  /// by Brooks et al.
  /// https://pubmed.ncbi.nlm.nih.gov/15113740/
  ///
  static double getPALValueFromActivityCategory(UserEntity userEntity) {
    double palValue;
    switch (userEntity.pal) {
      case UserPALEntity.sedentary:
        palValue = 1.25;
        break;
      case UserPALEntity.lowActive:
        palValue = 1.5;
        break;
      case UserPALEntity.active:
        palValue = 1.75;
        break;
      case UserPALEntity.veryActive:
        palValue = 2.2;
        break;
    }
    return palValue;
  }

  ///
  /// Returns the physical activity coefficient (PA) from the PAL value
  /// and user gender based on IOM recommendation
  ///
  /// Institute of Medicine. 2005. Dietary Reference Intakes for Energy,
  /// Carbohydrate, Fiber, Fat, Fatty Acids, Cholesterol, Protein,
  /// and Amino Acids. (p.204)
  /// Washington, DC: The National Academies Press.
  /// https://doi.org/10.17226/10490.
  /// https://nap.nationalacademies.org/catalog/10490/dietary-reference-intakes-for-energy-carbohydrate-fiber-fat-fatty-acids-cholesterol-protein-and-amino-acids
  static double getPAValueFromPALValue(UserEntity userEntity, double palValue) {
    double paValue = 1.0;
    if (palValue < 1.4) {
      paValue = 1.0;
    } else if (palValue < 1.6) {
      userEntity.gender == UserGenderEntity.male
          ? paValue = 1.12
          : paValue = 1.14;
    } else if (palValue < 1.9) {
      paValue = 1.27;
    } else {
      userEntity.gender == UserGenderEntity.male
          ? paValue = 1.54
          : paValue = 1.45;
    }
    return paValue;
  }
}
