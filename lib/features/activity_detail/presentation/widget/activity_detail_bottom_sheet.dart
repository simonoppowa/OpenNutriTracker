import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:opennutritracker/core/domain/entity/custom_activity_template_entity.dart';
import 'package:opennutritracker/core/domain/entity/physical_activity_entity.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/core/utils/calc/unit_calc.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/features/activity_detail/presentation/bloc/activity_detail_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

/// Bottom sheet for the Activity Detail screen.
///
/// For compendium activities this is the quantity-in-minutes field plus
/// an Add button — unchanged from #70. For the Custom activity it adds
/// an optional name field, a "Save as template" checkbox, and a "Pick
/// from saved" affordance (#70 follow-up) so people who do the same
/// workout repeatedly can avoid retyping the kcal each time.
class ActivityDetailBottomSheet extends StatefulWidget {
  final Function(BuildContext, {String? templateName, bool saveAsTemplate})
      onAddButtonPressed;
  final PhysicalActivityEntity activityEntity;
  final TextEditingController quantityTextController;
  final ActivityDetailBloc activityDetailBloc;

  const ActivityDetailBottomSheet({
    super.key,
    required this.onAddButtonPressed,
    required this.quantityTextController,
    required this.activityEntity,
    required this.activityDetailBloc,
  });

  @override
  State<ActivityDetailBottomSheet> createState() =>
      _ActivityDetailBottomSheetState();
}

class _ActivityDetailBottomSheetState extends State<ActivityDetailBottomSheet> {
  final TextEditingController _nameController = TextEditingController();
  bool _saveAsTemplate = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _openTemplatePicker() async {
    final templates =
        await widget.activityDetailBloc.loadCustomActivityTemplates();
    if (!mounted) return;

    final picked = await showModalBottomSheet<CustomActivityTemplateEntity>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: templates.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      S.of(sheetContext).customActivityTemplatesEmpty,
                      style: Theme.of(sheetContext).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: templates.length,
                    itemBuilder: (listContext, index) {
                      final template = templates[index];
                      final tileUsesKj = Provider.of<EnergyUnitProvider>(
                        listContext,
                        listen: false,
                      ).usesKilojoules;
                      final tileValue = tileUsesKj
                          ? UnitCalc.kcalToKj(template.typicalKcal)
                          : template.typicalKcal;
                      final tileUnit = tileUsesKj
                          ? S.of(listContext).kjLabel
                          : S.of(listContext).kcalLabel;
                      return ListTile(
                        leading: const Icon(Icons.bookmark_rounded),
                        title: Text(template.name),
                        subtitle: Text('${tileValue.toInt()} $tileUnit'),
                        onTap: () =>
                            Navigator.of(listContext).pop(template),
                      );
                    },
                  ),
          ),
        );
      },
    );

    if (picked != null && mounted) {
      final usesKj =
          Provider.of<EnergyUnitProvider>(context, listen: false)
              .usesKilojoules;
      final displayValue =
          usesKj ? UnitCalc.kcalToKj(picked.typicalKcal) : picked.typicalKcal;
      setState(() {
        _nameController.text = picked.name;
        widget.quantityTextController.text = displayValue.toInt().toString();
      });
    }
  }

  InputDecoration _fieldDecoration(
    BuildContext context, {
    String? labelText,
    String? hintText,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = isDark ? AppPalette.dark : AppPalette.light;
    final accent = Theme.of(context).colorScheme.primary;
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      filled: true,
      fillColor: palette.surfaceMuted,
      border: OutlineInputBorder(
        borderRadius: Dimens.borderRadiusM,
        borderSide: BorderSide(color: palette.border, width: Dimens.hairline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: Dimens.borderRadiusM,
        borderSide: BorderSide(color: palette.border, width: Dimens.hairline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: Dimens.borderRadiusM,
        borderSide: BorderSide(color: accent, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = isDark ? AppPalette.dark : AppPalette.light;
    final isCustom = widget.activityEntity.isCustom;
    // For Custom activities the input field follows the user's Energy
    // unit setting — typing happens in the same unit the rest of the
    // app is showing, with conversion back to the stored kcal handled
    // at save time. For compendium activities the field stays in
    // minutes regardless of the energy unit.
    final usesKj = context.watch<EnergyUnitProvider>().usesKilojoules;
    final customUnitSuffix =
        usesKj ? S.of(context).kjLabel : S.of(context).kcalLabel;
    return BottomSheet(
      elevation: 0,
      backgroundColor: Colors.transparent,
      onClosing: () {},
      enableDrag: false,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: palette.border, width: Dimens.hairline),
            color: palette.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(Dimens.radiusXL),
              topRight: Radius.circular(Dimens.radiusXL),
            ),
            boxShadow: [
              BoxShadow(color: palette.shadow, blurRadius: 18, offset: const Offset(0, -6)),
            ],
          ),
          // SafeArea(top: false) — keeps the sticky bottom Add button above
          // the gesture-nav strip on devices that don't reserve insets
          // (#156). top:false because the curved top edge handles that side.
          child: SafeArea(
            top: false,
            child: Wrap(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Dimens.spacing16,
                    Dimens.spacing32,
                    Dimens.spacing16,
                    Dimens.spacing8,
                  ),
                  child: Column(
                    children: [
                      if (isCustom) ...[
                        Row(
                          children: [
                            Expanded(
                              child: Semantics(
                                identifier: 'activity-detail-template-name-input',
                                container: true,
                                child: TextFormField(
                                  controller: _nameController,
                                  decoration: _fieldDecoration(
                                    context,
                                    labelText: S
                                        .of(context)
                                        .customActivityNameFieldLabel,
                                    hintText: S
                                        .of(context)
                                        .customActivityNameFieldHint,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: Dimens.spacing8),
                            Semantics(
                              identifier: 'activity-detail-pick-template',
                              child: IconButton(
                                tooltip: S
                                    .of(context)
                                    .customActivityPickFromTemplate,
                                icon: const Icon(Icons.bookmark_rounded),
                                onPressed: _openTemplatePicker,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: Dimens.spacing8),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: Semantics(
                              identifier: 'activity-detail-quantity-input',
                              container: true,
                              child: TextFormField(
                                controller: widget.quantityTextController,
                                keyboardType: TextInputType.number,
                                inputFormatters: <TextInputFormatter>[
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9]+[,.]{0,1}[0-9]*'),
                                  ),
                                  TextInputFormatter.withFunction(
                                    (oldValue, newValue) => newValue.copyWith(
                                      text: newValue.text.replaceAll(',', '.'),
                                    ),
                                  ),
                                ],
                                decoration: _fieldDecoration(
                                  context,
                                  labelText: isCustom
                                      ? (usesKj
                                          ? S.of(context).mealEnergyLabel
                                          : S
                                              .of(context)
                                              .customActivityKcalLabel)
                                      : S.of(context).quantityLabel,
                                  hintText: isCustom
                                      ? S.of(context).customActivityKcalHint
                                      : null,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: Dimens.spacing16),
                          Expanded(
                            child: DropdownButtonFormField(
                              itemHeight: null,
                              decoration: _fieldDecoration(
                                context,
                                labelText: S.of(context).unitLabel,
                              ),
                              items: <DropdownMenuItem<String>>[
                                DropdownMenuItem(
                                  child: Text(
                                    isCustom ? customUnitSuffix : 'min',
                                  ),
                                ),
                              ],
                              onChanged: (Object? value) {},
                            ),
                          ),
                        ],
                      ),
                      if (isCustom)
                        // Off by default: people who only ever log one-off
                        // entries shouldn't accumulate template clutter.
                        Semantics(
                          identifier: 'activity-detail-save-as-template',
                          child: CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            value: _saveAsTemplate,
                            onChanged: (value) {
                              setState(() {
                                _saveAsTemplate = value ?? false;
                              });
                            },
                            title: Text(
                              S.of(context).customActivitySaveAsTemplate,
                            ),
                          ),
                        ),
                      SizedBox(
                        width: double.infinity, // Make button full width
                        child: Semantics(
                          identifier: 'activity-detail-add-button',
                          child: ElevatedButton.icon(
                            onPressed: () {
                              final trimmedName = _nameController.text.trim();
                              widget.onAddButtonPressed(
                                context,
                                templateName: trimmedName.isEmpty
                                    ? null
                                    : trimmedName,
                                saveAsTemplate: _saveAsTemplate,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              shape: Dimens.shapeM,
                              padding: const EdgeInsets.symmetric(
                                vertical: Dimens.spacing16,
                              ),
                            ).copyWith(
                              elevation: ButtonStyleButton.allOrNull(0.0),
                            ),
                            icon: const Icon(Icons.add_rounded),
                            label: Text(S.of(context).addLabel),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
