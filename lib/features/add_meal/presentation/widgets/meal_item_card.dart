import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/presentation/widgets/meal_value_unit_text.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_type.dart';
import 'package:opennutritracker/features/meal_detail/meal_detail_screen.dart';
import 'package:opennutritracker/features/scanner/domain/usecase/search_product_by_barcode_usecase.dart';

class MealItemCard extends StatelessWidget {
  final DateTime day;
  final AddMealType addMealType;
  final MealEntity mealEntity;
  final bool usesImperialUnits;
  final GetConfigUsecase? getConfigUsecase;
  final SearchProductByBarcodeUseCase? searchProductByBarcodeUseCase;
  final _log = Logger('MealItemCard');

  MealItemCard({
    super.key,
    required this.day,
    required this.mealEntity,
    required this.addMealType,
    required this.usesImperialUnits,
    this.getConfigUsecase,
    this.searchProductByBarcodeUseCase
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Theme.of(context).colorScheme.outline),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: InkWell(
        child: SizedBox(
          height: 100,
          child: Center(
            child: ListTile(
              leading: mealEntity.thumbnailImageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CachedNetworkImage(
                        cacheManager: locator<CacheManager>(),
                        fit: BoxFit.cover,
                        width: 60,
                        height: 60,
                        imageUrl: mealEntity.thumbnailImageUrl ?? "",
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 60,
                        height: 60,
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        child: const Icon(Icons.restaurant_outlined),
                      ),
                    ),
              title: AutoSizeText.rich(
                TextSpan(
                  text: mealEntity.name ?? "?",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                  children: [
                    TextSpan(
                      text: ' ${mealEntity.brands ?? ""}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.8),
                          ),
                    ),
                  ],
                ),
                style: Theme.of(context).textTheme.titleLarge,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: mealEntity.mealQuantity != null
                  ? MealValueUnitText(
                      value: double.parse(mealEntity.mealQuantity ?? "0"),
                      meal: mealEntity,
                      usesImperialUnits: usesImperialUnits,
                    )
                  : const SizedBox(),
              trailing: IconButton(
                style: IconButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                ),
                icon: const Icon(Icons.add_outlined),
                onPressed: () => _onItemPressed(context),
              ),
            ),
          ),
        ),
        onTap: () => _onItemPressed(context),
      ),
    );
  }



  void _onItemPressed(BuildContext context) async {

    MealEntity entity = mealEntity;

    bool realoadData = false;
  
    if(getConfigUsecase != null) {
      ConfigEntity config = await getConfigUsecase!.getConfig();
      realoadData = (config.useLocalDataBase) && (searchProductByBarcodeUseCase != null) && (entity.code != null);
    }

    if(realoadData){
      try {
        entity = await searchProductByBarcodeUseCase!.searchProductByBarcode(entity.code!);
      } catch (e, s) {
        _log.severe("Exception while fetching product details");
        _log.severe(e.toString());
        _log.severe(s.toString());
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text("Failed to get product details"),
              content: Text("There was an error fetching the complete product details. Try again later. Details: ${e.toString()}"),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text("Ok"),
                ),
              ]
            );
          }
        );
        return;
      }
      
      Navigator.of(context).pushNamed(
        NavigationOptions.mealDetailRoute,
        arguments: MealDetailScreenArguments(
          entity,
          addMealType.getIntakeType(),
          day,
          usesImperialUnits,
        ),
      );

    }
  }
}
