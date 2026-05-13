import 'package:flutter/material.dart';
import 'package:opennutritracker/core/utils/url_const.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:url_launcher/url_launcher.dart';

/// Surfaces the peer-reviewed sources behind every health/medical
/// calculation OpenNutriTracker shows. Reachable from the Home dashboard,
/// the BMI overview on the Profile tab, the disclaimer dialog, and a
/// dedicated tile in Settings — so anyone scanning the app for citations
/// (Apple's reviewers included) can find them within one tap.
class SourcesScreen extends StatelessWidget {
  const SourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final entries = <_SourceEntry>[
      _SourceEntry(
        title: l10n.sourcesEnergyTitle,
        description: l10n.sourcesEnergyDescription,
        url: URLConst.sourceEnergyIomDriURL,
      ),
      _SourceEntry(
        title: l10n.sourcesBmiTitle,
        description: l10n.sourcesBmiDescription,
        url: URLConst.sourceBmiWhoURL,
      ),
      _SourceEntry(
        title: l10n.sourcesMacrosTitle,
        description: l10n.sourcesMacrosDescription,
        url: URLConst.sourceMacrosWhoTrs916URL,
      ),
      _SourceEntry(
        title: l10n.sourcesActivityTitle,
        description: l10n.sourcesActivityDescription,
        url: URLConst.sourceActivityCompendium2024URL,
      ),
      _SourceEntry(
        title: l10n.sourcesNonBinaryTitle,
        description: l10n.sourcesNonBinaryDescription,
        url: URLConst.sourceInclusiveDesignLinsenmeyer2021URL,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsSourcesLabel)),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          Text(
            l10n.sourcesScreenIntro,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          ...entries.map(
            (entry) => _SourceCard(
              entry: entry,
              onOpen: () => _launch(context, entry.url),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launch(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    final l10n = S.of(context);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorOpeningBrowser)),
      );
    }
  }
}

class _SourceEntry {
  final String title;
  final String description;
  final String url;

  const _SourceEntry({
    required this.title,
    required this.description,
    required this.url,
  });
}

class _SourceCard extends StatelessWidget {
  final _SourceEntry entry;
  final VoidCallback onOpen;

  const _SourceCard({required this.entry, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              entry.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.open_in_new_outlined),
                label: Text(S.of(context).sourcesOpenSourceLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
