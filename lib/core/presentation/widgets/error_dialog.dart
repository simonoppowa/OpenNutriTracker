import 'package:flutter/material.dart';
import 'package:opennutritracker/generated/l10n.dart';

class ErrorDialog extends StatelessWidget {
  final String errorText;
  final VoidCallback onRefreshPressed;

  const ErrorDialog(
      {Key? key, required this.errorText, required this.onRefreshPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 64),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off,
            size: 64,
          ),
          const SizedBox(height: 8),
          Text(errorText, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ElevatedButton.icon(
              onPressed: () => onRefreshPressed(),
              icon: const Icon(Icons.refresh_outlined),
              label: Text(S.of(context).retryLabel))
        ],
      ),
    );
  }
}
