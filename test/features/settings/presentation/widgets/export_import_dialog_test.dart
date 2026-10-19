import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/body_weight_unit_entity.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/home/domain/water_quick_amount.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:opennutritracker/features/settings/domain/backup_reminder.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/export_import_bloc.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:opennutritracker/features/settings/presentation/widgets/export_import_dialog.dart';
import 'package:opennutritracker/features/trends/presentation/bloc/trends_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';

import '../../../../helpers/fake_backup_reminder.dart';

/// Sits in the state an import ends in, so the dialog runs its reload.
class _SucceededExportImportBloc extends Fake implements ExportImportBloc {
  @override
  ExportImportState get state => ExportImportSuccess();

  @override
  Stream<ExportImportState> get stream =>
      const Stream<ExportImportState>.empty();
}

final _events = <Object>[];

class _HomeBloc extends Fake implements HomeBloc {
  @override
  void add(HomeEvent event) => _events.add(event);
}

class _DiaryBloc extends Fake implements DiaryBloc {
  @override
  void add(DiaryEvent event) => _events.add(event);
}

class _CalendarDayBloc extends Fake implements CalendarDayBloc {
  @override
  void add(CalendarDayEvent event) => _events.add(event);
}

class _SettingsBloc extends Fake implements SettingsBloc {
  @override
  void add(SettingsEvent event) => _events.add(event);
}

class _ProfileBloc extends Fake implements ProfileBloc {
  @override
  void add(ProfileEvent event) => _events.add(event);
}

class _TrendsBloc extends Fake implements TrendsBloc {
  _TrendsBloc(this.state);

  @override
  final TrendsState state;

  @override
  void add(TrendsEvent event) => _events.add(event);
}

final _quickAmount = _RecordingQuickAmount();

class _RecordingQuickAmount extends Fake implements WaterQuickAmount {
  var loads = 0;

  @override
  Future<int> load() async {
    loads++;
    return WaterQuickAmount.defaultMl;
  }
}

void main() {
  void register(TrendsState trendsState) {
    _events.clear();
    _quickAmount.loads = 0;
    locator
      ..registerSingleton<ExportImportBloc>(_SucceededExportImportBloc())
      ..registerSingleton<HomeBloc>(_HomeBloc())
      ..registerSingleton<DiaryBloc>(_DiaryBloc())
      ..registerSingleton<CalendarDayBloc>(_CalendarDayBloc())
      ..registerSingleton<SettingsBloc>(_SettingsBloc())
      ..registerSingleton<ProfileBloc>(_ProfileBloc())
      ..registerSingleton<TrendsBloc>(_TrendsBloc(trendsState))
      ..registerSingleton<BackupReminder>(FakeBackupReminder())
      ..registerSingleton<WaterQuickAmount>(_quickAmount);
  }

  Future<void> pumpDialog(WidgetTester tester) => tester.pumpWidget(
    const MaterialApp(
      localizationsDelegates: [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [Locale('en')],
      home: Scaffold(body: ExportImportDialog()),
    ),
  );

  tearDown(locator.reset);

  testWidgets('a finished import reloads the blocs that show goal settings, '
      'keeping the Trends range (#1363)', (tester) async {
    register(
      const TrendsLoaded(
        rangeDays: 30,
        windowDays: 30,
        days: [],
        priorWeek: [],
        weight: [],
        bodyWeightUnit: BodyWeightUnit.kg,
        targetWeightKg: null,
        waterByDay: {},
        waterGoalMl: 2000,
      ),
    );

    await pumpDialog(tester);

    expect(_events, contains(isA<LoadSettingsEvent>()));
    expect(_events, contains(isA<LoadProfileEvent>()));
    expect(_events, contains(isA<LoadItemsEvent>()));
    expect(_events, contains(isA<LoadDiaryYearEvent>()));
    expect(_events, contains(const LoadTrendsEvent(rangeDays: 30)));
    expect(_quickAmount.loads, 1, reason: 'a restore can change it (#29)');
  });

  testWidgets('Trends is left to load itself when it never has', (
    tester,
  ) async {
    register(const TrendsInitial());

    await pumpDialog(tester);

    expect(_events.whereType<LoadTrendsEvent>(), isEmpty);
  });
}
