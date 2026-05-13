import 'package:flutter/foundation.dart';

/// Tracks whether the user wants energy values shown in kilojoules
/// rather than the default kilocalories. Storage is always in kcal —
/// this preference only affects rendering.
///
/// Mirrors [LocaleProvider] / [ThemeModeProvider]: seeded from the
/// persisted config at app start and updated from Settings when the
/// user picks a different unit, so widgets that listen to it rebuild
/// without having to thread the flag through every Bloc state.
class EnergyUnitProvider extends ChangeNotifier {
  bool usesKilojoules;

  EnergyUnitProvider({this.usesKilojoules = false});

  void updateUsesKilojoules(bool usesKilojoules) {
    if (this.usesKilojoules == usesKilojoules) return;
    this.usesKilojoules = usesKilojoules;
    notifyListeners();
  }
}
