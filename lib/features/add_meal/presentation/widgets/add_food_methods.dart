import 'package:flutter/material.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/core/utils/custom_icons.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// The three ways into the add-food screen besides typing a search: scan a
/// barcode, photograph the meal, or describe it in words.
///
/// These used to be an icon inside the search field and an icon in the app
/// bar that opened a second screen, which is where the photo action lived —
/// two taps deep and unlabelled. Laid out side by side under the search
/// field, each one names itself, and the two that a model reads say so.
class AddFoodMethodTiles extends StatelessWidget {
  final VoidCallback onBarcodePressed;
  final VoidCallback onSnapMealPressed;
  final VoidCallback onDescribePressed;

  /// Whether the describe panel below is open, so its tile reads as on.
  final bool describeOpen;

  const AddFoodMethodTiles({
    super.key,
    required this.onBarcodePressed,
    required this.onSnapMealPressed,
    required this.onDescribePressed,
    required this.describeOpen,
  });

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppPalette.dark
        : AppPalette.light;
    final scheme = Theme.of(context).colorScheme;
    final s = S.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Semantics(
            identifier: 'add-meal-method-barcode',
            container: true,
            child: _MethodTile(
              icon: CustomIcons.barcode_scan,
              label: s.customMealBarcodeLabel,
              background: palette.surface,
              foreground: palette.textStrong,
              border: palette.border,
              onPressed: onBarcodePressed,
            ),
          ),
        ),
        const SizedBox(width: Dimens.spacing8),
        Expanded(
          child: Semantics(
            identifier: 'add-meal-method-photo',
            container: true,
            child: _MethodTile(
              icon: Icons.photo_camera_rounded,
              label: s.addMealSnapMealLabel,
              background: scheme.primary,
              foreground: scheme.onPrimary,
              ai: true,
              onPressed: onSnapMealPressed,
            ),
          ),
        ),
        const SizedBox(width: Dimens.spacing8),
        Expanded(
          child: Semantics(
            identifier: 'add-meal-method-describe',
            container: true,
            selected: describeOpen,
            child: _MethodTile(
              icon: Icons.auto_awesome_rounded,
              label: s.addMealDescribeLabel,
              background: describeOpen
                  ? Color.alphaBlend(
                      scheme.primary.withValues(alpha: 0.16),
                      palette.surfaceMuted,
                    )
                  : palette.surfaceMuted,
              foreground: palette.textStrong,
              border: describeOpen
                  ? scheme.primary
                  : scheme.primary.withValues(alpha: 0.35),
              ai: true,
              onPressed: onDescribePressed,
            ),
          ),
        ),
      ],
    );
  }
}

class _MethodTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;
  final Color? border;
  final bool ai;
  final VoidCallback onPressed;

  const _MethodTile({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    required this.onPressed,
    this.border,
    this.ai = false,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final shape = RoundedRectangleBorder(
      borderRadius: Dimens.borderRadiusM,
      side: border == null
          ? BorderSide.none
          : BorderSide(color: border!, width: Dimens.hairline),
    );
    return Material(
      color: background,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Dimens.spacing4,
                Dimens.spacing16,
                Dimens.spacing4,
                Dimens.spacing12,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(icon, size: 26, color: foreground),
                  const SizedBox(height: Dimens.spacing8),
                  // Wraps rather than ellipsizes: the labels are a word or
                  // two, and a clipped "Snap m…" names nothing.
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: textTheme.labelLarge?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            if (ai)
              PositionedDirectional(
                top: 7,
                end: 8,
                child: _AiBadge(tileColor: background, textColor: foreground),
              ),
          ],
        ),
      ),
    );
  }
}

/// Marks the two methods a model reads. The word is not translated: it is the
/// same two letters in every shipped language, and the experimental notice
/// lives on the screens behind these tiles.
class _AiBadge extends StatelessWidget {
  final Color tileColor;
  final Color textColor;

  const _AiBadge({required this.tileColor, required this.textColor});

  @override
  Widget build(BuildContext context) {
    // Inverted against whatever the tile is, so it reads on the accent tile
    // and the muted one alike.
    return ExcludeSemantics(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          color: textColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'AI',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: tileColor,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

/// The describe panel the Describe tile opens in place: type the meal, then
/// let the review screen match it.
class DescribeMealPanel extends StatefulWidget {
  final ValueChanged<String> onFindFoods;

  const DescribeMealPanel({super.key, required this.onFindFoods});

  @override
  State<DescribeMealPanel> createState() => _DescribeMealPanelState();
}

class _DescribeMealPanelState extends State<DescribeMealPanel> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppPalette.dark
        : AppPalette.light;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: const BorderRadius.all(Radius.circular(22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            identifier: 'add-meal-describe-input',
            child: TextField(
              controller: _controller,
              autofocus: true,
              minLines: 2,
              maxLines: 4,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              style: textTheme.bodyLarge,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: S.of(context).bulkAddInputHint,
                hintStyle: textTheme.bodyLarge?.copyWith(
                  color: palette.textMuted,
                ),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: Dimens.spacing12,
                  vertical: Dimens.spacing8,
                ),
              ),
            ),
          ),
          Semantics(
            identifier: 'add-meal-describe-submit',
            child: FilledButton.icon(
              onPressed: _controller.text.trim().isEmpty
                  ? null
                  : () {
                      FocusScope.of(context).unfocus();
                      widget.onFindFoods(_controller.text);
                    },
              icon: const Icon(Icons.search_rounded, size: 18),
              label: Text(S.of(context).bulkAddParseLabel),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                shape: const StadiumBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
