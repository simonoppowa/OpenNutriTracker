import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_weight_usecase.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_entity.dart';

part 'weight_event.dart';

part 'weight_state.dart';

class WeightBloc extends Bloc<WeightEvent, WeightState> {
  final GetUserUsecase _getUserUsecase = locator<GetUserUsecase>();
  final AddWeightUsecase _addWeightUsecase = locator<AddWeightUsecase>();

  final log = Logger('WeightBloc');

  final double weightStep = 0.1;

  double finalWeight = 0.0;

  WeightBloc() : super(WeightState(0.0)) {
    _loadInitialWeight();

    on<WeightIncrement>((event, emit) {
      finalWeight += weightStep;
      emit(WeightState(finalWeight));
    });
    on<WeightDecrement>((event, emit) {
      final newWeight = finalWeight - weightStep;
      if (newWeight >= 0) {
        finalWeight = newWeight;
      } else {
        finalWeight = 0.0;
      }
      emit(WeightState(finalWeight));
    });
    on<WeightSave>((event, emit) {
      log.info('Saving weight: $finalWeight');
      _addWeightUsecase.addUserActivity(
          UserWeightEntity(id: '', weight: finalWeight, date: DateTime.now()));
      emit(WeightState(finalWeight));
    });
  }

  Future<void> _loadInitialWeight() async {
    try {
      final userData = await _getUserUsecase.getUserData();
      final initialUserWeight = userData.weightKG;

      finalWeight = initialUserWeight;
      emit(WeightState(finalWeight));
    } catch (e, stackTrace) {
      log.severe('Failed to load initial weight', e, stackTrace);
    }
  }
}
