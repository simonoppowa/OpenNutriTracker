import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/features/addItem/domain/entity/product_entity.dart';
import 'package:opennutritracker/features/scanner/domain/usecase/search_product_by_barcode_usecase.dart';

part 'scanner_event.dart';

part 'scanner_state.dart';

class ScannerBloc extends Bloc<ScannerEvent, ScannerState> {
  final searchProductUseCase = SearchProductByBarcodeUseCase();

  ScannerBloc() : super(ScannerInitial()) {
    on<ScannerLoadProductEvent>((event, emit) async {
      emit(ScannerLoadingState());

      final result =
          await searchProductUseCase.searchProductByBarcode(event.barcode);
      emit(ScannerLoadedState(product: result));
    });
  }
}
