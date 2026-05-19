import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/entity/recipe_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/presentation/widgets/share_qr_dialog.dart';
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
            icon: const Icon(Icons.more_vert),
            onSelected: (action) => _onMenuSelected(context, action, recipe),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _RecipeMenuAction.duplicate,
                child: Row(
                  children: [
                    const Icon(Icons.copy_outlined),
                    const SizedBox(width: 12),
                    Text(S.of(context).duplicateRecipeLabel),
                  ],
                ),
              ),
              PopupMenuItem(
                value: _RecipeMenuAction.delete,
                child: Row(
                  children: [
                    const Icon(Icons.delete_outline),
                    const SizedBox(width: 12),
                    Text(S.of(context).dialogDeleteLabel),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (recipe.description != null && recipe.description!.isNotEmpty) ...[
            Text(
              recipe.description!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
          ],
          RecipeNutritionSummary(
            nutrimentsPer100: recipe.aggregatedNutrimentsPer100,
            totalWeightG: recipe.totalWeightG,
          ),
          const SizedBox(height: 24),
          Text(
            S.of(context).recipeIngredientsLabel,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...recipe.ingredients.map(
            (i) => IngredientListItem(ingredient: i),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _onLogPressed(context, recipe),
              icon: const Icon(Icons.add),
              label: Text(S.of(context).recipeLogCtaLabel),
            ),
          ),
          const SizedBox(height: 32),
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
        config.usesImperialUnits,
      ),
    );
  }

  Future<IntakeTypeEntity?> _pickIntakeType(BuildContext context) {
    final s = S.of(context);
    return showModalBottomSheet<IntakeTypeEntity>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(IntakeTypeEntity.breakfast.getIconData()),
                title: Text(s.breakfastLabel),
                onTap: () => Navigator.of(ctx).pop(IntakeTypeEntity.breakfast),
              ),
              ListTile(
                leading: Icon(IntakeTypeEntity.lunch.getIconData()),
                title: Text(s.lunchLabel),
                onTap: () => Navigator.of(ctx).pop(IntakeTypeEntity.lunch),
              ),
              ListTile(
                leading: Icon(IntakeTypeEntity.dinner.getIconData()),
                title: Text(s.dinnerLabel),
                onTap: () => Navigator.of(ctx).pop(IntakeTypeEntity.dinner),
              ),
              ListTile(
                leading: Icon(IntakeTypeEntity.snack.getIconData()),
                title: Text(s.snackLabel),
                onTap: () => Navigator.of(ctx).pop(IntakeTypeEntity.snack),
              ),
            ],
          ),
        );
      },
    );
  }
}
