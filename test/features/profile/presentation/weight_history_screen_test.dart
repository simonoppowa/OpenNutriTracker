import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/weight_log_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_weight_log_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/delete_weight_log_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_weight_log_usecase.dart';
import 'package:opennutritracker/features/profile/presentation/weight_history_screen.dart';
import 'package:opennutritracker/generated/l10n.dart';

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
  @override
  Future<void> deleteEntry(DateTime date) async {}
}

class _FakeConfigRepository extends Fake implements ConfigRepository {
  @override
  Future<ConfigEntity> getConfig() async {
    return ConfigEntity(
      false,
      false,
      false,
      AppThemeEntity.system,
    );
  }
}

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: S.delegate.supportedLocales,
    home: child,
  );
}

Widget _buildScreen(List<WeightLogEntity> entries) {
  return WeightHistoryScreen(
    getUsecase: _FakeGetWeightLogUsecase(entries),
    addUsecase: _FakeAddWeightLogUsecase(),
    deleteUsecase: _FakeDeleteWeightLogUsecase(),
    configRepository: _FakeConfigRepository(),
  );
}

void main() {
  group('WeightHistoryScreen chart', () {
    testWidgets('shows the empty-state copy when there are no entries',
        (tester) async {
      await tester.pumpWidget(_wrap(_buildScreen(const [])));
      await tester.pumpAndSettle();

      // 0 entries: the global "no readings yet" message is shown, no chart.
      expect(find.text(S.current.weightHistoryNoEntries), findsOneWidget);
      expect(find.byType(LineChart), findsNothing);
    });

    testWidgets('shows the chart empty-state when there is only one entry',
        (tester) async {
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
      expect(find.byKey(const Key('weightHistoryChartEmptyState')),
          findsOneWidget);
      expect(find.text(S.current.weightHistoryChartEmptyState), findsOneWidget);
      expect(find.byType(LineChart), findsNothing);
    });

    testWidgets('renders the chart when there are three entries',
        (tester) async {
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
      expect(find.byKey(const Key('weightHistoryChartEmptyState')),
          findsNothing);
    });
  });
}
