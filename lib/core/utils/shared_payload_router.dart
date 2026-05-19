import 'package:opennutritracker/features/home/domain/entity/shared_activity_payload.dart';
import 'package:opennutritracker/features/home/domain/entity/shared_meal_payload.dart';
import 'package:opennutritracker/features/recipes/domain/entity/shared_recipe_payload.dart';

enum SharedPayloadKind { meal, activity, recipe }

/// Try to classify [raw] as one of the app's shared-QR payloads.
///
/// Returns `null` when the input doesn't match any of them — the signal
/// to fall through to the standard barcode lookup path. The order
/// (meal → activity → recipe) is chosen so that each parser rejects
/// payloads of the other two kinds cleanly on structural mismatch; see
/// the accompanying tests for the cross-confusion cases.
SharedPayloadKind? classifySharedPayload(String raw) {
  if (raw.isEmpty) return null;
  try {
    SharedMealPayload.fromJsonString(raw);
    return SharedPayloadKind.meal;
  } on SharedMealParseException {
    // not a meal — try the next kind
  }
  try {
    SharedActivityPayload.fromJsonString(raw);
    return SharedPayloadKind.activity;
  } on SharedActivityParseException {
    // not an activity — try the next kind
  }
  try {
    SharedRecipePayload.fromJsonString(raw);
    return SharedPayloadKind.recipe;
  } on SharedRecipeParseException {
    // not a recipe either — caller falls through to barcode lookup
  }
  return null;
}
