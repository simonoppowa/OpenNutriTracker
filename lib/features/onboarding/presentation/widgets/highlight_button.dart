import 'package:flutter/material.dart';

class HighlightButton extends StatefulWidget {
  final String buttonLabel;
  final VoidCallback onButtonPressed;
  final bool buttonActive;

  const HighlightButton(
      {Key? key,
      required this.buttonLabel,
      required this.onButtonPressed,
      required this.buttonActive})
      : super(key: key);

  @override
  State<HighlightButton> createState() => _HighlightButtonState();
}

class _HighlightButtonState extends State<HighlightButton> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton.icon(
          onPressed: widget.buttonActive ? widget.onButtonPressed : null,
          style: ElevatedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          ).copyWith(elevation: ButtonStyleButton.allOrNull(0.0)),
          icon: const Icon(Icons.navigate_next_outlined),
          label: Text(widget.buttonLabel,
              style: Theme.of(context).textTheme.labelLarge)),
    );
  }
}
