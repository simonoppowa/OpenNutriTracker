import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/off_const.dart';
import 'package:opennutritracker/features/add_meal/data/dto/sp/sp_const.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:url_launcher/url_launcher.dart';

/// Settings → Food databases: lets the user pick which food databases the
/// search screens draw from. State is persisted on
/// [ConfigEntity.foodSourceToggles]; a source not present in the map
/// defaults to enabled, so users who never visit this screen search every
/// database. Open Food Facts powers the product and barcode search and is
/// shown as a fixed, always-on entry.
class FoodSourcesScreen extends StatefulWidget {
  const FoodSourcesScreen({super.key});

  @override
  State<FoodSourcesScreen> createState() => _FoodSourcesScreenState();
}

class _FoodSourcesScreenState extends State<FoodSourcesScreen> {
  Map<String, bool> _toggles = <String, bool>{};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadToggles();
  }

  Future<void> _loadToggles() async {
    final config = await locator<GetConfigUsecase>().getConfig();
    if (!mounted) return;
    setState(() {
      _toggles = Map<String, bool>.from(config.foodSourceToggles);
      _loading = false;
    });
  }

  Future<void> _toggle(String sourceCode, bool enabled) async {
    setState(() => _toggles[sourceCode] = enabled);
    await locator<AddConfigUsecase>().setConfigFoodSourceToggles(_toggles);
  }

  /// Opens the database's public website in the in-app browser (Custom
  /// Tabs / SFSafariViewController) so the user stays inside the app.
  Future<void> _openSourceInfo(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.inAppBrowserView);
  }

  Widget _infoButton(String url) => IconButton(
        icon: const Icon(Icons.info_outline_rounded),
        onPressed: () => _openSourceInfo(url),
      );

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.settingsFoodSourcesLabel)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Text(
                    s.foodSourcesHelpText,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                SwitchListTile(
                  secondary: _infoButton(OFFConst.offWebsiteUrl),
                  title: const Text(OFFConst.offSourceName),
                  subtitle: Text(s.foodSourcesAlwaysEnabledLabel),
                  value: true,
                  onChanged: null,
                ),
                for (final sourceCode in SPConst.settingsSelectableFoodSources)
                  SwitchListTile(
                    secondary: _infoButton(
                      SPConst.foodSourceWebsites[sourceCode]!,
                    ),
                    title: Text(
                      SPConst.foodSourceDisplayNames[sourceCode] ?? sourceCode,
                    ),
                    value: _toggles[sourceCode] ?? true,
                    onChanged: (value) => _toggle(sourceCode, value),
                  ),
              ],
            ),
    );
  }
}
