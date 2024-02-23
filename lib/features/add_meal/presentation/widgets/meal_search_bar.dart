import 'package:flutter/material.dart';
import 'package:opennutritracker/core/utils/custom_icons.dart';
import 'package:opennutritracker/generated/l10n.dart';

class MealSearchBar extends StatelessWidget {
  final ValueNotifier<String> searchStringListener;
  final Function(String) onSearchSubmit;
  final Function() onBarcodePressed;

  final _searchTextController = TextEditingController();

  MealSearchBar(
      {super.key,
      required this.searchStringListener,
      required this.onSearchSubmit,
      required this.onBarcodePressed});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          flex: 1,
          child: TextField(
              controller: _searchTextController,
              textInputAction: TextInputAction.search,
              onChanged: (input) {
                searchStringListener.value = input;
              },
              onSubmitted: onSearchSubmit,
              decoration: InputDecoration(
                hintText: S.of(context).searchLabel,
                prefixIcon: const Icon(Icons.search_outlined),
                suffixIcon: IconButton(
                  icon: const Icon(CustomIcons.barcode_scan),
                  onPressed: () {
                    onBarcodePressed();
                  },
                ),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              )),
        ),
        const SizedBox(width: 8.0),
        IconButton(
          onPressed: () {
            FocusManager.instance.primaryFocus?.unfocus(); // Hide Keyboard
            onSearchSubmit(_searchTextController.text);
          },
          icon: const Icon(Icons.search_outlined),
          style: IconButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              backgroundColor: Theme.of(context).colorScheme.primary),
        )
      ],
    );
  }
}
