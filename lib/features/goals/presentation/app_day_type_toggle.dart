import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/training_plan.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/set_day_type_usecase.dart';
import 'package:opennutritracker/core/utils/calc/day_boundary_calc.dart';
import 'package:opennutritracker/core/utils/goal_changes.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/goals/presentation/day_type_toggle.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';

Future<TrainingPlan> _loadPlan() async =>
    (await locator<GetConfigUsecase>().getConfig()).trainingPlan;

Future<void> _setDayType(DateTime day, DayType type) async {
  await locator<SetDayTypeUsecase>().setDayType(day, type);
  locator<HomeBloc>().add(const LoadItemsEvent());
  locator<CalendarDayBloc>().add(RefreshCalendarDayEvent());
  locator<GoalChanges>().notifyChanged();
}

/// [DayTypeToggle] wired to the app: the diary day [day], or the logical
/// today when it is null (Home).
class AppDayTypeToggle extends StatefulWidget {
  final DateTime? day;

  const AppDayTypeToggle({super.key, this.day});

  @override
  State<AppDayTypeToggle> createState() => _AppDayTypeToggleState();
}

class _AppDayTypeToggleState extends State<AppDayTypeToggle> {
  late Future<DateTime> _day = _resolveDay();

  Future<DateTime> _resolveDay() async {
    final day = widget.day;
    if (day != null) return DateTime(day.year, day.month, day.day);
    final config = await locator<GetConfigUsecase>().getConfig();
    return DayBoundaryCalc.currentLogicalDayLabel(
      config.dayStartOffsetHours,
      config.dayStartOffsetMinutes,
    );
  }

  @override
  void didUpdateWidget(AppDayTypeToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.day != widget.day) _day = _resolveDay();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<DateTime>(
    future: _day,
    builder: (context, snapshot) {
      final day = snapshot.data;
      if (day == null) return const SizedBox.shrink();
      return DayTypeToggle(
        key: ValueKey(day),
        day: day,
        loadPlan: _loadPlan,
        setDayType: _setDayType,
        changes: locator<GoalChanges>(),
      );
    },
  );
}
