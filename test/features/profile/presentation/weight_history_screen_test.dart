import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_gender_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_pal_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_goal_entity.dart';
import 'package:opennutritracker/core/domain/entity/weight_log_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_weight_log_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/delete_weight_log_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_weight_log_usecase.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/profile/presentation/weight_history_screen.dart';
import 'package:opennutritracker/generated/l10n.dart';
import '../../../helpers/fake_reload_blocs.dart';
import '../../../helpers/test_l10n.dart';

class _FakeGetWeightLogUsecase extends Fake implements GetWeightLogUsecase {
  final List<WeightLogEntity> _entries;

  _FakeGetWeightLogUsecase(this._entries);

  @override
  Future<List<WeightLogEntity>> getAllEntries() async => List.of(_entries);

  @override
  Future<List<WeightLogEntity>> getEntriesInRange(
    DateTime from,
    DateTime to,
  ) async {
    return _entries
        .where((e) => !e.date.isBefore(from) && !e.date.isAfter(to))
        .toList();
  }
}

class _FakeAddWeightLogUsecase extends Fake implements AddWeightLogUsecase {
  @override
  Future<void> addEntry(WeightLogEntity entry) async {}
}

class _FakeDeleteWeightLogUsecase extends Fake
    implements DeleteWeightLogUsecase {
  final deleted = <WeightLogEntity>[];

  @override
  Future<void> deleteEntry(WeightLogEntity entry) async => deleted.add(entry);
}

class _FakeConfigRepository extends Fake implements ConfigRepository {
  @override
  Future<ConfigEntity> getConfig() async {
    return ConfigEntity(false, false, false, AppThemeEntity.system);
  }
}

class _FakeGetUserUsecase extends Fake implements GetUserUsecase {
  _FakeGetUserUsecase(this.weightKg);

  final double weightKg;

  @override
  Future<UserEntity> getUserData() async => UserEntity(
    birthday: DateTime(1990, 6, 15),
    heightCM: 165,
    weightKG: weightKg,
    gender: UserGenderEntity.female,
    goal: UserWeightGoalEntity.maintainWeight,
    pal: UserPALEntity.sedentary,
  );
}

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: S.supportedLocales,
    home: child,
  );
}

Widget _buildScreen(
  List<WeightLogEntity> entries, {
  _FakeDeleteWeightLogUsecase? deleteUsecase,
}) {
  return WeightHistoryScreen(
    getUsecase: _FakeGetWeightLogUsecase(entries),
    addUsecase: _FakeAddWeightLogUsecase(),
    deleteUsecase: deleteUsecase ?? _FakeDeleteWeightLogUsecase(),
    configRepository: _FakeConfigRepository(),
  );
}

void main() {
  group('WeightHistoryScreen chart', () {
    testWidgets('shows the empty-state copy when there are no entries', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_buildScreen(const [])));
      await tester.pumpAndSettle();

      // 0 entries: the global "no readings yet" message is shown, no chart.
      expect(find.text(l10nEn.weightHistoryNoEntries), findsOneWidget);
      expect(find.byType(LineChart), findsNothing);
    });

    testWidgets('shows the chart empty-state when there is only one entry', (
      tester,
    ) async {
      final today = DateTime.now();
      final entries = [
        WeightLogEntity(
          date: DateTime(today.year, today.month, today.day),
          weightKg: 72.0,
        ),
      ];

      await tester.pumpWidget(_wrap(_buildScreen(entries)));
      await tester.pumpAndSettle();

      // 1 entry: the list shows the row, the chart slot shows the nudge.
      expect(
        find.byKey(const Key('weightHistoryChartEmptyState')),
        findsOneWidget,
      );
      expect(find.text(l10nEn.weightHistoryChartEmptyState), findsOneWidget);
      expect(find.byType(LineChart), findsNothing);
    });

    testWidgets('renders the chart when there are three entries', (
      tester,
    ) async {
      final today = DateTime.now();
      DateTime day(int daysAgo) {
        final d = today.subtract(Duration(days: daysAgo));
        return DateTime(d.year, d.month, d.day);
      }

      final entries = [
        WeightLogEntity(date: day(0), weightKg: 71.0),
        WeightLogEntity(date: day(7), weightKg: 71.5),
        WeightLogEntity(date: day(14), weightKg: 72.0),
      ];

      await tester.pumpWidget(_wrap(_buildScreen(entries)));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('weightHistoryChart')), findsOneWidget);
      expect(find.byType(LineChart), findsOneWidget);
      expect(
        find.byKey(const Key('weightHistoryChartEmptyState')),
        findsNothing,
      );
    });

    testWidgets('default 30d hides an older point (showing empty state), '
        'selecting 60d shows chart, and selecting All shows chart '
        'with very old history', (tester) async {
      final today = DateTime.now();
      DateTime day(int daysAgo) {
        final d = today.subtract(Duration(days: daysAgo));
        return DateTime(d.year, d.month, d.day);
      }

      final entries = [
        WeightLogEntity(date: day(0), weightKg: 70.0),
        WeightLogEntity(date: day(45), weightKg: 71.0),
        WeightLogEntity(date: day(200), weightKg: 72.0),
      ];

      await tester.pumpWidget(_wrap(_buildScreen(entries)));
      await tester.pumpAndSettle();

      // Default selected is 30d: only 1 point (today) is in window, so chart shows empty state.
      expect(
        find.byKey(const Key('weightHistoryChartEmptyState')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('weightHistoryChart')), findsNothing);

      // Tap 60d segment: should now include the 45-day-old point, showing the chart.
      final button60 = find.text('60d');
      expect(button60, findsOneWidget);
      await tester.tap(button60);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('weightHistoryChart')), findsOneWidget);
      expect(
        find.byKey(const Key('weightHistoryChartEmptyState')),
        findsNothing,
      );

      // Tap All segment: should show chart for all history including 200-day-old point.
      final buttonAll = find.text(l10nEn.allItemsLabel);
      expect(buttonAll, findsOneWidget);
      await tester.tap(buttonAll);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('weightHistoryChart')), findsOneWidget);
      expect(
        find.byKey(const Key('weightHistoryChartEmptyState')),
        findsNothing,
      );
    });
  });

  testWidgets('deleting an entry reloads Trends so its weight card drops '
      'the reading (#1359)', (tester) async {
    final recorder = ReloadRecorder()..register();
    addTearDown(locator.reset);
    final today = DateTime.now();
    final entries = [
      WeightLogEntity(
        date: DateTime(today.year, today.month, today.day),
        weightKg: 72.0,
      ),
    ];

    await tester.pumpWidget(_wrap(_buildScreen(entries)));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    expect(recorder.trendsReloaded, isTrue);
  });

  group('Add entry (#1367)', () {
    Future<String?> prefilled(
      WidgetTester tester,
      List<WeightLogEntity> entries, {
      double? profileKg,
    }) async {
      await tester.pumpWidget(
        _wrap(
          WeightHistoryScreen(
            getUsecase: _FakeGetWeightLogUsecase(entries),
            addUsecase: _FakeAddWeightLogUsecase(),
            deleteUsecase: _FakeDeleteWeightLogUsecase(),
            configRepository: _FakeConfigRepository(),
            getUserUsecase: profileKg == null
                ? null
                : _FakeGetUserUsecase(profileKg),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsIdentifier('weight-history-add'));
      await tester.pumpAndSettle();
      return tester
          .widget<TextField>(
            find.descendant(
              of: find.bySemanticsIdentifier('weight-history-weight-input'),
              matching: find.byType(TextField),
            ),
          )
          .controller
          ?.text;
    }

    testWidgets('starts from the profile weight, not a made-up 70 kg', (
      tester,
    ) async {
      expect(await prefilled(tester, const [], profileKg: 65), '65');
    });

    testWidgets('prefers the profile weight to an older reading', (
      tester,
    ) async {
      final entries = [
        WeightLogEntity(date: DateTime(2026, 1, 1), weightKg: 72),
      ];
      expect(await prefilled(tester, entries, profileKg: 65), '65');
    });

    testWidgets('falls back to the latest reading without a profile', (
      tester,
    ) async {
      final entries = [
        WeightLogEntity(date: DateTime(2026, 1, 1), weightKg: 72),
      ];
      expect(await prefilled(tester, entries), '72');
    });
  });

  testWidgets('deleting a row hands over that row, filed day and all, '
      'when its date shows a neighbouring day (#1418)', (tester) async {
    ReloadRecorder().register();
    addTearDown(locator.reset);
    final deleteUsecase = _FakeDeleteWeightLogUsecase();
    // A time-zone change moved the 10 March row's date onto 11 March, so
    // both rows show 11 March; only the filed day tells them apart.
    final entries = [
      WeightLogEntity(
        date: DateTime(2026, 3, 11),
        weightKg: 80.0,
        filedDay: DateTime(2026, 3, 10),
      ),
      WeightLogEntity(
        date: DateTime(2026, 3, 11),
        weightKg: 81.0,
        filedDay: DateTime(2026, 3, 11),
      ),
    ];

    await tester.pumpWidget(
      _wrap(_buildScreen(entries, deleteUsecase: deleteUsecase)),
    );
    await tester.pumpAndSettle();

    final shiftedRow = find.ancestor(
      of: find.text('80 ${l10nEn.kgLabel}'),
      matching: find.byType(ListTile),
    );
    await tester.tap(
      find.descendant(
        of: shiftedRow,
        matching: find.byIcon(Icons.delete_outline),
      ),
    );
    await tester.pumpAndSettle();

    expect(deleteUsecase.deleted, hasLength(1));
    expect(deleteUsecase.deleted.single.weightKg, 80.0);
    expect(deleteUsecase.deleted.single.filedDay, DateTime(2026, 3, 10));
  });
}
