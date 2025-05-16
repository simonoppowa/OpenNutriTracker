import 'package:opennutritracker/core/data/repository/user_weight_repository.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_entity.dart';

class AddWeightUsecase {
  final UserWeightRepository _userWeightRepository;

  AddWeightUsecase(this._userWeightRepository);

  Future<void> addUserActivity(UserWeightEntity userWeightEntity) async {
    return await _userWeightRepository.addUserWeight(userWeightEntity);
  }
}
