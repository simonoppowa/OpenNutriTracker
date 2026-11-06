import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:opennutritracker/features/edit_meal/domain/nutrition_import_parser.dart';
import 'package:opennutritracker/core/utils/food_name_validator.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// Returns one reviewed entry to the editor. File batches are saved only after
/// the user has inspected the preview and explicitly confirms the batch.
class NutritionImportDialog extends StatefulWidget {
  final Future<String> Function(List<NutritionEntry>)? saveAll;
  final Future<void> Function(List<NutritionEntry>)? applyAll;
  final bool allowFileImport;
  const NutritionImportDialog({
    super.key,
    this.saveAll,
    this.applyAll,
    this.allowFileImport = true,
  });

  @override
  State<NutritionImportDialog> createState() => _NutritionImportDialogState();
}

class _NutritionImportDialogState extends State<NutritionImportDialog> {
  final _paste = TextEditingController();
  final _name = TextEditingController();
  final _brand = TextEditingController();
  final _size = TextEditingController();
  final _values = {
    for (final field
        in nutritionFields.skip(2).takeWhile((field) => field != 'servingSize'))
      field: TextEditingController(),
  };
  List<NutritionEntry> _entries = [];
  List<String> _errors = [];
  NutritionFileResult? _file;
  final _sources =
      <
        ({String name, String content, bool json, NutritionFileResult result})
      >[];
  int _index = 0;
  bool _busy = false;
  bool _acknowledgedIssues = false;
  String? _message;
  NutritionBasis _basis = NutritionBasis.unknown;
  String? _unit;

  NutritionEntry get _current => _entries[_index];

  @override
  void dispose() {
    _paste.dispose();
    _name.dispose();
    _brand.dispose();
    _size.dispose();
    for (final controller in _values.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _showEntries(List<NutritionEntry> entries, List<String> errors) {
    setState(() {
      _entries = entries;
      _errors = errors;
      _index = 0;
      _message = null;
    });
    if (entries.isNotEmpty) _load(0);
  }

  void _load(int index) {
    _index = index;
    _acknowledgedIssues = false;
    final entry = _current;
    _name.text = entry.name;
    _brand.text = entry.brand;
    _size.text = entry.servingSize?.toString() ?? '';
    _basis = entry.basis;
    _unit = entry.servingUnit;
    for (final item in _values.entries) {
      item.value.text = entry.values[item.key]?.toString() ?? '';
    }
    setState(() {});
  }

  bool _commit() {
    final entry = _current;
    if (entry.issues.isNotEmpty && !_acknowledgedIssues) {
      setState(() => _message = S.of(context).nutritionReviewIssuesLabel);
      return false;
    }
    if (!FoodNameValidator.isValid(_name.text)) {
      setState(() => _message = S.of(context).mealNameValidationError);
      return false;
    }
    entry.name = _name.text.trim();
    entry.brand = _brand.text.trim();
    entry.basis = _basis;
    entry.servingUnit = _unit;
    entry.servingSize = _size.text.trim().isEmpty
        ? null
        : double.tryParse(_size.text.trim().replaceAll(',', '.'));
    if (_size.text.trim().isNotEmpty &&
        (entry.servingSize == null || entry.servingSize! <= 0)) {
      setState(() => _message = S.of(context).nutritionServingSizeInvalid);
      return false;
    }
    for (final item in _values.entries) {
      final raw = item.value.text.trim().replaceAll(',', '.');
      if (raw.isEmpty) {
        entry.values.remove(item.key);
        continue;
      }
      final value = double.tryParse(raw);
      if (value == null || !value.isFinite || value < 0) {
        setState(
          () => _message = S
              .of(context)
              .nutritionNumberInvalid(_fieldLabel(item.key)),
        );
        return false;
      }
      entry.values[item.key] = value;
    }
    if (!entry.hasNutrients) {
      setState(() => _message = S.of(context).nutritionNutrientRequired);
      return false;
    }
    try {
      entry.toPer100();
    } on FormatException catch (e) {
      setState(() => _message = e.message);
      return false;
    }
    setState(() => _message = null);
    return true;
  }

  void _parsePaste() {
    final result = NutritionImportParser.parseTextEntries(_paste.text);
    _file = null;
    _csvText = null;
    _jsonText = null;
    _sources.clear();
    _showEntries(result.entries, result.errors);
  }

  Future<void> _pickFile() async {
    try {
      final picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'json'],
      );
      if (picked.isEmpty || !mounted) return;
      final entries = <NutritionEntry>[];
      final errors = <String>[];
      _sources.clear();
      for (final selected in picked) {
        if (selected.path == null) {
          errors.add('${selected.name}: no readable file path.');
          continue;
        }
        final content = await File(selected.path!).readAsString(encoding: utf8);
        final isJson = selected.name.toLowerCase().endsWith('.json');
        final result = isJson
            ? NutritionImportParser.parseJson(content)
            : NutritionImportParser.parseCsv(content);
        entries.addAll(result.entries);
        errors.addAll(result.errors.map((error) => '${selected.name}: $error'));
        _sources.add((
          name: selected.name,
          content: content,
          json: isJson,
          result: result,
        ));
      }
      if (!mounted) return;
      _csvText = _sources.length == 1 && !_sources.single.json
          ? _sources.single.content
          : null;
      _jsonText = _sources.length == 1 && _sources.single.json
          ? _sources.single.content
          : null;
      _file = _sources.length == 1 ? _sources.single.result : null;
      _showEntries(entries, errors);
    } catch (error) {
      setState(
        () => _message = S.of(context).nutritionReadFileError(error.toString()),
      );
    }
  }

  void _remap(int column, String? field) {
    final file = _file;
    if (file == null) return;
    final mapping = Map<int, String>.from(file.mapping);
    if (field == null) {
      mapping.remove(column);
    } else {
      mapping[column] = field;
    }
    final result = _csvText != null
        ? NutritionImportParser.parseCsv(_csvText!, manualMapping: mapping)
        : NutritionImportParser.parseJson(_jsonText!, manualMapping: mapping);
    _file = result;
    _showEntries(result.entries, result.errors);
  }

  void _remapSource(int sourceIndex, int column, String? field) {
    final source = _sources[sourceIndex];
    final mapping = Map<int, String>.from(source.result.mapping);
    if (field == null) {
      mapping.remove(column);
    } else {
      mapping[column] = field;
    }
    final result = source.json
        ? NutritionImportParser.parseJson(
            source.content,
            manualMapping: mapping,
          )
        : NutritionImportParser.parseCsv(
            source.content,
            manualMapping: mapping,
          );
    _sources[sourceIndex] = (
      name: source.name,
      content: source.content,
      json: source.json,
      result: result,
    );
    _showEntries(
      [for (final item in _sources) ...item.result.entries],
      [
        for (final item in _sources)
          ...item.result.errors.map((error) => '${item.name}: $error'),
      ],
    );
  }

  String? _csvText;
  String? _jsonText;

  void _changeBasis(NutritionBasis basis) {
    if (_entries.isEmpty) return;
    NutritionEntry parsed;
    if (_sources.length > 1) {
      var offset = 0;
      final source = _sources.firstWhere((source) {
        final found = _index < offset + source.result.entries.length;
        if (!found) offset += source.result.entries.length;
        return found;
      });
      final result = source.json
          ? NutritionImportParser.parseJson(
              source.content,
              manualMapping: source.result.mapping,
              selectedBasis: basis,
            )
          : NutritionImportParser.parseCsv(
              source.content,
              manualMapping: source.result.mapping,
              selectedBasis: basis,
            );
      final localIndex = _index - offset;
      parsed = localIndex < result.entries.length
          ? result.entries[localIndex]
          : NutritionEntry(basis: basis);
    } else if (_csvText != null && _file != null) {
      final result = NutritionImportParser.parseCsv(
        _csvText!,
        manualMapping: _file!.mapping,
        selectedBasis: basis,
      );
      parsed = result.entries.length == _entries.length
          ? result.entries[_index]
          : NutritionEntry(basis: basis);
    } else if (_jsonText != null) {
      final result = NutritionImportParser.parseJson(
        _jsonText!,
        selectedBasis: basis,
        manualMapping: _file?.mapping,
      );
      parsed = result.entries.length == _entries.length
          ? result.entries[_index]
          : NutritionEntry(basis: basis);
    } else {
      final blocks = _paste.text.trim().split(RegExp(r'\r?\n\s*\r?\n+'));
      parsed = NutritionImportParser.parseText(
        blocks.length > _index ? blocks[_index] : _paste.text,
        selectedBasis: basis,
      );
    }
    parsed.name = _name.text;
    parsed.brand = _brand.text;
    parsed.servingSize = _size.text.trim().isEmpty
        ? null
        : double.tryParse(_size.text.trim().replaceAll(',', '.'));
    parsed.servingUnit = _unit;
    if (!parsed.hasNutrients) {
      parsed.issues.add(
        'No values in this column. Enter values manually or choose another basis.',
      );
    }
    _entries[_index] = parsed;
    _load(_index);
  }

  Future<void> _saveBatch() async {
    final saveAll = widget.saveAll;
    if (!_commit() || _busy || saveAll == null) return;
    setState(() => _busy = true);
    try {
      final summary = await saveAll(_entries);
      if (!mounted) return;
      setState(
        () => _message = summary.isEmpty
            ? S.of(context).nutritionNoFoodsSaved
            : summary,
      );
    } catch (error) {
      if (mounted) {
        setState(
          () =>
              _message = S.of(context).nutritionImportFailed(error.toString()),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _applyBatch() async {
    final applyAll = widget.applyAll;
    if (!_commit() || _busy || applyAll == null) return;
    for (final entry in _entries) {
      if (!FoodNameValidator.isValid(entry.name) || !entry.hasNutrients) {
        setState(() => _message = S.of(context).mealNameValidationError);
        return;
      }
      try {
        entry.toPer100();
      } on FormatException catch (error) {
        setState(() => _message = error.message);
        return;
      }
      if (entry.issues.isNotEmpty && entry != _current) {
        setState(() => _message = S.of(context).nutritionReviewIssuesLabel);
        return;
      }
    }
    setState(() => _busy = true);
    try {
      await applyAll(_entries);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        setState(
          () =>
              _message = S.of(context).nutritionImportFailed(error.toString()),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 560,
        height: math.min(
          620.0,
          MediaQuery.sizeOf(context).height -
              MediaQuery.viewInsetsOf(context).bottom -
              48,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                S.of(context).nutritionImportTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  children: [
                    Semantics(
                      identifier: 'nutrition-paste-text',
                      child: TextField(
                        controller: _paste,
                        maxLines: 5,
                        decoration: InputDecoration(
                          labelText: S.of(context).nutritionPasteAction,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        Semantics(
                          identifier: 'nutrition-parse-paste',
                          child: OutlinedButton(
                            onPressed: _parsePaste,
                            child: Text(S.of(context).nutritionImportAction),
                          ),
                        ),
                        if (widget.allowFileImport)
                          Semantics(
                            identifier: 'nutrition-pick-file',
                            child: OutlinedButton(
                              onPressed: () async {
                                await _pickFile();
                              },
                              child: Text(S.of(context).nutritionFileAction),
                            ),
                          ),
                      ],
                    ),
                    if (_file != null && _file!.headings.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(S.of(context).nutritionMappingLabel),
                      for (var i = 0; i < _file!.headings.length; i++)
                        Semantics(
                          identifier: 'nutrition-column-$i',
                          child: DropdownButtonFormField<String>(
                            key: ValueKey('mapping-$i-${_file!.mapping[i]}'),
                            initialValue: _file!.mapping[i],
                            decoration: InputDecoration(
                              labelText: _file!.headings[i],
                            ),
                            items: [
                              DropdownMenuItem<String>(
                                value: null,
                                child: Text(
                                  S.of(context).nutritionIgnoreColumnLabel,
                                ),
                              ),
                              for (final field in nutritionFields)
                                DropdownMenuItem(
                                  value: field,
                                  child: Text(_fieldLabel(field)),
                                ),
                            ],
                            onChanged: (field) => _remap(i, field),
                          ),
                        ),
                    ],
                    if (_sources.length > 1)
                      for (
                        var sourceIndex = 0;
                        sourceIndex < _sources.length;
                        sourceIndex++
                      ) ...[
                        const SizedBox(height: 12),
                        Text(
                          '${S.of(context).nutritionMappingLabel}: ${_sources[sourceIndex].name}',
                        ),
                        for (
                          var column = 0;
                          column < _sources[sourceIndex].result.headings.length;
                          column++
                        )
                          DropdownButtonFormField<String>(
                            key: ValueKey(
                              'source-$sourceIndex-column-$column-${_sources[sourceIndex].result.mapping[column]}',
                            ),
                            initialValue:
                                _sources[sourceIndex].result.mapping[column],
                            decoration: InputDecoration(
                              labelText:
                                  _sources[sourceIndex].result.headings[column],
                            ),
                            items: [
                              DropdownMenuItem<String>(
                                value: null,
                                child: Text(
                                  S.of(context).nutritionIgnoreColumnLabel,
                                ),
                              ),
                              for (final field in nutritionFields)
                                DropdownMenuItem(
                                  value: field,
                                  child: Text(_fieldLabel(field)),
                                ),
                            ],
                            onChanged: (field) =>
                                _remapSource(sourceIndex, column, field),
                          ),
                      ],
                    if (_errors.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      for (final error in _errors)
                        Text(
                          error,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                    ],
                    if (_entries.isNotEmpty) ...[
                      const Divider(),
                      if (_entries.length > 1)
                        Semantics(
                          identifier: 'nutrition-entry-tabs',
                          child: SizedBox(
                            height: 56,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _entries.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (context, index) => Semantics(
                                identifier: 'nutrition-entry-tab-$index',
                                selected: index == _index,
                                child: ChoiceChip(
                                  selected: index == _index,
                                  label: Text(
                                    '${index + 1}. ${_entries[index].name}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onSelected: (_) {
                                    if (index != _index && _commit()) {
                                      _load(index);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      for (final issue in _current.issues)
                        Text(
                          issue,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      if (_current.issues.isNotEmpty)
                        Semantics(
                          identifier: 'nutrition-acknowledge-issues',
                          child: CheckboxListTile(
                            value: _acknowledgedIssues,
                            onChanged: (value) => setState(
                              () => _acknowledgedIssues = value ?? false,
                            ),
                            title: Text(
                              S.of(context).nutritionReviewIssuesLabel,
                            ),
                          ),
                        ),
                      _field(S.of(context).mealNameLabel, _name, id: 'name'),
                      _field(
                        S.of(context).mealBrandsLabel,
                        _brand,
                        id: 'brand',
                      ),
                      Semantics(
                        identifier: 'nutrition-basis-select',
                        child: _labeledInput(
                          S.of(context).nutritionBasisLabel,
                          DropdownButtonFormField<NutritionBasis>(
                            key: ValueKey('basis-$_basis'),
                            initialValue: _basis,
                            decoration: const InputDecoration(),
                            items: [
                              for (final basis in NutritionBasis.values)
                                DropdownMenuItem(
                                  value: basis,
                                  child: Text(switch (basis) {
                                    NutritionBasis.per100g => '100 g',
                                    NutritionBasis.per100ml => '100 ml',
                                    NutritionBasis.serving =>
                                      S.of(context).nutritionServingBasisLabel,
                                    NutritionBasis.portion =>
                                      S.of(context).nutritionPortionBasisLabel,
                                    NutritionBasis.package =>
                                      S.of(context).nutritionPackageBasisLabel,
                                    NutritionBasis.unknown =>
                                      S.of(context).nutritionSelectBasisLabel,
                                  }),
                                ),
                            ],
                            onChanged: (value) =>
                                _changeBasis(value ?? NutritionBasis.unknown),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _field(
                              switch (_basis) {
                                NutritionBasis.portion =>
                                  S.of(context).nutritionPortionSizeLabel,
                                NutritionBasis.package =>
                                  S.of(context).nutritionPackageSizeLabel,
                                _ => S.of(context).nutritionServingSizeLabel,
                              },
                              _size,
                              id: 'serving-size',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Semantics(
                              identifier: 'nutrition-serving-unit',
                              child: _labeledInput(
                                S.of(context).nutritionServingUnitLabel,
                                DropdownButtonFormField<String>(
                                  key: ValueKey('unit-$_unit'),
                                  initialValue: _unit,
                                  decoration: const InputDecoration(),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'g',
                                      child: Text('g'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'ml',
                                      child: Text('ml'),
                                    ),
                                  ],
                                  onChanged: (unit) =>
                                      setState(() => _unit = unit),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      for (final item in _values.entries)
                        _field(
                          _fieldLabel(item.key),
                          item.value,
                          numeric: true,
                          id: item.key,
                        ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_message != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        _message!,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  if (_entries.isNotEmpty && widget.applyAll == null)
                    Semantics(
                      identifier: 'nutrition-apply-form',
                      child: FilledButton(
                        onPressed: () {
                          if (_commit()) Navigator.pop(context, _current);
                        },
                        child: Text(S.of(context).nutritionApplyAction),
                      ),
                    ),
                  if (_entries.isNotEmpty && widget.applyAll != null)
                    Semantics(
                      identifier: 'nutrition-add-all-to-meal',
                      child: FilledButton(
                        onPressed: _busy ? null : _applyBatch,
                        child: Text(S.of(context).nutritionAddAllToMealAction),
                      ),
                    ),
                  if (_entries.isNotEmpty && widget.saveAll != null)
                    Semantics(
                      identifier: 'nutrition-save-all',
                      child: OutlinedButton(
                        onPressed: _busy ? null : _saveBatch,
                        child: Text(S.of(context).nutritionSaveAllAction),
                      ),
                    ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(S.of(context).bulkAddWaitCancelLabel),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fieldLabel(String field) {
    final s = S.of(context);
    return switch (field) {
      'name' => s.mealNameLabel,
      'brand' => s.mealBrandsLabel,
      'kcal' => '${s.mealEnergyLabel} (kcal)',
      'kj' => '${s.mealEnergyLabel} (kJ)',
      'protein' => s.mealProteinLabel,
      'carbs' => s.mealCarbsLabel,
      'fat' => s.mealFatLabel,
      'saturatedFat' => s.saturatedFatLabel,
      'sugars' => s.sugarLabel,
      'fiber' => s.fiberLabel,
      'salt' => s.nutritionSaltLabel,
      'sodium' => '${s.sodiumLabel} (mg)',
      'calcium' => '${s.calciumLabel} (mg)',
      'iron' => '${s.ironLabel} (mg)',
      'potassium' => '${s.potassiumLabel} (mg)',
      'magnesium' => '${s.magnesiumLabel} (mg)',
      'vitaminD' => '${s.vitaminDLabel} (µg)',
      'vitaminB12' => '${s.vitaminB12Label} (µg)',
      'servingSize' => s.nutritionServingSizeLabel,
      'servingUnit' => s.nutritionServingUnitLabel,
      _ => field,
    };
  }

  Widget _labeledInput(String label, Widget field) => Padding(
    padding: const EdgeInsets.only(top: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 6),
          child: Text(label, style: Theme.of(context).textTheme.labelMedium),
        ),
        field,
      ],
    ),
  );

  Widget _field(
    String label,
    TextEditingController controller, {
    bool numeric = false,
    String? id,
  }) => Semantics(
    identifier: 'nutrition-${id ?? label}',
    child: _labeledInput(
      label,
      TextField(
        controller: controller,
        keyboardType: numeric
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        decoration: const InputDecoration(),
      ),
    ),
  );
}
