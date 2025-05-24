import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/scanner/data/product_not_found_exception.dart';
import 'package:opennutritracker/features/scanner/domain/usecase/search_product_by_barcode_usecase.dart';

part 'scanner_event.dart';

part 'scanner_state.dart';

class ScannerBloc extends Bloc<ScannerEvent, ScannerState> {
  final SearchProductByBarcodeUseCase _searchProductUseCase;
  final GetConfigUsecase _getConfigUsecase;

  ScannerBloc(this._searchProductUseCase, this._getConfigUsecase)
      : super(ScannerInitial()) {
    on<ScannerLoadProductEvent>((event, emit) async {
      emit(ScannerLoadingState());

      try {
        final result = await _searchProductUseCase.searchProductByBarcode(
          event.barcode,
        );
        final config = await _getConfigUsecase.getConfig();
        emit(
          ScannerLoadedState(
            product: result,
            usesImperialUnits: config.usesImperialUnits,
          ),
        );
      } catch (exception) {
        if (exception == ProductNotFoundException) {
          emit(
            const ScannerFailedState(ScannerFailedStateType.productNotFound),
          );
        } else {
          emit(const ScannerFailedState(ScannerFailedStateType.error));
        }
      }
    });
  }
}
