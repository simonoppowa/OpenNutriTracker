import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:opennutritracker/core/utils/barcode_validator.dart';
import 'package:opennutritracker/core/utils/calc/unit_calc.dart';
import 'package:opennutritracker/core/utils/custom_text_input_formatter.dart';
import 'package:opennutritracker/core/utils/extensions.dart';
import 'package:opennutritracker/core/utils/food_name_validator.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/edit_meal/presentation/bloc/edit_meal_bloc.dart';
import 'package:opennutritracker/features/edit_meal/presentation/widgets/default_meal_image.dart';
import 'package:opennutritracker/features/meal_detail/meal_detail_screen.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class EditMealScreen extends StatefulWidget {
  const EditMealScreen({super.key});

  @override
  State<EditMealScreen> createState() => _EditMealScreenState();
}

class _EditMealScreenState extends State<EditMealScreen> {
  final log = Logger('EditMealScreen');
  late MealEntity _mealEntity;
  late DateTime _day;
  late IntakeTypeEntity _intakeTypeEntity;
  late bool _usesImperialUnits;

  late bool _editOnly;

  late EditMealBloc _editMealBloc;

  final _nameTextController = TextEditingController();
  final _brandsTextController = TextEditingController();
  final _barcodeTextController = TextEditingController();
  final _mealQuantityTextController = TextEditingController();
  final _servingQuantityTextController = TextEditingController();
  final _baseQuantityTextController = TextEditingController();
  final _kcalTextController = TextEditingController();
  final _carbsTextController = TextEditingController();
  final _fatTextController = TextEditingController();
  final _proteinTextController = TextEditingController();

  final _units = ['g', 'ml', 'g/ml'];
  String? selectedUnit;
  bool _isTotal = false;
  // Default on so behaviour matches what existing users are used to — the
  // meal is saved to their custom list unless they actively untick the box.
  // #249 adds the *option* to skip the save; it does not change the default.
  bool _saveForLater = true;

  late List<ButtonSegment<String>> _mealUnitButtonSegment;

  // didChangeDependencies is called on every dependency change, including
  // ones triggered by Navigator pops returning from sub-pages (the barcode
  // scanner among them). Without this guard the controllers would get
  // re-seeded from _mealEntity.code on every return, wiping a value the
  // user just scanned into the field.
  bool _initialised = false;

  String baseQuantity = "100";
  String baseQuantityUnit = " g/ml";

  @override
  void initState() {
    super.initState();
    // Initialize once, not during build.
    _editMealBloc = locator<EditMealBloc>();
    _editMealBloc.add(InitializeEditMealEvent());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialised) return;
    _initialised = true;

    final args =
        ModalRoute.of(context)?.settings.arguments as EditMealScreenArguments;
    _mealEntity = args.mealEntity;
    _day = args.day;
    _intakeTypeEntity = args.intakeTypeEntity;
    _usesImperialUnits = args.usesImperialUnits;
    _editOnly = args.editOnly;

    _nameTextController.text = _mealEntity.name ?? "";
    _brandsTextController.text = _mealEntity.brands ?? "";
    // MealEntity.code is dual-purpose: it carries a real product barcode for
    // OFF / FDC scans, but for custom meals MealEntity.empty() seeds it with
    // an internal UUID that the user should never see in the Barcode input.
    // Only show codes that actually look like a retail barcode (8–14 digits);
    // anything else means there isn't a user-visible barcode yet.
    final existingCode = _mealEntity.code;
    _barcodeTextController.text =
        (existingCode != null && isBarcodeFormatValid(existingCode))
            ? existingCode
            : "";
    _mealQuantityTextController.text = _mealEntity.mealQuantity ?? "";
    _servingQuantityTextController.text =
        _mealEntity.servingQuantity.toStringOrEmpty();
    _kcalTextController.text =
        _mealEntity.nutriments.energyKcal100.toStringOrEmpty();
    _carbsTextController.text =
        _mealEntity.nutriments.carbohydrates100.toStringOrEmpty();
    _fatTextController.text = _mealEntity.nutriments.fat100.toStringOrEmpty();
    _proteinTextController.text =
        _mealEntity.nutriments.proteins100.toStringOrEmpty();
    selectedUnit = _switchButtonUnit(_mealEntity.mealUnit);

    // Convert meal size to imperial units if necessary
    if (_usesImperialUnits) {
      _mealQuantityTextController.text = _convertToImperial(
        _mealQuantityTextController.text,
        _mealEntity.mealUnit ?? "0",
      );
      _servingQuantityTextController.text = _convertToImperial(
        _servingQuantityTextController.text,
        _mealEntity.mealUnit ?? "0",
      );
    }

    _mealUnitButtonSegment = [
      ButtonSegment(
        value: _units[0],
        label: Text(
          _usesImperialUnits ? S.of(context).ozUnit : S.of(context).gramUnit,
        ),
      ),
      ButtonSegment(
        value: _units[1],
        label: Text(
          _usesImperialUnits
              ? S.of(context).flOzUnit
              : S.of(context).milliliterUnit,
        ),
      ),
      ButtonSegment(
        value: _units[2],
        label: Text(S.of(context).gramMilliliterUnit),
      ),
    ];
  }

  @override
  void dispose() {
    _nameTextController.dispose();
    _brandsTextController.dispose();
    _barcodeTextController.dispose();
    _mealQuantityTextController.dispose();
    _servingQuantityTextController.dispose();
    _baseQuantityTextController.dispose();
    _kcalTextController.dispose();
    _carbsTextController.dispose();
    _fatTextController.dispose();
    _proteinTextController.dispose();
    // Do not close _editMealBloc here if provided as a singleton by locator.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(S.of(context).editMealLabel),
          actions: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: FilledButton(
                onPressed: () => _onSavePressed(_usesImperialUnits),
                child: Text(S.of(context).buttonSaveLabel),
              ),
            ),
          ],
        ),
        body: BlocBuilder<EditMealBloc, EditMealState>(
          bloc: _editMealBloc,
          builder: (BuildContext context, EditMealState state) {
            if (state is EditMealLoadingState) {
              return _getLoadingContent();
            } else if (state is EditMealLoadedState) {
              return _getLoadedContent(state.usesImperialUnits);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _getLoadingContent() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _getLoadedContent(bool usesImperialUnits) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: ClipOval(
            child: CachedNetworkImage(
              cacheManager: locator<CacheManager>(),
              width: 120,
              height: 120,
              placeholder: (context, string) => const DefaultMealImage(),
              errorWidget: (context, exception, stacktrace) =>
                  const DefaultMealImage(),
              fit: BoxFit.cover,
              imageUrl: _mealEntity.mainImageUrl ?? "",
            ),
          ),
        ),
        const SizedBox(height: 32),
        TextFormField(
          controller: _nameTextController,
          decoration: InputDecoration(
            labelText: S.of(context).mealNameLabel,
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.text,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _brandsTextController,
          decoration: InputDecoration(
            labelText: S.of(context).mealBrandsLabel,
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.text,
        ),
        const SizedBox(height: 16),
        // Optional barcode (#167). Lets the user attach a code to a custom
        // meal so a future scan recalls the saved version directly without
        // round-tripping through Open Food Facts. The scan icon launches
        // the in-app camera; the result is validated by [BarcodeValidator]
        // before save (see _onSavePressed).
        Semantics(
          identifier: 'edit-meal-barcode-input',
          child: TextFormField(
            controller: _barcodeTextController,
            decoration: InputDecoration(
              labelText: S.of(context).customMealBarcodeLabel,
              hintText: S.of(context).customMealBarcodeHint,
              border: const OutlineInputBorder(),
              suffixIcon: Semantics(
                identifier: 'edit-meal-barcode-scan',
                child: IconButton(
                  tooltip: S.of(context).customMealBarcodeScanButton,
                  icon: const Icon(Icons.barcode_reader),
                  onPressed: _scanBarcodeIntoField,
                ),
              ),
            ),
            keyboardType: TextInputType.number,
          ),
        ),
        const SizedBox(height: 32),
        TextFormField(
          controller: _mealQuantityTextController,
          decoration: InputDecoration(
            labelText: _usesImperialUnits
                ? S.of(context).mealSizeLabelImperial
                : S.of(context).mealSizeLabel,
            border: const OutlineInputBorder(),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _servingQuantityTextController,
          inputFormatters: CustomTextInputFormatter.doubleOnly(),
          decoration: InputDecoration(
            labelText: _usesImperialUnits
                ? S.of(context).servingSizeLabelImperial
                : S.of(context).servingSizeLabelMetric,
            border: const OutlineInputBorder(),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 16),
        SegmentedButton<String>(
          segments: _mealUnitButtonSegment,
          selected: {selectedUnit ?? _units[2]},
          onSelectionChanged: (Set<String> newSelection) {
            setState(() {
              selectedUnit = newSelection.first;
            });
          },
        ),
        const SizedBox(height: 48),
        TextFormField(
          controller: _baseQuantityTextController,
          inputFormatters: CustomTextInputFormatter.doubleOnly(),
          decoration: InputDecoration(
              labelText: S.of(context).baseQuantityLabel,
              border: const OutlineInputBorder()),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 48),
        SegmentedButton<bool>(
          segments: [
            ButtonSegment(
              value: false,
              label: Text(S.of(context).mealNutrientsPerQtyLabel(
                  _getDisplayQuantity(), baseQuantityUnit.trim())),
            ),
            ButtonSegment(
              value: true,
              label: Text(S.of(context).mealNutrientsTotalLabel),
            ),
          ],
          selected: {_isTotal},
          onSelectionChanged: (Set<bool> newSelection) {
            setState(() {
              _isTotal = newSelection.first;
            });
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _kcalTextController,
          inputFormatters: CustomTextInputFormatter.doubleOnly(),
          decoration: InputDecoration(
              labelText: S.of(context).mealKcalLabel,
              helperText: _isTotal
                  ? S.of(context).mealNutrientsTotalLabel
                  : S.of(context).mealNutrientsPerQtyLabel(
                      _getDisplayQuantity(), baseQuantityUnit.trim()),
              border: const OutlineInputBorder()),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _carbsTextController,
          inputFormatters: CustomTextInputFormatter.doubleOnly(),
          decoration: InputDecoration(
              labelText: S.of(context).mealCarbsLabel,
              helperText: _isTotal
                  ? S.of(context).mealNutrientsTotalLabel
                  : S.of(context).mealNutrientsPerQtyLabel(
                      _getDisplayQuantity(), baseQuantityUnit.trim()),
              border: const OutlineInputBorder()),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _fatTextController,
          inputFormatters: CustomTextInputFormatter.doubleOnly(),
          decoration: InputDecoration(
              labelText: S.of(context).mealFatLabel,
              helperText: _isTotal
                  ? S.of(context).mealNutrientsTotalLabel
                  : S.of(context).mealNutrientsPerQtyLabel(
                      _getDisplayQuantity(), baseQuantityUnit.trim()),
              border: const OutlineInputBorder()),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _proteinTextController,
          inputFormatters: CustomTextInputFormatter.doubleOnly(),
          decoration: InputDecoration(
              labelText: S.of(context).mealProteinLabel,
              helperText: _isTotal
                  ? S.of(context).mealNutrientsTotalLabel
                  : S.of(context).mealNutrientsPerQtyLabel(
                      _getDisplayQuantity(), baseQuantityUnit.trim()),
              border: const OutlineInputBorder()),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        if (!_editOnly) ...[
          const SizedBox(height: 24),
          _SaveForLaterField(
            value: _saveForLater,
            onChanged: (newValue) {
              setState(() {
                _saveForLater = newValue;
              });
            },
          ),
        ],
      ],
    );
  }

  String _getDisplayQuantity() {
    final text = _baseQuantityTextController.text;
    return text.isEmpty ? baseQuantity : text;
  }

  Future<void> _onSavePressed(bool usesImperialUnits) async {
    try {
      // Validate meal name: non-empty and contains at least one letter (#211, #214)
      if (!FoodNameValidator.isValid(_nameTextController.text)) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.of(context).mealNameValidationError)));
        return;
      }

      // Validate barcode shape if the user typed or scanned one (#167).
      // Empty is fine — the field is optional. 8-14 digits required;
      // EAN-13 check digit must verify for codes of that exact length.
      final rawBarcode = _barcodeTextController.text.trim();
      if (rawBarcode.isNotEmpty) {
        if (!isBarcodeFormatValid(rawBarcode)) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(S.of(context).customMealBarcodeInvalid)));
          return;
        }
        if (!isEan13CheckDigitValid(rawBarcode)) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(S.of(context).barcodeInvalidEan13CheckDigit)));
          return;
        }
      }

      // Validate nutritional consistency (#213)
      final baseQty =
          double.tryParse(_baseQuantityTextController.text) ?? 100.0;
      final enteredKcal = double.tryParse(_kcalTextController.text);
      final enteredCarbs = double.tryParse(_carbsTextController.text);
      final enteredFat = double.tryParse(_fatTextController.text);
      final enteredProtein = double.tryParse(_proteinTextController.text);

      for (final entry in {
        'Carbs': enteredCarbs,
        'Fat': enteredFat,
        'Protein': enteredProtein,
      }.entries) {
        if (entry.value != null && entry.value! > baseQty) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  '${entry.key} cannot exceed base quantity (${baseQty}g/ml)')));
          return;
        }
      }

      if (enteredCarbs != null &&
          enteredFat != null &&
          enteredProtein != null) {
        final totalMacros = enteredCarbs + enteredFat + enteredProtein;
        if (totalMacros > baseQty * 1.05) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  'Total macros (${totalMacros.toStringAsFixed(1)}g) exceed base quantity (${baseQty.toStringAsFixed(0)}g)')));
          return;
        }
      }

      if (enteredKcal != null && enteredKcal > baseQty * 9) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text('Kcal value seems too high for ${baseQty.toStringAsFixed(0)}g/ml')));
        return;
      }

      // Atwater consistency check (#213): warn if entered kcal disagrees with
      // 4·carbs + 4·protein + 9·fat by more than 5%. Non-blocking — the
      // reporter explicitly asked that the user still be able to save if they
      // are sure of the numbers they typed. The 5% window is tight enough to
      // catch the reporter's example (kcal=0, protein=50g) and the common
      // typo class of "one macro forgotten by a factor of ten", while staying
      // above USDA rounding noise which in practice lives well under 5%.
      if (enteredKcal != null &&
          enteredCarbs != null &&
          enteredFat != null &&
          enteredProtein != null) {
        final expectedKcal =
            4 * enteredCarbs + 4 * enteredProtein + 9 * enteredFat;
        final delta = (enteredKcal - expectedKcal).abs();
        final ceiling = math.max(enteredKcal.abs(), expectedKcal.abs());
        if (ceiling > 0 && delta > 0.05 * ceiling) {
          final shouldSaveAnyway = await _showAtwaterWarningDialog();
          if (!mounted) return;
          if (shouldSaveAnyway != true) {
            return;
          }
        }
      }

      // Convert meal size back to metric units if necessary
      final mealUnitForConversion = selectedUnit ?? _mealEntity.mealUnit ?? '0';
      final mealQuantity = usesImperialUnits
          ? _convertToMetric(
              _mealQuantityTextController.text, mealUnitForConversion)
          : _mealQuantityTextController.text;

      // Convert total → per-base-qty if in total input mode
      String kcalText = _kcalTextController.text;
      String carbsText = _carbsTextController.text;
      String fatText = _fatTextController.text;
      String proteinText = _proteinTextController.text;
      if (_isTotal) {
        final mealQty = double.tryParse(mealQuantity) ?? 0.0;
        final baseQtyForConversion =
            double.tryParse(_baseQuantityTextController.text) ?? 100.0;
        if (mealQty > 0) {
          String convertTotal(String text) {
            final v = double.tryParse(text);
            if (v == null) return text;
            return ((v / mealQty) * baseQtyForConversion).toString();
          }

          kcalText = convertTotal(kcalText);
          carbsText = convertTotal(carbsText);
          fatText = convertTotal(fatText);
          proteinText = convertTotal(proteinText);
        }
      }

      final newMealEntity = _editMealBloc.createNewMealEntity(
        _mealEntity,
        _nameTextController.text,
        _brandsTextController.text,
        mealQuantity,
        _servingQuantityTextController.text,
        _baseQuantityTextController.text,
        selectedUnit,
        kcalText,
        carbsText,
        fatText,
        proteinText,
        // Empty-string clears the barcode; whitespace was already trimmed
        // during validation above so we can pass the raw value through.
        barcodeOverride: rawBarcode.isEmpty ? null : rawBarcode,
      );

      // Persist custom meal template (#267). Skipped for one-off entries
      // (#249) when the user has turned off "Save for next time" — the
      // intake itself is still logged below, but no template is kept.
      final shouldPersistTemplate = _editOnly || _saveForLater;
      if (newMealEntity.source == MealSourceEntity.custom &&
          shouldPersistTemplate) {
        await _editMealBloc.saveCustomMeal(newMealEntity);
      }

      if (!mounted) return;
      if (_editOnly) {
        Navigator.of(context).pop();
      } else {
        Navigator.of(context).pushNamedAndRemoveUntil(
          NavigationOptions.mealDetailRoute,
          ModalRoute.withName(NavigationOptions.addMealRoute),
          arguments: MealDetailScreenArguments(
            newMealEntity,
            _intakeTypeEntity,
            _day,
            usesImperialUnits,
          ),
        );
      }
    } catch (exception, stacktrace) {
      log.warning("Error while creating new meal entity");
      Sentry.captureException(exception, stackTrace: stacktrace);

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(S.of(context).errorMealSave)));
    }
  }

  /// Push a lightweight `MobileScanner` page that returns the first product
  /// barcode it sees, then drop the value into the barcode TextField. The
  /// scan-time validator on the field handles bad codes (8–14 digits,
  /// EAN-13 check digit) — we don't double-validate here so the user can
  /// see and edit the raw scanned value before saving.
  Future<void> _scanBarcodeIntoField() async {
    log.fine('Opening edit-meal barcode scanner');
    final navigator = Navigator.of(context);
    final result = await navigator.push<String?>(
      MaterialPageRoute(builder: (_) => const _EditMealBarcodeScanPage()),
    );
    log.fine('Edit-meal barcode scanner returned: $result');
    if (result == null) return;
    if (!mounted) return;
    setState(() {
      _barcodeTextController.text = result;
    });
    log.fine('Barcode text controller after set: ${_barcodeTextController.text}');
  }

  Future<bool?> _showAtwaterWarningDialog() {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(S.of(dialogContext).inconsistentNutritionWarningTitle),
          content: Text(S.of(dialogContext).inconsistentNutritionWarningBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(S.of(dialogContext).inconsistentNutritionWarningEdit),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                S.of(dialogContext).inconsistentNutritionWarningSaveAnyway,
              ),
            ),
          ],
        );
      },
    );
  }

  String? _switchButtonUnit(String? unit) {
    if (!_units.contains(unit)) {
      return _units[2]; // Default to g/ml
    }
    return unit;
  }

  String _convertToImperial(String value, String unit) {
    final double quantityValue = double.tryParse(value) ?? 0.0;
    switch (unit) {
      case 'g':
        return (UnitCalc.gToOz(quantityValue)).toStringAsFixed(2);
      case 'ml':
        return (UnitCalc.mlToFlOz(quantityValue)).toStringAsFixed(2);
      default:
        return value;
    }
  }

  String _convertToMetric(String value, String unit) {
    final double quantityValue = double.tryParse(value) ?? 0.0;
    switch (unit) {
      case 'g':
        return (UnitCalc.ozToG(quantityValue)).toStringAsFixed(2);
      case 'ml':
        return (UnitCalc.flOzToMl(quantityValue)).toStringAsFixed(2);
      default:
        return value;
    }
  }
}

class EditMealScreenArguments {
  final DateTime day;
  final MealEntity mealEntity;
  final IntakeTypeEntity intakeTypeEntity;
  final bool usesImperialUnits;
  final bool editOnly;

  EditMealScreenArguments(
    this.day,
    this.mealEntity,
    this.intakeTypeEntity,
    this.usesImperialUnits, {
    this.editOnly = false,
  });
}

/// "Save for next time" toggle shown on the create-and-log path (#249).
/// Defaults to off: the intake is logged today, and the user opts in here
/// to also keep the meal as a reusable template in the custom-meal list.
/// Leaving it off is the right call for one-off entries like a friend's
/// homemade dish or a restaurant meal that won't come back round.
class _SaveForLaterField extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SaveForLaterField({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              identifier: 'edit-meal-save-for-later',
              child: Checkbox(
                value: value,
                onChanged: (newValue) => onChanged(newValue ?? false),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.recipeSaveForLaterLabel,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s.recipeSaveForLaterDescription,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Minimal camera page used by [_EditMealScreenState._scanBarcodeIntoField].
/// Pops itself with the first product barcode it detects, or returns null
/// when the user taps the back button. We keep this private to the edit-meal
/// flow rather than reusing the full ScannerScreen because that screen runs
/// its own lookup-and-route logic that wouldn't fit a "give me the raw
/// string" use case.
class _EditMealBarcodeScanPage extends StatefulWidget {
  const _EditMealBarcodeScanPage();

  @override
  State<_EditMealBarcodeScanPage> createState() =>
      _EditMealBarcodeScanPageState();
}

class _EditMealBarcodeScanPageState extends State<_EditMealBarcodeScanPage> {
  static final _log = Logger('EditMealBarcodeScan');
  final MobileScannerController _controller = MobileScannerController();
  bool _done = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    _log.fine('onDetect: ${capture.barcodes.length} barcodes; '
        'types=${capture.barcodes.map((b) => b.type.name).toList()}; '
        'rawValues=${capture.barcodes.map((b) => b.rawValue).toList()}');
    if (_done) return;
    for (final b in capture.barcodes) {
      // Accept any non-null raw value. ML Kit's type classifier is reliable
      // for QR / data-matrix but sometimes labels a valid retail barcode as
      // `BarcodeType.unknown` depending on print quality and camera angle —
      // filtering strictly by `BarcodeType.product` was silently dropping
      // those. The save-time validator on the edit-meal screen does the
      // real "is this a valid barcode" check.
      final raw = b.rawValue;
      if (raw != null && raw.isNotEmpty) {
        _log.fine('Popping with rawValue=$raw (type=${b.type.name})');
        _done = true;
        Navigator.of(context).pop(raw);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).customMealBarcodeScanButton)),
      body: MobileScanner(controller: _controller, onDetect: _onDetect),
    );
  }
}
