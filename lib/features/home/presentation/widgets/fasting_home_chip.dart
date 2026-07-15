import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/fasting/presentation/bloc/fasting_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// Renders only while a fasting session is active. The chip is the home
/// surface's entire participation in fasting — no "start a fast" prompt
/// when dormant, no streak, no encouragement copy, all in line with the
/// rest of #84.
class FastingHomeChip extends StatelessWidget {
  const FastingHomeChip({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          locator<FastingBloc>()..add(const FastingLoadRequested()),
      child: const _FastingHomeChipView(),
    );
  }
}

class _FastingHomeChipView extends StatelessWidget {
  const _FastingHomeChipView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FastingBloc, FastingState>(
      builder: (context, state) {
        if (state is! FastingActive) {
          return const SizedBox.shrink();
        }
        final remaining = _formatHoursMinutes(state.remaining);
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final palette = isDark ? AppPalette.dark : AppPalette.light;
        final accent = Theme.of(context).colorScheme.primary;
        final textTheme = Theme.of(context).textTheme;
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            Dimens.spacing16,
            Dimens.spacing4,
            Dimens.spacing16,
            0,
          ),
          child: Semantics(
            identifier: 'home-fasting-chip',
            child: Material(
              color: Colors.transparent,
              borderRadius: Dimens.borderRadiusM,
              child: InkWell(
                borderRadius: Dimens.borderRadiusM,
                onTap: () => Navigator.of(context)
                    .pushNamed(NavigationOptions.fastingRoute),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimens.spacing16,
                    vertical: Dimens.spacing12,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: Dimens.borderRadiusM,
                    border: Border.all(
                      color: palette.border,
                      width: Dimens.hairline,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.timer_rounded, size: 18, color: accent),
                      const SizedBox(width: Dimens.spacing8),
                      Text(
                        S.of(context).fastingHomeChipBody(remaining),
                        style: textTheme.labelLarge?.copyWith(
                          color: palette.textStrong,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Minutes resolution on the chip — seconds would twitch every tick.
  String _formatHoursMinutes(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h == 0) return '${m}m';
    return '${h}h ${m}m';
  }
}
