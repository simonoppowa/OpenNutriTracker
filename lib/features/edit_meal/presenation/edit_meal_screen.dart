import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/utils/custom_text_input_formatter.dart';
import 'package:opennutritracker/core/utils/extensions.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/meal_detail/meal_detail_screen.dart';
import 'package:opennutritracker/generated/l10n.dart';

class EditMealScreen extends StatefulWidget {
  const EditMealScreen({super.key});

  @override
  State<EditMealScreen> createState() => _EditMealScreenState();
}

class _EditMealScreenState extends State<EditMealScreen> {
  late MealEntity _mealEntity;
  late IntakeTypeEntity _intakeTypeEntity;

  final _nameTextController = TextEditingController();
  final _brandsTextController = TextEditingController();
  final _mealSizeTextController = TextEditingController();
  final _servingSizeTextController = TextEditingController();
  final _kcalTextController = TextEditingController();
  final _carbsTextController = TextEditingController();
  final _fatTextController = TextEditingController();
  final _proteinTextController = TextEditingController();

  final _dropdownValues = ['g', 'ml'];
  late String? _dropdownUnitValue;
  late List<DropdownMenuItem> _mealUnitDropdownItems;

  @override
  void didChangeDependencies() {
    final args =
        ModalRoute.of(context)?.settings.arguments as EditMealScreenArguments;
    _mealEntity = args.mealEntity;
    _intakeTypeEntity = args.intakeTypeEntity;

    _nameTextController.text = _mealEntity.name ?? "";
    _brandsTextController.text = _mealEntity.brands ?? "";
    _mealSizeTextController.text = _mealEntity.mealQuantity ?? "";
    _servingSizeTextController.text =
        _mealEntity.servingQuantity.toStringOrEmpty();
    _kcalTextController.text =
        _mealEntity.nutriments.energyKcal100.toStringOrEmpty();
    _carbsTextController.text =
        _mealEntity.nutriments.carbohydrates100.toStringOrEmpty();
    _fatTextController.text = _mealEntity.nutriments.fat100.toStringOrEmpty();
    _proteinTextController.text =
        _mealEntity.nutriments.proteins100.toStringOrEmpty();
    _dropdownUnitValue = _switchDropdownUnit(_mealEntity.mealUnit);

    _mealUnitDropdownItems = <DropdownMenuItem>[
      DropdownMenuItem(
          value: _dropdownValues[0], child: Text(S.of(context).gramUnit)),
      DropdownMenuItem(
          value: _dropdownValues[1], child: Text(S.of(context).milliliterUnit)),
    ];

    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).editMealLabel),
        actions: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: FilledButton(
                onPressed: _onSavePressed,
                child: Text(S.of(context).buttonSaveLabel)),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
            child: Icon(
              Icons.restaurant_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _nameTextController,
            decoration: InputDecoration(
                labelText: S.of(context).mealNameLabel,
                border: const OutlineInputBorder()),
            keyboardType: TextInputType.text,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _brandsTextController,
            decoration: InputDecoration(
                labelText: S.of(context).mealBrandsLabel,
                border: const OutlineInputBorder()),
            keyboardType: TextInputType.text,
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _mealSizeTextController,
            decoration: InputDecoration(
                labelText: S.of(context).mealSizeLabel,
                border: const OutlineInputBorder()),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _servingSizeTextController,
            inputFormatters: CustomTextInputFormatter.doubleOnly(),
            decoration: InputDecoration(
                labelText: S.of(context).servingSizeLabel,
                border: const OutlineInputBorder()),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField(
            value: _dropdownUnitValue ?? _dropdownValues.first,
            items: _mealUnitDropdownItems,
            onChanged: (text) {
              _dropdownUnitValue = _switchDropdownUnit(text);
            },
            decoration: InputDecoration(
                labelText: S.of(context).mealUnitLabel,
                border: const OutlineInputBorder()),
          ),
          const SizedBox(height: 48),
          TextFormField(
            controller: _kcalTextController,
            inputFormatters: CustomTextInputFormatter.doubleOnly(),
            decoration: InputDecoration(
                labelText: S.of(context).mealKcalLabel,
                border: const OutlineInputBorder()),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _carbsTextController,
            inputFormatters: CustomTextInputFormatter.doubleOnly(),
            decoration: InputDecoration(
                labelText: S.of(context).mealCarbsLabel,
                border: const OutlineInputBorder()),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _fatTextController,
            inputFormatters: CustomTextInputFormatter.doubleOnly(),
            decoration: InputDecoration(
                labelText: S.of(context).mealFatLabel,
                border: const OutlineInputBorder()),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _proteinTextController,
            inputFormatters: CustomTextInputFormatter.doubleOnly(),
            decoration: InputDecoration(
                labelText: S.of(context).mealProteinLabel,
                border: const OutlineInputBorder()),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  void _onSavePressed() {
    final newMealNutriments = MealNutrimentsEntity(
        energyKcal100: _kcalTextController.text.toDoubleOrNull(),
        carbohydrates100: _carbsTextController.text.toDoubleOrNull(),
        fat100: _fatTextController.text.toDoubleOrNull(),
        proteins100: _proteinTextController.text.toDoubleOrNull(),
        sugars100: _mealEntity.nutriments.sugars100,
        saturatedFat100: _mealEntity.nutriments.saturatedFat100,
        fiber100: _mealEntity.nutriments.fiber100);

    final newMealEntity = MealEntity(
        code: _mealEntity.code,
        name: _nameTextController.text,
        brands: _brandsTextController.text,
        url: _mealEntity.url,
        thumbnailImageUrl: _mealEntity.thumbnailImageUrl,
        mainImageUrl: _mealEntity.mainImageUrl,
        mealQuantity: _mealSizeTextController.text,
        mealUnit: _dropdownUnitValue,
        servingQuantity: _servingSizeTextController.text.toDoubleOrNull(),
        servingUnit: _dropdownUnitValue,
        nutriments: newMealNutriments,
        source: _mealEntity.source);

    Navigator.of(context).pushNamedAndRemoveUntil(
        NavigationOptions.mealDetailRoute,
        ModalRoute.withName(NavigationOptions.addMealRoute),
        arguments: MealDetailScreenArguments(newMealEntity, _intakeTypeEntity));
  }

  String? _switchDropdownUnit(String? unit) {
    String? dropdownValue;
    if (!_dropdownValues.contains(unit)) {
      dropdownValue = _dropdownValues.first;
    } else {
      dropdownValue = unit;
    }
    return dropdownValue;
  }
}

class EditMealScreenArguments {
  final MealEntity mealEntity;
  final IntakeTypeEntity intakeTypeEntity;

  EditMealScreenArguments(this.mealEntity, this.intakeTypeEntity);
}
