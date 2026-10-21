import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:opennutritracker/features/settings/presentation/widgets/diary_day_boundary_dialog.dart';
import 'package:opennutritracker/generated/l10n.dart';

import '../../../../helpers/fake_reload_blocs.dart';
import '../../../../helpers/test_l10n.dart';

class _FakeSettingsBloc extends Fake implements SettingsBloc {
  final List<String> calls;

  _FakeSettingsBloc(this.calls);

  @override
  Future<int> getDayStartOffsetHours() async => 0;

  @override
  Future<int> getDayStartOffsetMinutes() async => 0;

  @override
  Future<void> setDayStartOffset(int hours, int minutes) async {
    // A real write yields; the reloads must not overtake it.
    await Future<void>.delayed(Duration.zero);
    calls.add('setDayStartOffset');
  }

  @override
  void add(SettingsEvent event) {}
}

class _FakeHomeBloc extends Fake implements HomeBloc {
  @override
  void add(HomeEvent event) {}
}

void main() {
  late ReloadRecorder recorder;

  setUp(() {
    recorder = ReloadRecorder()..register();
  });

  tearDown(() async => locator.reset());

  testWidgets('saving reloads Trends after the boundary has moved the '
      'tracked-day rows (#1317)', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [S.delegate],
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: DiaryDayBoundaryDialog(
            settingsBloc: _FakeSettingsBloc(recorder.log),
            homeBloc: _FakeHomeBloc(),
            diaryBloc: locator<DiaryBloc>(),
            calendarDayBloc: locator<CalendarDayBloc>(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10nEn.dialogOKLabel));
    await tester.pumpAndSettle();

    // Trends sits in the main IndexedStack and only loads on its first
    // build, so without this it keeps the rows' old dates.
    expect(recorder.trendsReloaded, isTrue);
    expect(recorder.diaryReloaded, isTrue);
    expect(recorder.calendarDayReloaded, isTrue);
    expect(recorder.log.first, 'setDayStartOffset');
  });
}
