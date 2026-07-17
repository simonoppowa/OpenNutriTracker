import 'package:flutter/material.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/core/utils/custom_icons.dart';
import 'package:opennutritracker/generated/l10n.dart';

class MealSearchBar extends StatefulWidget {
  final ValueNotifier<String> searchStringListener;
  final Function(String) onSearchSubmit;
  // Fired on every keystroke for debounced search-as-you-type. Optional so
  // callers that only want submit-on-enter can omit it.
  final Function(String)? onSearchChanged;
  // Nullable so callers that don't surface a barcode flow (e.g. the recipe
  // ingredient picker) can omit the suffix icon entirely.
  final Function()? onBarcodePressed;

  const MealSearchBar({
    super.key,
    required this.searchStringListener,
    required this.onSearchSubmit,
    required this.onBarcodePressed,
    this.onSearchChanged,
  });

  @override
  State<MealSearchBar> createState() => _MealSearchBarState();
}

class _MealSearchBarState extends State<MealSearchBar> {
  // Owned by the State so it survives parent rebuilds. The add-meal screen
  // switches search source on the first keystroke, which rebuilds this widget;
  // a controller created per build would be replaced and would swallow that
  // first character (the "first input ignored" bug).
  final _searchTextController = TextEditingController();

  @override
  void dispose() {
    _searchTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = isDark ? AppPalette.dark : AppPalette.light;
    final accent = Theme.of(context).colorScheme.primary;
    final border = OutlineInputBorder(
      borderRadius: Dimens.borderRadiusL,
      borderSide: BorderSide(color: palette.border, width: Dimens.hairline),
    );
    return Row(
      children: [
        Flexible(
          flex: 1,
          child: Semantics(
            identifier: 'meal-search-field',
            child: TextField(
              controller: _searchTextController,
              textInputAction: TextInputAction.search,
              style: Theme.of(context).textTheme.bodyLarge,
              onChanged: (input) {
                widget.searchStringListener.value = input;
                widget.onSearchChanged?.call(input);
              },
              onSubmitted: widget.onSearchSubmit,
              decoration: InputDecoration(
                hintText: S.of(context).searchLabel,
                hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(color: palette.textMuted),
                prefixIcon: Icon(Icons.search_rounded, size: 24, color: palette.textMuted),
                suffixIcon: widget.onBarcodePressed != null
                    ? Semantics(
                        identifier: 'meal-search-barcode',
                        child: IconButton(
                          icon: Icon(CustomIcons.barcode_scan, size: 22, color: palette.textMuted),
                          onPressed: widget.onBarcodePressed,
                        ),
                      )
                    : null,
                filled: true,
                fillColor: palette.surfaceMuted,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: Dimens.spacing16, horizontal: Dimens.spacing16),
                border: border,
                enabledBorder: border,
                focusedBorder: OutlineInputBorder(
                  borderRadius: Dimens.borderRadiusL,
                  borderSide: BorderSide(color: accent, width: 1.5),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: Dimens.spacing12),
        Semantics(
          identifier: 'meal-search-submit',
          child: IconButton(
            onPressed: () {
              FocusManager.instance.primaryFocus?.unfocus(); // Hide Keyboard
              widget.onSearchSubmit(_searchTextController.text);
            },
            icon: const Icon(Icons.search_rounded, size: 24),
            style: IconButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              backgroundColor: accent,
              padding: const EdgeInsets.all(Dimens.spacing12),
              shape: const RoundedRectangleBorder(borderRadius: Dimens.borderRadiusM),
            ),
          ),
        ),
      ],
    );
  }
}
