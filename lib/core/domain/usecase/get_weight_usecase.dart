import 'package:opennutritracker/core/data/repository/user_weight_repository.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_entity.dart';

class GetWeightUsecase {
  final UserWeightRepository _userWeightRepository;

  GetWeightUsecase(this._userWeightRepository);

  Future<UserWeightEntity> getUserWeightByDate() {
    return _userWeightRepository.getUserWeightByDate(DateTime.now());
  }
}
