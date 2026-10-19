import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/data/dbo/app_theme_dbo.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/search/search_region.dart';
import 'package:opennutritracker/features/settings/presentation/widgets/food_sources_screen.dart';
import 'package:opennutritracker/generated/l10n.dart';

import '../../../../helpers/test_l10n.dart';

class _FakeConfigDataSource implements ConfigDataSource {
  ConfigDBO config = ConfigDBO(false, false, false, AppThemeDBO.system);

  @override
  Future<ConfigDBO> getConfig() async => config;

  @override
  Future<void> addConfig(ConfigDBO configDBO) async => config = configDBO;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeGetConfigUsecase extends Fake implements GetConfigUsecase {
  @override
  Future<ConfigEntity> getConfig() async =>
      const ConfigEntity(true, true, false, AppThemeEntity.system);
}

void main() {
  late _FakeConfigDataSource config;

  setUp(() {
    config = _FakeConfigDataSource();
    GetIt.instance
      ..registerSingleton(SearchRegion(config))
      ..registerSingleton<GetConfigUsecase>(_FakeGetConfigUsecase());
  });

  tearDown(() => GetIt.instance.reset());

  testWidgets('the search region starts on Germany and can be changed', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('en')],
        home: FoodSourcesScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10nEn.searchRegionLabel), findsOneWidget);
    expect(find.text('🇩🇪 DE'), findsOneWidget);

    await tester.tap(find.text('🇩🇪 DE'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('🇦🇹 AT').last);
    await tester.pumpAndSettle();

    expect(config.config.offSearchCountry, 'AT');
    expect(find.text('🇦🇹 AT'), findsOneWidget);
  });
}
