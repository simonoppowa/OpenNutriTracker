import 'package:flutter/material.dart';
import 'package:opennutritracker/core/presentation/widgets/empty_hint.dart';
import 'package:opennutritracker/generated/l10n.dart';

class NoResultsWidget extends StatelessWidget {
  const NoResultsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyHint(
      icon: Icons.search_off_rounded,
      title: S.of(context).noResultsFound,
    );
  }
}
