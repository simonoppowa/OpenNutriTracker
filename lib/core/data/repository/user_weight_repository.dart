import 'package:opennutritracker/core/domain/entity/user_weight_entity.dart';
import 'package:opennutritracker/core/data/data_source/user_weight_data_source.dart';
import 'package:opennutritracker/core/data/data_source/user_weight_dbo.dart';

class UserWeightRepository {
  final UserWeightDataSource _userWeightDataSource;

  UserWeightRepository(this._userWeightDataSource);

  Future<void> addUserWeight(UserWeightEntity userWeight) async {
    final userWeightDbo = UserWeightDbo.fromUserWeightEntity(userWeight);

    _userWeightDataSource.addUserWeight(userWeightDbo);
  }

  Future<UserWeightEntity> getUserWeightByDate(DateTime dateTime) async {
    final UserWeightDbo weightDbo =
        await _userWeightDataSource.getUserWeightByDate(dateTime);

    return UserWeightEntity.fromUserWeightDbo(weightDbo);
  }
}
