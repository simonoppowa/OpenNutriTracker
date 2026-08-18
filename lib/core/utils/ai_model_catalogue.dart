import 'package:opennutritracker/core/utils/ai_credential_storage.dart';

/// One model the app is willing to send a meal to.
class AiModel {
  /// Exactly as the provider's API expects it.
  final String id;

  /// The OpenRouter provider slugs this model may be served by. Empty on the
  /// direct path, which has no broker to constrain.
  ///
  /// Non-empty means the request pins to these and switches fallbacks off,
  /// so the vendor named beside the model is the vendor that served it. A
  /// probe of `anthropic/claude-haiku-4.5` with no pin was answered by
  /// Amazon Bedrock on all three attempts, which is why "likely" is not good
  /// enough here.
  final List<String> providers;

  /// The company that actually answers, for the settings screen to name.
  final String servedBy;

  const AiModel({
    required this.id,
    required this.servedBy,
    this.providers = const [],
  });
}

/// The models the app offers, decided in #668 and hardcoded on purpose.
///
/// **This list cannot be fetched.** Membership requires a behavioural screen
/// against a photo corpus — `openai/gpt-5.4-nano` advertises every capability
/// flag and returned empty for both food-bearing photos in the non-food
/// slice — and the app cannot run that screen. The catalogue does not carry
/// the property the list is selected on, so there is nothing useful to fetch.
///
/// A stale entry fails loudly rather than silently: a withdrawn model and a
/// pin whose provider stopped serving it both answer **404**, which the
/// OpenRouter client classifies as [MealInterpreterFailure.unsupported] —
/// turning it into advice pointing at this screen.
///
/// Every entry is Anthropic-served, and that is a consequence rather than a
/// preference. #656 found the policy fit survives only under
/// `provider.only: ["anthropic"]`: OpenAI's usage policy covers "promoting
/// unhealthy dieting or exercise behavior to minors" with no wellness
/// carve-out, and Google Cloud's terms forbid use in a service "likely to be
/// accessed by individuals under the age of 18".
abstract final class AiModelCatalogue {
  /// The direct path has never offered a choice, and this does not add one.
  /// Changing which model an existing user's requests go to is exactly the
  /// silent behaviour change pinning exists to prevent.
  static const anthropic = <AiModel>[
    AiModel(id: 'claude-haiku-4-5', servedBy: 'Anthropic'),
  ];

  /// Ordered: the default is first.
  ///
  /// Sonnet leads on measurement, not price. Over 21 low-quality photos it
  /// identified the staple in 16 of the 16 that were scorable, against
  /// haiku's 12 — and haiku's four misses were confident, specific and wrong
  /// (`banh mi` for a basket of tacos), which resolve to *something* in the
  /// food search and have to be caught in review. At roughly $0.0033 against
  /// $0.0017 a photo, cost does not defend the weaker one.
  static const openrouter = <AiModel>[
    AiModel(
      id: 'anthropic/claude-sonnet-5',
      servedBy: 'Anthropic',
      providers: ['anthropic'],
    ),
    AiModel(
      id: 'anthropic/claude-haiku-4.5',
      servedBy: 'Anthropic',
      providers: ['anthropic'],
    ),
  ];

  static List<AiModel> forProvider(AiProvider provider) => switch (provider) {
    AiProvider.anthropic => anthropic,
    AiProvider.openrouter => openrouter,
  };

  static AiModel defaultFor(AiProvider provider) => forProvider(provider).first;

  /// The stored choice, or the default when nothing is stored — and also
  /// when the stored id is no longer on the list, which is what a user sees
  /// after an update that retires a model. Falling back beats leaving them
  /// pointed at an id that can only 404.
  static AiModel resolve(AiProvider provider, String? id) {
    final models = forProvider(provider);
    for (final model in models) {
      if (model.id == id) return model;
    }
    return models.first;
  }
}
