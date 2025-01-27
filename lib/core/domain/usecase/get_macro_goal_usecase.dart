import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/utils/calc/macro_calc.dart';

class GetMacroGoalUsecase {
  final ConfigRepository _configRepository;

  GetMacroGoalUsecase(this._configRepository);

  Future<double> getCarbsGoal(double totalCalorieGoal) async {
    final config = await _configRepository.getConfig();
    final userCarbGoal = config.userCarbGoalPct;

    return MacroCalc.getTotalCarbsGoal(totalCalorieGoal,
        userCarbsGoal: userCarbGoal);
  }

  Future<double> getFatsGoal(double totalCalorieGoal) async {
    final config = await _configRepository.getConfig();
    final userFatGoal = config.userFatGoalPct;

    return MacroCalc.getTotalFatsGoal(totalCalorieGoal,
        userFatsGoal: userFatGoal);
  }

  Future<double> getProteinsGoal(double totalCalorieGoal) async {
    final config = await _configRepository.getConfig();
    final userProteinGoal = config.userProteinGoalPct;

    return MacroCalc.getTotalProteinsGoal(totalCalorieGoal,
        userProteinsGoal: userProteinGoal);
  }
}
