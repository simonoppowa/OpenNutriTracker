import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:opennutritracker/core/utils/ai_credential_storage.dart';
import 'package:opennutritracker/core/utils/barcode_validator.dart';
import 'package:opennutritracker/features/add_meal/data/meal_items_api_factory.dart';
import 'package:opennutritracker/features/add_meal/domain/meal_items_api.dart';
import 'package:opennutritracker/features/add_meal/domain/meal_photo_interpreter.dart';
import 'package:opennutritracker/features/add_meal/util/meal_text_parser.dart';

/// The per-100 values the custom-meal form takes, each in the unit the form
/// reads it in.
const nutritionLabelUnits = {
  'energyKcal': 'kcal',
  'carbs': 'g',
  'fat': 'g',
  'protein': 'g',
  'fiber': 'g',
  'saturatedFat': 'g',
  'sugars': 'g',
  'sodium': 'mg',
  'calcium': 'mg',
  'iron': 'mg',
  'potassium': 'mg',
  'magnesium': 'mg',
  'vitaminD': 'µg',
  'vitaminB12': 'µg',
};

/// The most of each per 100 g a real label can print; more is a misread.
const _maxPer100 = {'energyKcal': 900.0, 'sodium': 40000.0};
const _gramsMax = 100.0;
const _otherMax = 100000.0;

/// The heaviest serving a label is taken to state, in g or ml.
const _servingMax = 5000.0;

/// The rules a label photo is read by.
///
/// **A transcription, not an estimate.** Everywhere else a model names foods
/// and the databases supply the numbers; a nutrition label is the one place
/// the numbers are printed in front of it, so it copies them, and a value it
/// cannot read is left out rather than guessed. The user checks every one in
/// the form before anything is saved.
///
/// The answer rides on the shared meal-items tool, one item per value with
/// `key=value` as its query, rather than a schema of its own: the tool's
/// quantity field refuses the zeros a label prints, and a second schema would
/// be a second thing every provider has to be held to.
final nutritionLabelPrompt =
    'You transcribe a packaged-food nutrition label from a photo, so the '
    'values can be typed into a nutrition tracker. You transcribe; you never '
    'estimate.\n'
    'Record one item per value you can read, and nothing else. Its query is '
    '`key=value`; leave quantity and unit out.\n'
    'Keys:\n'
    '- name: the product name as printed\n'
    '- brand: the brand as printed (not the shop)\n'
    '- barcode: the barcode digits, only when they are legible\n'
    '- serving: one stated portion in g (ml for drinks)\n'
    '${[for (final MapEntry(:key, :value) in nutritionLabelUnits.entries) '- $key: per 100 g (or 100 ml), in $value'].join('\n')}\n'
    'Rules:\n'
    '- Read the per-100 g / per-100 ml column. When only per-serving values '
    'are printed, convert them to per 100 g using the stated serving size.\n'
    '- Convert printed units to the ones named (g, mg, µg; kJ to kcal with '
    '1 kcal = 4.184 kJ). Prefer a printed kcal over a converted kJ.\n'
    '- Sodium: when only salt is printed, sodium (mg) = salt (g) x 400.\n'
    '- A value printed as 0 is 0. A value you cannot read is left out, never '
    'guessed.\n'
    '- Numbers use a dot for decimals: fat=3.2, not fat=3,2.';

/// What was read off a nutrition label. [per100] holds the
/// [nutritionLabelUnits] keys the label printed, in those units.
class NutritionLabelReading {
  final String? name;
  final String? brand;
  final String? barcode;
  final double? servingGrams;
  final Map<String, double> per100;

  const NutritionLabelReading({
    this.name,
    this.brand,
    this.barcode,
    this.servingGrams,
    this.per100 = const {},
  });

  bool get isEmpty =>
      name == null &&
      brand == null &&
      barcode == null &&
      servingGrams == null &&
      per100.isEmpty;

  /// From the model's items. An unknown key, a number that does not parse,
  /// a value no label prints and a barcode of the wrong shape are dropped.
  static NutritionLabelReading fromItems(List<ParsedMealItem> items) {
    String? name, brand, barcode;
    double? serving;
    final per100 = <String, double>{};
    for (final item in items) {
      final at = item.query.indexOf('=');
      if (at < 0) continue;
      final key = item.query.substring(0, at).trim();
      final raw = item.query.substring(at + 1).trim();
      if (raw.isEmpty) continue;
      switch (key) {
        case 'name':
          name = raw;
        case 'brand':
          brand = raw;
        case 'barcode':
          final digits = raw.replaceAll(RegExp(r'\D'), '');
          if (isBarcodeFormatValid(digits)) barcode = digits;
        case 'serving':
          final grams = _number(raw);
          if (grams != null && grams > 0 && grams <= _servingMax) {
            serving = grams;
          }
        default:
          final unit = nutritionLabelUnits[key];
          final value = _number(raw);
          if (unit == null || value == null) continue;
          final max = _maxPer100[key] ?? (unit == 'g' ? _gramsMax : _otherMax);
          if (value <= max) per100[key] = value;
      }
    }
    return NutritionLabelReading(
      name: name,
      brand: brand,
      barcode: barcode,
      servingGrams: serving,
      per100: per100,
    );
  }

  static double? _number(String raw) {
    final match = RegExp(r'\d+(?:[.,]\d+)?').firstMatch(raw);
    final value = double.tryParse(match?[0]?.replaceAll(',', '.') ?? '');
    return value != null && value.isFinite ? value : null;
  }
}

/// Reads a nutrition label photo with the model the user chose for AI meal
/// assistance, through the same client and guards a meal photo goes through.
class ReadNutritionLabelUseCase {
  final AiCredentialStorage _credentials;
  final http.Client _client;

  ReadNutritionLabelUseCase(this._credentials, this._client);

  /// Where a label photo would go, by the name the user knows it by — the
  /// company, or the address of a server they run — or null when it would
  /// go nowhere: AI meal assistance off, paused, hidden or not agreed to,
  /// all folded into [AiCredentialStorage.isEnabled], or a server the user
  /// runs whose setup check has not read a photo, which is the gate the meal
  /// photo's camera has too.
  Future<({AiProvider provider, String name})?> photoDestination() async {
    if (!await _credentials.isEnabled()) return null;
    final provider = await _credentials.activeProvider();
    switch (provider) {
      case null:
        return null;
      case AiProvider.anthropic:
        return (provider: provider, name: 'Anthropic');
      case AiProvider.openai:
        return (provider: provider, name: 'OpenAI');
      case AiProvider.openrouter:
        return (provider: provider, name: 'OpenRouter');
      case AiProvider.ownServer:
        final probe = await _credentials.readProbe(provider: provider);
        if (probe.photo != AiCapability.passed) return null;
        final endpoint = await _credentials.readEndpoint(provider: provider);
        final host = endpoint == null
            ? null
            : AiCredentialStorage.displayHost(endpoint);
        return host == null ? null : (provider: provider, name: host);
    }
  }

  /// Null when nothing is set up to read it; raises
  /// [MealInterpreterException] when the request fails.
  Future<NutritionLabelReading?> read(MealPhoto photo) async {
    if (await photoDestination() == null) return null;
    final selection = await _credentials.readSelection();
    if (selection == null) return null;
    final result = await mealItemsApiFor(_client, selection).requestItems(
      content: MealPhotoContent(
        mediaType: photo.mediaType,
        base64Data: base64Encode(photo.bytes),
      ),
      system: nutritionLabelPrompt,
    );
    return NutritionLabelReading.fromItems(result.items);
  }
}
