import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_gender_entity.dart';

///
/// Calculates BMR of UserEntity based on the 1918 Harris-Benedict equation
/// from the paper 'A Biometric Study of Human Basal Metabolism'
/// by Harris & Benedict
/// https://pubmed.ncbi.nlm.nih.gov/16576330/
///
class BMRCalc {
  static double getBMRHarrisBenedict1918(UserEntity user) {
    double bmr;
    switch (user.gender) {
      case UserGenderEntity.male:
        bmr = 66.4730 +
            13.7516 * user.weightKG +
            5.0033 * user.heightCM -
            6.7550 * user.age;
        break;
      case UserGenderEntity.female:
        bmr = 655.0955 +
            9.5634 * user.weightKG +
            1.8496 * user.heightCM -
            4.6756 * user.age;
        break;
    }
    return bmr;
  }

  ///
  /// Calculates BMR of UserEntity based on the 1984 revised
  /// Harris-Benedict equation from the paper
  /// 'The Harris Benedict equation reevaluated: resting energy
  /// requirements and the body cell mass' by Roza & Shizgal
  /// https://academic.oup.com/ajcn/article-abstract/40/1/168/4691315
  ///
  static double getBMRRevisedHarrisBenedict1984(UserEntity user) {
    double bmr;
    switch (user.gender) {
      case UserGenderEntity.male:
        bmr = 88.362 +
            13.397 * user.weightKG +
            4.799 * user.heightCM -
            5.677 * user.age;
        break;
      case UserGenderEntity.female:
        bmr = 447.593 +
            9.247 * user.weightKG +
            3.098 * user.heightCM -
            4.330 * user.age;
        break;
    }
    return bmr;
  }

  ///
  /// Calculates BMR of UserEntity based on the 1990 Mifflin-St.Jeor equation
  /// from the paper 'A new predictive equation for resting energy
  /// expenditure in healthy individuals'
  /// by Mifflin & St.Jeor
  /// https://academic.oup.com/ajcn/article-abstract/51/2/241/4695104
  ///
  static double getBMRMifflinStJeor1990(UserEntity user) {
    double a;
    switch(user.gender) {
      case UserGenderEntity.male:
        a = 5;
        break;
      case UserGenderEntity.female:
        a = -161;
        break;
    }
    final bmr = 10 * user.weightKG + 6.25 * user.heightCM - 5 * user.age + a;
    return bmr;
  }


}
