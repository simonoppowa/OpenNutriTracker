import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/domain/entity/copy_target.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';
import 'package:opennutritracker/core/domain/usecase/copy_entries_usecase.dart';
import 'package:opennutritracker/core/presentation/widgets/edit_activity_dialog.dart';
import 'package:opennutritracker/core/presentation/widgets/edit_dialog.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/widgets/copy_day_dialog.dart';
import 'package:opennutritracker/features/diary/presentation/widgets/diary_table_calendar.dart';
import 'package:opennutritracker/features/home/domain/day_water_log.dart';
import 'package:opennutritracker/features/diary/presentation/widgets/day_info_widget.dart';
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

  // #292: Extended from 356 days (~1 year) to 5 years so old entries are never truncated
  static const _calendarDurationDays = Duration(days: 365 * 5);
  // Derive today from the DiaryBloc so the "jump to today" button and swipe
  // clamp honour the configured day-start offset (otherwise between midnight
  // and e.g. 4 am Home and Diary disagree on which day is "today").
  DateTime get _currentDate => _diaryBloc.currentDay;
  var _selectedDate = DateTime.now();
  var _focusedDate = DateTime.now();

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    _diaryBloc = locator<DiaryBloc>();
    _calendarDayBloc = locator<CalendarDayBloc>();
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
            state.showActivityTracking,
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
    bool showActivityTracking,
  ) {
    return ListView(
      padding: const EdgeInsets.only(bottom: Dimens.spacing16),
      children: [
        DiaryTableCalendar(
          trackedDaysMap: trackedDaysMap,
          onDateSelected: _onDateSelected,
          calendarDurationDays: _calendarDurationDays,
          currentDate: _currentDate,
          selectedDate: _selectedDate,
          focusedDate: _focusedDate,
        ),
        if (!DateUtils.isSameDay(_selectedDate, _currentDate))
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: Dimens.spacing8),
              child: IconButton(
                icon: const Icon(Icons.today_rounded),
                onPressed: () => _onDateSelected(_currentDate, trackedDaysMap),
              ),
            ),
          ),
        const SizedBox(height: Dimens.spacing8),
        // Swipe horizontally on the day's detail to step a day back / forward.
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragEnd: (d) => _onDaySwipe(d, trackedDaysMap),
          child: BlocBuilder<CalendarDayBloc, CalendarDayState>(
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
                onCopyIntake: _onCopyIntakeItems,
                onCopyActivity: _onCopyActivityItem,
                onCopyDay: _onCopyDay,
                copyDefaultDay: _currentDate,
                onEditIntake: _onEditIntakeItem,
                onEditActivity: _onEditActivityItem,
                usesImperialUnits: usesImperialUnits,
                showMealMacros: showMealMacros,
                showActivityTracking: showActivityTracking,
                breakfastKcalTarget: state.breakfastKcalTarget,
                lunchKcalTarget: state.lunchKcalTarget,
                dinnerKcalTarget: state.dinnerKcalTarget,
                snackKcalTarget: state.snackKcalTarget,
                breakfastSharePct: state.breakfastSharePct,
                lunchSharePct: state.lunchSharePct,
                dinnerSharePct: state.dinnerSharePct,
                snackSharePct: state.snackSharePct,
                diarySortPreferences: state.diarySortPreferences,
              );
            }
            return const SizedBox();
          },
          ),
        ),
      ],
    );
  }

  void _onDaySwipe(
    DragEndDetails details,
    Map<String, TrackedDayEntity> trackedDaysMap,
  ) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity == 0) return;
    final today =
        DateTime(_currentDate.year, _currentDate.month, _currentDate.day);
    // Swipe left advances a day, swipe right goes back. Clamp to the calendar's
    // range (no further back than 5 years, no further forward than today).
    final delta = velocity < 0 ? 1 : -1;
    var next = DateUtils.addDaysToDate(_selectedDate, delta);
    final first = today.subtract(_calendarDurationDays);
    if (next.isBefore(first)) next = first;
    if (next.isAfter(today)) next = today;
    if (!DateUtils.isSameDay(next, _selectedDate)) {
      _onDateSelected(next, trackedDaysMap);
    }
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

  /// Copies [intakes] to [target] (#40) and refreshes what shows them.
  Future<void> _onCopyIntakeItems(
    List<IntakeEntity> intakes,
    CopyTarget target,
  ) => _copy(
    () => locator<CopyEntriesUsecase>().copyIntakes(intakes, target),
  );

  Future<void> _onCopyActivityItem(
    UserActivityEntity userActivityEntity,
    DateTime day,
  ) => _copy(
    () => locator<CopyEntriesUsecase>().copyActivities([
      userActivityEntity,
    ], day),
  );

  Future<void> _onCopyDay(CopyDayChoice choice) => _copy(
    () => locator<CopyEntriesUsecase>().copyDay(
      _selectedDate,
      choice.day,
      activities: choice.activities,
      water: choice.water,
    ),
  );

  /// Runs [copy] and refreshes the views whether or not it got through,
  /// since a failed copy may have written part of its entries.
  Future<void> _copy(Future<void> Function() copy) async {
    final messenger = ScaffoldMessenger.of(context);
    final copied = S.of(context).copiedLabel;
    final failed = S.of(context).copyFailedLabel;
    var succeeded = false;
    try {
      await copy();
      succeeded = true;
    } catch (error, stackTrace) {
      log.warning('Copy failed', error, stackTrace);
    } finally {
      _diaryBloc.add(const LoadDiaryYearEvent());
      _calendarDayBloc.add(RefreshCalendarDayEvent());
      _diaryBloc.updateHomePage();
      locator<DayWaterLog>().markChanged();
    }
    messenger.showSnackBar(
      SnackBar(content: Text(succeeded ? copied : failed)),
    );
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
    // #139: refresh unconditionally on resume so any day-boundary
    // setting change while the app was backgrounded is picked up.
    // The cost is one extra LoadDiaryYearEvent (already cheap) plus a
    // single CalendarDay refresh; keeping the original isSameDay check
    // would miss the offset case entirely.
    _calendarDayBloc.add(LoadCalendarDayEvent(_selectedDate));
    _diaryBloc.add(const LoadDiaryYearEvent());
  }
}
