import 'package:flutter/foundation.dart';

/// Tells open screens that the goals or the training days changed (#35),
/// so a day-type switch shows the current plan.
class GoalChanges extends ChangeNotifier {
  void notifyChanged() => notifyListeners();
}
