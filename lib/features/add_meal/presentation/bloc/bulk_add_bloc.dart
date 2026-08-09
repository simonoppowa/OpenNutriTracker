import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/resolve_parsed_meals_usecase.dart';
import 'package:opennutritracker/features/add_meal/util/meal_text_parser.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';

part 'bulk_add_event.dart';
part 'bulk_add_state.dart';

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

  const BulkAddRow({
    required this.resolved,
    required this.selectedIndex,
    required this.amountText,
    required this.unit,
    this.skipped = false,
    this.unitChosenByUser = false,
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

  /// The user stated a count the app cannot interpret: no unit was typed and
  /// the matched food has no scalable serving, so there is nothing for the
  /// "2" in `2 eggs` to count. The row still logs — both fields are editable
  /// — but it is marked so the eye lands on the one row needing a decision
  /// rather than on a plausible-looking wrong number (#622).
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
      resolved.parsed.unit == null &&
      meal?.servingQuantity == null;

  List<String> get allowedUnits => [
    if (meal?.hasServingValues ?? false) UnitDropdownItem.serving.toString(),
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

  /// Rows that will actually be written when the user confirms.
  bool get willBeLogged => isResolved && !skipped;

  BulkAddRow copyWith({
    int? selectedIndex,
    String? amountText,
    String? unit,
    bool? skipped,
    bool? unitChosenByUser,
  }) => BulkAddRow(
    resolved: resolved,
    selectedIndex: selectedIndex ?? this.selectedIndex,
    amountText: amountText ?? this.amountText,
    unit: unit ?? this.unit,
    skipped: skipped ?? this.skipped,
    unitChosenByUser: unitChosenByUser ?? this.unitChosenByUser,
  );

  @override
  List<Object?> get props => [
    resolved.parsed.query,
    selectedIndex,
    amountText,
    unit,
    skipped,
    unitChosenByUser,
  ];
}

class BulkAddBloc extends Bloc<BulkAddEvent, BulkAddState> {
  final log = Logger('BulkAddBloc');

  final ResolveParsedMealsUseCase _resolveParsedMealsUseCase;

  BulkAddBloc(this._resolveParsedMealsUseCase) : super(const BulkAddInitial()) {
    on<ParseBulkTextEvent>(_onParse);
    on<ChangeRowCandidateEvent>(_onChangeCandidate);
    on<ChangeRowAmountEvent>(_onChangeAmount);
    on<ChangeRowUnitEvent>(_onChangeUnit);
    on<ToggleRowSkippedEvent>(_onToggleSkipped);
  }

  Future<void> _onParse(
    ParseBulkTextEvent event,
    Emitter<BulkAddState> emit,
  ) async {
    final parsed = parseMealText(event.text);

    if (parsed.items.isEmpty) {
      // Nothing usable. The parser's own errors still go through so the
      // user is told why, rather than the screen just doing nothing.
      emit(
        BulkAddLoadedState(
          rows: const [],
          parseErrors: parsed.errors,
          usesImperialUnits: event.usesImperialUnits,
        ),
      );
      return;
    }

    emit(const BulkAddLoadingState());

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
                amountText: _initialAmount(item, event.usesImperialUnits),
                unit: _initialUnit(item, event.usesImperialUnits),
              ),
          ],
          parseErrors: parsed.errors,
          usesImperialUnits: event.usesImperialUnits,
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
  String _initialAmount(ResolvedMealItem item, bool usesImperialUnits) {
    final parsedQuantity = item.parsed.quantity;
    if (parsedQuantity != null) return _trimZeros(parsedQuantity);

    final meal = item.selected;
    if (meal != null && meal.hasServingValues) {
      final serving = meal.servingQuantity;
      if (serving != null) return _trimZeros(serving);
    }
    return usesImperialUnits ? '1' : '100';
  }

  String _initialUnit(ResolvedMealItem item, bool usesImperialUnits) {
    final parsedUnit = item.parsed.unit;
    if (parsedUnit != null) return parsedUnit;

    final meal = item.selected;
    final fallback = usesImperialUnits
        ? UnitDropdownItem.oz.toString()
        : UnitDropdownItem.gml.toString();
    if (meal == null) return fallback;

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
    if (item.parsed.quantity != null && meal.servingQuantity != null) {
      return UnitDropdownItem.serving.toString();
    }

    if (meal.hasServingValues) {
      return meal.servingUnit ?? UnitDropdownItem.gml.toString();
    }
    return fallback;
  }

  static String _trimZeros(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toString();

  void _onChangeCandidate(
    ChangeRowCandidateEvent event,
    Emitter<BulkAddState> emit,
  ) {
    _updateRow(
      event.rowIndex,
      emit,
      (row) => row.copyWith(selectedIndex: event.candidateIndex),
    );
  }

  void _onChangeAmount(ChangeRowAmountEvent event, Emitter<BulkAddState> emit) {
    _updateRow(
      event.rowIndex,
      emit,
      (row) => row.copyWith(amountText: event.amountText),
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
