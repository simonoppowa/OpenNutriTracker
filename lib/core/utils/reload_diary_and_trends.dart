import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/trends/presentation/bloc/trends_bloc.dart';

/// Reloads the Diary (calendar and the open day) and Trends after something
/// they read has been saved: a goal, a display setting, a weight entry.
///
/// All three blocs are lazy singletons living in the main `IndexedStack`, so
/// they keep their loaded state until told to reload; Home is reloaded by
/// its own callers. Call this after the write has completed — the blocs
/// read the stored values back (#1359).
void reloadDiaryAndTrends() {
  locator<DiaryBloc>().add(const LoadDiaryYearEvent());
  locator<CalendarDayBloc>().add(const RefreshCalendarDayEvent());
  locator<TrendsBloc>().add(const RefreshTrendsEvent());
}
