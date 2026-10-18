import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/trends/presentation/bloc/trends_bloc.dart';

/// Stand-ins for the screen-persistent Diary, CalendarDay and Trends blocs
/// that only record what they are sent. Every event lands in one shared
/// [log] (as its runtime type name) so a test can also assert that the
/// reload came after the write it depends on.
class ReloadRecorder {
  final List<String> log;

  ReloadRecorder([List<String>? log]) : log = log ?? <String>[];

  bool get diaryReloaded => log.contains('LoadDiaryYearEvent');

  bool get calendarDayReloaded => log.contains('RefreshCalendarDayEvent');

  bool get trendsReloaded => log.contains('RefreshTrendsEvent');

  /// Registers the recording fakes in the locator. Pair with
  /// `locator.reset()` in tearDown.
  void register() {
    locator.registerSingleton<DiaryBloc>(_RecordingDiaryBloc(log));
    locator.registerSingleton<CalendarDayBloc>(_RecordingCalendarDayBloc(log));
    locator.registerSingleton<TrendsBloc>(_RecordingTrendsBloc(log));
  }
}

class _RecordingDiaryBloc extends Fake implements DiaryBloc {
  final List<String> _log;

  _RecordingDiaryBloc(this._log);

  @override
  void add(DiaryEvent event) => _log.add(event.runtimeType.toString());
}

class _RecordingCalendarDayBloc extends Fake implements CalendarDayBloc {
  final List<String> _log;

  _RecordingCalendarDayBloc(this._log);

  @override
  void add(CalendarDayEvent event) => _log.add(event.runtimeType.toString());
}

class _RecordingTrendsBloc extends Fake implements TrendsBloc {
  final List<String> _log;

  _RecordingTrendsBloc(this._log);

  @override
  void add(TrendsEvent event) => _log.add(event.runtimeType.toString());
}
