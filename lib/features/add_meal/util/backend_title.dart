/// The title and the qualifiers of a backend record's name, derived one way
/// for everyone who scores it (#1164, #1170).
///
/// A backend name follows FDC's and BLS's comma convention — the family
/// first, the qualifiers after: "Egg, whole, raw" is titled "Egg" and
/// qualified "whole, raw". The scorers match on the title and read past
/// it only where the query names a qualifier; see `MealEntity.scoringName`
/// and `scoringQualifiers`, which apply this to an entity, and
/// `rankAndTruncateFoodsByName`, which applies it to a raw backend row
/// before any entity exists. Both must derive the same title from the
/// same name, or the twenty rows the data source keeps and the one the
/// resolver picks among them are chosen by two rules — which is how the
/// resolver's pick was cut before it was ever scored. One derivation, so
/// that cannot happen.
///
/// Derived rather than read off the backend's `short_title` column
/// because the column *is* this derivation: measured on the live backend
/// (2026-09-12), `short_title` equals `split_part(description, ',', 1)`,
/// trimmed and compared case-insensitively, on 5,432 of 5,432 survey
/// rows, 7,793 of 7,793 SR Legacy rows, 469 of 469 Foundation rows and
/// 7,135 of 7,140 BLS rows. A translated description follows the same
/// convention, so a German reader's "Milch, menschliche" derives "Milch"
/// — the word a German query is matched against — where the English
/// column would have scored it at nothing.
///
/// These take a name and know nothing of where it came from. Whether a
/// name is a backend name is the caller's to decide: the data source's
/// rows always are, and `MealEntity` guards on its source, because an
/// Open Food Facts product name is whatever the label says and a custom
/// meal is the user's own words, and a comma in either means nothing.
library;

/// Index in [name] of the comma that ends the title, or -1 when the name
/// is not split at all: no comma, or nothing before it.
int _titleEnd(String name) {
  final comma = name.indexOf(',');
  if (comma < 0 || name.substring(0, comma).trim().isEmpty) return -1;
  return comma;
}

/// [name] up to its first comma, trimmed — "Egg" for "Egg, whole, raw".
///
/// A name with no comma is its own title, and a name with nothing before
/// the comma is too, rather than an empty string.
String deriveTitle(String name) {
  final end = _titleEnd(name);
  return end < 0 ? name : name.substring(0, end).trim();
}

/// What follows the title in [name] — "whole, raw" for "Egg, whole, raw"
/// — or null when the name is not split, or nothing follows the comma.
String? deriveQualifiers(String name) {
  final end = _titleEnd(name);
  if (end < 0) return null;
  final rest = name.substring(end + 1).trim();
  return rest.isEmpty ? null : rest;
}
