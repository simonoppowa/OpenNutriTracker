import 'package:flutter/material.dart';
import 'package:opennutritracker/features/add_weight/presentation/bloc/weight_bloc.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';

class AddWeightScreen extends StatefulWidget {
  const AddWeightScreen({super.key});

  @override
  State<AddWeightScreen> createState() => _AddWeightScreenState();
}

class _AddWeightScreenState extends State<AddWeightScreen> {
  late WeightBloc _weightBloc;

  @override
  void initState() {
    _weightBloc = locator<WeightBloc>();
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
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.remove),
                    onPressed: () => _weightBloc.add(WeightDecrement()),
                  ),
                  BlocBuilder<WeightBloc, WeightState>(
                    bloc: _weightBloc,
                    builder: (context, state) {
                      return Text(
                        state.weight.toStringAsFixed(
                            2), // Affiche le poids avec 2 décimales
                        style: Theme.of(context).textTheme.headlineMedium,
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.add),
                    onPressed: () => _weightBloc.add(WeightIncrement()),
                  )
                ]),
          ),
        ),
      ),
    );
  }
}

class AddWeightScreenArguments {
  final DateTime day;
  final double weight;

  AddWeightScreenArguments({required this.day, required this.weight});
}
