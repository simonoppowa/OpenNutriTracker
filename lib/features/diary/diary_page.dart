import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/widgets/diary_table_calendar.dart';
import 'package:opennutritracker/features/diary/presentation/widgets/day_info_widget.dart';
import 'package:opennutritracker/generated/l10n.dart';

class DiaryPage extends StatefulWidget {
  const DiaryPage({Key? key}) : super(key: key);

  @override
  State<DiaryPage> createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> with WidgetsBindingObserver {
  final log = Logger('DiaryPage');

  late DiaryBloc _diaryBloc;
  late CalendarDayBloc _calendarDayBloc;

  static const _calendarDurationDays = Duration(days: 356);
  final _currentDate = DateTime.now();
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
          return _getLoadedContent(context, state.trackedDayMap);
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
      BuildContext context, Map<String, TrackedDayEntity> trackedDaysMap) {
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
              );
            }
            return const SizedBox();
          },
        )
      ],
    );
  }

  void _onDeleteIntakeItem(
      IntakeEntity intakeEntity, TrackedDayEntity? trackedDayEntity) async {
    await _calendarDayBloc.deleteIntakeItem(
        context, intakeEntity, trackedDayEntity?.day ?? DateTime.now());
    _diaryBloc.add(const LoadDiaryYearEvent());
    _calendarDayBloc.add(LoadCalendarDayEvent(_selectedDate));
    _diaryBloc.updateHomePage();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).itemDeletedSnackbar)));
    }
  }

  void _onDeleteActivityItem(UserActivityEntity userActivityEntity,
      TrackedDayEntity? trackedDayEntity) async {
    await _calendarDayBloc.deleteUserActivityItem(
        context, userActivityEntity, trackedDayEntity?.day ?? DateTime.now());
    _diaryBloc.add(const LoadDiaryYearEvent());
    _calendarDayBloc.add(LoadCalendarDayEvent(_selectedDate));
    _diaryBloc.updateHomePage();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).itemDeletedSnackbar)));
    }
  }

  void _onDateSelected(
      DateTime newDate, Map<String, TrackedDayEntity> trackedDaysMap) {
    setState(() {
      _selectedDate = newDate;
      _focusedDate = newDate;
      _calendarDayBloc.add(LoadCalendarDayEvent(newDate));
    });
  }

  void _refreshPageOnDayChange() {
    if (DateUtils.isSameDay(_selectedDate, DateTime.now())) {
      _calendarDayBloc.add(LoadCalendarDayEvent(_selectedDate));
      _diaryBloc.add(const LoadDiaryYearEvent());
    }
  }
}
