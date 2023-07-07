import 'package:flutter/material.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/generated/l10n.dart';

class EditMealScreen extends StatefulWidget {
  const EditMealScreen({super.key});

  @override
  State<EditMealScreen> createState() => _EditMealScreenState();
}

class _EditMealScreenState extends State<EditMealScreen> {
  late MealEntity _mealEntity;

  final _mealNameController = TextEditingController();
  final _mealBrandsController = TextEditingController();
  final _mealSizeController = TextEditingController();
  final _mealKcalController = TextEditingController();
  final _mealCarbsController = TextEditingController();
  final _mealFatController = TextEditingController();
  final _mealProteinController = TextEditingController();

  final _mealUnitDropdownItems = <DropdownMenuItem>[
    DropdownMenuItem(value: "g", child: Text("g")),
    DropdownMenuItem(value: "ml", child: Text("ml")),
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    final args =
        ModalRoute.of(context)?.settings.arguments as EditMealScreenArguments;
    _mealEntity = args.mealEntity;

    _mealNameController.text = _mealEntity.name ?? "";
    _mealBrandsController.text = _mealEntity.brands ?? "";
    _mealSizeController.text = _mealEntity.mealQuantity ?? "";
    _mealKcalController.text =
        _mealEntity.nutriments.energyKcal100.toString() ?? "";
    _mealCarbsController.text =
        _mealEntity.nutriments.carbohydrates100g.toString() ?? "";
    _mealFatController.text = _mealEntity.nutriments.fat100g.toString() ?? "";
    _mealProteinController.text =
        _mealEntity.nutriments.proteins100g.toString() ?? "";

    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).editMealLabel)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
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
              controller: _mealNameController,
              decoration: InputDecoration(
                  labelText: S.of(context).mealNameLabel,
                  border: const OutlineInputBorder()),
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _mealBrandsController,
              decoration: InputDecoration(
                  labelText: S.of(context).mealBrandsLabel,
                  border: const OutlineInputBorder()),
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _mealSizeController,
              decoration: InputDecoration(
                  labelText: S.of(context).mealSizeLabel,
                  border: const OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField(
              value: _mealUnitDropdownItems.first.value,
              items: _mealUnitDropdownItems,
              onChanged: (text) {},
              decoration: InputDecoration(
                  labelText: S.of(context).mealUnitLabel,
                  border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 48),
            TextFormField(
              controller: _mealKcalController,
              decoration: InputDecoration(
                  labelText: S.of(context).mealKcalLabel,
                  border: const OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _mealCarbsController,
              decoration: InputDecoration(
                  labelText: S.of(context).mealCarbsLabel,
                  border: const OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _mealFatController,
              decoration: InputDecoration(
                  labelText: S.of(context).mealFatLabel,
                  border: const OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _mealProteinController,
              decoration: InputDecoration(
                  labelText: S.of(context).mealProteinLabel,
                  border: const OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }
}

class EditMealScreenArguments {
  final MealEntity mealEntity;

  EditMealScreenArguments(this.mealEntity);
}
