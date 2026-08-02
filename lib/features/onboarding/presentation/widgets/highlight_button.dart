import 'package:flutter/material.dart';

class HighlightButton extends StatefulWidget {
  final String buttonLabel;
  final VoidCallback onButtonPressed;
  final bool buttonActive;

  /// Shown as a snackbar when the button is tapped while [buttonActive] is
  /// false, so a blocked step says what it is waiting for instead of
  /// swallowing the tap. Null keeps the older behaviour of an inert button,
  /// for pages that can never be blocked.
  final String? inactiveMessage;

  /// Called alongside the message when a blocked button is tapped, so the
  /// page can also point at the fields that are holding it up.
  final VoidCallback? onBlockedPressed;

  const HighlightButton({
    super.key,
    required this.buttonLabel,
    required this.onButtonPressed,
    required this.buttonActive,
    this.inactiveMessage,
    this.onBlockedPressed,
  });

  @override
  State<HighlightButton> createState() => _HighlightButtonState();
}

class _HighlightButtonState extends State<HighlightButton> {
  /// Keeps the disabled *look* while the button stays tappable: Material 3's
  /// disabled button colours, applied by hand because the button is only
  /// visually disabled, not actually disabled.
  ButtonStyle _inactiveStyle(ColorScheme colors) => ElevatedButton.styleFrom(
    foregroundColor: colors.onSurface.withValues(alpha: 0.38),
    backgroundColor: colors.onSurface.withValues(alpha: 0.12),
  ).copyWith(elevation: ButtonStyleButton.allOrNull(0.0));

  void _onBlockedPressed() {
    widget.onBlockedPressed?.call();
    final message = widget.inactiveMessage;
    if (message == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final active = widget.buttonActive;
    // A blocked button with nothing to say and nothing to do stays
    // genuinely disabled.
    final hasBlockedBehaviour =
        widget.inactiveMessage != null || widget.onBlockedPressed != null;
    final onPressed = active
        ? widget.onButtonPressed
        : (hasBlockedBehaviour ? _onBlockedPressed : null);
    // A blocked button reads as an ordinary one to a screen reader: the grey
    // is the only cue that the step can't be completed, and that cue is
    // visual. Publish the reason as the button's hint so it is announced
    // along with the label.
    //
    // The node is not marked disabled. This button does respond — it explains
    // itself — and some screen readers skip disabled controls, which would
    // bury the very explanation being added here. `excludeSemantics` replaces
    // the button's own node rather than sitting beside it, so the label, the
    // hint and the tap action are announced as one control.
    final blockedReason = active ? null : widget.inactiveMessage;
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
          // of the button.
          container: true,
          button: blockedReason != null ? true : null,
          label: blockedReason != null ? widget.buttonLabel : null,
          hint: blockedReason,
          onTap: blockedReason != null ? _onBlockedPressed : null,
          excludeSemantics: blockedReason != null,
          child: ElevatedButton.icon(
            onPressed: onPressed,
            style: active
                ? ElevatedButton.styleFrom(
                    foregroundColor: colors.onPrimaryContainer,
                    backgroundColor: colors.primaryContainer,
                  ).copyWith(elevation: ButtonStyleButton.allOrNull(0.0))
                : _inactiveStyle(colors),
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
