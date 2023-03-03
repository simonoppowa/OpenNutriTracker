part of 'scanner_bloc.dart';

@immutable
abstract class ScannerEvent extends Equatable {
  const ScannerEvent();

  @override
  List<Object?> get props => [];
}

class ScannerLoadProductEvent extends ScannerEvent {
  final String barcode;

  const ScannerLoadProductEvent({required this.barcode});

  @override
  List<Object?> get props => [barcode];
}
