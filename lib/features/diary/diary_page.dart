import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/core/utils/extensions.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/widgets/diary_table_calendar.dart';
import 'package:opennutritracker/features/diary/presentation/widgets/day_info_widget.dart';
import 'package:provider/provider.dart';

class DiaryPage extends StatefulWidget {
  const DiaryPage({Key? key}) : super(key: key);

  @override
  State<DiaryPage> createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> {
  late DiaryBloc _diaryBloc;
  final _calendarDayBloc = CalendarDayBloc();

  static const _calendarDurationDays = Duration(days: 356);
  final _currentDate = DateTime.now();
  var _selectedDate = DateTime.now();
  var _focusedDate = DateTime.now();

  @override
  void initState() {
    _diaryBloc = BlocProvider.of<DiaryBloc>(context, listen: false);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DiaryBloc, DiaryState>(
      bloc: _diaryBloc,
      builder: (context, state) {
        if (state is DiaryInitial) {
          _diaryBloc.add(LoadDiaryYearEvent(context));
        } else if (state is DiaryLoadingState) {
          return _getLoadingContent();
        } else if (state is DiaryLoadedState) {
          return _getLoadedContent(context, state.trackedDayMap);
        }
        return const SizedBox();
      },
    );
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
              _calendarDayBloc.add(LoadCalendarDayEvent(context, _selectedDate,
                  trackedDaysMap[_selectedDate.toParsedDay()]));
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
              );
            }
            return const SizedBox();
          },
        )
      ],
    );
  }

  void _onDateSelected(
      DateTime newDate, Map<String, TrackedDayEntity> trackedDaysMap) {
    setState(() {
      _selectedDate = newDate;
      _focusedDate = newDate;
      final trackedDayEvent = trackedDaysMap[newDate.toParsedDay()];
      _calendarDayBloc
          .add(LoadCalendarDayEvent(context, newDate, trackedDayEvent));
    });
  }
}
