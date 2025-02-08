import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/meal_value_unit_text.dart';
import 'package:opennutritracker/core/presentation/widgets/image_full_screen.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/edit_meal/presentation/edit_meal_screen.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';
import 'package:opennutritracker/features/meal_detail/presentation/widgets/meal_detail_bottom_sheet.dart';
import 'package:opennutritracker/features/meal_detail/presentation/widgets/meal_detail_macro_nutrients.dart';
import 'package:opennutritracker/features/meal_detail/presentation/widgets/meal_detail_nutriments_table.dart';
import 'package:opennutritracker/features/meal_detail/presentation/widgets/meal_info_button.dart';
import 'package:opennutritracker/features/meal_detail/presentation/widgets/meal_placeholder.dart';
import 'package:opennutritracker/features/meal_detail/presentation/widgets/meal_title_expanded.dart';
import 'package:opennutritracker/features/meal_detail/presentation/widgets/off_disclaimer.dart';
import 'package:opennutritracker/generated/l10n.dart';

class MealDetailScreen extends StatefulWidget {
  const MealDetailScreen({super.key});

  @override
  State<MealDetailScreen> createState() => _MealDetailScreenState();
}

class _MealDetailScreenState extends State<MealDetailScreen> {
  static const _containerSize = 350.0;

  static const String _initialQuantityMetric = '100';
  static const String _initialQuantityImperial = '1';

  final log = Logger('ItemDetailScreen');

  late MealDetailBloc _mealDetailBloc;
  final _scrollController = ScrollController();

  late MealEntity meal;
  late DateTime _day;
  late IntakeTypeEntity intakeTypeEntity;

  final quantityTextController = TextEditingController();
  late bool _usesImperialUnits;

  String _initialUnit = "";
  String _initialQuantity = "";

  @override
  void initState() {
    _mealDetailBloc = locator<MealDetailBloc>();

    super.initState();
  }

  @override
  void didChangeDependencies() {
    final args =
        ModalRoute.of(context)?.settings.arguments as MealDetailScreenArguments;
    meal = args.mealEntity;
    _day = args.day;
    intakeTypeEntity = args.intakeTypeEntity;
    _usesImperialUnits = args.usesImperialUnits;

    // Set initial unit
    if (_initialUnit == "") {
      if (meal.hasServingValues) {
        _initialUnit = UnitDropdownItem.serving.toString();
      } else if (meal.isLiquid) {
        _initialUnit = _usesImperialUnits
            ? UnitDropdownItem.flOz.toString()
            : UnitDropdownItem.ml.toString();
      } else if (meal.isSolid) {
        _initialUnit = _usesImperialUnits
            ? UnitDropdownItem.oz.toString()

            : UnitDropdownItem.g.toString();
      } else {
        _initialUnit = UnitDropdownItem.gml.toString();
      }
      _mealDetailBloc
          .add(UpdateKcalEvent(meal: meal, selectedUnit: _initialUnit));
    }

    // Set initial quantity
    if (_initialQuantity == "") {
      if (meal.hasServingValues) {
        _initialQuantity = "1";
        quantityTextController.text = "1";
      } else if (_usesImperialUnits) {
        _initialQuantity = _initialQuantityImperial;
        quantityTextController.text = _initialQuantityImperial;
      } else {
        _initialQuantity = _initialQuantityMetric;
        quantityTextController.text = _initialQuantityMetric;
      }
      _mealDetailBloc.add(UpdateKcalEvent(
          meal: meal, totalQuantity: quantityTextController.text));
    }

    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MealDetailBloc, MealDetailState>(
      bloc: _mealDetailBloc,
      builder: (context, state) {
        if (state is MealDetailInitial) {
          return Scaffold(
            body: _getLoadedContent(
              context,
              state.totalQuantityConverted,
              state.totalKcal,
              state.totalCarbs,
              state.totalFat,
              state.totalProtein,
              state.selectedUnit,
            ),
            bottomSheet: MealDetailBottomSheet(
              product: meal,
              day: _day,
              intakeTypeEntity: intakeTypeEntity,
              selectedUnit: state.selectedUnit,
              mealDetailBloc: _mealDetailBloc,
              quantityTextController: quantityTextController,
              onQuantityOrUnitChanged: onQuantityOrUnitChanged,
            ),
          );
        } else {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
      },
    );
  }

  Widget _getLoadedContent(
      BuildContext context,
      String totalQuantity,
      double totalKcal,
      double totalCarbs,
      double totalFat,
      double totalProtein,
      String selectedUnit) {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 200,
          flexibleSpace: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
            final top = constraints.biggest.height;
            final barsHeight =
                MediaQuery.of(context).padding.top + kToolbarHeight;
            const offset = 10;
            return FlexibleSpaceBar(
                expandedTitleScale: 1, // don't scale title
                background: MealTitleExpanded(
                    meal: meal, usesImperialUnits: _usesImperialUnits),
                title: AnimatedOpacity(
                    opacity: 1.0,
                    duration: const Duration(milliseconds: 300),
                    child:
                        top > barsHeight - offset && top < barsHeight + offset
                            ? Text(meal.name ?? '',
                                style: Theme.of(context).textTheme.titleLarge,
                                overflow: TextOverflow.ellipsis)
                            : const SizedBox()));
          }),
          actions: [
            IconButton(
                onPressed: () {
                  Navigator.of(context)
                      .pushNamed(NavigationOptions.editMealRoute,
                          arguments: EditMealScreenArguments(
                            _day,
                            meal,
                            intakeTypeEntity,
                            _usesImperialUnits,
                          ));
                },
                icon: const Icon(Icons.edit_outlined))
          ],
        ),
        SliverList(
            delegate: SliverChildListDelegate([
          const SizedBox(height: 16),
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(80),
              child: GestureDetector(
                  child: Hero(
                    tag: ImageFullScreen.fullScreenHeroTag,
                    child: CachedNetworkImage(
                      width: 250,
                      height: 250,
                      cacheManager: locator<CacheManager>(),
                      imageUrl: meal.mainImageUrl ?? "",
                      fit: BoxFit.cover,
                      placeholder: (context, string) => const MealPlaceholder(),
                      errorWidget: (context, url, error) =>
                          const MealPlaceholder(),
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).pushNamed(
                        NavigationOptions.imageFullScreenRoute,
                        arguments:
                            ImageFullScreenArguments(meal.mainImageUrl ?? ""));
                  }),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Text('${totalKcal.toInt()} ${S.of(context).kcalLabel}',
                        style: Theme.of(context).textTheme.headlineSmall),
                    MealValueUnitText(
                      value: double.parse(totalQuantity),
                      meal: meal,
                      displayUnit:
                          selectedUnit == UnitDropdownItem.serving.toString()
                              ? meal.servingUnit
                              : selectedUnit,
                      usesImperialUnits: _usesImperialUnits,
                      textStyle: Theme.of(context).textTheme.bodyMedium,
                      prefix: ' / ',
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    MealDetailMacroNutrients(
                        typeString: S.of(context).carbsLabel,
                        value: totalCarbs),
                    MealDetailMacroNutrients(
                        typeString: S.of(context).fatLabel, value: totalFat),
                    MealDetailMacroNutrients(
                        typeString: S.of(context).proteinLabel,
                        value: totalProtein)
                  ],
                ),
                const Divider(),
                const SizedBox(height: 16.0),
                MealDetailNutrimentsTable(
                    product: meal,
                    usesImperialUnits: _usesImperialUnits,
                    servingQuantity: meal.servingQuantity,
                    servingUnit: meal.servingUnit),
                const SizedBox(height: 32.0),
                MealInfoButton(url: meal.url, source: meal.source),
                meal.source == MealSourceEntity.off
                    ? const Column(
                        children: [
                          SizedBox(height: 32),
                          OffDisclaimer(),
                        ],
                      )
                    : const SizedBox(),
                const SizedBox(height: 200.0) // height added to scroll
              ],
            ),
          )
        ]))
      ],
    );
  }

  void onQuantityOrUnitChanged(String? quantityString, String? unit) {
    if (quantityString == null || unit == null) {
      return;
    }
    _mealDetailBloc.add(UpdateKcalEvent(
        meal: meal, totalQuantity: quantityString, selectedUnit: unit));
    _scrollToCalorieText();
  }

  void _scrollToCalorieText() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _containerSize - 50,
        duration: const Duration(seconds: 1),
        curve: Curves.easeInOut,
      );
    }
  }
}

class MealDetailScreenArguments {
  final MealEntity mealEntity;
  final IntakeTypeEntity intakeTypeEntity;
  final DateTime day;
  final bool usesImperialUnits;

  MealDetailScreenArguments(
      this.mealEntity, this.intakeTypeEntity, this.day, this.usesImperialUnits);
}
