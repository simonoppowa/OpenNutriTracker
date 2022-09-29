import 'package:flutter/material.dart';
import 'package:opennutritracker/generated/l10n.dart';

class ItemDetailBottomSheet extends StatefulWidget {
  const ItemDetailBottomSheet({Key? key}) : super(key: key);

  @override
  State<ItemDetailBottomSheet> createState() => _ItemDetailBottomSheetState();
}

class _ItemDetailBottomSheetState extends State<ItemDetailBottomSheet> {
  @override
  Widget build(BuildContext context) {
    return BottomSheet(
        elevation: 10,
        onClosing: () {},
        builder: (context) {
          return Wrap(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 32.0, 16.0, 8.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: '100',
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              labelText: S.of(context).quantityLabel,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16.0),
                        Expanded(
                            child: DropdownButtonFormField(
                          decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              labelText: S.of(context).unitLabel),
                          items: const <DropdownMenuItem<String>>[
                            DropdownMenuItem(child: Text('g'))
                          ],
                          onChanged: (Object? value) {},
                        ))
                      ],
                    ),
                    SizedBox(
                      width: double.infinity, // Make button full width
                      child: ElevatedButton.icon(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                            backgroundColor:
                                Theme.of(context).colorScheme.primaryContainer,
                          ).copyWith(
                              elevation: ButtonStyleButton.allOrNull(0.0)),
                          icon: const Icon(Icons.add_outlined),
                          label: Text(S.of(context).addLabel)),
                    ),
                  ],
                ),
              ),
            ],
          );
        });
  }
}
