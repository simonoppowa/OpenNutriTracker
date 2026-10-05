import 'package:flutter/material.dart';

/// Closes the on-screen keyboard when the user taps outside a text field.
///
/// The iOS number and decimal pads have no return key, so without this a
/// numeric field could not be left at all: the keyboard stayed up over the
/// page's buttons (#1324). Flutter's own `onTapOutside` only unfocuses for
/// mouse taps on mobile.
///
/// Taps that a descendant claims (a button, a chip, the text field itself)
/// win the gesture arena, so this fires only on otherwise inert areas.
class KeyboardDismisser extends StatelessWidget {
  final Widget child;

  const KeyboardDismisser({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: child,
    );
  }
}
