import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'diary_event.dart';

part 'diary_state.dart';

class DiaryBloc extends Bloc<DiaryEvent, DiaryState> {
  DiaryBloc() : super(DiaryInitial()) {
    on<LoadDiaryEvent>((event, emit) async {
      emit(DiaryLoadingState());

      // TODO load data

      emit(DiaryLoadedState());
    });
  }
}
