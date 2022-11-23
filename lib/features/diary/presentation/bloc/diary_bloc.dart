import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_tracked_day_usecase.dart';
import 'package:opennutritracker/core/utils/extensions.dart';

part 'diary_event.dart';

part 'diary_state.dart';

class DiaryBloc extends Bloc<DiaryEvent, DiaryState> {
  final _getDayTrackedUsecase = GetTrackedDayUsecase();

  DiaryBloc() : super(DiaryInitial()) {
    on<LoadDiaryYearEvent>((event, emit) async {
      emit(DiaryLoadingState());

      final currentDate = DateTime.now();
      const yearDuration = Duration(days: 356);

      final trackedDays = await _getDayTrackedUsecase.getTrackedDaysByRange(
          event.context,
          currentDate.subtract(yearDuration),
          currentDate.add(yearDuration));

      final trackedDaysMap = {
        for (var trackedDay in trackedDays)
          trackedDay.day.toParsedDay(): trackedDay
      };

      emit(DiaryLoadedState(trackedDaysMap));
    });
  }
}
