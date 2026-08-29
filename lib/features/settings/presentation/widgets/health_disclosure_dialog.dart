import 'package:flutter/material.dart';
import 'package:opennutritracker/features/settings/presentation/widgets/health_sync_screen.dart'
    show healthPlatformName;
import 'package:opennutritracker/generated/l10n.dart';

/// Says what the health import will read, and what for, before the platform is
/// ever asked for permission (#926).
///
/// Play's User Data policy wants a disclosure inside the app, ahead of the
/// system prompt, resolved by an affirmative action. The system prompt is not
/// a substitute: it names the data types and nothing else — not what they are
/// used for, not that nothing is written back, not that none of it leaves the
/// device. Those are the parts a person actually needs, and until now the app
/// never said them anywhere the user would look before deciding.
///
/// Returns true only on the confirm action. A dismissal returns null and the
/// caller treats that as a refusal, so nothing is ever asked for by accident —
/// which is why the barrier is not dismissible and there is no default.
///
/// Shown on iOS too. `NSHealthShareUsageDescription` already carries the same
/// sentences into Apple's prompt, so this is not required there, but a
/// disclosure that appeared on one platform and not the other would be a
/// strange thing to explain and a worse thing to maintain.
class HealthDisclosureDialog extends StatelessWidget {
  const HealthDisclosureDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return AlertDialog(
      // Four paragraphs, and German runs longest of the nine languages — the
      // dialog's own column is what overflows on a short viewport, so the
      // whole thing scrolls rather than just the content (see
      // PolicyChangeDialog, which had exactly this bug).
      scrollable: true,
      title: Text(s.healthSyncDisclosureTitle(healthPlatformName)),
      content: Text(s.healthSyncDisclosureBody(healthPlatformName)),
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
