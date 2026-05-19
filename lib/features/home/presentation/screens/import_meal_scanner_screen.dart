import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:opennutritracker/core/data/data_source/custom_meal_data_source.dart';
import 'package:opennutritracker/core/data/data_source/remote_search_cache_data_source.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/usecase/save_recipe_usecase.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/retry_util.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_type.dart';
import 'package:opennutritracker/features/scanner/domain/usecase/search_product_by_barcode_usecase.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/home/domain/entity/shared_meal_payload.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';
import 'package:opennutritracker/features/recipes/presentation/bloc/recipes_bloc.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/custom_meals_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';


class ImportMealScannerArguments {
  final IntakeTypeEntity intakeTypeEntity;
  final AddMealType addMealType;
  final DateTime day;

  /// QR text already captured by the standard barcode scanner. When set,
  /// the import screen skips its own camera and goes straight to the
  /// confirm dialog so the user doesn't have to point the camera at the
  /// same QR twice.
  final String? initialCode;

  ImportMealScannerArguments(
    this.intakeTypeEntity,
    this.addMealType,
    this.day, {
    this.initialCode,
  });
}

class ImportMealScannerScreen extends StatefulWidget {
  const ImportMealScannerScreen({super.key});

  @override
  State<ImportMealScannerScreen> createState() =>
      _ImportMealScannerScreenState();
}

class _ImportMealScannerScreenState extends State<ImportMealScannerScreen> {
  late MealDetailBloc _mealDetailBloc;
  late SearchProductByBarcodeUseCase _searchProductByBarcodeUseCase;
  late IntakeTypeEntity _intakeTypeEntity;
  late AddMealType _addMealType;
  late DateTime _day;
  bool _isProcessing = false;

  @override
  void initState() {
    _mealDetailBloc = locator<MealDetailBloc>();
    _searchProductByBarcodeUseCase = locator<SearchProductByBarcodeUseCase>();
    super.initState();
  }

  bool _handledInitialCode = false;

  @override
  void didChangeDependencies() {
    final args = ModalRoute.of(context)?.settings.arguments
        as ImportMealScannerArguments;
    _intakeTypeEntity = args.intakeTypeEntity;
    _addMealType = args.addMealType;
    _day = args.day;
    super.didChangeDependencies();

    // If the standard scanner already captured the QR text, jump straight
    // to the confirm dialog instead of opening another camera.
    if (!_handledInitialCode && args.initialCode != null) {
      _handledInitialCode = true;
      _isProcessing = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _processCode(args.initialCode!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).importMealLabel),
        actions: [
          IconButton(
            icon: const Icon(Icons.keyboard_outlined),
            tooltip: S.of(context).pasteCodeLabel,
            onPressed: _showPasteCodeDialog,
          ),
        ],
      ),
      body: MobileScanner(
        controller: MobileScannerController(
          formats: const [BarcodeFormat.qrCode],
        ),
        onDetect: _onDetect,
      ),
    );
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;
    // Flip the flag synchronously, before any await, so a second
    // onDetect call queued by mobile_scanner while the QR is still
    // in frame can't pass the gate. Without this, two detections
    // fired in the same microtask window both reach the dialog.
    _isProcessing = true;
    await _processCode(raw);
  }

  Future<void> _showPasteCodeDialog() async {
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.of(ctx).pasteCodeLabel),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: S.of(ctx).pasteCodeHint,
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(S.of(ctx).dialogCancelLabel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: Text(S.of(ctx).importMealLabel),
          ),
        ],
      ),
    );
    if (code != null && code.isNotEmpty) {
      await _processCode(code);
    }
  }

  Future<void> _processCode(String raw) async {
    // Idempotent set — _onDetect flips the flag synchronously before
    // calling here, but the paste-code dialog path doesn't, so this
    // still needs to set it.
    setState(() => _isProcessing = true);

    var didPop = false;
    try {
      final payload = SharedMealPayload.fromJsonString(raw);
      if (!mounted) return;
      final confirmed = await _showConfirmDialog(payload);
      if (confirmed == true && mounted) {
        await _importItems(payload);
        _refreshPages();
        if (mounted) {
          Navigator.of(context).pop();
          didPop = true;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.of(context).importMealSuccessLabel)),
          );
        }
      }
    } on SharedMealParseException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).importMealErrorLabel)),
        );
      }
    } finally {
      // Don't reset the flag on the success-and-pop path. Navigator.pop
      // schedules the pop for the next frame, so a buffered onDetect
      // that mobile_scanner emits in the same microtask would otherwise
      // pass the gate and show a second confirm dialog — except by
      // then the scanner has popped, so the dialog appears on the
      // home screen.
      if (mounted && !didPop) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<bool?> _showConfirmDialog(SharedMealPayload payload) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          S.of(ctx).importMealConfirmTitle(payload.totalCount),
        ),
        content: Text(
          S.of(ctx).importMealConfirmContent(_addMealType.getTypeName(ctx)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(S.of(ctx).dialogCancelLabel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(S.of(ctx).dialogOKLabel),
          ),
        ],
      ),
    );
  }

  Future<void> _importItems(SharedMealPayload payload) async {
    final customMealDataSource = locator<CustomMealDataSource>();
    final remoteCache = locator<RemoteSearchCacheDataSource>();
    final saveRecipeUseCase = locator<SaveRecipeUseCase>();

    // Custom + FDC items: route to the right local store before logging the
    // intake. Custom snapshots become entries in the user's custom-meal
    // box; FDC snapshots populate the remote-search cache so future
    // searches hit them locally.
    for (final item in payload.items) {
      final meal = item.toMealEntity();
      if (item.source == MealSourceEntity.fdc) {
        await remoteCache.cache(MealDBO.fromMealEntity(meal));
      } else {
        await customMealDataSource.saveCustomMeal(MealDBO.fromMealEntity(meal));
      }
      if (!mounted) return;
      _mealDetailBloc.addIntake(
        context,
        item.unit,
        item.amount.toString(),
        _intakeTypeEntity,
        meal,
        _day,
      );
    }

    // Recipes: persist to the recipe box (so the user can re-log them later
    // from the Recipes tab) and create an intake from the recipe-as-meal.
    for (final recipeItem in payload.recipes) {
      final recipe = recipeItem.recipe.toRecipeEntity();
      final saved = await saveRecipeUseCase.save(recipe);
      if (!mounted) return;
      _mealDetailBloc.addIntake(
        context,
        recipeItem.unit,
        recipeItem.amount.toString(),
        _intakeTypeEntity,
        saved.toMealEntity(),
        _day,
      );
    }

    // OFF refs: barcode lookup already populates the cache via
    // SearchProductByBarcodeUseCase, so no extra cache write needed here.
    final offResults = await Future.wait(payload.offRefs.map((ref) async {
      try {
        final meal = await withRetry(
          () => _searchProductByBarcodeUseCase.searchProductByBarcode(ref.barcode),
        );
        return (ref: ref, meal: meal);
      } catch (_) {
        return null;
      }
    }));

    if (!mounted) return;

    var skipped = 0;
    for (final r in offResults) {
      if (r != null) {
        _mealDetailBloc.addIntake(context, r.ref.unit, r.ref.amount.toString(),
            _intakeTypeEntity, r.meal, _day);
      } else {
        skipped++;
      }
    }

    if (skipped > 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(S.of(context).importOffFetchFailedLabel(skipped))),
      );
    }
  }

  void _refreshPages() {
    locator<HomeBloc>().add(const LoadItemsEvent());
    locator<DiaryBloc>().add(const LoadDiaryYearEvent());
    locator<CalendarDayBloc>().add(RefreshCalendarDayEvent());
    // The shared meal may have populated the user's custom-meal box and/or
    // recipe box. Refresh those screens so the new entries surface
    // immediately when the user navigates back.
    locator<CustomMealsBloc>().add(LoadCustomMealsEvent());
    locator<RecipesBloc>().add(const LoadRecipesEvent());
  }
}
