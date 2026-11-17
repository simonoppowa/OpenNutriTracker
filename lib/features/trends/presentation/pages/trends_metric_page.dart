import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/features/trends/presentation/bloc/trends_bloc.dart';
import 'package:opennutritracker/features/trends/presentation/widgets/trends_range_pills.dart';

/// Builds a Trends card from the loaded state, in the palette of the page
/// that shows it.
typedef TrendsCardBuilder =
    Widget Function(TrendsLoaded state, AppPalette palette);

/// One metric's page, opened from its overview tile: the range pills over
/// the metric's chart and figures.
class TrendsMetricPage extends StatelessWidget {
  final String title;
  final TrendsCardBuilder body;

  const TrendsMetricPage({super.key, required this.title, required this.body});

  /// Opens a metric's page on the overview's bloc, so a range picked there
  /// is the overview's range too.
  static Future<void> open(
    BuildContext context, {
    required String title,
    required TrendsCardBuilder body,
  }) {
    final bloc = context.read<TrendsBloc>();
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider<TrendsBloc>.value(
          value: bloc,
          child: TrendsMetricPage(title: title, body: body),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = isDark ? AppPalette.dark : AppPalette.light;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: BlocBuilder<TrendsBloc, TrendsState>(
        builder: (context, state) {
          if (state is! TrendsLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: EdgeInsets.fromLTRB(
              Dimens.spacing16,
              Dimens.spacing8,
              Dimens.spacing16,
              Dimens.spacing32 + MediaQuery.paddingOf(context).bottom,
            ),
            children: [
              TrendsRangePills(rangeDays: state.rangeDays),
              const SizedBox(height: Dimens.spacing16),
              body(state, palette),
            ],
          );
        },
      ),
    );
  }
}
