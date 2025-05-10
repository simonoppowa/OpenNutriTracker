import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';

part 'weight_event.dart';

part 'weight_state.dart';

class WeightBloc extends Bloc<WeightEvent, WeightState> {
  final log = Logger('WeightBloc');

  final double weightStep = 0.1;

  WeightBloc() : super(const WeightState(0)) {
    on<WeightIncrement>((event, emit) {
      emit(WeightState(state.weight + weightStep));
    });
    on<WeightDecrement>((event, emit) {
      final newWeight = state.weight - weightStep;
      if (newWeight >= 0) {
        emit(WeightState(newWeight));
      } else {
        emit(WeightState(0));
        log.severe('Weight cannot be negative');
      }
    });
  }
}
