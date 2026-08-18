import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/scanner/data/product_not_found_exception.dart';
import 'package:opennutritracker/features/scanner/domain/usecase/search_product_by_barcode_usecase.dart';
import 'package:opennutritracker/features/scanner/presentation/scanner_bloc.dart';

void main() {
  group('ScannerBloc failure classification', () {
    late _FakeSearchUseCase searchUseCase;
    late ScannerBloc bloc;

    setUp(() {
      searchUseCase = _FakeSearchUseCase();
      bloc = ScannerBloc(searchUseCase, _FakeGetConfigUsecase());
    });

    tearDown(() => bloc.close());

    test(
      'a not-found barcode reports productNotFound, not a fetch error',
      () async {
        searchUseCase.error = ProductNotFoundException();

        final state = await _failureFor(bloc, '03299289');

        expect(state.type, ScannerFailedStateType.productNotFound);
      },
    );

    test('any other failure reports a generic error', () async {
      searchUseCase.error = Exception('OFF HTTP 500');

      final state = await _failureFor(bloc, '03299289');

      expect(state.type, ScannerFailedStateType.error);
    });
  });
}

/// Drives one scan and returns the [ScannerFailedState] it settles on.
Future<ScannerFailedState> _failureFor(ScannerBloc bloc, String barcode) async {
  final failed = bloc.stream.whereType<ScannerFailedState>().first;
  bloc.add(ScannerLoadProductEvent(barcode: barcode));
  return failed;
}

extension _WhereType on Stream<ScannerState> {
  Stream<T> whereType<T>() => where((state) => state is T).cast<T>();
}

class _FakeSearchUseCase implements SearchProductByBarcodeUseCase {
  Object? error;

  @override
  Future<MealEntity> searchProductByBarcode(String barcode) async {
    throw error!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeGetConfigUsecase implements GetConfigUsecase {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}
