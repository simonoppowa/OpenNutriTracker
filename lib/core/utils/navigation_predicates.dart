import 'package:flutter/widgets.dart';

/// Route predicates for the "unwind to a known screen" navigations.
///
/// [ModalRoute.withName] on its own is unsafe for this: when the named route
/// is not on the stack the predicate matches nothing, and both
/// `popUntil` and `pushNamedAndRemoveUntil` respond by removing *every*
/// route — leaving an empty navigator, which renders as a black screen.
///
/// A stack without the expected name is a normal situation, not a bug to
/// assert on: a screen reached through more than one entry point only has
/// the named route below it on some of those paths — Edit Meal sits under
/// `addMealRoute` when opened from Add Meal, and directly under the route
/// that pushed it otherwise. So this predicate stops at the first route as
/// well: after the splash screen replaces itself the first route is the
/// main screen, the floor these unwinds are aiming for. Landing there is a
/// worse-case outcome worth having — an empty navigator renders as a black
/// screen with nothing to navigate back to.
RoutePredicate namedRouteOrFirst(String routeName) =>
    (route) => route.isFirst || route.settings.name == routeName;
