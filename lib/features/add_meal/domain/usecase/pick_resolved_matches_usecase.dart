import 'package:logging/logging.dart';
import 'package:opennutritracker/core/utils/ai_credential_storage.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/meal_items_api.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/resolve_parsed_meals_usecase.dart';
import 'package:opennutritracker/features/add_meal/util/meal_text_parser.dart';

/// Lets the model choose among the database rows the resolver found for a
/// meal line it read.
///
/// The resolver ranks candidates by how well their names match the query,
/// and auto-selects the top one. Name matching cannot tell that "tostada"
/// in a Spanish meal is toast and not a tostada shell, or that "eggs" means
/// a whole egg and not the yolk. The model, shown the meal as the user wrote
/// it beside each item's candidates, can.
///
/// **The model picks a row, nothing else.** It returns a candidate number per
/// item. The amount, unit and portion word stay exactly as the first reading
/// found them, so an amount still appears only where the user stated one and
/// a portion still gets its weight from the picked row. Every number on the
/// review screen comes from the database, as before.
///
/// The request goes through the same [MealItemsApi] clients and the same
/// `log_meal_items` tool as the first reading, so it adds no schema and no
/// HTTP code: each answer's `query` carries `"<item>:c<candidate>"`, or
/// `"<item>:none"` when no candidate is the food. Any failure returns the
/// resolver's rows unchanged, so this pass can only change which row is
/// selected, never block the screen.
class PickResolvedMatchesUseCase {
  static final _log = Logger('PickResolvedMatchesUseCase');

  /// How many candidates per item the model sees. The resolver ranks them,
  /// and past the first few they are rarely the food.
  static const maxCandidates = 6;

  final AiCredentialStorage _credentials;
  final MealItemsApi Function(AiSelection selection) _apiFactory;

  PickResolvedMatchesUseCase(this._credentials, this._apiFactory);

  static const systemPrompt = '''
You match a meal the user described against food-database search results.
You do not estimate nutrition or amounts: the app keeps the amounts the user
stated and takes every value from the row you pick.

The user message holds the meal exactly as the user wrote it, then numbered
items. Each item lists candidate rows as
  c<N>: name [source] | kcal, protein, fat, carbs per 100 g | portions

Return exactly one entry per item, in item order, with only "query":
- "<item number>:c<N>" for the candidate that is the food the user ate,
  matching the preparation when it matters (raw or cooked, whole or
  skimmed, plain or sweetened). Prefer a generic food over a brand unless
  the user named the brand.
- "<item number>:none" when no candidate is that food.
Never include "quantity", "unit" or "portion". Never merge, split or add
items.''';

  /// [items] with the model's picks applied, or [items] itself when there is
  /// nothing to choose, no model configured, or the model could not answer.
  Future<List<ResolvedMealItem>> pick(
    String text,
    List<ResolvedMealItem> items,
  ) async {
    if (!items.any((item) => item.candidates.length > 1)) return items;
    final selection = await _credentials.readSelection();
    if (selection == null) return items;

    try {
      final result = await _apiFactory(selection).requestItems(
        content: MealTextContent(buildRequest(text, items)),
        system: systemPrompt,
      );
      return applyPicks(items, result.items);
    } on MealInterpreterException catch (e) {
      // Logged without the meal text, as the first reading is.
      _log.info('Match picking unavailable, keeping the matches: ${e.reason}');
      return items;
    } catch (e, stackTrace) {
      _log.severe('Match picking failed unexpectedly', e, stackTrace);
      return items;
    }
  }

  /// The user message: the meal, then each item with its candidates.
  static String buildRequest(String text, List<ResolvedMealItem> items) {
    final out = StringBuffer('Meal: "${text.trim()}"\n');
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      out.writeln('\nItem ${i + 1}: "${item.parsed.query}"');
      final shown = _candidateIndexes(item);
      if (shown.isEmpty) out.writeln('  (no candidates)');
      for (final c in shown) {
        out.writeln('  c$c: ${_describe(item.candidates[c])}');
      }
    }
    return out.toString();
  }

  /// The first [maxCandidates], plus the resolver's own pick if it ranked
  /// lower, so the model can always confirm it.
  static List<int> _candidateIndexes(ResolvedMealItem item) {
    final count = item.candidates.length;
    final shown = [for (var i = 0; i < count && i < maxCandidates; i++) i];
    if (item.isResolved && !shown.contains(item.selectedIndex)) {
      shown.add(item.selectedIndex);
    }
    return shown;
  }

  static String _describe(MealEntity meal) {
    final n = meal.nutriments;
    final name = [
      meal.name ?? '?',
      if (meal.brands case final brands? when brands.trim().isNotEmpty)
        '(${brands.trim()})',
    ].join(' ');
    final source = meal.backendSource ?? meal.source.name;
    String v(double? value) => value == null ? '?' : _number(value);
    final per100 =
        '${v(n.energyKcal100)} kcal, P ${v(n.proteins100)}, '
        'F ${v(n.fat100)}, C ${v(n.carbohydrates100)} '
        'per 100 ${meal.isLiquid ? 'ml' : 'g'}';
    final portions = [for (final p in meal.portions) p.englishLabel ?? p.label];
    return '$name [$source] | $per100'
        '${portions.isEmpty ? '' : ' | portions: ${portions.join('; ')}'}';
  }

  static final _answer = RegExp(
    r'^\s*(\d+)\s*:\s*(?:c\s*(\d+)|(none))\s*$',
    caseSensitive: false,
  );

  /// Applies the model's picks to [items].
  ///
  /// A picked row takes that candidate and keeps what the first reading
  /// parsed; it starts at least at [kResolutionConfidenceFloor], because the
  /// model looked at it and said it is the food. A row the model rejected
  /// keeps the resolver's candidate but drops to zero confidence, so the
  /// review screen asks the user to check it. A row the model skipped, or
  /// answered with something unusable, stays exactly as the resolver left
  /// it.
  static List<ResolvedMealItem> applyPicks(
    List<ResolvedMealItem> items,
    List<ParsedMealItem> answers,
  ) {
    final picked = [...items];
    for (final answer in answers) {
      final match = _answer.firstMatch(answer.query);
      if (match == null) continue;
      final index = int.parse(match.group(1)!) - 1;
      if (index < 0 || index >= items.length) continue;
      final item = items[index];
      if (!item.isResolved) continue;

      if (match.group(3) != null) {
        picked[index] = ResolvedMealItem(
          parsed: item.parsed,
          candidates: item.candidates,
          selectedIndex: item.selectedIndex,
          confidence: 0,
        );
        continue;
      }

      final candidate = int.parse(match.group(2)!);
      if (candidate >= item.candidates.length) continue;
      picked[index] = ResolvedMealItem(
        parsed: item.parsed,
        candidates: item.candidates,
        selectedIndex: candidate,
        confidence: item.confidence < kResolutionConfidenceFloor
            ? kResolutionConfidenceFloor
            : item.confidence,
      );
    }
    return picked;
  }

  static String _number(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
}
