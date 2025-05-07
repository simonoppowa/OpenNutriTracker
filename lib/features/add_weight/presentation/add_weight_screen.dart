import 'package:flutter/material.dart';
import 'package:opennutritracker/generated/l10n.dart';

class AddWeightScreen extends StatefulWidget {
  const AddWeightScreen({super.key});

  @override
  State<AddWeightScreen> createState() => _AddWeightScreenState();
}

class _AddWeightScreenState extends State<AddWeightScreen> {
  double _currentValue = 70;

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
                    icon: Icon(Icons.remove, // Icon '-'
                        size: 35,
                        color: Theme.of(context).colorScheme.onSurface),
                    onPressed: () {
                      setState(() {
                        _currentValue -= 0.05;
                      });
                    },
                  ),
                  Text(
                    _currentValue.toStringAsFixed(2),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  IconButton(
                    icon: Icon(Icons.add, // Icon '+'
                        size: 35,
                        color: Theme.of(context).colorScheme.onSurface),
                    onPressed: () {
                      setState(() {
                        _currentValue += 0.05;
                      });
                    },
                  ),
                ],
              )),
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
