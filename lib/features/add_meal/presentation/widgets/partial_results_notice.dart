import 'package:flutter/material.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// A slim inline banner for the "All" search tab: one product/food source
/// answered while the other errored. Distinct from [EmptyHint] (a full
/// centered state) and [ErrorDialog] (a full-screen takeover) — this sits
/// above whatever the surviving source returned, so a partial outage never
/// reads as "no matching foods" or blocks browsing what did load.
///
/// [allSourcesDown] is for both online sources failing while local matches
/// (saved and cached foods) still fill the list: the notice then says that
/// nothing online answered, instead of blaming a single source.
class PartialResultsNotice extends StatelessWidget {
  final VoidCallback onRetry;
  final bool allSourcesDown;

  const PartialResultsNotice({
    super.key,
    required this.onRetry,
    this.allSourcesDown = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = isDark ? AppPalette.dark : AppPalette.light;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimens.spacing4,
        vertical: Dimens.spacing8,
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off_rounded, size: 18, color: palette.textMuted),
          const SizedBox(width: Dimens.spacing8),
          Expanded(
            child: Text(
              allSourcesDown
                  ? S.of(context).partialResultsAllSourcesDownNotice
                  : S.of(context).partialResultsNotice,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: palette.textMuted),
            ),
          ),
          Semantics(
            identifier: 'search-partial-results-retry',
            child: TextButton(
              onPressed: onRetry,
              child: Text(S.of(context).retryLabel),
            ),
          ),
        ],
      ),
    );
  }
}
