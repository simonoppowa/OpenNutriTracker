import 'package:flutter/material.dart';
import 'package:opennutritracker/features/add_weight/presentation/bloc/weight_bloc.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';

import 'package:opennutritracker/core/domain/usecase/add_weight_usecase.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_entity.dart';

class AddWeightScreen extends StatefulWidget {
  const AddWeightScreen({super.key});

  @override
  State<AddWeightScreen> createState() => _AddWeightScreenState();
}

class _AddWeightScreenState extends State<AddWeightScreen> {
  late WeightBloc _weightBloc;
  late AddWeightUsecase _addWeightUsecase;

  @override
  void initState() {
    _weightBloc = locator<WeightBloc>();
    _addWeightUsecase = locator<AddWeightUsecase>();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).weightLabel),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            padding: const EdgeInsets.all(20.0),
            decoration: ShapeDecoration(
              color: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              shadows: kElevationToShadow[2],
            ),
            child: Column(
              mainAxisSize: MainAxisSize
                  .min, // Pour que la colonne ne prenne que la hauteur nécessaire
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () => _weightBloc.add(WeightDecrement()),
                    ),
                    BlocBuilder<WeightBloc, WeightState>(
                      bloc: _weightBloc,
                      builder: (context, state) {
                        return Text(
                          "${state.weight.toStringAsFixed(1)} kg",
                          style: Theme.of(context).textTheme.headlineMedium,
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => _weightBloc.add(WeightIncrement()),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _addWeightUsecase.addUserActivity(
                        UserWeightEntity(
                            id: "id",
                            weight: _weightBloc.finalWeight,
                            date: DateTime.now())),
                    child: Text("Save"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AddWeightScreenArguments {
  final DateTime day;

  AddWeightScreenArguments({required this.day});
}
