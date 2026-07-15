import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/entity/recipe_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/presentation/widgets/share_qr_dialog.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/meal_detail/meal_detail_screen.dart';
import 'package:opennutritracker/features/recipes/domain/entity/shared_recipe_payload.dart';
import 'package:opennutritracker/features/recipes/presentation/bloc/recipe_detail_bloc.dart';
import 'package:opennutritracker/features/recipes/presentation/screens/recipe_builder_screen.dart';
import 'package:opennutritracker/features/recipes/presentation/widgets/ingredient_list_item.dart';
import 'package:opennutritracker/features/recipes/presentation/widgets/recipe_nutrition_summary.dart';
import 'package:opennutritracker/generated/l10n.dart';

class RecipeDetailArguments {
  final String recipeId;
  const RecipeDetailArguments({required this.recipeId});
}

enum _RecipeMenuAction { duplicate, delete }

class RecipeDetailScreen extends StatefulWidget {
  const RecipeDetailScreen({super.key});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  late RecipeDetailBloc _bloc;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _bloc = locator<RecipeDetailBloc>();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final args = ModalRoute.of(context)?.settings.arguments
          as RecipeDetailArguments;
      _bloc.add(LoadRecipeEvent(args.recipeId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RecipeDetailBloc, RecipeDetailState>(
      bloc: _bloc,
      listener: (context, state) {
        if (state is RecipeDetailDeleted || state is RecipeDetailMissing) {
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        if (state is RecipeDetailLoaded) {
          return _buildLoaded(context, state.recipe);
        }
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  Widget _buildLoaded(BuildContext context, RecipeEntity recipe) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = isDark ? AppPalette.dark : AppPalette.light;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(recipe.name),
        actions: [
          IconButton(
            tooltip: S.of(context).shareRecipeLabel,
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              final code = SharedRecipePayload.fromRecipe(recipe).toJsonString();
              showDialog(
                context: context,
                builder: (_) => ShareQrDialog(
                  title: S.of(context).shareRecipeLabel,
                  code: code,
                  fileBaseName: 'recipe_qr',
                ),
              );
            },
          ),
          IconButton(
            tooltip: S.of(context).editRecipeTitle,
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              await Navigator.of(context).pushNamed(
                NavigationOptions.recipeBuilderRoute,
                arguments: RecipeBuilderArguments(existing: recipe),
              );
              if (mounted) _bloc.add(LoadRecipeEvent(recipe.id));
            },
          ),
          PopupMenuButton<_RecipeMenuAction>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (action) => _onMenuSelected(context, action, recipe),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _RecipeMenuAction.duplicate,
                child: Row(
                  children: [
                    const Icon(Icons.copy_outlined),
                    const SizedBox(width: Dimens.spacing12),
                    Text(S.of(context).duplicateRecipeLabel),
                  ],
                ),
              ),
              PopupMenuItem(
                value: _RecipeMenuAction.delete,
                child: Row(
                  children: [
                    const Icon(Icons.delete_outline_rounded),
                    const SizedBox(width: Dimens.spacing12),
                    Text(S.of(context).dialogDeleteLabel),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(Dimens.spacing16),
        children: [
          if (recipe.description != null && recipe.description!.isNotEmpty) ...[
            Text(
              recipe.description!,
              style: textTheme.bodyMedium?.copyWith(color: palette.textMuted),
            ),
            const SizedBox(height: Dimens.spacing16),
          ],
          RecipeNutritionSummary(
            nutrimentsPer100: recipe.aggregatedNutrimentsPer100,
            totalWeightG: recipe.totalWeightG,
          ),
          const SizedBox(height: Dimens.spacing24),
          Text(
            S.of(context).recipeIngredientsLabel,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: Dimens.spacing8),
          ...recipe.ingredients.map(
            (i) => IngredientListItem(ingredient: i),
          ),
          const SizedBox(height: Dimens.spacing24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: Dimens.spacing16),
                shape: Dimens.shapeM,
              ),
              onPressed: () => _onLogPressed(context, recipe),
              icon: const Icon(Icons.add_rounded),
              label: Text(S.of(context).recipeLogCtaLabel),
            ),
          ),
          const SizedBox(height: Dimens.spacing32),
        ],
      ),
    );
  }

  Future<void> _onMenuSelected(
    BuildContext context,
    _RecipeMenuAction action,
    RecipeEntity recipe,
  ) async {
    switch (action) {
      case _RecipeMenuAction.duplicate:
        // Open the builder with a copy: drop the id (so save() assigns a new
        // one) and append the localized "(copy)" suffix to the name. The
        // user can rename before saving — common workflow is "tweak one
        // ingredient and save as new".
        final suffix = S.of(context).duplicateRecipeNameSuffix;
        final draft = recipe.copyWith(
          id: '',
          name: '${recipe.name} $suffix',
        );
        // copyWith on RecipeEntity always carries the id forward; we want a
        // fresh one. The builder treats an empty id as a "create new"
        // sentinel: it generates a UUID at save time.
        final fresh = RecipeEntity(
          id: '',
          name: draft.name,
          description: draft.description,
          ingredients: draft.ingredients,
          totalWeightG: draft.totalWeightG,
          aggregatedNutrimentsPer100: draft.aggregatedNutrimentsPer100,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          servingsCount: draft.servingsCount,
          tags: draft.tags,
        );
        await Navigator.of(context).pushNamed(
          NavigationOptions.recipeBuilderRoute,
          arguments: RecipeBuilderArguments(existing: fresh),
        );
        if (mounted) _bloc.add(LoadRecipeEvent(recipe.id));
      case _RecipeMenuAction.delete:
        await _confirmDelete(context);
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.of(context).recipeDeleteConfirmTitle),
        content: Text(S.of(context).recipeDeleteConfirmContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(S.of(context).dialogCancelLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(S.of(context).dialogDeleteLabel),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      _bloc.add(const DeleteRecipeFromDetailEvent());
    }
  }

  Future<void> _onLogPressed(BuildContext context, RecipeEntity recipe) async {
    final intakeType = await _pickIntakeType(context);
    if (intakeType == null || !context.mounted) return;
    final config = await locator<GetConfigUsecase>().getConfig();
    if (!context.mounted) return;
    Navigator.of(context).pushNamed(
      NavigationOptions.mealDetailRoute,
      arguments: MealDetailScreenArguments(
        recipe.toMealEntity(),
        intakeType,
        DateTime.now(),
        config.usesImperialFoodUnits,
      ),
    );
  }

  Future<IntakeTypeEntity?> _pickIntakeType(BuildContext context) {
    final s = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = isDark ? AppPalette.dark : AppPalette.light;
    return showModalBottomSheet<IntakeTypeEntity>(
      context: context,
      builder: (ctx) {
        Widget tile(IntakeTypeEntity type, String label) {
          final accent = Theme.of(ctx).colorScheme.primary;
          return ListTile(
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: Dimens.borderRadiusS,
              ),
              child: Icon(type.getIconData(), color: accent, size: 22),
            ),
            title: Text(
              label,
              style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            onTap: () => Navigator.of(ctx).pop(type),
          );
        }

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: Dimens.spacing12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: palette.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: Dimens.spacing8),
              tile(IntakeTypeEntity.breakfast, s.breakfastLabel),
              tile(IntakeTypeEntity.lunch, s.lunchLabel),
              tile(IntakeTypeEntity.dinner, s.dinnerLabel),
              tile(IntakeTypeEntity.snack, s.snackLabel),
            ],
          ),
        );
      },
    );
  }
}
