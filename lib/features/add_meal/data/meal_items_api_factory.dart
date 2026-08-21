import 'package:http/http.dart' as http;
import 'package:opennutritracker/core/utils/ai_credential_storage.dart';
import 'package:opennutritracker/core/utils/ai_model_catalogue.dart';
import 'package:opennutritracker/features/add_meal/data/anthropic_meal_items_api.dart';
import 'package:opennutritracker/features/add_meal/data/openai_meal_items_api.dart';
import 'package:opennutritracker/features/add_meal/data/openai_compatible_meal_items_api.dart';
import 'package:opennutritracker/features/add_meal/domain/meal_items_api.dart';

/// Turns a stored selection into the client that will carry it.
///
/// **This is the whole of provider selection.** The interpreters take a
/// [MealItemsApi] and never learn which one they were handed, because the
/// prompt and the schema never depended on the destination — so adding a
/// provider is a case here and a change nowhere else.
///
/// A free function rather than a private helper in `locator.dart` so it can
/// be tested directly. The thing worth asserting is that choosing OpenRouter
/// in settings really produces an OpenRouter request pinned to the vendor
/// the screen named, and that is not observable through the locator.
MealItemsApi mealItemsApiFor(http.Client client, AiSelection selection) {
  final model = AiModelCatalogue.resolve(selection.provider, selection.modelId);

  return switch (selection.provider) {
    AiProvider.anthropic => AnthropicMealItemsApi(
      client,
      () => selection.apiKey,
      model: model.id,
    ),
    AiProvider.openrouter => OpenAiCompatibleMealItemsApi.openRouter(
      client,
      () => selection.apiKey,
      model: model.id,
      // Pinned with fallbacks off, so the vendor named in settings is the
      // vendor that served the request rather than the one the slug happens
      // to mention. Unpinned, `anthropic/claude-haiku-4.5` was answered by
      // Amazon Bedrock on every attempt of a three-run probe.
      providers: model.providers,
    ),
    // No pin and no metadata header: reached directly, so there is no broker
    // to constrain and nobody in between to name.
    AiProvider.openai => OpenAiMealItemsApi(
      client,
      () => selection.apiKey,
      model: model.id,
    ),
  };
}
