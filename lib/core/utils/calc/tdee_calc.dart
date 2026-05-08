import 'package:opennutritracker/core/domain/entity/calories_profile_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_gender_entity.dart';
import 'package:opennutritracker/core/utils/calc/bmr_calc.dart';
import 'package:opennutritracker/core/utils/calc/pal_calc.dart';

class TDEECalc {
  /// Calculates TDEE from userEntity based on the formula from
  /// 'Human energy requirements Report of a Joint FAO/WHO/UNU
  /// Expert Consultation'
  /// TDEE = BMR x PAL
  /// https://www.fao.org/3/y5686e/y5686e00.htm
  static double getTDEEKcalWHO2001(UserEntity userEntity) {
    final userBMR = BMRCalc.getBMRSchofield11985(userEntity);
    final userPAL = PalCalc.getPALValueFromActivityCategory(userEntity);
    return userBMR * userPAL;
  }

  /// Returns the total daily energy expenditure (TDEE) of given userEntity
  /// based on 2005 IOM equation
  ///
  /// Institute of Medicine. 2005. Dietary Reference Intakes for Energy,
  /// Carbohydrate, Fiber, Fat, Fatty Acids, Cholesterol, Protein,
  /// and Amino Acids. (p.204)
  /// Washington, DC: The National Academies Press.
  /// https://doi.org/10.17226/10490.
  /// https://nap.nationalacademies.org/catalog/10490/dietary-reference-intakes-for-energy-carbohydrate-fiber-fat-fatty-acids-cholesterol-protein-and-amino-acids
  ///
  /// For non-binary users without an explicit hormone profile, the result is
  /// the mean of the male / female reference outputs. This is a comfort and
  /// privacy choice rather than a statistical claim. The IOM 2005 equations
  /// are sex-stratified and there isn't a published non-binary baseline; any
  /// single default we picked would be making a claim the source data doesn't
  /// support. Averaging produces a neutral midpoint bounded by the two
  /// reference outputs, and lets a non-binary user use the app without having
  /// to disclose whether their profile is estrogen- or testosterone-dominant.
  ///
  /// Users who want a closer estimate can opt into the estrogenTypical or
  /// testosteroneTypical reference via the calorie-profile setting; either
  /// choice routes through the existing male / female formula. The kcal offset
  /// slider in Settings is available for further fine-tuning regardless of
  /// which profile is selected.
  static double getTDEEKcalIOM2005(UserEntity userEntity) {
    final palValue = PalCalc.getPALValueFromActivityCategory(userEntity);
    switch (userEntity.gender) {
      case UserGenderEntity.male:
        return _iom2005MaleKcal(userEntity, palValue);
      case UserGenderEntity.female:
        return _iom2005FemaleKcal(userEntity, palValue);
      case UserGenderEntity.nonBinary:
        switch (userEntity.caloriesProfile ?? CaloriesProfileEntity.averaged) {
          case CaloriesProfileEntity.averaged:
            return (_iom2005MaleKcal(userEntity, palValue) +
                    _iom2005FemaleKcal(userEntity, palValue)) /
                2;
          case CaloriesProfileEntity.estrogenTypical:
            return _iom2005FemaleKcal(userEntity, palValue);
          case CaloriesProfileEntity.testosteroneTypical:
            return _iom2005MaleKcal(userEntity, palValue);
        }
    }
  }

  static double _iom2005MaleKcal(UserEntity userEntity, double palValue) {
    final paValue = PalCalc.getPAValueForFormula(
      palValue: palValue,
      isMaleFormula: true,
    );
    return 864 -
        9.72 * userEntity.age +
        paValue * 14.2 * userEntity.weightKG +
        503 * (userEntity.heightCM / 100);
  }

  static double _iom2005FemaleKcal(UserEntity userEntity, double palValue) {
    final paValue = PalCalc.getPAValueForFormula(
      palValue: palValue,
      isMaleFormula: false,
    );
    return 387 -
        7.31 * userEntity.age +
        paValue * 10.9 * userEntity.weightKG +
        660.7 * (userEntity.heightCM / 100);
  }
}
