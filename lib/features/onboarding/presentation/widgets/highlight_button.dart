import 'package:flutter/material.dart';

class HighlightButton extends StatefulWidget {
  final String buttonLabel;
  final VoidCallback onButtonPressed;
  final bool buttonActive;

  const HighlightButton({
    super.key,
    required this.buttonLabel,
    required this.onButtonPressed,
    required this.buttonActive,
  });

  @override
  State<HighlightButton> createState() => _HighlightButtonState();
}

class _HighlightButtonState extends State<HighlightButton> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.bottomCenter,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Semantics(
          identifier: 'onboarding-button',
          // `container: true` is load-bearing: without it the Semantics node
          // inherits the surrounding Expanded/Container bounds (the full
          // footer area) and uiautomator-based tests tap mid-screen instead
          // of the button. Visible/TalkBack behavior is unchanged — this
          // Semantics carries no role or label, only the test identifier.
          container: true,
          child: ElevatedButton.icon(
            onPressed: widget.buttonActive ? widget.onButtonPressed : null,
            style: ElevatedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            ).copyWith(elevation: ButtonStyleButton.allOrNull(0.0)),
            icon: const Icon(Icons.navigate_next_outlined),
            label: Text(
              widget.buttonLabel,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
        ),
      ),
    );
  }
}
