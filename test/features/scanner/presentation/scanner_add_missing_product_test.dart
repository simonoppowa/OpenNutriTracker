import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/edit_meal/presentation/edit_meal_screen.dart';
import 'package:opennutritracker/features/scanner/data/product_not_found_exception.dart';
import 'package:opennutritracker/features/scanner/domain/usecase/search_product_by_barcode_usecase.dart';
import 'package:opennutritracker/features/scanner/presentation/scanner_bloc.dart';
import 'package:opennutritracker/features/scanner/scanner_screen.dart';
import 'package:opennutritracker/generated/l10n.dart';

import '../../../helpers/test_l10n.dart';

class _NotFound implements SearchProductByBarcodeUseCase {
  @override
  Future<MealEntity> searchProductByBarcode(String barcode) async =>
      throw ProductNotFoundException();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _Config implements GetConfigUsecase {
  @override
  Future<ConfigEntity> getConfig() async =>
      const ConfigEntity(
        true,
        true,
        false,
        AppThemeEntity.system,
        usesImperialFoodUnits: true,
      );

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

/// Under "Product not found", a barcode no database knows can become the
/// user's own custom meal, carrying the barcode.
void main() {
  final getIt = GetIt.instance;

  setUp(() async {
    await getIt.reset();
    getIt.registerFactory<ScannerBloc>(
      () => ScannerBloc(_NotFound(), _Config()),
    );
    getIt.registerSingleton<GetConfigUsecase>(_Config());
  });

  tearDown(() => getIt.reset());

  Future<List<Object?>> open(
    WidgetTester tester,
    ScannerScreenArguments args,
  ) async {
    final pushed = <Object?>[];
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [S.delegate],
        supportedLocales: S.supportedLocales,
        onGenerateRoute: (settings) {
          if (settings.name != NavigationOptions.editMealRoute) return null;
          pushed.add(settings.arguments);
          return MaterialPageRoute(builder: (_) => const Text('edit-meal'));
        },
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                settings: RouteSettings(arguments: args),
                builder: (_) => const ScannerScreen(),
              ),
            ),
            child: const Text('scan'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('scan'));
    await tester.pumpAndSettle();
    return pushed;
  }

  testWidgets('an unknown barcode can become a custom food with it', (
    tester,
  ) async {
    final pushed = await open(
      tester,
      ScannerScreenArguments(
        DateTime(2026, 10, 23),
        IntakeTypeEntity.lunch,
        initialBarcode: '4006381333931',
      ),
    );

    await tester.tap(find.text(l10nEn.scannerAddFromLabelButton));
    await tester.pumpAndSettle();

    expect(find.text('edit-meal'), findsOneWidget);
    final args = pushed.single! as EditMealScreenArguments;
    expect(args.mealEntity.code, '4006381333931');
    expect(args.mealEntity.source, MealSourceEntity.custom);
    expect(args.intakeTypeEntity, IntakeTypeEntity.lunch);
    expect(args.day, DateTime(2026, 10, 23));
    expect(args.usesImperialUnits, isTrue);
  });

  testWidgets('the recipe picker gets no such offer', (tester) async {
    await open(
      tester,
      ScannerScreenArguments.pick(initialBarcode: '4006381333931'),
    );
    expect(find.text(l10nEn.scannerAddFromLabelButton), findsNothing);
  });
}
