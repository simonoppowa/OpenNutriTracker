import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/diary/presentation/widgets/daily_nutrient_panel.dart';
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
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadVisibility();
  }

  Future<void> _loadVisibility() async {
    final config = await locator<GetConfigUsecase>().getConfig();
    if (!mounted) return;
    setState(() {
      _visibility = Map<String, bool>.from(config.nutrientPanelVisibility);
      _loading = false;
    });
  }

  Future<void> _toggle(String key, bool visible) async {
    setState(() => _visibility[key] = visible);
    await locator<AddConfigUsecase>()
        .setConfigNutrientPanelVisibility(_visibility);
  }

  String _labelFor(BuildContext context, String key) {
    final s = S.of(context);
    switch (key) {
      case NutrientPanelKeys.fiber:
        return s.fiberLabel;
      case NutrientPanelKeys.sodium:
        return s.sodiumLabel;
      case NutrientPanelKeys.saturatedFat:
        return s.saturatedFatLabel;
      case NutrientPanelKeys.sugar:
        return s.sugarLabel;
      case NutrientPanelKeys.calcium:
        return s.calciumLabel;
      case NutrientPanelKeys.iron:
        return s.ironLabel;
      case NutrientPanelKeys.potassium:
        return s.potassiumLabel;
      case NutrientPanelKeys.vitaminD:
        return s.vitaminDLabel;
      case NutrientPanelKeys.vitaminB12:
        return s.vitaminB12Label;
      case NutrientPanelKeys.magnesium:
        return s.magnesiumLabel;
      default:
        return key;
    }
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
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Text(
                    s.settingsNutrientsHelp,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                for (final key in NutrientPanelKeys.all)
                  CheckboxListTile(
                    title: Text(_labelFor(context, key)),
                    value: _visibility[key] ?? true,
                    onChanged: (value) => _toggle(key, value ?? true),
                  ),
              ],
            ),
    );
  }
}
