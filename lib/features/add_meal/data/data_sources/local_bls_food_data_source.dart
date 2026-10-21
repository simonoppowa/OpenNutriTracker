import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/utils/app_locale.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/local_bls_catalog.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/local_food_catalog.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/sp_food_data_source.dart';
import 'package:opennutritracker/features/add_meal/data/dto/sp/sp_const.dart';
import 'package:opennutritracker/features/add_meal/data/dto/sp/sp_food_dto.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_portion_entity.dart';

const _assetPath = 'assets/bls/bls_4_0.json.gz';

Future<LocalBlsCatalog> _loadBundledCatalog() async {
  final data = await rootBundle.load(_assetPath);
  return compute(LocalBlsCatalog.decode, data.buffer.asUint8List());
}

Future<bool> _blsSwitchedOn() async {
  final toggles = await locator<ConfigDataSource>().getFoodSourceToggles();
  return toggles?[SPConst.blsSourceCode] ?? true;
}

/// The fork's reference food database: the BLS 4.0 shipped as a local asset
/// (see `tool/bls/`), searched offline. It stands where upstream's Supabase
/// source stood and hands out the same records, so ranking, the meal detail
/// and the BLS source label work unchanged.
///
/// The catalog is decoded once, off the UI isolate, on the first search.
class LocalBlsFoodDataSource extends SpFoodDataSource {
  /// Keeps BLS ids clear of the backend's numeric food ids.
  static const _idOffset = 900000000000;

  final Future<LocalBlsCatalog> Function() _loadCatalog;
  final Future<bool> Function() _isEnabled;
  final String Function() _localeName;
  Future<LocalBlsCatalog>? _catalog;

  LocalBlsFoodDataSource({
    Future<LocalBlsCatalog> Function()? loadCatalog,
    Future<bool> Function()? isEnabled,
    String Function()? localeName,
  }) : _loadCatalog = loadCatalog ?? _loadBundledCatalog,
       _isEnabled = isEnabled ?? _blsSwitchedOn,
       _localeName = localeName ?? (() => AppLocale.localeName);

  @override
  Future<List<SpFoodDTO>> fetchSearchWordResults(
    String searchString, {
    bool forResolution = false,
  }) async {
    if (!await _isEnabled()) return const [];
    final catalog = await (_catalog ??= _loadCatalog());
    final german = _localeName().toLowerCase().startsWith('de');
    return [
      for (final food in catalog.search(
        searchString,
        limit: SPConst.maxNumberOfItems,
      ))
        _toDto(food, german: german),
    ];
  }

  @override
  Future<Map<int, String>> fetchPortionLabels(List<int> foodIds) async =>
      const {};

  @override
  Future<Map<int, List<MealPortionEntity>>?> fetchPortions(
    List<int> foodIds,
  ) async => const {};

  static SpFoodDTO _toDto(BlsFood food, {required bool german}) =>
      localFoodDto(
        foodId: _idOffset + int.parse(food.code, radix: 36),
        source: SPConst.blsSourceCode,
        sourceCode: food.code,
        name: food.nameEn ?? food.nameDe,
        localizedName: german ? food.nameDe : null,
        values: food.values,
      );
}
