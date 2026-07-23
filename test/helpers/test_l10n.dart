import 'dart:ui';

import 'package:opennutritracker/generated/l10n.dart';

/// English strings for test assertions — the widget tests pump their trees
/// with the default `en` locale, so this mirrors what `S.of(context)`
/// resolves to inside them (replacement for the old S-dot-current).
final S l10nEn = lookupS(const Locale('en'));
