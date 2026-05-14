import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:opennutritracker/core/domain/entity/custom_activity_template_entity.dart';
import 'package:opennutritracker/core/domain/entity/physical_activity_entity.dart';
import 'package:opennutritracker/features/activity_detail/presentation/bloc/activity_detail_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';

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
                      return ListTile(
                        leading: const Icon(Icons.bookmark_outline),
                        title: Text(template.name),
                        subtitle: Text(
                          '${template.typicalKcal.toInt()} '
                          '${S.of(listContext).kcalLabel}',
                        ),
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
      setState(() {
        _nameController.text = picked.name;
        widget.quantityTextController.text =
            picked.typicalKcal.toInt().toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCustom = widget.activityEntity.isCustom;
    return BottomSheet(
      elevation: 10,
      onClosing: () {},
      enableDrag: false,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outline,
              width: 0.5,
            ),
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
          ),
          // SafeArea(top: false) — keeps the sticky bottom Add button above
          // the gesture-nav strip on devices that don't reserve insets
          // (#156). top:false because the curved top edge handles that side.
          child: SafeArea(
            top: false,
            child: Wrap(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 32.0, 16.0, 8.0),
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
                                  decoration: InputDecoration(
                                    border: const OutlineInputBorder(),
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
                            const SizedBox(width: 8.0),
                            Semantics(
                              identifier: 'activity-detail-pick-template',
                              child: IconButton(
                                tooltip: S
                                    .of(context)
                                    .customActivityPickFromTemplate,
                                icon: const Icon(Icons.bookmark_outline),
                                onPressed: _openTemplatePicker,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8.0),
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
                                decoration: InputDecoration(
                                  border: const OutlineInputBorder(),
                                  labelText: isCustom
                                      ? S.of(context).customActivityKcalLabel
                                      : S.of(context).quantityLabel,
                                  hintText: isCustom
                                      ? S.of(context).customActivityKcalHint
                                      : null,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16.0),
                          Expanded(
                            child: DropdownButtonFormField(
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                labelText: S.of(context).unitLabel,
                              ),
                              items: <DropdownMenuItem<String>>[
                                DropdownMenuItem(
                                  child: Text(isCustom ? 'kcal' : 'min'),
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
                            ).copyWith(
                              elevation: ButtonStyleButton.allOrNull(0.0),
                            ),
                            icon: const Icon(Icons.add_outlined),
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
