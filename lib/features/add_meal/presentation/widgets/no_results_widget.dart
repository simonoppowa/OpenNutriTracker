import 'package:flutter/material.dart';
import 'package:opennutritracker/generated/l10n.dart';

class NoResultsWidget extends StatelessWidget {
  const NoResultsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 64),
      child: Column(
        children: [
          const Icon(Icons.search, size: 64),
          const SizedBox(height: 8),
          Text(S.of(context).noResultsFound,
              style: Theme.of(context).textTheme.titleMedium)
        ],
      ),
    );
  }
}
