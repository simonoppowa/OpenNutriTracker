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
/// Throws [StateError] where the selection cannot name a model. For the three
/// curated providers that is unreachable — an unknown id falls back to the
/// list's first entry — and for a server the user runs it is prevented one
/// layer up, because the model is part of what "configured" means there
/// (#738) and an unconfigured provider never reaches this function.
/// How long a setup-time probe waits for an endpoint the user just typed.
///
/// The same measurement the request path needs, for the same reason: #779's
/// probe is the *first* request a machine ever sees, so its model is cold by
/// definition — 22–24s on an M4 Mac mini, and the provider exists to serve
/// slower hardware than that. A budget tuned to a warm model would fail every
/// endpoint on the one call that decides whether the feature is offered.
const aiEndpointProbeTimeout = Duration(seconds: 120);

/// Turns a stored selection into the client that will carry it.
///
/// [timeout] overrides the per-provider default. It exists for the probe,
/// which is not an ordinary request: it runs once at setup, against an
/// address nobody has spoken to yet, and giving up on it early is how a
/// perfectly good server gets recorded as unfit.
MealItemsApi mealItemsApiFor(
  http.Client client,
  AiSelection selection, {
  Duration? timeout,
}) {
  final model = AiModelCatalogue.resolve(selection.provider, selection.modelId);
  final modelId = model?.id ?? selection.modelId;
  if (modelId == null) {
    throw StateError('no model for ${selection.provider.name}');
  }
  // The hosted three cannot be reached without one; only the fourth may have
  // none, and it must not send an empty bearer.
  String key() => selection.apiKey ?? '';

  return switch (selection.provider) {
    AiProvider.anthropic => AnthropicMealItemsApi(
      client,
      key,
      model: modelId,
      timeout: timeout ?? AnthropicMealItemsApi.defaultTimeout,
    ),
    AiProvider.openrouter => OpenAiCompatibleMealItemsApi.openRouter(
      client,
      key,
      model: modelId,
      // Pinned with fallbacks off, so the vendor named in settings is the
      // vendor that served the request rather than the one the slug happens
      // to mention. Unpinned, `anthropic/claude-haiku-4.5` was answered by
      // Amazon Bedrock on every attempt of a three-run probe.
      providers: model?.providers,
      timeout: timeout ?? OpenAiCompatibleMealItemsApi.defaultTimeout,
    ),
    // No pin and no metadata header: reached directly, so there is no broker
    // to constrain and nobody in between to name.
    AiProvider.openai => OpenAiMealItemsApi(
      client,
      key,
      model: modelId,
      timeout: timeout ?? OpenAiMealItemsApi.defaultTimeout,
    ),
    // The user's own address, no broker, and **no forcing by name**: #733
    // measured that Ollama has no `tool_choice` field at all and llama.cpp
    // silently downgrades an object to "auto", so asking for a named function
    // would be a request most of these servers quietly ignore. `required` is
    // what the app means with one tool defined, and where it is unsupported
    // the reply lands as the existing no-tool-call refusal.
    AiProvider.ownServer => OpenAiCompatibleMealItemsApi(
      client,
      selection.apiKey == null ? null : key,
      model: modelId,
      endpoint: Uri.parse(selection.endpoint!),
      toolChoice: ToolChoiceMode.anyTool,
      timeout: timeout ?? OpenAiCompatibleMealItemsApi.defaultTimeout,
    ),
  };
}
