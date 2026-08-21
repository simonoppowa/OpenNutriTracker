import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/scanner/data/product_not_found_exception.dart';
import 'package:opennutritracker/features/scanner/domain/usecase/search_product_by_barcode_usecase.dart';
import 'package:opennutritracker/features/scanner/presentation/scanner_bloc.dart';

/// Only ever reached if the bloc stops emitting altogether. Every fake here
/// settles on the next microtask, so this is slack against a hung stream
/// rather than a budget the machine can lose a race against — and it stays
/// strictly under `package:test`'s 30s default per-test timeout, so such a
/// hang surfaces as this file's own diagnostic instead of the harness's
/// generic one.
const _settleTimeout = Duration(seconds: 5);

void main() {
  group('ScannerBloc failure classification', () {
    final blocs = <ScannerBloc>[];

    /// Builds the bloc under test around a search that always fails with
    /// [error], and returns the failure state one scan settles on.
    Future<ScannerFailedState> scanFailingWith(Object error) {
      final searchUseCase = _FakeSearchUseCase(error);
      final subject = ScannerBloc(searchUseCase, _FakeGetConfigUsecase());
      blocs.add(subject);
      return _failureFor(subject, searchUseCase, '03299289');
    }

    tearDown(() async {
      for (final bloc in blocs) {
        await bloc.close();
      }
      blocs.clear();
    });

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

  // `emit` silently drops a state that compares equal to the current one, so
  // any field the screen reads has to be part of `props`. Neither omission
  // below is reachable today — a loading state always sits between two
  // failures, and a rescan always rebuilds the product — but both would turn
  // into a stale message on screen the moment that stopped being true, and
  // the failure would look like a rendering bug rather than an equality one.
  group('scanner state equality', () {
    test('two failures of different kinds are not equal', () {
      expect(
        const ScannerFailedState(ScannerFailedStateType.productNotFound),
        isNot(const ScannerFailedState(ScannerFailedStateType.error)),
        reason: 'the failure type decides which message the screen shows',
      );
    });

    test('two failures of the same kind are equal', () {
      expect(
        const ScannerFailedState(ScannerFailedStateType.productNotFound),
        const ScannerFailedState(ScannerFailedStateType.productNotFound),
      );
    });

    test('the same product in different units is not equal', () {
      final product = MealEntity.empty();

      expect(
        ScannerLoadedState(product: product, usesImperialUnits: true),
        isNot(ScannerLoadedState(product: product, usesImperialUnits: false)),
        reason: 'the unit decides how the serving reads',
      );
    });
  });

  // Pins the reason the equality bug is latent rather than live: the loading
  // state the bloc emits first is what separates two failures today, so both
  // arrive even with the old `props`. Deliberately not a guard for the fix
  // above — the equality group is that — but the thing that would have to
  // change for the fix to start mattering, and worth failing loudly if it
  // ever does.
  test('a second failure of a different kind reaches the screen', () async {
    final searchUseCase = _SwitchableSearchUseCase(ProductNotFoundException());
    final bloc = ScannerBloc(searchUseCase, _FakeGetConfigUsecase());
    addTearDown(bloc.close);

    final seen = <ScannerState>[];
    final subscription = bloc.stream.listen(seen.add);

    bloc.add(const ScannerLoadProductEvent(barcode: '03299289'));
    await bloc.stream
        .firstWhere((state) => state is ScannerFailedState)
        .timeout(_settleTimeout);

    searchUseCase.error = Exception('OFF HTTP 500');
    bloc.add(const ScannerLoadProductEvent(barcode: '03299289'));
    await bloc.stream
        .firstWhere((state) =>
            state is ScannerFailedState &&
            state.type == ScannerFailedStateType.error)
        .timeout(_settleTimeout);

    await subscription.cancel();

    expect(
      seen.whereType<ScannerFailedState>().map((state) => state.type),
      [ScannerFailedStateType.productNotFound, ScannerFailedStateType.error],
    );
  });
}

/// A search whose failure can be swapped between scans, so one bloc can be
/// driven through two different failures in a row.
class _SwitchableSearchUseCase implements SearchProductByBarcodeUseCase {
  _SwitchableSearchUseCase(this.error);

  Object error;

  @override
  Future<MealEntity> searchProductByBarcode(String barcode) async {
    throw error;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
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

/// Succeeds so the bloc's success path stays reachable — see [_failureFor].
/// The values are placeholders: these tests never reach that path, and the
/// only field the bloc reads there is `usesImperialFoodUnits`, left at its
/// default.
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
