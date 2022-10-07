import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/item_detail/item_detail_screen.dart';
import 'package:opennutritracker/features/scanner/presentation/scanner_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';

class ScannerScreen extends StatelessWidget {
  final log = Logger('ScannerScreen');

  ScannerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scannerBloc = ScannerBloc();
    return BlocBuilder<ScannerBloc, ScannerState>(
      bloc: scannerBloc,
      builder: (context, state) {
        if (state is ScannerInitial) {
          return _getScannerContent(context, scannerBloc);
        } else if (state is ScannerLoadingState) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (state is ScannerLoadedState) {
          // Push new route after build
          Future.microtask(() => Navigator.of(context).pushReplacementNamed(
              NavigationOptions.itemDetailRoute,
              arguments: ItemDetailScreenArguments(state.product)));
        }
        return const SizedBox();
      },
    );
  }

  Scaffold _getScannerContent(BuildContext context, ScannerBloc scannerBloc) {
    final cameraController = MobileScannerController();
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).scanProductLabel),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: cameraController.torchState,
              builder: (context, state, child) {
                switch (state) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off_outlined,
                        color: Colors.grey);
                  case TorchState.on:
                    return const Icon(Icons.flash_on_outlined);
                }
              },
            ),
            onPressed: () => cameraController.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_android_outlined),
            onPressed: () => cameraController.switchCamera(),
          ),
        ],
      ),
      body: MobileScanner(
        controller: cameraController,
        allowDuplicates: false,
        onDetect: (barcode, args) {
          if (barcode.rawValue != null && barcode.type == BarcodeType.product) {
            final productCode = barcode.rawValue;
            if (productCode != null) {
              // TODO check barcode validity
              log.fine('Barcode found: $productCode');
              scannerBloc.add(ScannerLoadProductEvent(barcode: productCode));
            }
          }
        },
      ),
    );
  }
}
