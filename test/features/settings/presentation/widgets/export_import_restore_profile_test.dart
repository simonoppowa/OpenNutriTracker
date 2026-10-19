import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:opennutritracker/features/settings/domain/backup_reminder.dart';
import 'package:opennutritracker/features/settings/domain/usecase/export_data_usecase.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/export_import_bloc.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:opennutritracker/features/settings/presentation/widgets/export_import_dialog.dart';
import 'package:opennutritracker/features/trends/presentation/bloc/trends_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';

import '../../../../helpers/fake_backup_reminder.dart';

/// An idle bloc that records what the dialog asks of it.
class _RecordingExportImportBloc extends Fake implements ExportImportBloc {
  final events = <ExportImportEvent>[];

  @override
  ExportImportState get state => ExportImportInitial();

  @override
  Stream<ExportImportState> get stream =>
      const Stream<ExportImportState>.empty();

  @override
  void add(ExportImportEvent event) => events.add(event);
}

class _HomeBloc extends Fake implements HomeBloc {}

class _DiaryBloc extends Fake implements DiaryBloc {}

class _CalendarDayBloc extends Fake implements CalendarDayBloc {}

class _SettingsBloc extends Fake implements SettingsBloc {}

class _ProfileBloc extends Fake implements ProfileBloc {}

class _TrendsBloc extends Fake implements TrendsBloc {}

void main() {
  late _RecordingExportImportBloc bloc;

  setUp(() {
    bloc = _RecordingExportImportBloc();
    locator
      ..registerSingleton<ExportImportBloc>(bloc)
      ..registerSingleton<HomeBloc>(_HomeBloc())
      ..registerSingleton<DiaryBloc>(_DiaryBloc())
      ..registerSingleton<CalendarDayBloc>(_CalendarDayBloc())
      ..registerSingleton<SettingsBloc>(_SettingsBloc())
      ..registerSingleton<ProfileBloc>(_ProfileBloc())
      ..registerSingleton<TrendsBloc>(_TrendsBloc())
      ..registerSingleton<BackupReminder>(FakeBackupReminder());
  });

  tearDown(locator.reset);

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

  Finder restoreSwitch() =>
      find.bySemanticsIdentifier('export-import-restore-profile');

  ImportDataEvent lastImport() => bloc.events.whereType<ImportDataEvent>().last;

  testWidgets('a JSON import restores profile and settings by default', (
    tester,
  ) async {
    await pumpDialog(tester);

    expect(restoreSwitch(), findsOneWidget);
    await tester.tap(find.text('Import'));

    expect(lastImport().format, ExportFormat.json);
    expect(lastImport().restoreProfileAndSettings, isTrue);
  });

  testWidgets('switching it off is passed on to the import', (tester) async {
    await pumpDialog(tester);

    await tester.tap(restoreSwitch());
    await tester.pump();
    await tester.tap(find.text('Import'));

    expect(lastImport().restoreProfileAndSettings, isFalse);
  });

  testWidgets('the CSV format does not offer it', (tester) async {
    await pumpDialog(tester);

    await tester.tap(find.text('CSV'));
    await tester.pump();

    expect(restoreSwitch(), findsNothing);
  });

  testWidgets('replacing asks first and only imports after the user agrees', (
    tester,
  ) async {
    await pumpDialog(tester);

    await tester.tap(find.bySemanticsIdentifier('export-import-replace'));
    await tester.pump();
    await tester.tap(find.text('Import'));
    await tester.pumpAndSettle();

    expect(find.text('Replace all data?'), findsOneWidget);
    expect(bloc.events.whereType<ImportDataEvent>(), isEmpty);

    await tester.tap(find.text('CANCEL'));
    await tester.pumpAndSettle();
    expect(bloc.events.whereType<ImportDataEvent>(), isEmpty);

    await tester.tap(find.text('Import'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Replace'));
    await tester.pumpAndSettle();

    expect(lastImport().replaceExisting, isTrue);
  });

  testWidgets('a plain import merges', (tester) async {
    await pumpDialog(tester);

    await tester.tap(find.text('Import'));

    expect(lastImport().replaceExisting, isFalse);
  });
}
