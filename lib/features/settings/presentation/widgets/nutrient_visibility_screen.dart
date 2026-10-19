import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/diary/presentation/widgets/nutrient_panel_rows.dart';
import 'package:opennutritracker/features/settings/domain/nutrient_reference_setting.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// A small sub-screen inside Settings → Nutrients that lets the user pick
/// which nutrients should appear on the daily nutrient panel. State is
/// persisted on [ConfigEntity.nutrientPanelVisibility]; any nutrient not
/// present in the map defaults to visible (so users who never visit this
/// screen see every nutrient, which matches the panel's pre-toggle
/// behaviour).
class NutrientVisibilityScreen extends StatefulWidget {
  const NutrientVisibilityScreen({super.key});

  @override
  State<NutrientVisibilityScreen> createState() =>
      _NutrientVisibilityScreenState();
}

class _NutrientVisibilityScreenState extends State<NutrientVisibilityScreen> {
  Map<String, bool> _visibility = <String, bool>{};
  var _standard = NutrientReferenceSetting.defaultStandard;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadVisibility();
  }

  Future<void> _loadVisibility() async {
    final config = await locator<GetConfigUsecase>().getConfig();
    final standard = await locator<NutrientReferenceSetting>().standard();
    if (!mounted) return;
    setState(() {
      _visibility = Map<String, bool>.from(config.nutrientPanelVisibility);
      _standard = standard;
      _loading = false;
    });
  }

  Future<void> _setStandard(NutrientReferenceStandard standard) async {
    setState(() => _standard = standard);
    await locator<NutrientReferenceSetting>().save(standard);
  }

  Future<void> _toggle(String key, bool visible) async {
    setState(() => _visibility[key] = visible);
    await locator<AddConfigUsecase>()
        .setConfigNutrientPanelVisibility(_visibility);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.settingsNutrientsLabel)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                ListTile(
                  title: Text(s.nutrientReferenceStandardLabel),
                  subtitle: Text(s.nutrientReferenceStandardHelp),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Semantics(
                    identifier: 'nutrient-reference-standard',
                    child: SegmentedButton<NutrientReferenceStandard>(
                      segments: [
                        ButtonSegment(
                          value: NutrientReferenceStandard.iom,
                          label: Text(s.nutrientReferenceIomLabel),
                        ),
                        ButtonSegment(
                          value: NutrientReferenceStandard.dge,
                          label: Text(s.nutrientReferenceDgeLabel),
                        ),
                      ],
                      selected: {_standard},
                      onSelectionChanged: (selection) =>
                          _setStandard(selection.first),
                    ),
                  ),
                ),
                const Divider(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Text(
                    s.settingsNutrientsHelp,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                for (final group in NutrientPanelGroup.values) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Text(
                      group.label(s),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  for (final row in NutrientPanelRow.all)
                    if (row.group == group)
                      CheckboxListTile(
                        title: Text(row.label(s)),
                        value: _visibility[row.key] ?? true,
                        onChanged: (value) => _toggle(row.key, value ?? true),
                      ),
                ],
              ],
            ),
    );
  }
}
