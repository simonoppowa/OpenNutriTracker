import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/presentation/scanner_orientation_mixin.dart';
import 'package:opennutritracker/core/presentation/widgets/error_dialog.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/core/utils/shared_payload_router.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_type.dart';
import 'package:opennutritracker/features/home/presentation/screens/import_activity_scanner_screen.dart';
import 'package:opennutritracker/features/home/presentation/screens/import_meal_scanner_screen.dart';
import 'package:opennutritracker/features/meal_detail/meal_detail_screen.dart';
import 'package:opennutritracker/features/recipes/presentation/screens/import_recipe_scanner_screen.dart';
import 'package:opennutritracker/features/scanner/presentation/scanner_bloc.dart';
import 'package:opennutritracker/features/scanner/util/barcode_check_digit.dart';
import 'package:opennutritracker/generated/l10n.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with WidgetsBindingObserver, ScannerOrientationMixin {
  final log = Logger('ScannerScreen');

  String? _scannedBarcode;
  IntakeTypeEntity? _intakeTypeEntity;
  DateTime? _day;
  bool _pickMode = false;
  // BlocBuilder can rebuild for [ScannerLoadedState] more than once before
  // the scanner route is fully unmounted (e.g. the route-transition's
  // parent rebuild propagates down). Without this latch, the second
  // microtask races against the now-removed scanner and ends up popping
  // whichever route is on top — in the recipe ingredient flow that's the
  // quantity-dialog bottom sheet, which then crashes with a result-type
  // mismatch. The latch makes the post-load navigation idempotent.
  bool _navigatedAfterLoad = false;

  late ScannerBloc _scannerBloc;
  // MobileScanner stops but doesn't dispose externally-owned controllers.
  late final MobileScannerController _cameraController;

  @override
  void initState() {
    super.initState();
    _scannerBloc = locator<ScannerBloc>();
    _cameraController = MobileScannerController();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_cameraController.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_cameraController.value.hasCameraPermission) return;
    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        unawaited(_cameraController.stop());
      case AppLifecycleState.resumed:
        unawaited(_cameraController.start());
      case AppLifecycleState.inactive:
        break;
    }
  }

  @override
  void didChangeDependencies() {
    final args =
        ModalRoute.of(context)?.settings.arguments as ScannerScreenArguments;
    _intakeTypeEntity = args.intakeTypeEntity;
    _day = args.day;
    _pickMode = args.pickMode;
    if (args.initialBarcode != null && _scannedBarcode == null) {
      _scannedBarcode = args.initialBarcode;
      _scannerBloc.add(ScannerLoadProductEvent(barcode: args.initialBarcode!));
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = isDark ? AppPalette.dark : AppPalette.light;
    return BlocBuilder<ScannerBloc, ScannerState>(
      bloc: _scannerBloc,
      builder: (context, state) {
        if (state is ScannerInitial) {
          if (_scannedBarcode != null) {
            return Scaffold(
              backgroundColor: palette.canvas,
              appBar: AppBar(backgroundColor: palette.canvas),
              body: const Center(child: CircularProgressIndicator()),
            );
          }
          return _getScannerContent(context);
        } else if (state is ScannerLoadingState) {
          return Scaffold(
            backgroundColor: palette.canvas,
            appBar: AppBar(backgroundColor: palette.canvas),
            body: const Center(child: CircularProgressIndicator()),
          );
        } else if (state is ScannerLoadedState) {
          // Push new route after build
          if (!_navigatedAfterLoad) {
            _navigatedAfterLoad = true;
            Future.microtask(() {
              if (!context.mounted) return;
              if (_pickMode) {
                // Recipe ingredient picker — hand the loaded MealEntity back
                // to whoever pushed us instead of routing into the meal-detail
                // logging flow.
                Navigator.of(context).pop(state.product);
                return;
              }
              Navigator.of(context).pushReplacementNamed(
                NavigationOptions.mealDetailRoute,
                arguments: MealDetailScreenArguments(
                  state.product,
                  _intakeTypeEntity!,
                  _day!,
                  state.usesImperialUnits,
                ),
              );
            });
          }
        } else if (state is ScannerFailedState) {
          return Scaffold(
            backgroundColor: palette.canvas,
            appBar: AppBar(backgroundColor: palette.canvas),
            body: Center(
              child: ErrorDialog(
                errorText: state.type == ScannerFailedStateType.productNotFound
                    ? S.of(context).errorProductNotFound
                    : S.of(context).errorFetchingProductData,
                onRefreshPressed: _onRefreshButtonPressed,
              ),
            ),
          );
        }
        return const SizedBox();
      },
    );
  }

  Scaffold _getScannerContent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = isDark ? AppPalette.dark : AppPalette.light;
    return Scaffold(
      backgroundColor: palette.canvas,
      appBar: AppBar(
        backgroundColor: palette.canvas,
        toolbarHeight: MediaQuery.textScalerOf(context).scale(kToolbarHeight),
        title: Text(
          S.of(context).scanProductLabel,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _cameraController,
              builder: (context, state, child) {
                switch (state.torchState) {
                  case TorchState.off || TorchState.unavailable:
                    return Icon(
                      Icons.flash_off_rounded,
                      color: palette.textMuted,
                    );
                  case TorchState.on || TorchState.auto:
                    return const Icon(Icons.flash_on_rounded);
                }
              },
            ),
            onPressed: () => _cameraController.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_android_rounded),
            onPressed: () => _cameraController.switchCamera(),
          ),
          buildPortraitLockAction(context),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(
              controller: _cameraController,
              onDetect: (capture) {
                if (_scannedBarcode != null) return;
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  final raw = barcode.rawValue;
                  if (raw == null) continue;

                  // Shared-QR codes generated by the app's share dialog
                  // arrive as plain text/url (not BarcodeType.product). If
                  // one of these is recognised, hand off to the matching
                  // import screen with the already-scanned code so the
                  // user doesn't have to scan a second time. In pick mode
                  // (recipe ingredient picker) we ignore these — handing
                  // off would silently abandon the recipe builder mid-edit,
                  // and a shared meal/recipe/activity isn't a single
                  // ingredient anyway.
                  if (!_pickMode) {
                    final kind = classifySharedPayload(raw);
                    if (kind != null) {
                      _scannedBarcode = raw;
                      log.fine('Shared payload found: $kind');
                      _routeToSharedImport(kind, raw);
                      return;
                    }
                  }

                  if (barcode.type == BarcodeType.product) {
                    _scannedBarcode = raw;
                    log.fine('Barcode found: $raw');
                    _scannerBloc.add(ScannerLoadProductEvent(barcode: raw));
                  }
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Dimens.spacing16),
            child: Semantics(
              identifier: 'scanner-manual-entry-open',
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  shape: Dimens.shapeM,
                  side: BorderSide(color: palette.border, width: Dimens.hairline),
                  padding: const EdgeInsets.symmetric(vertical: Dimens.spacing16),
                ),
                icon: const Icon(Icons.keyboard_rounded),
                label: Text(S.of(context).scannerManualEntryButton),
                onPressed: () => _showManualEntryDialog(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showManualEntryDialog(BuildContext context) async {
    final controller = TextEditingController();
    final rootMessenger = ScaffoldMessenger.of(context);
    final invalidMessage = S.of(context).scannerManualEntryInvalid;

    final submitted = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: Dimens.shapeL,
          title: Text(S.of(dialogContext).scannerManualEntryDialogTitle),
          content: Semantics(
            identifier: 'scanner-manual-entry-field',
            child: TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(14),
              ],
              decoration: InputDecoration(
                hintText: S.of(dialogContext).scannerManualEntryFieldHint,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(S.of(dialogContext).scannerManualEntryCancel),
            ),
            Semantics(
              identifier: 'scanner-manual-entry-submit',
              child: TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()),
                child: Text(S.of(dialogContext).scannerManualEntrySubmit),
              ),
            ),
          ],
        );
      },
    );

    if (!mounted) return;
    if (submitted == null || submitted.isEmpty) return;

    if (!isValidBarcodeCheckDigit(submitted)) {
      rootMessenger.showSnackBar(SnackBar(content: Text(invalidMessage)));
      return;
    }

    _scannedBarcode = submitted;
    log.fine('Manual barcode entered: $submitted');
    _scannerBloc.add(ScannerLoadProductEvent(barcode: submitted));
  }

  void _routeToSharedImport(SharedPayloadKind kind, String code) {
    // Pick-mode skips shared-payload handling entirely (see onDetect), so
    // by the time we land here `_intakeTypeEntity` and `_day` were set from
    // the logging-flow args.
    final intakeType = _intakeTypeEntity!;
    final day = _day!;
    final navigator = Navigator.of(context);
    Future.microtask(() {
      if (!mounted) return;
      switch (kind) {
        case SharedPayloadKind.meal:
          navigator.pushReplacementNamed(
            NavigationOptions.importMealScannerRoute,
            arguments: ImportMealScannerArguments(
              intakeType,
              AddMealExtension.fromIntakeTypeEntity(intakeType),
              day,
              initialCode: code,
            ),
          );
        case SharedPayloadKind.activity:
          navigator.pushReplacementNamed(
            NavigationOptions.importActivityScannerRoute,
            arguments: ImportActivityScannerArguments(initialCode: code),
          );
        case SharedPayloadKind.recipe:
          navigator.pushReplacementNamed(
            NavigationOptions.importRecipeScannerRoute,
            arguments: ImportRecipeScannerArguments(initialCode: code),
          );
      }
    });
  }

  void _onRefreshButtonPressed() {
    final barcode = _scannedBarcode;
    if (barcode != null) {
      _scannerBloc.add(ScannerLoadProductEvent(barcode: barcode));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).errorFetchingProductData)),
      );
    }
  }
}

class ScannerScreenArguments {
  // `day` and `intakeTypeEntity` are required for the normal logging flow
  // (the scanner routes into MealDetailScreen, which needs both). In
  // [ScannerScreenArguments.pick] they're left null because the screen
  // simply pops the scanned [MealEntity] back to its caller — the recipe
  // ingredient picker doesn't yet know which day or intake the user will
  // attach it to.
  final DateTime? day;
  final IntakeTypeEntity? intakeTypeEntity;
  final String? initialBarcode;
  final bool pickMode;

  ScannerScreenArguments(
    DateTime forDay,
    IntakeTypeEntity forIntakeType, {
    this.initialBarcode,
  })  : day = forDay,
        intakeTypeEntity = forIntakeType,
        pickMode = false;

  /// Opens the scanner in "pick" mode: on a successful product load it pops
  /// the resulting [MealEntity] back to the caller instead of routing into
  /// the meal-detail logging screen. Used by the recipe ingredient picker.
  ScannerScreenArguments.pick({this.initialBarcode})
      : day = null,
        intakeTypeEntity = null,
        pickMode = true;
}
