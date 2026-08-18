import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/scanner/data/product_not_found_exception.dart';
import 'package:opennutritracker/features/scanner/domain/usecase/search_product_by_barcode_usecase.dart';
import 'package:opennutritracker/features/scanner/presentation/scanner_bloc.dart';

/// Only ever reached if the bloc stops emitting altogether: every fake here
/// completes on the next microtask, so this is slack against a hung stream,
/// not a budget the machine can lose a race against.
const _settleTimeout = Duration(seconds: 30);

void main() {
  group('ScannerBloc failure classification', () {
    ScannerBloc? bloc;

    /// Builds the bloc under test around a search that always fails with
    /// [error], and returns the failure state one scan settles on.
    Future<ScannerFailedState> scanFailingWith(Object error) {
      final searchUseCase = _FakeSearchUseCase(error);
      final subject = ScannerBloc(searchUseCase, _FakeGetConfigUsecase());
      bloc = subject;
      return _failureFor(subject, searchUseCase, '03299289');
    }

    tearDown(() => bloc?.close());

    test('a not-found barcode reports productNotFound, not a fetch error',
        () async {
      final state = await scanFailingWith(ProductNotFoundException());

      expect(state.type, ScannerFailedStateType.productNotFound);
    });

    test('any other failure reports a generic error', () async {
      final state = await scanFailingWith(Exception('OFF HTTP 500'));

      expect(state.type, ScannerFailedStateType.error);
    });
  });
}

/// Drives one scan and returns the [ScannerFailedState] it settles on.
///
/// Asserts the settled state is a failure rather than filtering for one. The
/// search always throws, so the only way a [ScannerLoadedState] can arrive is
/// the bloc dropping that exception — which this catches with a readable diff
/// instead of a green run. Config lookup deliberately succeeds so that path
/// stays reachable; a throwing config fake would funnel it back into the same
/// catch and hide the very failure being guarded against.
///
/// Also asserts the barcode reached [searchUseCase], so a throw from anywhere
/// else — a misused fake, or a future reordering that queries config first —
/// cannot masquerade as the classification under test.
Future<ScannerFailedState> _failureFor(
  ScannerBloc bloc,
  _FakeSearchUseCase searchUseCase,
  String barcode,
) async {
  final settled = bloc.stream
      .firstWhere((state) => state is! ScannerLoadingState)
      .timeout(_settleTimeout);
  bloc.add(ScannerLoadProductEvent(barcode: barcode));
  final state = await settled;

  expect(searchUseCase.calls, [barcode],
      reason: 'the barcode should have reached the search use case');
  expect(state, isA<ScannerFailedState>());
  return state as ScannerFailedState;
}

class _FakeSearchUseCase implements SearchProductByBarcodeUseCase {
  _FakeSearchUseCase(this.error);

  final Object error;
  final List<String> calls = [];

  @override
  Future<MealEntity> searchProductByBarcode(String barcode) async {
    calls.add(barcode);
    throw error;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeGetConfigUsecase implements GetConfigUsecase {
  @override
  Future<ConfigEntity> getConfig() async => const ConfigEntity(
        true,
        true,
        false,
        AppThemeEntity.system,
      );

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}
