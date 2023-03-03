import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/utils/off_const.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/product_entity.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';
import 'package:opennutritracker/features/meal_detail/presentation/widgets/meal_detail_bottom_sheet.dart';
import 'package:opennutritracker/features/meal_detail/presentation/widgets/meal_detail_macro_nutrients.dart';
import 'package:opennutritracker/features/meal_detail/presentation/widgets/meal_detail_nutriments_table.dart';
import 'package:opennutritracker/features/meal_detail/presentation/widgets/meal_info_button.dart';
import 'package:opennutritracker/features/meal_detail/presentation/widgets/meal_placeholder.dart';
import 'package:opennutritracker/generated/l10n.dart';

class MealDetailScreen extends StatefulWidget {
  const MealDetailScreen({Key? key}) : super(key: key);

  @override
  State<MealDetailScreen> createState() => _MealDetailScreenState();
}

class _MealDetailScreenState extends State<MealDetailScreen> {
  final log = Logger('ItemDetailScreen');

  final mealDetailBloc = MealDetailBloc();

  late ProductEntity product;
  late IntakeTypeEntity intakeTypeEntity;
  late TextEditingController quantityTextController;

  late double totalQuantity;
  late double totalKcal;
  late double totalCarbs;
  late double totalFat;
  late double totalProtein;

  @override
  void initState() {
    quantityTextController = TextEditingController();
    quantityTextController.text = '100';
    totalQuantity = 100;
    super.initState();
  }

  @override
  void didChangeDependencies() {
    final args =
        ModalRoute.of(context)?.settings.arguments as MealDetailScreenArguments;
    product = args.productEntity;
    intakeTypeEntity = args.intakeTypeEntity;
    totalKcal = product.nutriments.energyKcal100 ?? 0;
    totalCarbs = product.nutriments.carbohydrates100g ?? 0;
    totalFat = product.nutriments.fat100g ?? 0;
    totalProtein = product.nutriments.fat100g ?? 0;
    quantityTextController.addListener(() {
      _onQuantityChanged(quantityTextController.text);
    });
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${product.productName}')),
      body: ListView(
        children: [
          Stack(children: [
            CachedNetworkImage(
              imageUrl: product.mainImageUrl ?? "",
              imageBuilder: (context, imageProvider) {
                return Container(
                  height: 300,
                  decoration: BoxDecoration(
                      image: DecorationImage(
                          image: imageProvider, fit: BoxFit.cover)),
                );
              },
              placeholder: (context, string) => const MealPlaceholder(),
              errorWidget: (context, url, error) => const MealPlaceholder(),
            ),
            Align(
              alignment: AlignmentDirectional.topStart,
              child: Card(
                child: SizedBox(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('${product.brands}',
                        style: Theme.of(context).textTheme.bodyText1),
                  ),
                ),
              ),
            ),
            Align(
              alignment: AlignmentDirectional.topEnd,
              child: Card(
                  child: SizedBox(
                      child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                              '${product.productQuantity?.toInt()} ${product.productUnit}',
                              style: Theme.of(context).textTheme.bodyText1)))),
            )
          ]),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Text('${totalKcal.toInt()} ${S.of(context).kcalLabel}',
                        style: Theme.of(context).textTheme.headline5),
                    Text(' / ${totalQuantity.toInt()} ${product.productUnit}')
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
                MealDetailNutrimentsTable(product: product),
                const SizedBox(height: 32.0),
                MealInfoButton(url: product.url ?? OFFConst.offWebsiteUrl),
                const SizedBox(height: 200.0) // height added to scroll
              ],
            ),
          )
        ],
      ),
      bottomSheet: MealDetailBottomSheet(
          product: product,
          intakeTypeEntity: intakeTypeEntity,
          quantityTextController: quantityTextController,
          mealDetailBloc: mealDetailBloc),
    );
  }

  void _onQuantityChanged(String quantityString) {
    setState(() {
      try {
        final energyPerUnit = (product.nutriments.energyPerUnit ?? 0);
        final carbsPerUnit = (product.nutriments.carbohydratesPerUnit ?? 0);
        final fatPerUnit = (product.nutriments.fatPerUnit ?? 0);
        final proteinPerUnit = (product.nutriments.proteinsPerUnit ?? 0);

        final quantity = double.parse(quantityString);
        totalQuantity = quantity;
        totalKcal = (quantity * energyPerUnit);
        totalCarbs = (quantity * carbsPerUnit);
        totalFat = (quantity * fatPerUnit);
        totalProtein = (quantity * proteinPerUnit);
      } on FormatException catch (e) {
        log.warning("Error while parsing: \"$quantityString\"");
      }
    });
  }
}

class MealDetailScreenArguments {
  final ProductEntity productEntity;
  final IntakeTypeEntity intakeTypeEntity;

  MealDetailScreenArguments(this.productEntity, this.intakeTypeEntity);
}
