import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:opennutritracker/core/domain/entity/recipe_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/user_image_picker_tile.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/core/utils/id_generator.dart';
import 'package:opennutritracker/core/utils/user_image_storage.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/edit_meal/domain/nutrition_import_parser.dart';
import 'package:opennutritracker/features/edit_meal/presentation/nutrition_import_dialog.dart';
import 'package:opennutritracker/features/edit_meal/presentation/nutrition_import_saver.dart';
import 'package:opennutritracker/features/edit_meal/presentation/bloc/edit_meal_bloc.dart';
import 'package:opennutritracker/features/recipes/presentation/bloc/recipe_builder_bloc.dart';
import 'package:opennutritracker/features/recipes/presentation/widgets/food_search_tab_view.dart';
import 'package:opennutritracker/features/recipes/presentation/widgets/ingredient_list_item.dart';
import 'package:opennutritracker/features/recipes/presentation/widgets/ingredient_quantity_dialog.dart';
import 'package:opennutritracker/features/recipes/presentation/widgets/recipe_nutrition_summary.dart';
import 'package:opennutritracker/features/scanner/scanner_screen.dart';
import 'package:opennutritracker/generated/l10n.dart';

class RecipeBuilderArguments {
  final RecipeEntity? existing;
  const RecipeBuilderArguments({this.existing});
}

class RecipeBuilderScreen extends StatefulWidget {
  const RecipeBuilderScreen({super.key});

  @override
  State<RecipeBuilderScreen> createState() => _RecipeBuilderScreenState();
}

class _RecipeBuilderScreenState extends State<RecipeBuilderScreen> {
  late RecipeBuilderBloc _bloc;
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _servingsController;
  late TextEditingController _totalWeightController;
  late TextEditingController _tagsController;

  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _bloc = locator<RecipeBuilderBloc>();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _servingsController = TextEditingController();
    _totalWeightController = TextEditingController();
    _tagsController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final args =
          ModalRoute.of(context)?.settings.arguments as RecipeBuilderArguments?;
      _bloc.add(InitializeBuilderEvent(existing: args?.existing));
      if (args?.existing != null) {
        final r = args!.existing!;
        _nameController.text = r.name;
        _descriptionController.text = r.description ?? '';
        _servingsController.text = r.servingsCount?.toString() ?? '';
        _totalWeightController.text = r.totalWeightG.toStringAsFixed(0);
        _tagsController.text = r.tags.join(', ');
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _servingsController.dispose();
    _totalWeightController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  InputBorder _fieldBorder(AppPalette palette) {
    return OutlineInputBorder(
      borderRadius: Dimens.borderRadiusS,
      borderSide: BorderSide(color: palette.border, width: Dimens.hairline),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = isDark ? AppPalette.dark : AppPalette.light;
    final fieldBorder = _fieldBorder(palette);
    return BlocConsumer<RecipeBuilderBloc, RecipeBuilderState>(
      bloc: _bloc,
      listener: (context, state) {
        if (state.didSave) {
          Navigator.of(context).pop();
          return;
        }
        // Sync the auto-computed total weight into the controller so the
        // user sees the running sum until they manually override it.
        if (!state.totalWeightOverridden) {
          final newText = state.totalWeightG.toStringAsFixed(0);
          if (_totalWeightController.text != newText) {
            _totalWeightController.text = newText;
          }
        }
        if (state.saveError != null) {
          _showSaveError(context, state.saveError!);
        }
      },
      builder: (context, state) {
        return PopScope(
          canPop: !_hasUnsavedChanges(state),
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            final shouldDiscard = await _confirmDiscard(context);
            if (shouldDiscard == true && context.mounted) {
              Navigator.of(context).pop();
            }
          },
          child: Scaffold(
            appBar: AppBar(
              toolbarHeight: MediaQuery.textScalerOf(
                context,
              ).scale(kToolbarHeight),
              title: Text(
                state.isExistingRecipe
                    ? S.of(context).editRecipeTitle
                    : S.of(context).createRecipeTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              actions: [
                if (state.isSaving)
                  const Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                else
                  Semantics(
                    identifier: 'recipe-builder-save',
                    child: TextButton.icon(
                      onPressed: () => _bloc.add(const SaveRecipeEvent()),
                      icon: const Icon(Icons.save_outlined),
                      label: Text(S.of(context).recipeSaveLabel),
                    ),
                  ),
              ],
            ),
            body: ListView(
              padding: const EdgeInsets.all(Dimens.spacing16),
              children: [
                UserImagePickerTile(
                  kind: UserImageKind.recipe,
                  imagePath: state.imagePath,
                  onPickFromGallery: () =>
                      _onPickImage(context, source: ImageSource.gallery),
                  onTakePhoto: () =>
                      _onPickImage(context, source: ImageSource.camera),
                  onRemove: () => _onRemoveImage(context),
                ),
                const SizedBox(height: Dimens.spacing16),
                Semantics(
                  identifier: 'recipe-builder-paste-nutrition',
                  child: OutlinedButton.icon(
                    onPressed: () => _openNutritionPaste(context),
                    icon: const Icon(Icons.content_paste_outlined),
                    label: Text(S.of(context).nutritionPasteAction),
                  ),
                ),
                const SizedBox(height: Dimens.spacing12),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: S.of(context).recipeNameLabel,
                    border: fieldBorder,
                    enabledBorder: fieldBorder,
                  ),
                  onChanged: (v) => _bloc.add(UpdateNameEvent(v)),
                ),
                const SizedBox(height: Dimens.spacing12),
                TextField(
                  controller: _descriptionController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: S.of(context).recipeDescriptionLabel,
                    border: fieldBorder,
                    enabledBorder: fieldBorder,
                  ),
                  onChanged: (v) => _bloc.add(UpdateDescriptionEvent(v)),
                ),
                const SizedBox(height: Dimens.spacing12),
                TextField(
                  controller: _servingsController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: S.of(context).recipeServingsCountLabel,
                    helperText: S.of(context).recipeServingsCountHelper,
                    helperMaxLines: 2,
                    border: fieldBorder,
                    enabledBorder: fieldBorder,
                  ),
                  onChanged: (v) {
                    final parsed = v.trim().isEmpty ? null : int.tryParse(v);
                    _bloc.add(UpdateServingsCountEvent(parsed));
                  },
                ),
                const SizedBox(height: Dimens.spacing12),
                TextField(
                  controller: _tagsController,
                  decoration: InputDecoration(
                    labelText: S.of(context).recipeTagsLabel,
                    helperText: S.of(context).recipeTagsHelper,
                    helperMaxLines: 2,
                    border: fieldBorder,
                    enabledBorder: fieldBorder,
                  ),
                  onChanged: (v) {
                    final parsed = v
                        .split(',')
                        .map((t) => t.trim())
                        .where((t) => t.isNotEmpty)
                        .toList();
                    _bloc.add(UpdateTagsEvent(parsed));
                  },
                ),
                const SizedBox(height: Dimens.spacing24),
                Text(
                  S.of(context).recipeIngredientsLabel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: Dimens.spacing8),
                if (state.ingredients.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: Dimens.spacing16,
                    ),
                    child: Center(
                      child: Text(
                        S.of(context).recipeNoIngredientsLabel,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: palette.textMuted,
                        ),
                      ),
                    ),
                  )
                else
                  ...List.generate(
                    state.ingredients.length,
                    (i) => IngredientListItem(
                      ingredient: state.ingredients[i],
                      onEdit: () => _onEditIngredient(context, i),
                      onRemove: () => _bloc.add(RemoveIngredientEvent(i)),
                    ),
                  ),
                const SizedBox(height: Dimens.spacing8),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: Dimens.spacing16,
                    ),
                    side: BorderSide(
                      color: palette.border,
                      width: Dimens.hairline,
                    ),
                    shape: Dimens.shapeM,
                  ),
                  onPressed: () => _onAddIngredient(context),
                  icon: const Icon(Icons.add_rounded),
                  label: Text(S.of(context).recipeAddIngredientLabel),
                ),
                const SizedBox(height: Dimens.spacing24),
                TextField(
                  controller: _totalWeightController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+([.,]\d{0,2})?$'),
                    ),
                  ],
                  decoration: InputDecoration(
                    labelText: S.of(context).recipeTotalWeightLabel,
                    // Says which of the two the number is, since nothing else
                    // on screen does unless the ingredients are added up.
                    helperText: state.totalWeightOverridden
                        ? S.of(context).recipeTotalWeightManualHelper
                        : S.of(context).recipeTotalWeightCalculatedHelper,
                    helperMaxLines: 3,
                    border: fieldBorder,
                    enabledBorder: fieldBorder,
                  ),
                  onChanged: (v) {
                    final raw = v.replaceAll(',', '.');
                    final parsed = double.tryParse(raw);
                    if (parsed != null && parsed > 0) {
                      _bloc.add(UpdateTotalWeightEvent(parsed));
                    }
                  },
                ),
                // The way back from a typed weight. Without it the only route
                // was typing the exact ingredient sum and reopening the recipe.
                if (state.totalWeightOverridden)
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Semantics(
                      identifier: 'recipe-builder-weight-reset',
                      child: TextButton.icon(
                        onPressed: () =>
                            _bloc.add(const ResetTotalWeightEvent()),
                        icon: const Icon(Icons.calculate_outlined),
                        label: Text(
                          S
                              .of(context)
                              .recipeTotalWeightUseIngredientTotalButton,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: Dimens.spacing16),
                RecipeNutritionSummary(
                  nutrimentsPer100: state.aggregatedNutrimentsPer100,
                  totalWeightG: state.totalWeightG,
                ),
                const SizedBox(height: Dimens.spacing32),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _hasUnsavedChanges(RecipeBuilderState state) {
    if (state.didSave || state.isSaving) return false;
    return state.name.trim().isNotEmpty ||
        (state.description?.trim().isNotEmpty ?? false) ||
        state.ingredients.isNotEmpty ||
        state.servingsCount != null ||
        state.tags.isNotEmpty ||
        state.imagePath != null;
  }

  Future<bool?> _confirmDiscard(BuildContext context) {
    final s = S.of(context);
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.discardChangesTitle),
        content: Text(s.discardChangesContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(s.dialogCancelLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(s.discardChangesConfirmLabel),
          ),
        ],
      ),
    );
  }

  Future<void> _onAddIngredient(BuildContext context) async {
    final selectedMeal = await Navigator.of(context).push<MealEntity>(
      MaterialPageRoute(
        builder: (searchContext) => Scaffold(
          appBar: AppBar(title: Text(S.of(context).recipeAddIngredientLabel)),
          body: FoodSearchTabView(
            onMealSelected: (meal) => Navigator.of(searchContext).pop(meal),
            onBarcodePressed: () async {
              // Push the scanner in pick-mode — it pops a MealEntity back to
              // us instead of routing into the meal-detail logging flow. We
              // then thread the scanned meal through the same code path the
              // tap-to-pick handler uses, so the quantity dialog runs
              // identically whether the user typed or scanned.
              final scannedMeal = await Navigator.of(searchContext).pushNamed(
                NavigationOptions.scannerRoute,
                arguments: ScannerScreenArguments.pick(),
              );
              if (scannedMeal is MealEntity && searchContext.mounted) {
                Navigator.of(searchContext).pop(scannedMeal);
              }
            },
          ),
        ),
      ),
    );
    if (selectedMeal == null || !context.mounted) return;
    final selection = await showIngredientQuantityDialog(
      context,
      meal: selectedMeal,
    );
    if (selection == null) return;
    _bloc.add(
      AddIngredientEvent(
        meal: selectedMeal,
        amount: selection.amount,
        unit: selection.unit,
      ),
    );
  }

  Future<void> _openNutritionPaste(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (_) => NutritionImportDialog(
        saveAll: _saveImportedFoods,
        applyAll: _addImportedToRecipe,
      ),
    );
  }

  Future<void> _addImportedToRecipe(List<NutritionEntry> entries) async {
    if (entries.any(
      (entry) =>
          entry.basis == NutritionBasis.per100ml || entry.servingUnit == 'ml',
    )) {
      throw FormatException(S.of(context).recipeNutritionImportMassRequired);
    }
    final replacements =
        (_nameController.text.trim().isNotEmpty ? 1 : 0) +
        _bloc.state.ingredients.length;
    if (replacements > 0) {
      final replace = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(S.of(dialogContext).nutritionReplaceTitle),
          content: Text(S.of(dialogContext).nutritionReplaceBody(replacements)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(S.of(dialogContext).bulkAddWaitCancelLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(S.of(dialogContext).nutritionReplaceAction),
            ),
          ],
        ),
      );
      if (replace != true || !context.mounted) {
        throw const FormatException('Import was cancelled.');
      }
    }

    for (var i = _bloc.state.ingredients.length - 1; i >= 0; i--) {
      _bloc.add(RemoveIngredientEvent(i));
    }
    for (final entry in entries) {
      final values = entry.toPer100();
      final meal = MealEntity(
        code: IdGenerator.getUniqueID(),
        name: entry.name.trim(),
        brands: entry.brand.trim().isEmpty ? null : entry.brand.trim(),
        url: null,
        mealQuantity: '100',
        mealUnit: 'g',
        servingQuantity: entry.servingSize,
        servingUnit: entry.servingUnit,
        servingSize: entry.servingSize == null
            ? null
            : '${entry.servingSize} g',
        nutriments: MealNutrimentsEntity(
          energyKcal100: values['kcal'],
          carbohydrates100: values['carbs'],
          fat100: values['fat'],
          proteins100: values['protein'],
          sugars100: values['sugars'],
          saturatedFat100: values['saturatedFat'],
          fiber100: values['fiber'],
          sodium100: values['sodium'],
          potassium100: values['potassium'],
          magnesium100: values['magnesium'],
          calcium100: values['calcium'],
          iron100: values['iron'],
          vitaminD100: values['vitaminD'],
          vitaminB12100: values['vitaminB12'],
        ),
        source: MealSourceEntity.custom,
      );
      final amount = entry.basis == NutritionBasis.per100g
          ? 100.0
          : entry.servingSize!;
      _bloc.add(AddIngredientEvent(meal: meal, amount: amount, unit: 'g'));
    }
    if (entries.length == 1) {
      _nameController.text = entries.single.name.trim();
      _bloc.add(UpdateNameEvent(entries.single.name.trim()));
    }
  }

  Future<String> _saveImportedFoods(List<NutritionEntry> entries) async {
    final selection = await saveImportedNutritionEntries(
      locator<EditMealBloc>(),
      entries,
    );
    if (!mounted) return '';
    return S
        .of(context)
        .nutritionBatchSummary(
          selection.entries.length,
          selection.duplicates,
          selection.invalid,
        );
  }

  Future<void> _onEditIngredient(BuildContext context, int index) async {
    final ingredient = _bloc.state.ingredients[index];
    final selection = await showIngredientQuantityDialog(
      context,
      meal: ingredient.snapshotMeal,
      initialAmount: ingredient.amount,
      initialUnit: ingredient.unit,
    );
    if (selection == null) return;
    _bloc.add(
      UpdateIngredientEvent(
        index: index,
        amount: selection.amount,
        unit: selection.unit,
      ),
    );
  }

  Future<void> _onPickImage(
    BuildContext context, {
    required ImageSource source,
  }) async {
    final recipeId = _bloc.state.id;
    if (recipeId == null) return;
    try {
      final picker = ImagePicker();
      // Pick at full resolution — `UserImageStorage.importFrom` re-encodes
      // to WebP at quality 80, bounding the shortest edge at 1024px, so we
      // don't need image_picker's own JPEG compression on top. Doing it in one
      // place keeps the on-disk footprint consistent regardless of which
      // source (camera / gallery) the photo came from.
      final picked = await picker.pickImage(source: source);
      if (picked == null) return;
      final relative = await UserImageStorage.importFrom(
        kind: UserImageKind.recipe,
        ownerId: recipeId,
        sourcePath: picked.path,
      );
      // Bust the in-memory Image.file cache so the new picture shows up
      // immediately instead of redrawing the previous bytes for this path.
      FileImage(File(await UserImageStorage.absolutePath(relative))).evict();
      _bloc.add(UpdateImagePathEvent(relative));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).recipeSaveErrorLabel)),
      );
    }
  }

  Future<void> _onRemoveImage(BuildContext context) async {
    final current = _bloc.state.imagePath;
    if (current == null) return;
    await UserImageStorage.delete(current);
    _bloc.add(const UpdateImagePathEvent(null));
  }

  void _showSaveError(BuildContext context, SaveError error) {
    final s = S.of(context);
    final message = switch (error) {
      SaveError.nameRequired => s.recipeNameRequiredLabel,
      SaveError.needsIngredients => s.recipeNeedsIngredientsLabel,
      SaveError.invalidTotalWeight => s.recipeInvalidTotalWeightLabel,
      SaveError.unknown => s.recipeSaveErrorLabel,
    };
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
