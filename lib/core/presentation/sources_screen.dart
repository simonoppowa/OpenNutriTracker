import 'package:flutter/material.dart';
import 'package:opennutritracker/core/presentation/widgets/app_card.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/core/utils/url_const.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:url_launcher/url_launcher.dart';

/// Surfaces the peer-reviewed sources behind every health/medical
/// calculation OpenNutriTracker shows. Reachable from the Home dashboard,
/// the BMI overview on the Profile tab, both gender-selection screens,
/// and the disclaimer dialog — so anyone scanning the app for citations
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
        sources: const [
          _SourceLink(
            citation:
                'Institute of Medicine (2005). Dietary Reference Intakes for '
                'Energy, Carbohydrate, Fiber, Fat, Fatty Acids, Cholesterol, '
                'Protein, and Amino Acids. National Academies Press.',
            url: URLConst.sourceEnergyIomDriURL,
          ),
        ],
      ),
      _SourceEntry(
        title: l10n.sourcesBmiTitle,
        description: l10n.sourcesBmiDescription,
        sources: const [
          _SourceLink(
            citation:
                'World Health Organization. Body mass index (BMI), adult '
                'classification. WHO Global Health Observatory.',
            url: URLConst.sourceBmiWhoURL,
          ),
        ],
      ),
      _SourceEntry(
        title: l10n.sourcesMacrosTitle,
        description: l10n.sourcesMacrosDescription,
        sources: const [
          _SourceLink(
            citation:
                'World Health Organization (2003). Diet, Nutrition and the '
                'Prevention of Chronic Diseases. WHO Technical Report '
                'Series 916.',
            url: URLConst.sourceMacrosWhoTrs916URL,
          ),
        ],
      ),
      _SourceEntry(
        title: l10n.sourcesActivityTitle,
        description: l10n.sourcesActivityDescription,
        sources: const [
          _SourceLink(
            citation:
                'Herrmann SD, et al. (2024). 2024 Adult Compendium of '
                'Physical Activities. Journal of Sport and Health Science.',
            url: URLConst.sourceActivityCompendium2024URL,
          ),
        ],
      ),
      _SourceEntry(
        title: l10n.sourcesNonBinaryTitle,
        description: l10n.sourcesNonBinaryDescription,
        sources: const [
          _SourceLink(
            citation:
                'Linsenmeyer W, Waters J (2021). Sex and gender differences '
                'in nutrition research: considerations with the transgender '
                'and gender nonconforming population. Nutrition Journal, '
                '20:6.',
            url: URLConst.sourceInclusiveDesignLinsenmeyer2021URL,
          ),
          _SourceLink(
            citation:
                'Wiik A, et al. (2018). Metabolic and functional changes in '
                'transgender individuals following cross-sex hormone '
                'treatment: Design and methods of the GETS study. '
                'Contemporary Clinical Trials Communications, 10:148–153.',
            url: URLConst.sourceTransMetabolismWiik2018URL,
          ),
          _SourceLink(
            citation:
                'Linsenmeyer W, Drallmeier T, Thomure M (2020). Towards '
                'gender-affirming nutrition assessment: a case series of '
                'adult transgender men with distinct nutrition '
                'considerations. Nutrition Journal, 19:74.',
            url: URLConst.sourceTransNutritionLinsenmeyer2020URL,
          ),
        ],
      ),
      _SourceEntry(
        title: l10n.sourcesNutrientReferenceTitle,
        description: l10n.sourcesNutrientReferenceDescription,
        sources: const [
          _SourceLink(
            citation:
                'Institute of Medicine. Dietary Reference Intakes: The '
                'Essential Guide to Nutrient Requirements. Summary Report. '
                'National Academies Press.',
            url: URLConst.sourceNutrientReferenceIomURL,
          ),
        ],
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsSourcesLabel)),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: Dimens.spacing16, vertical: Dimens.spacing16),
        children: [
          Text(
            l10n.sourcesScreenIntro,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: Dimens.spacing16),
          ...entries.map((entry) => _SourceCard(entry: entry)),
        ],
      ),
    );
  }
}

class _SourceEntry {
  final String title;
  final String description;
  final List<_SourceLink> sources;

  const _SourceEntry({
    required this.title,
    required this.description,
    required this.sources,
  });
}

class _SourceLink {
  // Paper citations stay in English by academic convention — the journal,
  // authors, and title are the canonical record regardless of the user's
  // app language.
  final String citation;
  final String url;

  const _SourceLink({required this.citation, required this.url});
}

class _SourceCard extends StatelessWidget {
  final _SourceEntry entry;

  const _SourceCard({required this.entry});

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Dimens.spacing12),
      child: AppCard(
        padding: const EdgeInsets.all(Dimens.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.title,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: Dimens.spacing8),
            Text(
              entry.description,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: Dimens.spacing12),
            ...entry.sources.map(
              (source) => Padding(
                padding: const EdgeInsets.only(bottom: Dimens.spacing4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      source.citation,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton.icon(
                        onPressed: () => _launch(context, source.url),
                        icon: const Icon(Icons.open_in_new_rounded, size: 18),
                        label: Text(S.of(context).sourcesOpenSourceLabel),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: Dimens.spacing8),
                          minimumSize: const Size(0, 32),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
