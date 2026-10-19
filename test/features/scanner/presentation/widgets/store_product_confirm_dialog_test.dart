import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/scanner/presentation/widgets/store_product_confirm_dialog.dart';
import 'package:opennutritracker/generated/l10n.dart';

import '../../../../helpers/test_l10n.dart';

final _product = MealEntity(
  code: '20697112',
  name: 'Milk chocolate de Noël',
  brands: 'Favorina',
  url: null,
  mealQuantity: null,
  mealUnit: 'g',
  servingQuantity: null,
  servingUnit: 'g',
  servingSize: null,
  nutriments: MealNutrimentsEntity.empty(),
  source: MealSourceEntity.off,
);

void main() {
  setUp(
    () => GetIt.instance.registerLazySingleton<CacheManager>(
      _FakeCacheManager.new,
    ),
  );
  tearDown(() => GetIt.instance.reset());

  bool? answer;

  Future<void> openDialog(WidgetTester tester) async {
    answer = null;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async =>
                answer = await showStoreProductConfirmDialog(context, _product),
            child: const Text('scan'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('scan'));
    await tester.pump();
  }

  testWidgets('shows the product Open Food Facts returned', (tester) async {
    await openDialog(tester);

    expect(find.text(l10nEn.storeCodeConfirmTitle), findsOneWidget);
    expect(find.text('Milk chocolate de Noël'), findsOneWidget);
    expect(find.text('Favorina'), findsOneWidget);
    expect(find.text(l10nEn.storeCodeConfirmBody), findsOneWidget);
  });

  testWidgets('yes confirms the product', (tester) async {
    await openDialog(tester);
    await tester.tap(find.text(l10nEn.storeCodeConfirmYes));
    await tester.pump();

    expect(answer, isTrue);
  });

  testWidgets('no rejects it', (tester) async {
    await openDialog(tester);
    await tester.tap(find.text(l10nEn.storeCodeConfirmNo));
    await tester.pump();

    expect(answer, isFalse);
  });
}

class _FakeCacheManager implements CacheManager {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}
