/// The household word a food names its own portion with — "slice", "cup,
/// sliced", "egg" — pulled out of the serving description for **display
/// only**.
///
/// The app's unit vocabulary is six fixed values and `serving` is the only
/// one a count can land on, so a row that correctly logs three slices of
/// bread says "3 serving". The word the user actually said is already in
/// the data: the backend's `food_summary` builds `serving_size` from FDC's
/// `portion_description`/`modifier`, and `MealEntity._spServingLabel`
/// renders it as "1 slice (38 g)". Nothing read it back out.
///
/// **Display only, and that is a decision rather than an omission (#864).**
/// The stored unit stays inside the closed six-value set, because
/// `IntakeEntity.unit` is published in `docs/export-format.md` and rides in
/// a *positional* QR share array parsed by other builds on other phones.
/// Feeding dataset prose — which carries commas, per the backend's own
/// schema comment for "cup, sliced" — into a CSV column and a positional
/// array would be a compatibility change wearing a label change's clothes.
library;

/// A leading count: "1 slice", "0.5 cup", "1,5 l".
final _leadingCount = RegExp(r'^\s*\d+(?:[.,]\d+)?\s*');

/// A trailing parenthetical carrying the weight: "1 slice (38 g)".
final _trailingWeight = RegExp(r'\s*\([^)]*\)\s*$');

/// What is left when a description names no household measure at all — a
/// bare weight or volume. Matched whole, so "cup" survives and "g" does
/// not.
final _bareUnit = RegExp(
  r'^(?:g|kg|ml|l|lb|oz|fl\.?\s?oz|g/ml|portion|serving)$',
  caseSensitive: false,
);

/// Anything with a letter in it. A description reduced to punctuation or
/// digits names nothing.
final _hasLetter = RegExp(r'\p{L}', unicode: true);

/// Long enough for "cup, sliced" and short enough not to reopen #824, where
/// this row overflowed by 65px because one field took the width it wanted.
/// The dropdown sizes itself to its widest item, so this bound is a layout
/// constraint rather than a stylistic one — a label that would blow the row
/// out is worth losing, since "Serving" is still correct underneath it.
const maxHouseholdPortionLabel = 16;

/// The household measure in [servingSize], or null when it names none and
/// the caller should keep saying "serving".
///
/// Deliberately conservative: every rejection falls back to today's wording,
/// so a miss costs nothing and a false positive would cost a wrong-looking
/// unit on a correct number.
///
/// **Only in English, because that is the only language this text exists
/// in.** `food_summary.serving_size` is built straight from
/// `food_portion.portion_description` with no join to
/// `food_portion_translation`, and that table is empty — measured against the
/// live backend, 0 rows, alongside 36,682 portions. So the word is "slice"
/// for every locale the app ships. Food *names* are translated (20,834 rows
/// in `food_translation`), which is what made the gap easy to miss: the row
/// showed a German name beside an English unit.
///
/// The cost is admitted rather than hidden: an Open Food Facts product whose
/// own `serving_size` happens to be in the reader's language is suppressed
/// too, because nothing here can tell which language that field is in. That
/// returns those rows to what they said before this function existed, which
/// was never wrong — only less specific. Guessing the other way puts an
/// English word in eight other languages' UI.
///
/// This is the gate to remove first if `food_portion_translation` is ever
/// populated (#864).
String? householdPortionLabel(String? servingSize, {
  required String languageCode,
}) {
  if (languageCode != 'en') return null;
  if (servingSize == null) return null;

  final withoutWeight = servingSize.replaceFirst(_trailingWeight, '');
  final label = withoutWeight.replaceFirst(_leadingCount, '').trim();

  if (label.isEmpty) return null;
  // "30 g" reduces to "g", and OFF's "1 portion" to "portion". Neither says
  // more than the word already on the dropdown.
  if (_bareUnit.hasMatch(label)) return null;
  if (!_hasLetter.hasMatch(label)) return null;
  if (label.length > maxHouseholdPortionLabel) return null;

  return label;
}
