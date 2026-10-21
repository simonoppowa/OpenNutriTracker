import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/local_fdc_catalog.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/local_food_catalog.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/sp_food_data_source.dart';
import 'package:opennutritracker/features/add_meal/data/dto/sp/sp_const.dart';
import 'package:opennutritracker/features/add_meal/data/dto/sp/sp_food_dto.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_portion_entity.dart';

const _assetPath = 'assets/fdc/fdc.json.gz';

const _datasets = [
  SPConst.fdcFoundationSourceCode,
  SPConst.fdcSrLegacySourceCode,
];

Future<LocalFdcCatalog> _loadBundledCatalog() async {
  final data = await rootBundle.load(_assetPath);
  return compute(LocalFdcCatalog.decode, data.buffer.asUint8List());
}

Future<Set<String>> _switchedOnDatasets() async {
  final toggles = await locator<ConfigDataSource>().getFoodSourceToggles();
  return {
    for (final dataset in _datasets)
      if (toggles?[dataset] ?? SPConst.isFoodSourceOnByDefault(dataset))
        dataset,
  };
}

/// USDA FoodData Central Foundation Foods and SR Legacy, shipped as a local
/// asset (see `tool/fdc/`, #80) and searched offline on the English names.
/// Each dataset has its own switch in Settings → Food databases; both start
/// off. The records carry the FDC id as their source code, so the meal
/// links to its FDC page.
///
/// The catalog is decoded once, off the UI isolate, on the first search
/// with a dataset switched on.
class LocalFdcFoodDataSource extends SpFoodDataSource {
  /// Keeps FDC ids clear of the BLS ids and the backend's food ids.
  static const _idOffset = 800000000000;

  final Future<LocalFdcCatalog> Function() _loadCatalog;
  final Future<Set<String>> Function() _enabledDatasets;
  Future<LocalFdcCatalog>? _catalog;

  LocalFdcFoodDataSource({
    Future<LocalFdcCatalog> Function()? loadCatalog,
    Future<Set<String>> Function()? enabledDatasets,
  }) : _loadCatalog = loadCatalog ?? _loadBundledCatalog,
       _enabledDatasets = enabledDatasets ?? _switchedOnDatasets;

  @override
  Future<List<SpFoodDTO>> fetchSearchWordResults(
    String searchString, {
    bool forResolution = false,
  }) async {
    final enabled = await _enabledDatasets();
    if (enabled.isEmpty) return const [];
    final catalog = await (_catalog ??= _loadCatalog());
    return [
      for (final food in catalog.search(
        searchString,
        limit: SPConst.maxNumberOfItems,
        where: (food) => enabled.contains(food.dataset),
      ))
        localFoodDto(
          foodId: _idOffset + food.fdcId,
          source: food.dataset,
          sourceCode: food.fdcId.toString(),
          name: food.name,
          values: food.values,
        ),
    ];
  }

  @override
  Future<Map<int, String>> fetchPortionLabels(List<int> foodIds) async =>
      const {};

  @override
  Future<Map<int, List<MealPortionEntity>>?> fetchPortions(
    List<int> foodIds,
  ) async => const {};
}
