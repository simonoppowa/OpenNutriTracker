import 'package:flutter/material.dart';

class PlaceholderCard extends StatelessWidget {
  final DateTime day;
  final VoidCallback onTap;
  final bool firstListElement;

  const PlaceholderCard({
    super.key,
    required this.day,
    required this.onTap,
    required this.firstListElement,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: Row(
        children: [
          SizedBox(
            width: firstListElement ? 16 : 0, // Add leading padding
          ),
          SizedBox(
            width: 120,
            height: 120,
            child: Card(
              clipBehavior: Clip.antiAliasWithSaveLayer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: InkWell(
                onTap: onTap,
                child: Icon(Icons.add,
                    size: 36,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.5)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
