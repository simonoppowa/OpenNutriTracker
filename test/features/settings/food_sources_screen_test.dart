import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/off_const.dart';
import 'package:opennutritracker/features/settings/presentation/widgets/food_sources_screen.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// Holds the toggles the way the config box does: what Settings writes is
/// what the next read returns.
class _Store {
  Map<String, bool> toggles;
  final List<Map<String, bool>> writes = [];

  _Store(this.toggles);
}

class _FakeGetConfigUsecase implements GetConfigUsecase {
  final _Store store;

  _FakeGetConfigUsecase(this.store);

  @override
  Future<ConfigEntity> getConfig() async => ConfigEntity(
    true,
    true,
    false,
    AppThemeEntity.system,
    foodSourceToggles: Map.of(store.toggles),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeAddConfigUsecase implements AddConfigUsecase {
  final _Store store;

  _FakeAddConfigUsecase(this.store);

  @override
  Future<void> setConfigFoodSourceToggles(Map<String, bool> toggles) async {
    store.toggles = Map.of(toggles);
    store.writes.add(Map.of(toggles));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

Widget _app() => MaterialApp(
  localizationsDelegates: const [
    S.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: S.supportedLocales,
  home: const FoodSourcesScreen(),
);

void main() {
  late _Store store;

  Future<void> pumpScreen(WidgetTester tester, Map<String, bool> stored) async {
    store = _Store(stored);
    await locator.reset();
    locator
      ..registerSingleton<GetConfigUsecase>(_FakeGetConfigUsecase(store))
      ..registerSingleton<AddConfigUsecase>(_FakeAddConfigUsecase(store));
    addTearDown(locator.reset);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
  }

  SwitchListTile offSwitch(WidgetTester tester) => tester.widget(
    find.ancestor(
      of: find.text(OFFConst.offSourceName),
      matching: find.byType(SwitchListTile),
    ),
  );

  testWidgets('Open Food Facts is on and can be switched, by default', (
    tester,
  ) async {
    await pumpScreen(tester, const {});

    expect(offSwitch(tester).value, isTrue);
    expect(offSwitch(tester).onChanged, isNotNull);
  });

  testWidgets('switching it off is stored and survives reopening the screen', (
    tester,
  ) async {
    await pumpScreen(tester, const {'bls': false});

    await tester.tap(find.text(OFFConst.offSourceName));
    await tester.pumpAndSettle();

    expect(offSwitch(tester).value, isFalse);
    expect(store.writes.last, {'bls': false, OFFConst.offSourceCode: false});

    // A fresh screen reads it back from the store.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    expect(offSwitch(tester).value, isFalse);
  });

  testWidgets('every switch carries a locale-independent identifier', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpScreen(tester, const {});

    expect(
      find.bySemanticsIdentifier('food-sources-switch-off'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsIdentifier('food-sources-switch-bls'),
      findsOneWidget,
    );
    handle.dispose();
  });
}
