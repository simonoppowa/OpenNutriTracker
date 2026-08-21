import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/ai_credential_storage.dart';
import 'package:opennutritracker/core/utils/ai_model_catalogue.dart';

void main() {
  group('the default nobody chose', () {
    // `AiCredentialStorage.writeModel` is only ever reached from an explicit
    // tap in the settings dialog, so everyone who saved a key without opening
    // the model list has no stored id and resolves to `.first` on every
    // request. That makes list *order* a behavioural property, not a
    // cosmetic one, and these tests exist because #726 added a model that is
    // a tenth of the default's price and would have been tempting to promote.

    test('an unset model resolves to the head of the curated lists', () {
      for (final provider in AiProvider.values) {
        final models = AiModelCatalogue.forProvider(provider);
        if (models.isEmpty) continue;
        expect(
          AiModelCatalogue.resolve(provider, null)?.id,
          models.first.id,
          reason: '${provider.name} must not need a stored choice to work',
        );
      }
    });

    test('a server the user runs has no default, and that is the answer', () {
      // #738: there is no curated list to take a first element from, and
      // defaulting to something would mean choosing on the user's behalf from
      // models nobody has screened — on Ollama the first pulled entry could
      // be an embedding model. The model is part of what "configured" means
      // there instead, so "none" has to be representable. #755.
      expect(AiModelCatalogue.forProvider(AiProvider.ownServer), isEmpty);
      expect(AiModelCatalogue.defaultFor(AiProvider.ownServer), isNull);
      expect(AiModelCatalogue.resolve(AiProvider.ownServer, 'gemma3:4b'), isNull);
    });

    test('adding cheaper OpenAI models did not move the OpenRouter default', () {
      // Reordering would send the food photographs of everyone who never
      // opened the picker to a different company, with no interaction, after
      // the photo sheet had named the old one — it interpolates `servedBy`.
      // #688 refused a smaller version of this.
      final unchosen = AiModelCatalogue.resolve(AiProvider.openrouter, null)!;
      expect(unchosen.id, 'anthropic/claude-sonnet-5');
      expect(unchosen.servedBy, 'Anthropic');
    });

    test('a retired id falls back rather than 404ing forever', () {
      expect(
        AiModelCatalogue.resolve(AiProvider.openrouter, 'anthropic/gone')!.id,
        'anthropic/claude-sonnet-5',
      );
    });
  });

  group('what a row is allowed to say about itself', () {
    test('the head of every list carries no note, and the rest carry one', () {
      for (final provider in AiProvider.values) {
        final models = AiModelCatalogue.forProvider(provider);
        if (models.isEmpty) continue;
        expect(
          models.first.note,
          isNull,
          reason: '${provider.name} head is labelled Recommended by position',
        );
        for (final model in models.skip(1)) {
          expect(
            model.note,
            isNotNull,
            reason: '${model.id} would render a bare "Served by" and no reason',
          );
        }
      }
    });

    test('no two rows on a list make the same claim', () {
      // A note is a *comparison against the other rows*. Two rows sharing one
      // is the bug #726 fixed: the label was keyed on the provider, so every
      // non-default row said the same thing whether or not it was true.
      for (final provider in AiProvider.values) {
        final notes = AiModelCatalogue.forProvider(provider)
            .map((m) => m.note)
            .whereType<AiModelNote>()
            .toList();
        expect(notes.toSet().length, notes.length, reason: provider.name);
      }
    });

    test('only the OpenRouter list claims a cheapest, and luna holds it', () {
      // The superlative is safe because luna sits below every sibling on both
      // the prompt and the completion axis. It is only meaningful among
      // siblings, so it must not appear on a list where there is nothing to
      // be cheapest *than*.
      for (final provider in AiProvider.values) {
        final models = AiModelCatalogue.forProvider(provider);
        final cheapest = models.where((m) => m.note == AiModelNote.cheapest);
        if (provider == AiProvider.openrouter) {
          expect(cheapest.single.id, 'openai/gpt-5.6-luna');
          expect(models.length, greaterThan(1));
        } else {
          expect(cheapest, isEmpty, reason: provider.name);
        }
      }
    });
  });

  group('the pin, which is what makes servedBy a guarantee', () {
    test('every brokered model pins, and every direct one does not', () {
      // `providers` constrains an OpenRouter route. A direct path has no
      // broker to constrain, so a pin there would be silently meaningless.
      for (final model in AiModelCatalogue.openrouter) {
        expect(model.providers, isNotEmpty, reason: model.id);
      }
      for (final provider in [AiProvider.anthropic, AiProvider.openai]) {
        for (final model in AiModelCatalogue.forProvider(provider)) {
          expect(model.providers, isEmpty, reason: model.id);
        }
      }
    });

    test('the pin agrees with the vendor the row names', () {
      // Settings states the serving vendor as a guarantee. If the pin named a
      // different company than the row does, the app would be checking a
      // claim it never made. The id prefix is the third statement of the same
      // fact and must agree too.
      const slugFor = {'Anthropic': 'anthropic', 'OpenAI': 'openai'};
      for (final model in AiModelCatalogue.openrouter) {
        final slug = slugFor[model.servedBy];
        expect(slug, isNotNull, reason: 'unmapped vendor ${model.servedBy}');
        expect(model.providers, [slug], reason: model.id);
        expect(model.id.split('/').first, slug, reason: model.id);
      }
    });

    test('a pin names exactly one vendor', () {
      // Two would reintroduce the ambiguity the pin removes: the row names
      // one company, so only one may answer.
      for (final model in AiModelCatalogue.openrouter) {
        expect(model.providers.length, 1, reason: model.id);
      }
    });
  });
}
