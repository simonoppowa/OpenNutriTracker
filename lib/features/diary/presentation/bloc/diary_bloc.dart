import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_tracked_day_usecase.dart';
import 'package:opennutritracker/core/utils/extensions.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';

part 'diary_event.dart';

part 'diary_state.dart';

class DiaryBloc extends Bloc<DiaryEvent, DiaryState> {
  final GetTrackedDayUsecase _getDayTrackedUsecase;

  DateTime currentDay = DateTime.now();

  DiaryBloc(this._getDayTrackedUsecase) : super(DiaryInitial()) {
    on<LoadDiaryYearEvent>((event, emit) async {
      emit(DiaryLoadingState());

      currentDay = DateTime.now();
      const yearDuration = Duration(days: 356);

      final trackedDays = await _getDayTrackedUsecase.getTrackedDaysByRange(
          currentDay.subtract(yearDuration), currentDay.add(yearDuration));

      final trackedDaysMap = {
        for (var trackedDay in trackedDays)
          trackedDay.day.toParsedDay(): trackedDay
      };

      emit(DiaryLoadedState(trackedDaysMap));
    });
  }

  void updateHomePage() {
    locator<HomeBloc>().add(const LoadItemsEvent());
  }
}
