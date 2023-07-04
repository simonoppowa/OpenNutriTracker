import 'package:flutter/material.dart';

class ErrorDialog extends StatelessWidget {
  final String errorText;

  const ErrorDialog({Key? key, required this.errorText}) : super(key: key);

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
        ],
      ),
    );
  }
}
