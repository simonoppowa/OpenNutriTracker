import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/core/data/data_source/custom_meal_data_source.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/data/repository/favourite_meal_repository.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/utils/barcode_validator.dart';
import 'package:opennutritracker/core/utils/extensions.dart';
import 'package:opennutritracker/core/utils/id_generator.dart';
import 'package:opennutritracker/core/utils/tracked_day_lock.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';

part 'edit_meal_state.dart';

part 'edit_meal_event.dart';

/// Computes the per-100g scale factor for a typed base-quantity string.
///
/// `createNewMealEntity` multiplies every typed nutriment by this factor
/// before storing it on the per-100g fields, so values typed at the
/// user's chosen base quantity land in the canonical "per 100" slot.
/// Lifted out of the bloc so it can be unit-tested directly without
/// instantiating the bloc's dependency graph — see
/// `test/unit_test/edit_meal_simple_mode_scale_test.dart` for the
/// regression coverage on Simple-mode (#232).
///
/// A base of 0 falls back to the no-op factor like unparseable input does:
/// `100 / 0` is infinite, and a nutriment typed as 0 times infinity is NaN,
/// which reached the stored meal, the intake and the day's totals, and
/// blanked every card that rounds a total with `toInt()` (#1254).
double factorTo100gFromBase(String baseQuantity) {
  final parsed = double.tryParse(baseQuantity);
  return (parsed != null && parsed.isFinite && parsed > 0) ? (100 / parsed) : 1;
}

/// The code an edited meal is saved with, given the Barcode field.
///
/// `null` keeps the old code. A typed or scanned barcode replaces it. An
/// empty string is a blanked field: it clears the barcode a custom meal had,
/// and the meal gets a fresh internal id in its place, the kind
/// `MealEntity.empty()` gives a new custom meal, so it stays identified by a
/// code rather than falling back to its name. A code the field never showed
/// (an internal id) and an Open Food Facts or FDC product's code are kept.
/// [newId] makes the fresh id.
String? codeAfterEdit(
  MealEntity oldMealEntity,
  String? barcodeOverride, {
  String Function() newId = IdGenerator.getUniqueID,
}) {
  final oldCode = oldMealEntity.code;
  if (barcodeOverride == null) return oldCode;
  if (barcodeOverride.isNotEmpty) return barcodeOverride;
  final hadBarcode = oldMealEntity.source == MealSourceEntity.custom &&
      oldCode != null &&
      isBarcodeFormatValid(oldCode);
  return hadBarcode ? newId() : oldCode;
}

/// Custom meal form view mode (#232). Persisted on ConfigDBO so the form
/// remembers which view the user prefers between sessions.
enum CustomMealFormMode {
  simple,
  advanced;

  static CustomMealFormMode fromString(String? value) {
    if (value == advanced.name) return advanced;
    // Simple is the default for new users and for any unrecognised value:
    // it removes the per-100g cognitive load and matches the most common
    // request from the people who filed #232.
    return simple;
  }
}

class EditMealBloc extends Bloc<EditMealEvent, EditMealState> {
  final GetConfigUsecase _getConfigUsecase;
  final CustomMealDataSource _customMealDataSource; // #267
  final ConfigRepository _configRepository;
  final FavouriteMealRepository _favouriteMealRepository; // #1307
  final IntakeRepository _intakeRepository; // #1417

  /// The id a cleared barcode is replaced with, made once per editor. A Save
  /// retried after a failed one then saves the same meal again rather than a
  /// second one beside it, and moves the diary entries to the same id the
  /// first attempt may already have moved some of them to (#1417).
  String? _clearedBarcodeId;

  EditMealBloc(
    this._getConfigUsecase,
    this._customMealDataSource,
    this._configRepository,
    this._favouriteMealRepository,
    this._intakeRepository,
  ) : super(EditMealInitial()) {
    on<InitializeEditMealEvent>((event, emit) async {
      emit(EditMealLoadingState());

      final config = await _getConfigUsecase.getConfig();
      final mode = CustomMealFormMode.fromString(
        await _configRepository.getCustomMealFormMode(),
      );
      emit(EditMealLoadedState(
        usesImperialUnits: config.usesImperialFoodUnits,
        formMode: mode,
      ));
    });
  }

  /// Persist the user's form view preference so the next custom-meal entry
  /// opens in the same mode they last used (#232).
  Future<void> setFormMode(CustomMealFormMode mode) async {
    await _configRepository.setCustomMealFormMode(mode.name);
  }

  MealEntity createNewMealEntity(
    MealEntity oldMealEntity,
    String nameText,
    String brandsText,
    String mealQuantityText,
    String servingQuantityText,
    String baseQuantity,
    String? unitText,
    String kcalText,
    String carbsText,
    String fatText,
    String proteinText, {
    String? fiberText,
    String? saturatedFatText,
    String? sugarsText,
    String? sodiumText,
    String? calciumText,
    String? ironText,
    String? potassiumText,
    String? magnesiumText,
    String? vitaminDText,
    String? vitaminB12Text,
    String? barcodeOverride,
    String? localImagePathOverride,
    bool clearLocalImagePath = false,
  }) {
    final double factorTo100g = factorTo100gFromBase(baseQuantity);

    double? multiplyIfNotNull(double? nutrimentValue) {
      return nutrimentValue != null ? nutrimentValue * factorTo100g : null;
    }

    double? fromTextOrOld(String? text, double? oldValue) =>
        multiplyIfNotNull(text?.toDoubleOrNull() ?? oldValue);

    final newMealNutriments = MealNutrimentsEntity(
      energyKcal100: multiplyIfNotNull(kcalText.toDoubleOrNull()),
      carbohydrates100: multiplyIfNotNull(carbsText.toDoubleOrNull()),
      fat100: multiplyIfNotNull(fatText.toDoubleOrNull()),
      proteins100: multiplyIfNotNull(proteinText.toDoubleOrNull()),
      sugars100: fromTextOrOld(sugarsText, oldMealEntity.nutriments.sugars100),
      saturatedFat100: fromTextOrOld(saturatedFatText, oldMealEntity.nutriments.saturatedFat100),
      fiber100: fromTextOrOld(fiberText, oldMealEntity.nutriments.fiber100),
      sodium100: fromTextOrOld(sodiumText, oldMealEntity.nutriments.sodium100),
      calcium100: fromTextOrOld(calciumText, oldMealEntity.nutriments.calcium100),
      iron100: fromTextOrOld(ironText, oldMealEntity.nutriments.iron100),
      potassium100: fromTextOrOld(potassiumText, oldMealEntity.nutriments.potassium100),
      magnesium100: fromTextOrOld(magnesiumText, oldMealEntity.nutriments.magnesium100),
      vitaminD100: fromTextOrOld(vitaminDText, oldMealEntity.nutriments.vitaminD100),
      vitaminB12100: fromTextOrOld(vitaminB12Text, oldMealEntity.nutriments.vitaminB12100),
    );

    return MealEntity(
      // #167: a user-typed or scanned barcode wins over whatever came
      // from the originating OFF/FDC record, but only when the override
      // was actually supplied. Empty-string is treated as "clear" so a
      // user can erase a stored code by blanking the field.
      code: codeAfterEdit(
        oldMealEntity,
        barcodeOverride,
        newId: () => _clearedBarcodeId ??= IdGenerator.getUniqueID(),
      ),
      name: nameText.toStringOrNull(),
      brands: brandsText.toStringOrNull(),
      url: oldMealEntity.url,
      thumbnailImageUrl: oldMealEntity.thumbnailImageUrl,
      mainImageUrl: oldMealEntity.mainImageUrl,
      mealQuantity: mealQuantityText.toStringOrNull(),
      mealUnit: unitText,
      servingQuantity: servingQuantityText.toDoubleOrNull(),
      // The custom-meal form has a single unit selector shared by the meal
      // size and the serving size, so the serving unit is that selected unit
      // — not the serving *quantity* text, which used to land here and made
      // the meal-detail serving option read "Serving (50.0 50)" instead of
      // "Serving (50 g)" (#495).
      servingUnit: unitText,
      servingSize: oldMealEntity.servingSize,
      nutriments: newMealNutriments,
      source: oldMealEntity.source,
      // #64 follow-up: a freshly-picked local photo wins over what was
      // on the old entity; a clear flag means the user removed the
      // photo and the slug should be wiped from the saved meal.
      localImagePath: clearLocalImagePath
          ? null
          : (localImagePathOverride ?? oldMealEntity.localImagePath),
    );
  }

  /// Persist custom meal template so it appears in Recent Meals before first log (#267)
  ///
  /// [previous] is the meal as it was before the edit: its library entry is
  /// the one replaced, even when the edit changed the barcode or the name
  /// the meal is found by (#1403). When [previous] is in the library, the
  /// diary entries logged under its barcode or name move to the new one, in
  /// every profile, so they stay the meal's and deleting it removes them too
  /// (#1417). A [previous] the library does not hold — the placeholder a new
  /// meal starts from — has no entries, so nothing is searched.
  ///
  /// A favourite on it, in any profile, takes the edited version, and moves
  /// to its key when the edit changed its identity, so it stays starred
  /// (#1307). Another library entry that already had the new identity is
  /// dropped by the save; a favourite on it is keyed by that identity, so it
  /// now resolves to the edited meal, and a profile that starred both keeps
  /// one entry, starred at the earlier time.
  ///
  /// The entries move first, then the library entry is replaced, then the
  /// favourite moves. A failed entry move puts back what it moved, so the
  /// meal and its entries stay as they were. Once the library holds the
  /// edited meal the entries are not searched again, so a retry after a
  /// failed favourite move redoes only the save and the favourite move.
  ///
  /// All three run as one step under the tracked-day lock, so no profile
  /// switch lands between them and swaps the intake or favourites box
  /// mid-way. Not tied to the profile the edit began on: the library is
  /// shared and the moves cover every profile, so a switch queued behind it
  /// just waits rather than dropping the user's save.
  Future<void> saveCustomMeal(
    MealEntity mealEntity, {
    MealEntity? previous,
  }) async {
    final saved = MealDBO.fromMealEntity(mealEntity);
    final before = previous == null ? null : MealDBO.fromMealEntity(previous);
    await withTrackedDayLock(() async {
      final fromKey = before?.code ?? before?.name;
      final toKey = saved.code ?? saved.name;
      if (fromKey != null &&
          toKey != null &&
          fromKey != toKey &&
          _customMealDataSource.getAllCustomMeals().any(
            (meal) => (meal.code ?? meal.name) == fromKey,
          )) {
        await _intakeRepository.moveCustomMealInEveryProfile(
          fromMealKey: fromKey,
          toMeal: saved,
        );
      }
      await _customMealDataSource.saveCustomMeal(saved, previous: before);
      if (previous != null) {
        await _favouriteMealRepository.moveFavourite(previous, mealEntity);
      }
    });
  }
}
