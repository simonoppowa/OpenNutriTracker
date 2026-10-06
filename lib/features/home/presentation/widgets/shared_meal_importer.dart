import 'dart:async';

import 'package:flutter/material.dart';
import 'package:opennutritracker/core/data/data_source/custom_meal_data_source.dart';
import 'package:opennutritracker/core/data/data_source/remote_search_cache_data_source.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/usecase/save_recipe_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/compute_recipe_nutrition_usecase.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/retry_util.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_type.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/home/domain/entity/shared_meal_payload.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';
import 'package:opennutritracker/features/recipes/presentation/bloc/recipes_bloc.dart';
import 'package:opennutritracker/features/scanner/domain/usecase/search_product_by_barcode_usecase.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/custom_meals_bloc.dart';
import 'package:opennutritracker/features/home/presentation/widgets/shared_meal_import_dialogs.dart';
import 'package:opennutritracker/generated/l10n.dart';

class SharedMealImporter {
  final BuildContext context;
  final IntakeTypeEntity _intakeTypeEntity;
  final AddMealType _addMealType;
  final DateTime _day;
  final MealDetailBloc _mealDetailBloc = locator<MealDetailBloc>();
  final SearchProductByBarcodeUseCase _searchProductByBarcodeUseCase =
      locator<SearchProductByBarcodeUseCase>();

  SharedMealImporter(
    this.context,
    this._intakeTypeEntity,
    this._addMealType,
    this._day,
  );

  Future<bool> importCode(String raw) async {
    try {
      final payload = SharedMealPayload.fromJsonString(raw);
      return await importPayload(payload);
    } on SharedMealParseException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).importMealErrorLabel)),
        );
      }
      return false;
    }
  }

  bool _busy = false;

  Future<T> _withProgress<T>(Future<T> Function() action) async {
    final navigator = Navigator.of(context);
    final route = DialogRoute<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: AlertDialog(
          content: SizedBox(
            height: 64,
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      ),
    );
    unawaited(navigator.push(route));
    try {
      return await action();
    } finally {
      if (route.isActive) navigator.removeRoute(route);
    }
  }

  Future<bool> importPayload(SharedMealPayload payload) async {
    if (_busy || !context.mounted) return false;
    _busy = true;
    try {
      final items = await _withProgress(() => _prepareItems(payload));
      if (!context.mounted) return false;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => SharedMealPreviewDialog(
          items: items,
          mealType: _addMealType.getTypeName(context),
        ),
      );
      if (confirmed != true || !context.mounted) return false;
      final completed = await _withProgress(() => _importItems(items));
      if (!completed || !context.mounted) return false;
      _refreshPages();
      return true;
    } finally {
      _busy = false;
    }
  }

  Future<List<SharedMealPreviewItem>> _prepareItems(
      SharedMealPayload payload) async {
    final items = <SharedMealPreviewItem>[
      for (final item in payload.items)
        SharedMealPreviewItem(
          meal: item.toMealEntity(),
          amount: item.amount,
          unit: item.unit,
        ),
    ];
    for (final item in payload.recipes) {
      final recipe = item.recipe.toRecipeEntity();
      // Match SaveRecipeUseCase's calculation before showing the preview.
      final nutrition =
          locator<ComputeRecipeNutritionUseCase>().compute(recipe.ingredients);
      final prepared = recipe.copyWith(
        totalWeightG: nutrition.totalWeightG,
        aggregatedNutrimentsPer100: nutrition.perHundredG,
      );
      items.add(SharedMealPreviewItem(
        meal: prepared.toMealEntity(),
        recipe: prepared,
        amount: item.amount,
        unit: item.unit,
      ));
    }
    final offItems = await Future.wait(payload.offRefs.map((ref) async {
      MealEntity? meal;
      try {
        meal = await withRetry(() =>
            _searchProductByBarcodeUseCase.searchProductByBarcode(ref.barcode));
      } catch (_) {
        // Keep the failed reference visible so the user can review omissions.
      }
      return SharedMealPreviewItem(
        meal: meal,
        barcode: ref.barcode,
        amount: ref.amount,
        unit: ref.unit,
      );
    }));
    return [...items, ...offItems];
  }

  Future<bool> _importItems(List<SharedMealPreviewItem> items) async {
    for (final item in items) {
      if (!context.mounted) return false;
      final meal = item.meal;
      if (meal == null) continue;
      if (item.recipe != null) {
        await locator<SaveRecipeUseCase>().save(item.recipe!);
      } else if (item.barcode == null) {
        if (meal.source == MealSourceEntity.fdc) {
          await locator<RemoteSearchCacheDataSource>()
              .cache(MealDBO.fromMealEntity(meal));
        } else {
          await locator<CustomMealDataSource>()
              .saveCustomMeal(MealDBO.fromMealEntity(meal));
        }
      }
      if (!context.mounted) return false;
      await _mealDetailBloc.addIntake(
        context,
        item.unit,
        item.amount.toString(),
        _intakeTypeEntity,
        meal,
        _day,
      );
    }
    return true;
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
