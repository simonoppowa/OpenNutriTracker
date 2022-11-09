import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/widgets/diary_table_calendar.dart';

class DiaryPage extends StatefulWidget {
  const DiaryPage({Key? key}) : super(key: key);

  @override
  State<DiaryPage> createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> {
  final _diaryBloc = DiaryBloc();

  static const _calendarDurationDays = Duration(days: 356);
  final _currentDate = DateTime.now();
  var _selectedDate = DateTime.now();
  var _focusedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DiaryBloc, DiaryState>(
      bloc: _diaryBloc,
      builder: (context, state) {
        if (state is DiaryInitial) {
          _diaryBloc.add(LoadDiaryEvent(
              context,
              _currentDate.subtract(_calendarDurationDays),
              _currentDate.add(_calendarDurationDays)));
        } else if (state is DiaryLoadingState) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is DiaryLoadedState) {
          return getLoadedContent(context, state.trackedDayMap);
        }
        return const SizedBox();
      },
    );
  }

  Widget getLoadedContent(
      BuildContext context, Map<String, TrackedDayEntity> trackedDaysMap) {
    return ListView(
      children: [
        DiaryTableCalendar(
          trackedDaysMap: trackedDaysMap,
          onDateSelected: onDateSelected,
          calendarDurationDays: _calendarDurationDays,
          currentDate: _currentDate,
          selectedDate: _selectedDate,
          focusedDate: _focusedDate,
        ),
      ],
    );
  }

  void onDateSelected(DateTime newDate) {
    setState(() {
      _selectedDate = newDate;
      _focusedDate = _focusedDate;
    });
  }
}
