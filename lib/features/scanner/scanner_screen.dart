import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/meal_detail/meal_detail_screen.dart';
import 'package:opennutritracker/features/scanner/presentation/scanner_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({Key? key}) : super(key: key);

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final log = Logger('ScannerScreen');

  late IntakeTypeEntity intakeTypeEntity;

  @override
  void didChangeDependencies() {
    final args =
        ModalRoute.of(context)?.settings.arguments as ScannerScreenArguments;
    intakeTypeEntity = args.intakeTypeEntity;
    super.didChangeDependencies();
  }

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
              arguments:
                  MealDetailScreenArguments(state.product, intakeTypeEntity)));
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

class ScannerScreenArguments {
  final IntakeTypeEntity intakeTypeEntity;

  ScannerScreenArguments(this.intakeTypeEntity);
}
