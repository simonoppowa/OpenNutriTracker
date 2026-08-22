import 'package:http/http.dart' as http;
import 'package:opennutritracker/core/utils/ai_credential_storage.dart';
import 'package:opennutritracker/core/utils/ai_model_catalogue.dart';
import 'package:opennutritracker/core/utils/plaintext_destination_guard.dart';
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
/// How long a server the user runs is given to answer.
///
/// Six times the hosted budget, and not a guess. #774 measured a real Ollama
/// on an **M4 Mac mini, 16 GB** — good hardware for this, not a stress case —
/// serving an 8B model: **22–24s from cold, 8–17s warm**. The 20s the hosted
/// clients use failed two of three requests after the model was unloaded, and
/// Ollama unloads after five idle minutes by default, so "the first request
/// of the meal" is the ordinary case rather than an edge one.
///
/// The margin is deliberately generous because the measurement came from the
/// fast end of the range this provider exists to serve. Someone running the
/// same model on an older laptop or a Raspberry Pi is the *point* of "your
/// own server", and a budget tuned to an M4 would quietly exclude them.
///
/// It costs nothing when the server is quick: the timeout is a ceiling on
/// waiting, not a delay. What it does cost is how long the bulk-add screen
/// can sit in its progress state, which is the open half of #774 — the fix
/// there is a progress state that does not read as a hang, not a shorter
/// ceiling.
const ownServerTimeout = Duration(seconds: 120);

MealItemsApi mealItemsApiFor(http.Client client, AiSelection selection) {
  final model = AiModelCatalogue.resolve(selection.provider, selection.modelId);
  final modelId = model?.id ?? selection.modelId;
  if (modelId == null) {
    throw StateError('no model for ${selection.provider.name}');
  }
  // The hosted three cannot be reached without one; only the fourth may have
  // none, and it must not send an empty bearer.
  String key() => selection.apiKey ?? '';

  return switch (selection.provider) {
    AiProvider.anthropic => AnthropicMealItemsApi(client, key, model: modelId),
    AiProvider.openrouter => OpenAiCompatibleMealItemsApi.openRouter(
      client,
      key,
      model: modelId,
      // Pinned with fallbacks off, so the vendor named in settings is the
      // vendor that served the request rather than the one the slug happens
      // to mention. Unpinned, `anthropic/claude-haiku-4.5` was answered by
      // Amazon Bedrock on every attempt of a three-run probe.
      providers: model?.providers,
    ),
    // No pin and no metadata header: reached directly, so there is no broker
    // to constrain and nobody in between to name.
    AiProvider.openai => OpenAiMealItemsApi(client, key, model: modelId),
    // The user's own address, no broker, and **no forcing by name**: #733
    // measured that Ollama has no `tool_choice` field at all and llama.cpp
    // silently downgrades an object to "auto", so asking for a named function
    // would be a request most of these servers quietly ignore. `required` is
    // what the app means with one tool defined, and where it is unsupported
    // the reply lands as the existing no-tool-call refusal.
    AiProvider.ownServer => OpenAiCompatibleMealItemsApi(
      // The only provider whose address the user supplies, so the only one
      // where plaintext is possible at all — the other three are compiled-in
      // `https://`. Wrapping here rather than at the call site means any
      // future caller of this factory is covered without knowing to ask.
      GuardedPlaintextClient(client),
      selection.apiKey == null ? null : key,
      model: modelId,
      endpoint: Uri.parse(selection.endpoint!),
      toolChoice: ToolChoiceMode.anyTool,
      // The two halves of #774, and they only make sense together. The
      // longer budget is what stops a cold model load being reported as a
      // failure at all; the classification is what stops the failures that
      // remain — a machine that genuinely cannot serve this model in two
      // minutes — from being described as a network problem.
      timeout: ownServerTimeout,
      timeoutFailure: MealInterpreterFailure.timeout,
    ),
  };
}
