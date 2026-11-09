import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_tracked_day_usecase.dart';
import 'package:opennutritracker/core/utils/calc/day_boundary_calc.dart';
import 'package:opennutritracker/core/utils/extensions.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';

part 'diary_event.dart';

part 'diary_state.dart';

class DiaryBloc extends Bloc<DiaryEvent, DiaryState> {
  final GetTrackedDayUsecase _getDayTrackedUsecase;
  final GetConfigUsecase _getConfigUsecase;
  final GetIntakeUsecase _getIntakeUsecase;

  DateTime currentDay = DateTime.now();

  DiaryBloc(
    this._getDayTrackedUsecase,
    this._getConfigUsecase,
    this._getIntakeUsecase,
  )
      : super(DiaryInitial()) {
    on<LoadDiaryYearEvent>((event, emit) async {
      emit(DiaryLoadingState());

      final config = await _getConfigUsecase.getConfig();
      final usesImperialUnits = config.usesImperialFoodUnits;
      final showMealMacros = config.showMealMacros;
      final showActivityTracking = config.showActivityTracking;

      // #139: pin currentDay to the user's logical "today" so the
      // diary calendar's today-marker shifts with the configured boundary.
      // Follow-up: total minutes lets a 04:30 boundary land precisely.
      currentDay = DayBoundaryCalc.currentLogicalDayMinutes(
        config.dayStartOffsetTotalMinutes,
      );
      // #292: Extended to match calendar range (5 years back)
      const yearDuration = Duration(days: 365 * 5);

      final trackedDays = await _getDayTrackedUsecase.getTrackedDaysByRange(
        currentDay.subtract(yearDuration),
        currentDay.add(yearDuration),
      );

      final trackedDaysMap = {
        for (var trackedDay in trackedDays)
          trackedDay.day.toParsedDay(): trackedDay,
      };

      // The calendar marks a day by what is logged on it, not by its row:
      // a row stays for its goals when a boundary move empties its day.
      final daysWithEntries = await _getIntakeUsecase.getDayKeysWithIntakes(
        config.dayStartOffsetTotalMinutes,
      );

      emit(DiaryLoadedState(
        trackedDaysMap,
        usesImperialUnits,
        daysWithEntries: daysWithEntries,
        showMealMacros: showMealMacros,
        showActivityTracking: showActivityTracking,
      ));
    });
  }

  void updateHomePage() {
    locator<HomeBloc>().add(const LoadItemsEvent());
  }
}
