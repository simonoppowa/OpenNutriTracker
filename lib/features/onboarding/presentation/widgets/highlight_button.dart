import 'package:flutter/material.dart';

class HighlightButton extends StatelessWidget {
  final String buttonLabel;

  const HighlightButton({Key? key, required this.buttonLabel})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        ).copyWith(elevation: ButtonStyleButton.allOrNull(0.0)),
        icon: const Icon(Icons.navigate_next_outlined),
        label: Text(buttonLabel, style: Theme.of(context).textTheme.button));
  }
}
