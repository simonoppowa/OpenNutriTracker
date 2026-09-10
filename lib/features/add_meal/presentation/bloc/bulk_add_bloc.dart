import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/meal_photo_interpreter.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/read_meal_photo_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/read_meal_text_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/resolve_parsed_meals_usecase.dart';
import 'package:opennutritracker/features/add_meal/util/meal_text_parser.dart';
import 'package:opennutritracker/features/add_meal/util/portion_match.dart';
import 'package:opennutritracker/features/add_meal/util/portion_unit.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';
import 'package:opennutritracker/features/meal_detail/util/meal_quantity_converter.dart';

part 'bulk_add_event.dart';
part 'bulk_add_state.dart';

/// The shape an amount has to have: no scientific notation, no sign, at most
/// two decimals. The same shape the manual-entry quantity field enforces
/// (`meal_detail_bottom_sheet.dart`), so the bulk path accepts exactly what
/// manual entry does.
///
/// Kept here rather than on the screen because three things have to agree
/// about it and only one of them is a widget: the field's input formatter,
/// [BulkAddBloc._amountText] — which rounds every prefilled amount to satisfy
/// it — and [BulkAddRow.quantityError], which reports what fails it.
final bulkAddQuantityPattern = RegExp(r'^\d+([.,]\d{0,2})?$');

/// Matches the manual-entry upper bound.
const bulkAddMaxQuantity = 10000;

/// Why a row's amount cannot be written, in terms the user can act on.
///
/// The three arrived at the screen as one message naming the field and
/// nothing else, so "0", "99999" and "1.234" all read as `Rice: Quantity`.
/// They are separated here rather than at the render site because the render
/// site would then have to re-derive which of them happened. #1013.
enum BulkAddQuantityError {
  /// Not a number this screen accepts: empty, or carrying more decimals than
  /// the field allows. The one failure the UI never stated a rule for.
  malformed,

  /// Zero or less. Nothing to log.
  tooSmall,

  /// Above [bulkAddMaxQuantity].
  tooLarge,
}

/// One editable row on the review screen.
///
/// Holds the user's edits separately from what the resolver produced, so
/// re-parsing or picking a different candidate never silently discards a
/// quantity the user typed.
class BulkAddRow extends Equatable {
  final ResolvedMealItem resolved;

  /// Index into [ResolvedMealItem.candidates], possibly changed by the user
  /// via the candidate picker.
  final int selectedIndex;

  /// As typed. Kept as text rather than a double so the field can hold an
  /// in-progress value ("1," / "") without the row deciding it is invalid
  /// mid-keystroke — validation happens on submit.
  final String amountText;
  final String unit;

  /// Rows the user chose to leave out. Skipped rather than removed, so the
  /// decision stays visible and reversible until the batch is logged.
  final bool skipped;

  /// Set once the user picks a unit from the dropdown themselves, which
  /// settles [amountNeedsCheck] — they have made the call it was asking for.
  final bool unitChosenByUser;

  /// Set once the user types in the amount field.
  final bool amountEditedByUser;

  /// True while the amount and unit are still what the bloc derived, so
  /// re-deriving them against a newly picked candidate cannot overwrite
  /// anything the user typed or chose.
  bool get isPristine => !unitChosenByUser && !amountEditedByUser;

  const BulkAddRow({
    required this.resolved,
    required this.selectedIndex,
    required this.amountText,
    required this.unit,
    this.skipped = false,
    this.unitChosenByUser = false,
    this.amountEditedByUser = false,
  });

  bool get isResolved => resolved.isResolved;

  /// True when a match was found but is weak enough to show a caution.
  /// Only meaningful for the resolver's own first choice — once the user
  /// picks a candidate themselves, the machine's doubt is no longer
  /// relevant and the flag clears.
  bool get isLowConfidence =>
      resolved.isLowConfidence && selectedIndex == resolved.selectedIndex;

  MealEntity? get meal =>
      isResolved ? resolved.candidates[selectedIndex] : null;

  /// The row's amount cannot be trusted to mean what the user typed, for
  /// either of two reasons.
  ///
  /// **No unit was stated** and the matched food has no scalable serving, so
  /// there is nothing for the "2" in `2 eggs` to count (#622).
  ///
  /// **A unit was stated but this food cannot honour it**, so
  /// [effectiveUnit] quietly substituted another. A model answers "three
  /// slices of bread" as `3 serving`; against a record with no scalable
  /// serving that becomes 3 g/ml, and looking only for a *missing* unit
  /// would let it through unmarked.
  ///
  /// Either way the row is **held back from the batch** until the user
  /// settles it, and marked so the eye lands on the one row needing a
  /// decision rather than on a plausible-looking wrong number.
  ///
  /// Marking alone used to be the whole remedy, and it was not enough. A
  /// device pass typed `zwei Eier und drei Scheiben Brot`, got two flagged
  /// rows reading 2 g/ml and 3 g/ml, and **Save all** wrote both: 11 kcal
  /// for a breakfast. The flag was doing its job and the batch ignored it.
  /// Worse, the control the flag points at cannot always answer — a record
  /// with no portion offers only `g`, `oz`, `g/ml`, so there is no unit on
  /// the dropdown that means *one egg*. A warning pointing at a control that
  /// cannot resolve it, over a button that logs it anyway, is not a warning.
  /// #973.
  ///
  /// Derived rather than stored, so picking a different candidate
  /// re-evaluates it against the food actually selected. A stored flag
  /// survived the switch and could leave a wrong number unflagged.
  ///
  /// [MealEntity.hasServingValues] is deliberately *not* the gate: it is
  /// also true for a record carrying only unparseable `servingSize` text
  /// ("1 egg"), which `convertQuantityToBaseUnit` cannot scale. Only
  /// `servingQuantity` makes a count convertible.
  bool get amountNeedsCheck =>
      !unitChosenByUser &&
      // An unresolved row has no food to count, and already says so. A
      // second complaint about its amount is noise on a row that cannot be
      // logged anyway.
      isResolved &&
      resolved.parsed.quantity != null &&
      (resolved.parsed.unit == null
          // Nothing stated, and nothing for the number to count.
          ? meal?.servingQuantity == null
          // A unit *was* stated but this food cannot honour it, so
          // `effectiveUnit` quietly substituted another. Live probing found
          // a model answering "three slices of bread" as `3 serving`; on a
          // record with no scalable serving that becomes 3 g/ml with no
          // warning, because the old condition only looked at a *missing*
          // unit. A substituted one is just as wrong and less visible.
          : effectiveUnit != unit);

  /// True when the amount on this row is the app's flat fallback — neither
  /// stated by the user nor carried by the food record.
  ///
  /// The gap [amountNeedsCheck] cannot see, and deliberately so: that getter
  /// requires `resolved.parsed.quantity != null`, so it only ever speaks about
  /// a number somebody supplied. When nobody supplies one the row falls to
  /// 100 g (1 oz imperial) and says nothing at all — the case where the app
  /// guesses hardest is the one case it stayed quiet about. #864.
  ///
  /// **Weaker than [amountNeedsCheck], and rendered more quietly.** That flag
  /// means "this number probably does not mean what you think"; this one only
  /// means "this number is not yours". 100 g is a defensible neutral — the
  /// nutriments are published per 100 g, so it is the one figure here nobody
  /// invented — and a warning that fires on every unquantified row would
  /// become wallpaper, which is exactly what the model-failure notices were
  /// shaped to avoid.
  ///
  /// Clears once the user types an amount: they have answered it.
  ///
  /// Gated on `servingQuantity`, and **not** on `scalableServingQuantity`.
  /// `_initialAmount` falls back to the flat number exactly when the numeric
  /// field is absent, so the wider getter would go quiet on rows the fallback
  /// really did fire on: OFF often leaves `servingQuantity` empty while
  /// `serving_size` carries "30 g" as text, and `scalableServingQuantity`
  /// reads the 30 out of it (#629). The row still shows 100.
  ///
  /// `hasServingValues` is not consulted either — it is true whenever
  /// `servingQuantity` is, so pairing them only looks like a stricter test.
  bool get amountIsProvisional =>
      !amountEditedByUser &&
      isResolved &&
      resolved.parsed.quantity == null &&
      meal?.servingQuantity == null;

  List<String> get allowedUnits => [
    // One entry per portion the food actually has — cup, slice, ounce —
    // rather than the single one `food_summary` picked. The values are
    // `serving`, `serving#1`, ...; `storedUnit` strips the suffix before
    // anything is written, so the published unit vocabulary is unchanged.
    // #864.
    if (meal?.portions.isNotEmpty ?? false)
      for (var i = 0; i < meal!.portions.length; i++) portionUnit(i)
    // Only when the serving can actually be scaled. `hasServingValues` is
    // also true for a record carrying nothing but `servingSize` text, and
    // `convertQuantityToBaseUnit` leaves those unscaled — so offering
    // `serving` there is a no-op dressed as a fix. Worse, it is the option
    // a user reaches for after reading `amountNeedsCheck`: picking it
    // relabels the row, clears the warning and logs the same wrong number.
    else if (meal?.servingQuantity != null)
      UnitDropdownItem.serving.toString(),
    if (meal?.isSolid ?? false) ...[
      UnitDropdownItem.g.toString(),
      UnitDropdownItem.oz.toString(),
    ],
    if (meal?.isLiquid ?? false) ...[
      UnitDropdownItem.ml.toString(),
      UnitDropdownItem.flOz.toString(),
    ],
    if (!(meal?.isSolid ?? false) && !(meal?.isLiquid ?? false)) ...[
      UnitDropdownItem.g.toString(),
      UnitDropdownItem.oz.toString(),
      UnitDropdownItem.ml.toString(),
      UnitDropdownItem.flOz.toString(),
    ],
    UnitDropdownItem.gml.toString(),
  ];

  String get effectiveUnit =>
      allowedUnits.contains(unit) ? unit : UnitDropdownItem.gml.toString();

  /// True when the row's number would reach the diary meaning something
  /// other than what was asked for.
  ///
  /// **Narrower than [amountNeedsCheck], deliberately.** That flag fires on
  /// every substituted unit, including substitutions that change nothing.
  /// A record measured in grams offers no `ml`, so `200ml Milch` becomes
  /// `200 g/ml` — same number, same base quantity, same energy, and a row
  /// that was right all along. The guard added for #973 (#975) held those
  /// back too, refusing an amount the user typed correctly and the app
  /// understood correctly.
  ///
  /// Three ways a number does go wrong, and each is checked on its own terms
  /// rather than inferred from the label:
  ///
  /// * **Nothing was stated** and the food cannot be counted, so the number
  ///   is a count about to be read as a weight — `2 Eier` as two grams.
  /// * **A serving the food cannot scale.** `3 serving` against a record
  ///   with no scalable serving converts to a bare `3`, and so does
  ///   `3 g/ml` — numerically identical, both meaningless, so comparing the
  ///   two conversions cannot see it. Caught by asking what the unit *is*.
  /// * **The conversion moves the number**, `4oz` against a record that
  ///   cannot honour ounces being the plain case.
  bool get amountWouldBeWrong {
    if (!amountNeedsCheck) return false;
    // Nothing to compare against: the count has no unit and no serving to
    // land on.
    if (resolved.parsed.unit == null) return true;
    // A serving the food cannot honour. Checked before the conversion, not
    // by it — see above.
    if (isPortionUnit(unit)) return true;
    final quantity = resolved.parsed.quantity;
    final food = meal;
    if (quantity == null || food == null) return true;
    return convertQuantityToBaseUnit(quantity, unit, food) !=
        convertQuantityToBaseUnit(quantity, effectiveUnit, food);
  }

  /// Rows that will actually be written when the user confirms.
  ///
  /// [amountWouldBeWrong] excludes rather than merely annotates: an amount
  /// that would land meaning something else is not written to the diary on
  /// the user's behalf. Picking a unit clears it and the row rejoins the
  /// batch, so the way out is one tap on the control the warning already
  /// points at. #973.
  bool get willBeLogged => isResolved && !skipped && !amountWouldBeWrong;

  /// What is wrong with [amountText], or null when the row can be written.
  ///
  /// Deliberately **not** consulted by [willBeLogged]. A row the user
  /// mistyped is handed back to them to fix; dropping it from the batch
  /// instead would log the rest and say nothing about the one that was
  /// meant to be there.
  ///
  /// Asked on submit rather than on every keystroke — [amountText] is text
  /// precisely so that a half-typed "1," is not called wrong mid-edit.
  BulkAddQuantityError? get quantityError {
    final text = amountText.trim();
    final quantity = double.tryParse(text.replaceAll(',', '.'));
    // Shape first, because the other two need a number to compare against a
    // bound and "" and "1.234" do not supply one. The parse is checked
    // beside the pattern rather than after it, so that whatever the write
    // would actually parse is what the bounds below are read from.
    if (!bulkAddQuantityPattern.hasMatch(text) || quantity == null) {
      return BulkAddQuantityError.malformed;
    }
    if (quantity <= 0) return BulkAddQuantityError.tooSmall;
    if (quantity > bulkAddMaxQuantity) return BulkAddQuantityError.tooLarge;
    return null;
  }

  BulkAddRow copyWith({
    int? selectedIndex,
    String? amountText,
    String? unit,
    bool? skipped,
    bool? unitChosenByUser,
    bool? amountEditedByUser,
  }) => BulkAddRow(
    resolved: resolved,
    selectedIndex: selectedIndex ?? this.selectedIndex,
    amountText: amountText ?? this.amountText,
    unit: unit ?? this.unit,
    skipped: skipped ?? this.skipped,
    unitChosenByUser: unitChosenByUser ?? this.unitChosenByUser,
    amountEditedByUser: amountEditedByUser ?? this.amountEditedByUser,
  );

  @override
  List<Object?> get props => [
    resolved.parsed.query,
    selectedIndex,
    amountText,
    unit,
    skipped,
    unitChosenByUser,
    amountEditedByUser,
  ];
}

class BulkAddBloc extends Bloc<BulkAddEvent, BulkAddState> {
  final log = Logger('BulkAddBloc');

  final ResolveParsedMealsUseCase _resolveParsedMealsUseCase;
  final ReadMealTextUseCase _readMealTextUseCase;
  final ReadMealPhotoUseCase _readMealPhotoUseCase;

  BulkAddBloc(
    this._resolveParsedMealsUseCase,
    this._readMealTextUseCase,
    this._readMealPhotoUseCase,
  ) : super(const BulkAddInitial()) {
    on<ParseBulkTextEvent>(_onParse);
    on<ReadMealPhotoEvent>(_onReadPhoto);
    on<ReadMealPhotoFailedEvent>(
      (event, emit) => emit(BulkAddPhotoErrorState(event.error)),
    );
    on<ChangeRowCandidateEvent>(_onChangeCandidate);
    on<ChangeRowAmountEvent>(_onChangeAmount);
    on<ChangeRowUnitEvent>(_onChangeUnit);
    on<ToggleRowSkippedEvent>(_onToggleSkipped);
  }

  Future<void> _onParse(
    ParseBulkTextEvent event,
    Emitter<BulkAddState> emit,
  ) async {
    // Emitted before the read, not after: with a key configured this waits
    // on a network round trip, and a screen that does nothing for two
    // seconds reads as broken.
    emit(const BulkAddLoadingState());

    final reading = await _readMealTextUseCase.read(
      event.text,
      localeCode: event.localeCode,
    );
    if (emit.isDone) return;

    await _resolveAndEmit(
      reading.result,
      emit,
      usesImperialUnits: event.usesImperialUnits,
      source: reading.usedModel
          ? BulkAddReadSource.model
          : BulkAddReadSource.parser,
      modelFailure: reading.modelFailure,
    );
  }

  /// A photo has no deterministic reader underneath it, so unlike the text
  /// path every failure here reaches the user. Saying "that did not work" is
  /// the honest outcome; quietly emitting no rows would leave the screen
  /// looking broken with nothing to act on.
  Future<void> _onReadPhoto(
    ReadMealPhotoEvent event,
    Emitter<BulkAddState> emit,
  ) async {
    emit(const BulkAddLoadingState());

    final reading = await _readMealPhotoUseCase.read(
      event.photo,
      localeCode: event.localeCode,
    );
    if (emit.isDone) return;

    switch (reading) {
      case MealPhotoUnavailable():
        emit(const BulkAddPhotoErrorState(BulkAddPhotoError.unavailable));
      case MealPhotoFailed(:final failure):
        emit(
          BulkAddPhotoErrorState(switch (failure) {
            MealPhotoFailure.auth => BulkAddPhotoError.auth,
            // The provider will refuse this picture every time, so it lands
            // on "try another photo" rather than on "try again".
            MealPhotoFailure.rejectedImage => BulkAddPhotoError.unreadable,
            MealPhotoFailure.unsupported => BulkAddPhotoError.unsupported,
            MealPhotoFailure.insecureDestination =>
              BulkAddPhotoError.insecureDestination,
            MealPhotoFailure.billing => BulkAddPhotoError.billing,
            MealPhotoFailure.transient => BulkAddPhotoError.transient,
          }),
        );
      case MealPhotoRead(:final result):
        // An empty list is an answer, not a failure: the model looked and
        // found no food. It lands on the same "nothing to log" message the
        // text path uses rather than on an error, because nothing went
        // wrong — the photo just was not of a meal.
        await _resolveAndEmit(
          result,
          emit,
          usesImperialUnits: event.usesImperialUnits,
          source: BulkAddReadSource.photo,
        );
    }
  }

  /// Shared by both readers: resolve whatever was extracted against the food
  /// database and emit the review rows. Which reader produced the items only
  /// changes [source] — everything downstream of here treats all three the
  /// same, which is what keeps the review screen honest about all of them.
  Future<void> _resolveAndEmit(
    MealTextParseResult parsed,
    Emitter<BulkAddState> emit, {
    required bool usesImperialUnits,
    required BulkAddReadSource source,
    MealTextModelFailure? modelFailure,
  }) async {
    if (parsed.items.isEmpty) {
      // Nothing usable. The parser's own errors still go through so the
      // user is told why, rather than the screen just doing nothing.
      emit(
        BulkAddLoadedState(
          rows: const [],
          parseErrors: parsed.errors,
          usesImperialUnits: usesImperialUnits,
          source: source,
          modelFailure: modelFailure,
        ),
      );
      return;
    }

    try {
      final resolved = await _resolveParsedMealsUseCase.resolve(parsed.items);
      if (emit.isDone) return;

      emit(
        BulkAddLoadedState(
          rows: [
            for (final item in resolved)
              BulkAddRow(
                resolved: item,
                selectedIndex: item.selectedIndex,
                amountText: _initialAmount(
                  item.parsed,
                  item.selected,
                  usesImperialUnits,
                ),
                unit: _initialUnit(
                  item.parsed,
                  item.selected,
                  usesImperialUnits,
                ),
              ),
          ],
          parseErrors: parsed.errors,
          usesImperialUnits: usesImperialUnits,
          source: source,
          modelFailure: modelFailure,
        ),
      );
    } catch (e, stackTrace) {
      log.severe('Bulk resolution failed', e, stackTrace);
      if (emit.isDone) return;
      emit(const BulkAddErrorState());
    }
  }

  /// The parser leaves quantity null when the user stated none. Fall back to
  /// the same defaults the meal-detail screen already applies, so a bulk row
  /// and a hand-added row of the same food start from the same number.
  String _initialAmount(
    ParsedMealItem parsed,
    MealEntity? meal,
    bool usesImperialUnits,
  ) {
    final parsedQuantity = parsed.quantity;
    if (parsedQuantity != null) return _amountText(parsedQuantity);

    if (meal != null && meal.hasServingValues) {
      final serving = meal.servingQuantity;
      if (serving != null) return _amountText(serving);
    }
    return usesImperialUnits ? '1' : '100';
  }

  String _initialUnit(
    ParsedMealItem parsed,
    MealEntity? meal,
    bool usesImperialUnits,
  ) {
    final parsedUnit = parsed.unit;
    if (parsedUnit != null) return parsedUnit;

    final fallback = usesImperialUnits
        ? UnitDropdownItem.oz.toString()
        : UnitDropdownItem.gml.toString();
    if (meal == null) return fallback;

    // The user named a portion, so their word decides which — "3 slices of
    // bread" is slices, not the cup that happens to sort first. Above the
    // bare-count rule below, because that rule cannot tell the two apart and
    // would take the default.
    //
    // Only ever *narrows* the choice: no match leaves the preselection
    // exactly as it was, which is decision 7 — nothing changes for anyone
    // who did not name a portion.
    if (parsed.quantity != null) {
      // The model's own word first, then the user's. A photograph has no
      // typed text to search, so `portion` is the only thing that can name a
      // slice there; where both exist they usually agree, and the model saw
      // the food.
      final named =
          matchPortionToQuery(parsed.portion ?? '', meal.portions) ??
          matchPortionToQuery(parsed.query, meal.portions);
      if (named != null) return portionUnit(named);
    }

    // A bare count means "N of them", and when the record's serving can be
    // scaled that is precisely what a serving is — so `2 eggs` is two
    // servings. Falling through to grams instead turned a count into a
    // weight and logged two grams of egg (#622).
    //
    // Gate on `servingQuantity`, not `hasServingValues`: the latter is also
    // true for a record with only unparseable `servingSize` text, which
    // `convertQuantityToBaseUnit` leaves unscaled. Labelling those `serving`
    // would rename the bug rather than fix it — the row would read
    // "2 serving" and still log 2 g. Those fall through to the weight
    // default below and are marked by `BulkAddRow.amountNeedsCheck`.
    if (parsed.quantity != null && meal.servingQuantity != null) {
      return UnitDropdownItem.serving.toString();
    }

    if (meal.hasServingValues) {
      return meal.servingUnit ?? UnitDropdownItem.gml.toString();
    }
    return fallback;
  }

  /// Formats a quantity for the amount field, which accepts at most two
  /// decimals — [bulkAddQuantityPattern] is both the submit check and the
  /// field's input formatter. A converted imperial quantity has
  /// many more: `1 lb` is 453.59237 g. Prefilling that verbatim produced a row
  /// the submit check refused, with a message naming only the field, and
  /// because that check aborts the batch, one such row blocked every correct
  /// row beside it. The pattern is anchored, so the formatter then rejected
  /// every edit too and the field blanked on the first keystroke. Rounding
  /// here is what keeps the prefill and the check in step.
  ///
  /// The floor is the same concern from the other end: a positive quantity
  /// below 0.005 would round to zero, which the check rejects for being
  /// non-positive.
  static String _amountText(double value) {
    final rounded = double.parse(value.toStringAsFixed(2));
    final quantity = rounded <= 0 && value > 0 ? 0.01 : rounded;
    return quantity == quantity.roundToDouble()
        ? quantity.toInt().toString()
        : quantity.toString();
  }

  void _onChangeCandidate(
    ChangeRowCandidateEvent event,
    Emitter<BulkAddState> emit,
  ) {
    final current = state;
    final imperial = current is BulkAddLoadedState && current.usesImperialUnits;

    _updateRow(event.rowIndex, emit, (row) {
      final moved = row.copyWith(selectedIndex: event.candidateIndex);
      // A different food means different defaults. Re-derive them, or the
      // row keeps the previous candidate's unit — picking a countable
      // record after an uncountable one cleared the "check the unit"
      // warning while the amount stayed a weight, which is the #622
      // failure again with the warning switched off. Only for a pristine
      // row: anything the user typed or chose outranks a default.
      if (!moved.isPristine) return moved;
      return moved.copyWith(
        amountText: _initialAmount(row.resolved.parsed, moved.meal, imperial),
        unit: _initialUnit(row.resolved.parsed, moved.meal, imperial),
      );
    });
  }

  void _onChangeAmount(ChangeRowAmountEvent event, Emitter<BulkAddState> emit) {
    _updateRow(
      event.rowIndex,
      emit,
      (row) =>
          row.copyWith(amountText: event.amountText, amountEditedByUser: true),
    );
  }

  void _onChangeUnit(ChangeRowUnitEvent event, Emitter<BulkAddState> emit) {
    _updateRow(
      event.rowIndex,
      emit,
      // Picking a unit answers the question `amountNeedsCheck` was asking,
      // so the row stops asking it.
      (row) => row.copyWith(unit: event.unit, unitChosenByUser: true),
    );
  }

  void _onToggleSkipped(
    ToggleRowSkippedEvent event,
    Emitter<BulkAddState> emit,
  ) {
    _updateRow(
      event.rowIndex,
      emit,
      (row) => row.copyWith(skipped: !row.skipped),
    );
  }

  void _updateRow(
    int index,
    Emitter<BulkAddState> emit,
    BulkAddRow Function(BulkAddRow) change,
  ) {
    final current = state;
    if (current is! BulkAddLoadedState) return;
    if (index < 0 || index >= current.rows.length) return;

    final rows = [...current.rows];
    rows[index] = change(rows[index]);
    emit(current.copyWith(rows: rows));
  }
}
