import 'package:flutter/material.dart';
import 'package:opennutritracker/features/settings/presentation/widgets/health_sync_screen.dart'
    show healthPlatformName, healthStoreReadsBodyFat;
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
///
/// Workout import and weight import are separate opt-ins that ask the platform
/// for separate permissions, so each gets its own disclosure naming only what
/// that switch reads ([subject]).
class HealthDisclosureDialog extends StatelessWidget {
  final HealthDisclosureSubject subject;

  const HealthDisclosureDialog({
    super.key,
    this.subject = HealthDisclosureSubject.workouts,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return AlertDialog(
      // Four paragraphs, five where body fat is read, and German runs longest
      // of the nine languages — the dialog's own column is what overflows on a
      // short viewport, so the whole thing scrolls rather than just the
      // content (see PolicyChangeDialog, which had exactly this bug).
      scrollable: true,
      title: Text(switch (subject) {
        HealthDisclosureSubject.workouts => s.healthSyncDisclosureTitle(
          healthPlatformName,
        ),
        HealthDisclosureSubject.weight => s.healthSyncWeightDisclosureTitle(
          healthPlatformName,
        ),
      }),
      content: Text(_body(s)),
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

  /// The disclosure is assembled rather than stored as one string because the
  /// body-fat paragraph belongs only where body fat is actually read (see
  /// [healthStoreReadsBodyFat]). It goes between what is read and the closing
  /// guarantees, which is where those sentences sat when the two platforms
  /// still read the same things — a paragraph about what is collected reads
  /// as an afterthought once it follows the line about turning the feature
  /// off.
  ///
  /// The weight disclosure never carries the body-fat paragraph: body fat is
  /// requested with workouts, not with weight.
  String _body(S s) => [
    ...switch (subject) {
      HealthDisclosureSubject.workouts => [
        s.healthSyncDisclosureBody(healthPlatformName),
        if (healthStoreReadsBodyFat)
          s.healthSyncDisclosureBodyFatAddendum(healthPlatformName),
      ],
      HealthDisclosureSubject.weight => [
        s.healthSyncWeightDisclosureBody(healthPlatformName),
      ],
    },
    s.healthSyncDisclosureFooter(healthPlatformName),
  ].join('\n\n');
}

/// Which health import a [HealthDisclosureDialog] is asking consent for.
enum HealthDisclosureSubject { workouts, weight }
