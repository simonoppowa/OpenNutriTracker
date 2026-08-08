import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/bulk_add_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';

class BulkAddScreenArguments {
  final IntakeTypeEntity intakeTypeEntity;
  final DateTime day;
  final bool usesImperialUnits;

  const BulkAddScreenArguments(
    this.intakeTypeEntity,
    this.day,
    this.usesImperialUnits,
  );
}

/// Type a whole meal, confirm what it matched, log it in one go.
///
/// **The confirmation step is not optional.** It exists so nothing reaches
/// the diary that the user has not looked at. Tier 0 resolves everything
/// against the food database and invents no numbers, so today that is a
/// correctness concern; once a model tier lands it also becomes the human
/// review that AI Act Art. 50(4) and both providers' usage policies expect.
/// See #599 and `docs/ai-legal-constraints.md` before removing it.
class BulkAddScreen extends StatefulWidget {
  const BulkAddScreen({super.key});

  @override
  State<BulkAddScreen> createState() => _BulkAddScreenState();
}

class _BulkAddScreenState extends State<BulkAddScreen> {
  final _bloc = locator<BulkAddBloc>();
  final _textController = TextEditingController();

  /// One controller per row, keyed by row index and rebuilt whenever a new
  /// parse produces a different set of rows.
  final _amountControllers = <int, TextEditingController>{};

  late BulkAddScreenArguments _args;
  bool _submitting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _args =
        ModalRoute.of(context)!.settings.arguments as BulkAddScreenArguments;
  }

  @override
  void dispose() {
    _textController.dispose();
    for (final controller in _amountControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).bulkAddTitle)),
      body: SafeArea(
        child: BlocBuilder<BulkAddBloc, BulkAddState>(
          bloc: _bloc,
          builder: (context, state) => Column(
            children: [
              _buildInput(context),
              const Divider(height: 1),
              Expanded(child: _buildBody(context, state)),
              if (state is BulkAddLoadedState) _buildSubmitBar(context, state),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          identifier: 'bulk-add-input',
          child: TextField(
            controller: _textController,
            minLines: 2,
            maxLines: 4,
            textInputAction: TextInputAction.newline,
            keyboardType: TextInputType.multiline,
            decoration: InputDecoration(
              hintText: S.of(context).bulkAddInputHint,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Semantics(
          identifier: 'bulk-add-parse',
          child: FilledButton.icon(
            onPressed: _onParsePressed,
            icon: const Icon(Icons.search),
            label: Text(S.of(context).bulkAddParseLabel),
          ),
        ),
      ],
    ),
  );

  Widget _buildBody(BuildContext context, BulkAddState state) {
    if (state is BulkAddLoadingState) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is BulkAddErrorState) {
      return _centeredMessage(context, S.of(context).bulkAddSearchFailedLabel);
    }
    if (state is! BulkAddLoadedState) {
      return const SizedBox();
    }
    if (state.rows.isEmpty) {
      return _centeredMessage(
        context,
        state.parseErrors.isEmpty
            ? S.of(context).bulkAddNothingToLogLabel
            : state.parseErrors.join('\n'),
      );
    }

    // The list is the labelled surface, not each child — row identifiers
    // would churn every time the row count changes.
    return Semantics(
      identifier: 'bulk-add-row-list',
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: state.rows.length + (state.parseErrors.isEmpty ? 0 : 1),
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          if (index == state.rows.length) {
            return _buildParseErrors(context, state.parseErrors);
          }
          return _buildRow(context, state, index);
        },
      ),
    );
  }

  Widget _centeredMessage(BuildContext context, String message) => Padding(
    padding: const EdgeInsets.all(24),
    child: Center(child: Text(message, textAlign: TextAlign.center)),
  );

  Widget _buildParseErrors(BuildContext context, List<String> errors) =>
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Text(
          errors.join('\n'),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.error,
          ),
        ),
      );

  Widget _buildRow(BuildContext context, BulkAddLoadedState state, int index) {
    final row = state.rows[index];
    final theme = Theme.of(context);
    final meal = row.meal;

    final title = meal?.name ?? row.resolved.parsed.query;
    final faded = row.skipped || !row.isResolved;

    return Opacity(
      opacity: row.skipped ? 0.5 : 1.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: row.isResolved
                        ? () => _showCandidatePicker(index, row)
                        : null,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            decoration: row.skipped
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        if (!row.isResolved)
                          Text(
                            S.of(context).bulkAddNoMatchLabel,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          )
                        else if (row.isLowConfidence)
                          Text(
                            S.of(context).bulkAddUncertainLabel,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.tertiary,
                            ),
                          )
                        else if (meal?.brands != null)
                          Text(meal!.brands!, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => _bloc.add(ToggleRowSkippedEvent(index)),
                  child: Text(
                    row.skipped
                        ? S.of(context).bulkAddIncludeLabel
                        : S.of(context).bulkAddSkipLabel,
                  ),
                ),
              ],
            ),
            if (!faded) _buildAmountRow(context, state, index, row),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountRow(
    BuildContext context,
    BulkAddLoadedState state,
    int index,
    BulkAddRow row,
  ) {
    final controller = _amountControllers.putIfAbsent(
      index,
      () => TextEditingController(text: row.amountText),
    );
    if (controller.text != row.amountText) {
      controller.text = row.amountText;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: S.of(context).quantityLabel,
                isDense: true,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) =>
                  _bloc.add(ChangeRowAmountEvent(index, value)),
            ),
          ),
          const SizedBox(width: 12),
          DropdownButton<String>(
            value: MealDetailUnits.all.contains(row.unit)
                ? row.unit
                : MealDetailUnits.gml,
            items: [
              for (final unit in MealDetailUnits.all)
                DropdownMenuItem(value: unit, child: Text(unit)),
            ],
            onChanged: (value) {
              if (value != null) _bloc.add(ChangeRowUnitEvent(index, value));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitBar(BuildContext context, BulkAddLoadedState state) {
    final count = state.loggableCount;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Semantics(
          identifier: 'bulk-add-submit',
          child: FilledButton.icon(
            onPressed: count == 0 || _submitting
                ? null
                : () => _onSubmitPressed(state),
            icon: const Icon(Icons.add_rounded),
            label: Text(S.of(context).bulkAddSubmitLabel(count)),
          ),
        ),
      ),
    );
  }

  void _onParsePressed() {
    FocusScope.of(context).unfocus();
    for (final controller in _amountControllers.values) {
      controller.dispose();
    }
    _amountControllers.clear();
    _bloc.add(
      ParseBulkTextEvent(
        text: _textController.text,
        usesImperialUnits: _args.usesImperialUnits,
      ),
    );
  }

  Future<void> _showCandidatePicker(int index, BulkAddRow row) async {
    final chosen = await showModalBottomSheet<int>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                S.of(context).bulkAddChooseFoodLabel,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (var i = 0; i < row.resolved.candidates.length; i++)
              ListTile(
                title: Text(row.resolved.candidates[i].name ?? ''),
                subtitle: row.resolved.candidates[i].brands != null
                    ? Text(row.resolved.candidates[i].brands!)
                    : null,
                trailing: i == row.selectedIndex
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => Navigator.of(context).pop(i),
              ),
          ],
        ),
      ),
    );
    if (chosen != null) _bloc.add(ChangeRowCandidateEvent(index, chosen));
  }

  /// Validate the whole batch, then write it.
  ///
  /// `MealDetailBloc.addIntake` calls `double.parse` with no guard, so a
  /// single bad row throws mid-loop and leaves the rows before it already
  /// written — a half-logged meal with no rollback. Checking every row up
  /// front is what makes the batch all-or-nothing.
  Future<void> _onSubmitPressed(BulkAddLoadedState state) async {
    final rows = state.loggableRows.toList();

    for (final row in rows) {
      final quantity = double.tryParse(row.amountText.replaceAll(',', '.'));
      if (quantity == null || quantity <= 0 || quantity > 10000) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${row.meal?.name ?? row.resolved.parsed.query}: '
              '${S.of(context).quantityLabel}',
            ),
          ),
        );
        return;
      }
    }

    setState(() => _submitting = true);

    final mealDetailBloc = locator<MealDetailBloc>();
    for (final row in rows) {
      if (!mounted) return;
      mealDetailBloc.addIntake(
        context,
        row.unit,
        row.amountText,
        _args.intakeTypeEntity,
        row.meal!,
        _args.day,
      );
    }

    if (!mounted) return;

    locator<HomeBloc>().add(const LoadItemsEvent());
    locator<DiaryBloc>().add(const LoadDiaryYearEvent());
    locator<CalendarDayBloc>().add(const RefreshCalendarDayEvent());

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(S.of(context).infoAddedIntakeLabel)));
    Navigator.of(
      context,
    ).popUntil(ModalRoute.withName(NavigationOptions.mainRoute));
  }
}
