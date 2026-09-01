import 'package:flutter/material.dart';
import 'package:opennutritracker/core/presentation/ai_assist_summary.dart';
import 'package:opennutritracker/core/utils/ai_credential_storage.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// The agreement that stands between pressing OK and a credential being
/// stored.
///
/// The same words were already on screen before this existed — as a paragraph
/// of `bodySmall` below the fields, which is where a reader's eye does not go
/// on the way to a key box. Nothing about *what* the app says changed here.
/// What changed is that it now has to be read past rather than scrolled past,
/// and answered.
///
/// **A screen rather than a checkbox beside that paragraph.** A tick box next
/// to small print is ticked without reading, which would have produced the
/// appearance of consent and none of the substance.
///
/// It is shown before anything is written, which is also what the paragraph
/// itself promises: it is a *saved* credential that starts the sending, so
/// asking here means nothing has left the device when the question is put.
class AiConsentScreen extends StatelessWidget {
  const AiConsentScreen({
    super.key,
    required this.provider,
    required this.typedEndpoint,
  });

  /// The destination selected at this moment. Named on screen, because the
  /// agreement is worth less if the user cannot see who it is with.
  final AiProvider provider;

  /// The address as it currently reads in the field, for a server the user
  /// runs. #736: an address they can check on sight.
  final String typedEndpoint;

  /// Returns true only if the user agreed. A dismissed route — back gesture,
  /// system back — is not agreement, so it reads as false.
  static Future<bool> show(
    BuildContext context, {
    required AiProvider provider,
    required String typedEndpoint,
  }) async =>
      await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => AiConsentScreen(
            provider: provider,
            typedEndpoint: typedEndpoint,
          ),
        ),
      ) ??
      false;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    // Deliberately not `bodySmall`. The size this is set at is most of what
    // this screen changes.
    final body = theme.textTheme.bodyLarge;

    return Scaffold(
      appBar: AppBar(title: Text(s.aiConsentTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            // The destination first, because it is the fact that changes
            // between one user's decision and another's.
            Text(
              aiDisclosureFor(
                s,
                provider: provider,
                typedEndpoint: typedEndpoint,
              ),
              style: body,
            ),
            const SizedBox(height: 20),
            // What holds whichever provider is chosen — the diary, the
            // nutrition numbers, the key. Already written, already translated,
            // and the same sentences the settings dialog shows.
            Text(s.aiAssistDisclosureCommon, style: body),
            const SizedBox(height: 20),
            // One agreement covers the feature, not one provider (#835), so
            // the screen has to say that plainly rather than let a user infer
            // they agreed only to the company in front of them.
            Text(
              s.aiConsentChangeProviderNote,
              style: body?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            // Only a server the user runs is contacted before the feature is
            // used: saving its address asks it for its model list and runs the
            // setup check. The three hosted providers have a curated catalogue
            // and no probe, so they are sent nothing until a meal is read, and
            // a note about checks would be false for them rather than merely
            // redundant.
            //
            // The note above stays true for every provider because of its
            // qualifier — nothing *you type or photograph* — which the probe
            // does not breach: it sends a fixed line and a bundled photograph.
            // This paragraph is what makes that qualifier legible instead of
            // lawyerly, on the one screen whose job is to be accurate before
            // someone agrees. #985.
            if (provider == AiProvider.ownServer) ...[
              const SizedBox(height: 12),
              Text(
                s.aiConsentOwnServerCheckNote,
                style: body?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 20),
            Text(
              s.aiAssistExperimentalNote,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 28),
            Semantics(
              identifier: 'ai-consent-agree',
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(s.aiConsentAgreeLabel),
              ),
            ),
            const SizedBox(height: 8),
            Semantics(
              identifier: 'ai-consent-decline',
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(s.dialogCancelLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
