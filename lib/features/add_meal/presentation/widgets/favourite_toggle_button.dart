import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/favourite_toggle_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// The ☆ that adds [meal] to the Favourites list or takes it off (#1307).
/// Starring does not log anything.
class FavouriteToggleButton extends StatefulWidget {
  final MealEntity meal;

  /// Locale-independent handle for UI drivers, e.g. `meal-detail-favourite`.
  final String semanticsIdentifier;

  const FavouriteToggleButton({
    super.key,
    required this.meal,
    required this.semanticsIdentifier,
  });

  @override
  State<FavouriteToggleButton> createState() => _FavouriteToggleButtonState();
}

class _FavouriteToggleButtonState extends State<FavouriteToggleButton> {
  late final FavouriteToggleBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = locator<FavouriteToggleBloc>()
      ..add(LoadFavouriteStatusEvent(widget.meal));
  }

  @override
  void didUpdateWidget(FavouriteToggleButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A recycled list row hands this state a different food.
    if (oldWidget.meal != widget.meal) {
      _bloc.add(LoadFavouriteStatusEvent(widget.meal));
    }
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FavouriteToggleBloc, FavouriteToggleState>(
      bloc: _bloc,
      builder: (context, state) {
        return Semantics(
          identifier: widget.semanticsIdentifier,
          child: IconButton(
            isSelected: state.isFavourite,
            icon: const Icon(Icons.star_outline_rounded),
            selectedIcon: Icon(
              Icons.star_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            tooltip: state.isFavourite
                ? S.of(context).favouriteRemoveTooltip
                : S.of(context).favouriteAddTooltip,
            // The use case reads the stored state itself, so a tap before
            // the first read still lands the right way round.
            onPressed: () => _bloc.add(ToggleFavouriteEvent(widget.meal)),
          ),
        );
      },
    );
  }
}
