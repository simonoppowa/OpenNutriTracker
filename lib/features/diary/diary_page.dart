import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/edit_activity_dialog.dart';
import 'package:opennutritracker/core/presentation/widgets/edit_dialog.dart';
import 'package:opennutritracker/core/utils/calc/met_calc.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_usecase.dart';
import 'package:opennutritracker/features/activity_detail/presentation/bloc/activity_detail_bloc.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_type.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/widgets/diary_table_calendar.dart';
import 'package:opennutritracker/features/diary/presentation/widgets/day_info_widget.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';

class DiaryPage extends StatefulWidget {
  const DiaryPage({super.key});

  @override
  State<DiaryPage> createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> with WidgetsBindingObserver {
  final log = Logger('DiaryPage');

  late DiaryBloc _diaryBloc;
  late CalendarDayBloc _calendarDayBloc;
  late MealDetailBloc _mealDetailBloc;
  late ActivityDetailBloc _activityDetailBloc;

  // #292: Extended from 356 days (~1 year) to 5 years so old entries are never truncated
  static const _calendarDurationDays = Duration(days: 365 * 5);
  final _currentDate = DateTime.now();
  var _selectedDate = DateTime.now();
  var _focusedDate = DateTime.now();

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    _diaryBloc = locator<DiaryBloc>();
    _calendarDayBloc = locator<CalendarDayBloc>();
    _mealDetailBloc = locator<MealDetailBloc>();
    _activityDetailBloc = locator<ActivityDetailBloc>();
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DiaryBloc, DiaryState>(
      bloc: _diaryBloc,
      builder: (context, state) {
        if (state is DiaryInitial) {
          _diaryBloc.add(const LoadDiaryYearEvent());
        } else if (state is DiaryLoadingState) {
          return _getLoadingContent();
        } else if (state is DiaryLoadedState) {
          return _getLoadedContent(
            context,
            state.trackedDayMap,
            state.usesImperialUnits,
            state.showMealMacros,
          );
        }
        return const SizedBox();
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      log.info('App resumed');
      _refreshPageOnDayChange();
    }
    super.didChangeAppLifecycleState(state);
  }

  Widget _getLoadingContent() =>
      const Center(child: CircularProgressIndicator());

  Widget _getLoadedContent(
    BuildContext context,
    Map<String, TrackedDayEntity> trackedDaysMap,
    bool usesImperialUnits,
    bool showMealMacros,
  ) {
    return ListView(
      children: [
        DiaryTableCalendar(
          trackedDaysMap: trackedDaysMap,
          onDateSelected: _onDateSelected,
          calendarDurationDays: _calendarDurationDays,
          currentDate: _currentDate,
          selectedDate: _selectedDate,
          focusedDate: _focusedDate,
        ),
        const SizedBox(height: 16.0),
        BlocBuilder<CalendarDayBloc, CalendarDayState>(
          bloc: _calendarDayBloc,
          builder: (context, state) {
            if (state is CalendarDayInitial) {
              _calendarDayBloc.add(LoadCalendarDayEvent(_selectedDate));
            } else if (state is CalendarDayLoading) {
              return _getLoadingContent();
            } else if (state is CalendarDayLoaded) {
              return DayInfoWidget(
                trackedDayEntity: state.trackedDayEntity,
                selectedDay: _selectedDate,
                userActivities: state.userActivityList,
                breakfastIntake: state.breakfastIntakeList,
                lunchIntake: state.lunchIntakeList,
                dinnerIntake: state.dinnerIntakeList,
                snackIntake: state.snackIntakeList,
                onDeleteIntake: _onDeleteIntakeItem,
                onDeleteActivity: _onDeleteActivityItem,
                onCopyIntake: _onCopyIntakeItem,
                onCopyActivity: _onCopyActivityItem,
                onEditIntake: _onEditIntakeItem,
                onEditActivity: _onEditActivityItem,
                usesImperialUnits: usesImperialUnits,
                showMealMacros: showMealMacros,
                diarySortPreferences: state.diarySortPreferences,
              );
            }
            return const SizedBox();
          },
        ),
      ],
    );
  }

  void _onDeleteIntakeItem(
    IntakeEntity intakeEntity,
    TrackedDayEntity? trackedDayEntity,
  ) async {
    await _calendarDayBloc.deleteIntakeItem(
      context,
      intakeEntity,
      trackedDayEntity?.day ?? DateTime.now(),
    );
    _diaryBloc.add(const LoadDiaryYearEvent());
    _calendarDayBloc.add(LoadCalendarDayEvent(_selectedDate));
    _diaryBloc.updateHomePage();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).itemDeletedSnackbar)),
      );
    }
  }

  void _onDeleteActivityItem(
    UserActivityEntity userActivityEntity,
    TrackedDayEntity? trackedDayEntity,
  ) async {
    await _calendarDayBloc.deleteUserActivityItem(
      context,
      userActivityEntity,
      trackedDayEntity?.day ?? DateTime.now(),
    );
    _diaryBloc.add(const LoadDiaryYearEvent());
    _calendarDayBloc.add(LoadCalendarDayEvent(_selectedDate));
    _diaryBloc.updateHomePage();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).itemDeletedSnackbar)),
      );
    }
  }

  void _onCopyIntakeItem(
    IntakeEntity intakeEntity,
    TrackedDayEntity? trackedDayEntity,
    AddMealType? type,
  ) async {
    IntakeTypeEntity finalType;
    if (type == null) {
      finalType = intakeEntity.type;
    } else {
      finalType = type.getIntakeType();
    }
    _mealDetailBloc.addIntake(
      context,
      intakeEntity.unit,
      intakeEntity.amount.toString(),
      finalType,
      intakeEntity.meal,
      DateTime.now(),
    );
    _diaryBloc.updateHomePage();
  }

  void _onCopyActivityItem(
    UserActivityEntity userActivityEntity,
    TrackedDayEntity? trackedDayEntity,
  ) async {
    final activity = userActivityEntity.physicalActivityEntity;
    if (activity.isCustom) {
      // Custom activities (#70) store the user-entered kcal directly — the
      // MET formula would just return zero for them, so we pass the saved
      // kcal figure through unchanged so a copied entry keeps its calories.
      final kcal =
          userActivityEntity.userKcal ?? userActivityEntity.burnedKcal;
      _activityDetailBloc.persistActivity(
        kcal.toString(),
        kcal,
        activity,
        DateTime.now(),
      );
    } else {
      final user = await locator<GetUserUsecase>().getUserData();
      final burnedKcal = METCalc.getTotalBurnedKcal(
        user,
        activity,
        userActivityEntity.duration,
      );
      _activityDetailBloc.persistActivity(
        userActivityEntity.duration.toString(),
        burnedKcal,
        activity,
        DateTime.now(),
      );
    }
    _diaryBloc.updateHomePage();
  }

  void _onEditIntakeItem(
    BuildContext context,
    IntakeEntity intakeEntity,
    bool usesImperialUnits,
  ) async {
    final changeIntakeAmount = await showDialog<double>(
      context: context,
      builder: (context) => EditDialog(
        intakeEntity: intakeEntity,
        usesImperialUnits: usesImperialUnits,
      ),
    );
    if (changeIntakeAmount != null) {
      await _calendarDayBloc.updateIntakeItem(
        intakeEntity.id,
        {'amount': changeIntakeAmount},
        _selectedDate,
      );
      _diaryBloc.add(const LoadDiaryYearEvent());
      _calendarDayBloc.add(LoadCalendarDayEvent(_selectedDate));
      _diaryBloc.updateHomePage();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).itemUpdatedSnackbar)),
        );
      }
    }
  }

  void _onEditActivityItem(
    BuildContext context,
    UserActivityEntity activityEntity,
  ) async {
    final newDuration = await showDialog<double>(
      context: context,
      builder: (context) =>
          EditActivityDialog(activityEntity: activityEntity),
    );
    if (newDuration != null) {
      await _calendarDayBloc.updateUserActivityItem(
        activityEntity,
        newDuration,
        _selectedDate,
      );
      _diaryBloc.add(const LoadDiaryYearEvent());
      _calendarDayBloc.add(LoadCalendarDayEvent(_selectedDate));
      _diaryBloc.updateHomePage();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).itemUpdatedSnackbar)),
        );
      }
    }
  }

  void _onDateSelected(
    DateTime newDate,
    Map<String, TrackedDayEntity> trackedDaysMap,
  ) {
    setState(() {
      _selectedDate = newDate;
      _focusedDate = newDate;
      _calendarDayBloc.add(LoadCalendarDayEvent(newDate));
    });
    if (newDate.isAfter(_currentDate) && !DateUtils.isSameDay(newDate, _currentDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).diaryFutureDateWarning)),
      );
    }
  }

  void _refreshPageOnDayChange() {
    if (DateUtils.isSameDay(_selectedDate, DateTime.now())) {
      _calendarDayBloc.add(LoadCalendarDayEvent(_selectedDate));
      _diaryBloc.add(const LoadDiaryYearEvent());
    }
  }
}
