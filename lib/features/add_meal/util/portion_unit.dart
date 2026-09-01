/// How one portion out of several is named in the unit dropdown, without that
/// name ever reaching storage.
///
/// The dropdown's value is what `addIntake` writes to `IntakeDBO.unit`, and
/// that column is published in `docs/export-format.md` and rides in a
/// *positional* QR share array other builds parse. So a food's portion names
/// — dataset prose, commas and all — may never be the value; #864 decision 3
/// settled that and this file is how it holds while the dropdown still offers
/// a choice.
///
/// The encoding is deliberately dull: `serving` for the first portion, then
/// `serving#1`, `serving#2`. Everything before the `#` is exactly what the
/// app stored before portions existed, so [storedUnit] is a suffix strip and
/// an old row and a new one are the same row.
library;

import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';

const _portionSeparator = '#';

/// The dropdown value for the portion at [index].
///
/// Index 0 is the bare `serving`, so a food with one portion produces exactly
/// the string it always did and nothing downstream can tell the difference.
String portionUnit(int index) {
  final serving = UnitDropdownItem.serving.toString();
  return index == 0 ? serving : '$serving$_portionSeparator$index';
}

/// Which portion [unit] names, or null when it names none.
///
/// Null for `g`, `oz`, a bare `serving` — the first portion is index 0 but
/// callers that ask "which portion is this" about an unadorned unit want "no
/// answer", not "the first one". [effectivePortionIndex] is the one that
/// defaults.
int? portionIndexOf(String unit) {
  final at = unit.indexOf(_portionSeparator);
  if (at < 0) return null;
  return int.tryParse(unit.substring(at + 1));
}

/// Which portion a serving-shaped [unit] scales by: the named one, or the
/// first when none is named.
///
/// Exists so a row saved before portions existed, and a row that simply took
/// the default, both resolve to the portion `food_summary` would have picked.
int effectivePortionIndex(String unit) => portionIndexOf(unit) ?? 0;

/// True when [unit] is any portion of a food, named or not.
bool isPortionUnit(String unit) =>
    storedUnit(unit) == UnitDropdownItem.serving.toString();

/// What actually gets written down.
///
/// Strips the portion so the stored vocabulary stays the closed set the
/// export format and the QR payload were written against. Anything without a
/// separator passes through untouched, so this is safe to call on every unit
/// rather than only the ones that might carry one.
String storedUnit(String unit) {
  final at = unit.indexOf(_portionSeparator);
  return at < 0 ? unit : unit.substring(0, at);
}
