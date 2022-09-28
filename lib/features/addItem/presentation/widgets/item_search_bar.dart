import 'package:flutter/material.dart';
import 'package:opennutritracker/generated/l10n.dart';

class ItemSearchBar extends StatelessWidget {
  const ItemSearchBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          flex: 1,
          child: TextField(
              textInputAction: TextInputAction.search,
              onSubmitted: (String text) {},
              decoration: InputDecoration(
                hintText: S.of(context).searchLabel,
                prefixIcon: const Icon(Icons.search_outlined),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner_outlined),
                  onPressed: () {},
                ),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              )),
        ),
        const SizedBox(width: 8.0),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.search_outlined),
          style: IconButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              backgroundColor: Theme.of(context).colorScheme.primary),
        )
      ],
    );
  }
}
