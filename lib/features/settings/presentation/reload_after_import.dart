import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:opennutritracker/features/trends/presentation/bloc/trends_bloc.dart';

/// Reloads every screen a restore can change, the way the export dialog does
/// after an import.
void reloadScreensAfterImport() {
  locator<HomeBloc>().add(const LoadItemsEvent());
  locator<DiaryBloc>().add(const LoadDiaryYearEvent());
  locator<CalendarDayBloc>().add(RefreshCalendarDayEvent());
  locator<SettingsBloc>().add(LoadSettingsEvent());
  locator<ProfileBloc>().add(LoadProfileEvent());
  final trendsBloc = locator<TrendsBloc>();
  final trendsState = trendsBloc.state;
  if (trendsState is TrendsLoaded) {
    trendsBloc.add(LoadTrendsEvent(rangeDays: trendsState.rangeDays));
  }
}
