import 'package:opennutritracker/core/utils/ai_credential_storage.dart';

/// The one measured thing a non-default model's row says about it.
///
/// A key rather than a string, because the catalogue is a `const` with no
/// `BuildContext` to localize against; the dialog maps this to an ARB key.
///
/// It sits on the model rather than on the provider, which is how it was
/// written first. That worked only while every provider's list was two
/// entries whose difference was the same difference: with a third and fourth
/// on one list, a single per-provider string reached
/// `openai/gpt-5.6-terra` and said "cheaper", which is false — it matches
/// `claude-sonnet-5` on input and is dearer on output. #726.
enum AiModelNote {
  /// Measured in #668: over 21 low-quality photos the cheaper Anthropic model
  /// identified the staple in 12 of the 16 that were scorable, against 16.
  cheaper,

  /// Measured in #686: on the same plate `luna` returned 3 rows to `terra`'s
  /// 7. Neither is wrong, which is why both are offered.
  moreItems,

  /// A superlative on purpose. The row above it on the OpenRouter list
  /// already claims to be *cheaper*, so a second comparative would be
  /// ambiguous about its referent; this entry sits 5x below the next cheapest
  /// **on both the prompt and the completion axis**, so no request shape can
  /// invert it.
  ///
  /// This is a relative ordering read off the provider's own endpoint data,
  /// not a cost estimate — the standing "no pricing claim without measuring
  /// it" rule below is intact. It does go stale silently if OpenRouter
  /// reprices, and nothing in the app checks.
  cheapest,
}

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

  /// What this row says about itself when it is not the default.
  ///
  /// Null on the first entry of every list, which is labelled *Recommended*
  /// by position, and on a list of one, which has nothing to compare to.
  final AiModelNote? note;

  const AiModel({
    required this.id,
    required this.servedBy,
    this.providers = const [],
    this.note,
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
/// A stale entry fails loudly rather than silently — but **how** it says so is
/// provider-specific, and one provider had to be made to. A withdrawn model
/// answers 404 on the Anthropic and OpenRouter paths, which those clients
/// classify as [MealInterpreterFailure.unsupported] and turn into advice
/// pointing at this screen. OpenAI answers **400**, and reuses 400 for a
/// rejected image, so status alone cannot separate "this model is gone" from
/// "this photo cannot be read". `OpenAiMealItemsApi` reads `model_not_found`
/// out of the error body to keep the guarantee. Measured in #684 and #686.
///
/// **The all-Anthropic ruling this comment used to record has been reversed.**
/// It read: *every entry is Anthropic-served … #656 found the policy fit
/// survives only under `provider.only: ["anthropic"]`*, naming OpenAI's clause
/// about promoting unhealthy dieting to minors as the cause. #679 re-read all
/// three usage policies and found that conflated two different rejections:
/// Anthropic's own disordered-eating prohibition is *broader* than OpenAI's,
/// so it cannot be what separates them, and Google's is a distribution test
/// that OpenAI has no equivalent of. OpenAI offers no carve-out, only the
/// absence of a prohibition, so the defence is factual — the app gives no
/// advice — and it dies the day a feature says something evaluative.
///
/// Google is still out, on the distribution test and on a training clause
/// that covers free-tier submissions.
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
  ///
  /// **The OpenAI pair is appended, and that placement is the decision.**
  /// `luna` is a tenth of sonnet's per-token price and would be a defensible
  /// default on cost — but [AiCredentialStorage.writeModel] is only ever
  /// called from an explicit tap in the dialog, so everyone who saved a key
  /// without opening the model list has no stored id and resolves to
  /// `.first`. Reordering would therefore send their food photographs to a
  /// different company with no interaction, after the photo sheet had named
  /// the old one — it interpolates [AiModel.servedBy]. That is what #688
  /// refused when it declined to let an unrecognised provider tag fall back
  /// silently "to a company they never chose"; the cost here is only that the
  /// cheapest entry sits third, which the row label answers. #726.
  ///
  /// This is the first list to hold more than one vendor, so it is also the
  /// first time the dialog's per-row *Served by* branch is reachable in
  /// production.
  ///
  /// Screened through the broker before landing, because the direct-path
  /// measurements in #684/#719 do not transfer on their own: #669 measured
  /// `openai/gpt-5.4-nano` *through OpenRouter* and got the opposite result
  /// from the direct API. 22 live calls, no invariant violations, and a
  /// withdrawn `openai/*` id answered 404 rather than OpenAI's native 400 —
  /// so the loud-failure promise above needs no `error.code` reader here.
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
      note: AiModelNote.cheaper,
    ),
    AiModel(
      id: 'openai/gpt-5.6-luna',
      servedBy: 'OpenAI',
      providers: ['openai'],
      note: AiModelNote.cheapest,
    ),
    AiModel(
      id: 'openai/gpt-5.6-terra',
      servedBy: 'OpenAI',
      providers: ['openai'],
      note: AiModelNote.moreItems,
    ),
  ];

  /// Ordered: the default is first.
  ///
  /// Both were screened behaviourally over 90 live calls (#684, #686) — 18/18
  /// forced tool calls each, no measurement ever leaked from a photo, no
  /// duplicate rows, no unit invented on a bare count. Every candidate passed
  /// those; what separated them was quality. `gpt-5.4-mini` turned one photo
  /// of a bunch of bananas into **twelve** `banana` rows, and `gpt-5.4-nano`
  /// duplicated on two photos and attached a `serving` to a bare count. Both
  /// advertise the same capabilities as these two, which is the second time
  /// this project has measured that a capability flag is not fitness.
  ///
  /// luna leads because it is the more conservative reader: on the same plate
  /// it returned 3 rows where terra returned 7. Neither is wrong, and terra is
  /// offered for exactly that reason.
  ///
  /// **No pricing claim is made here**, because none was measured. Do not add
  /// one without measuring it.
  ///
  /// `providers` stays empty: that field pins an OpenRouter route, and a
  /// direct path has no broker to constrain.
  static const openai = <AiModel>[
    AiModel(id: 'gpt-5.6-luna', servedBy: 'OpenAI'),
    AiModel(
      id: 'gpt-5.6-terra',
      servedBy: 'OpenAI',
      note: AiModelNote.moreItems,
    ),
  ];

  static List<AiModel> forProvider(AiProvider provider) => switch (provider) {
    AiProvider.anthropic => anthropic,
    AiProvider.openrouter => openrouter,
    AiProvider.openai => openai,
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
