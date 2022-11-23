import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/product_entity.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

class MealDetailBottomSheet extends StatefulWidget {
  final ProductEntity product;
  final IntakeTypeEntity intakeTypeEntity;
  final TextEditingController quantityTextController;
  final MealDetailBloc mealDetailBloc;

  const MealDetailBottomSheet(
      {Key? key,
      required this.product,
      required this.intakeTypeEntity,
      required this.mealDetailBloc,
      required this.quantityTextController})
      : super(key: key);

  @override
  State<MealDetailBottomSheet> createState() => _MealDetailBottomSheetState();
}

class _MealDetailBottomSheetState extends State<MealDetailBottomSheet> {
  @override
  Widget build(BuildContext context) {
    return BottomSheet(
        elevation: 10,
        onClosing: () {},
        enableDrag: false,
        builder: (context) {
          return Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
                width: 0.5,
              ),
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
            ),
            child: Wrap(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 32.0, 16.0, 8.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: widget.quantityTextController,
                              keyboardType: TextInputType.number,
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9]+[,.]{0,1}[0-9]*')),
                                TextInputFormatter.withFunction(
                                  (oldValue, newValue) => newValue.copyWith(
                                    text: newValue.text.replaceAll(',', '.'),
                                  ),
                                ),
                              ],
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                labelText: S.of(context).quantityLabel,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16.0),
                          Expanded(
                              child: DropdownButtonFormField(
                            decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                labelText: S.of(context).unitLabel),
                            items: const <DropdownMenuItem<String>>[
                              DropdownMenuItem(child: Text('g'))
                            ],
                            onChanged: (Object? value) {},
                          ))
                        ],
                      ),
                      SizedBox(
                        width: double.infinity, // Make button full width
                        child: ElevatedButton.icon(
                            onPressed: () {
                              onAddButtonPressed(context);
                            },
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                            ).copyWith(
                                elevation: ButtonStyleButton.allOrNull(0.0)),
                            icon: const Icon(Icons.add_outlined),
                            label: Text(S.of(context).addLabel)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        });
  }

  void onAddButtonPressed(BuildContext context) {
    // TODO

    widget.mealDetailBloc.addIntake(
        context,
        widget.product.productUnit ?? "g",
        widget.quantityTextController.text,
        widget.intakeTypeEntity,
        widget.product);

    // Refresh Home Page
    Provider.of<HomeBloc>(context, listen: false)
        .add(LoadItemsEvent(context: context));

    // Show snackbar and return to dashboard
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).infoAddedIntakeLabel)));
    Navigator.of(context)
        .popUntil(ModalRoute.withName(NavigationOptions.mainRoute));
  }
}
