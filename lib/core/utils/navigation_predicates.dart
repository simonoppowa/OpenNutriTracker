import 'package:flutter/widgets.dart';

/// Route predicates for the "unwind to a known screen" navigations.
///
/// [ModalRoute.withName] on its own is unsafe for this: when the named route
/// is not on the stack the predicate matches nothing, and both
/// `popUntil` and `pushNamedAndRemoveUntil` respond by removing *every*
/// route — leaving an empty navigator, which renders as a black screen.
///
/// A stack without the expected name is a normal situation, not a bug to
/// assert on: the same screen can be reached from the Add Meal flow (which
/// pushes `addMealRoute`), from the home shortcut's scanner, and from the
/// voice-add flow, and only the first of those has that route below it.
/// So the predicates here stop at the first route instead — after the
/// splash screen replaces itself, the first route is the main screen, which
/// is exactly the floor these unwinds are aiming for.
RoutePredicate namedRouteOrFirst(String routeName) =>
    (route) => route.isFirst || route.settings.name == routeName;
