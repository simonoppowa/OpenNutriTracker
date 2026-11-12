import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/features/scanner/domain/usecase/search_product_by_barcode_usecase.dart';
import 'package:opennutritracker/features/scanner/presentation/scanner_bloc.dart';
import 'package:opennutritracker/features/scanner/scanner_screen.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// The app draws edge to edge, so the scanner's bottom button has to clear
/// the system navigation bar itself.
void main() {
  final getIt = GetIt.instance;

  setUp(() async {
    if (getIt.isRegistered<ScannerBloc>()) {
      await getIt.unregister<ScannerBloc>();
    }
    getIt.registerFactory<ScannerBloc>(
      () => ScannerBloc(_FakeSearchUseCase(), _FakeGetConfigUsecase()),
    );
  });

  tearDown(() async {
    if (getIt.isRegistered<ScannerBloc>()) {
      await getIt.unregister<ScannerBloc>();
    }
  });

  testWidgets('manual entry button sits above the navigation bar', (
    tester,
  ) async {
    const navBarHeight = 48.0;
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 800);
    tester.view.padding = const FakeViewPadding(bottom: navBarHeight);
    tester.view.viewPadding = const FakeViewPadding(bottom: navBarHeight);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [S.delegate],
        supportedLocales: S.supportedLocales,
        onGenerateRoute: (_) => MaterialPageRoute(
          settings: RouteSettings(
            arguments: ScannerScreenArguments(
              DateTime(2026, 5, 21),
              IntakeTypeEntity.breakfast,
            ),
          ),
          builder: (_) => const ScannerScreen(),
        ),
      ),
    );
    await tester.pump();

    final button = find.byType(OutlinedButton);
    expect(button, findsOneWidget);
    expect(
      tester.getBottomLeft(button).dy,
      lessThanOrEqualTo(800 - navBarHeight),
    );
  });
}

class _FakeSearchUseCase implements SearchProductByBarcodeUseCase {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeGetConfigUsecase implements GetConfigUsecase {
  @override
  Future<ConfigEntity> getConfig() async =>
      const ConfigEntity(true, true, false, AppThemeEntity.system);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}
