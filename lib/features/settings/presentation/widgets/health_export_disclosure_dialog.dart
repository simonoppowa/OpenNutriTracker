import 'package:flutter/material.dart';
import 'package:opennutritracker/features/settings/presentation/widgets/health_sync_screen.dart'
    show healthPlatformName;
import 'package:opennutritracker/generated/l10n.dart';

/// Explains what nutrition data is exported to the health store before requesting
/// write permissions from the user.
class HealthExportDisclosureDialog extends StatelessWidget {
  const HealthExportDisclosureDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return AlertDialog(
      scrollable: true,
      title: Text(s.healthSyncExportDisclosureTitle(healthPlatformName)),
      content: Text(s.healthSyncExportDisclosureBody(healthPlatformName)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(s.dialogCancelLabel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(s.healthSyncDisclosureContinueAction),
        ),
      ],
    );
  }
}
