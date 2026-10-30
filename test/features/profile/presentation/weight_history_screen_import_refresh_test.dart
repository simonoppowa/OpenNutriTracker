import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/weight_log_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_weight_log_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/delete_weight_log_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_weight_log_usecase.dart';
import 'package:opennutritracker/features/profile/presentation/weight_history_screen.dart';
import 'package:opennutritracker/generated/l10n.dart';

import '../../../helpers/test_l10n.dart';

class _FakeGetWeightLogUsecase extends Fake implements GetWeightLogUsecase {
  List<WeightLogEntity> entries = [];
  int getAllEntriesCalls = 0;

  @override
  Future<List<WeightLogEntity>> getAllEntries() async {
    getAllEntriesCalls++;
    return List.of(entries);
  }
}

class _FakeAddWeightLogUsecase extends Fake implements AddWeightLogUsecase {}

class _FakeDeleteWeightLogUsecase extends Fake
    implements DeleteWeightLogUsecase {}

class _FakeConfigRepository extends Fake implements ConfigRepository {
  @override
  Future<ConfigEntity> getConfig() async {
    return ConfigEntity(false, false, false, AppThemeEntity.system);
  }
}

void main() {
  testWidgets('an open weight history reloads when an import files readings', (
    tester,
  ) async {
    final getUsecase = _FakeGetWeightLogUsecase();
    final weightsImported = StreamController<void>.broadcast();
    addTearDown(weightsImported.close);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.supportedLocales,
        home: WeightHistoryScreen(
          getUsecase: getUsecase,
          addUsecase: _FakeAddWeightLogUsecase(),
          deleteUsecase: _FakeDeleteWeightLogUsecase(),
          configRepository: _FakeConfigRepository(),
          weightsImported: weightsImported.stream,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(l10nEn.weightHistoryNoEntries), findsOneWidget);

    final now = DateTime.now();
    getUsecase.entries = [
      WeightLogEntity(
        date: DateTime(now.year, now.month, now.day),
        weightKg: 78.4,
        externalId: 'scale-1',
      ),
    ];
    weightsImported.add(null);
    await tester.pumpAndSettle();

    expect(getUsecase.getAllEntriesCalls, 2);
    expect(find.text(l10nEn.weightHistoryNoEntries), findsNothing);
  });
}
