import 'package:flutter/material.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/off_contribution/data/off_contribution_settings.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// Settings → Contribute to Open Food Facts (#81): the switch, the account
/// and the server the uploads go to.
class OffContributionScreen extends StatefulWidget {
  final OffContributionSettingsStore? store;

  const OffContributionScreen({super.key, this.store});

  @override
  State<OffContributionScreen> createState() => _OffContributionScreenState();
}

class _OffContributionScreenState extends State<OffContributionScreen> {
  late final OffContributionSettingsStore _store =
      widget.store ?? locator<OffContributionSettingsStore>();
  final _userId = TextEditingController();
  final _password = TextEditingController();
  OffContributionSettings? _settings;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _userId.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final settings = await _store.load();
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _userId.text = settings.userId;
      _password.text = settings.password;
    });
  }

  /// Applies [change] to the current settings, takes over the text fields
  /// and stores the result.
  Future<void> _save([
    OffContributionSettings Function(OffContributionSettings current)? change,
  ]) async {
    final current = _settings!;
    final updated = (change?.call(current) ?? current).copyWith(
      userId: _userId.text.trim(),
      password: _password.text,
    );
    setState(() => _settings = updated);
    await _store.save(updated);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final settings = _settings;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.offContributionTitle)),
      body: settings == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(Dimens.spacing16),
              children: [
                Text(
                  l10n.offContributionInfo,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: Dimens.spacing16),
                Semantics(
                  identifier: 'off-contribution-enabled',
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.offContributionEnable),
                    value: settings.enabled,
                    onChanged: (value) =>
                        _save((current) => current.copyWith(enabled: value)),
                  ),
                ),
                const SizedBox(height: Dimens.spacing8),
                Semantics(
                  identifier: 'off-contribution-user',
                  child: TextField(
                    controller: _userId,
                    autocorrect: false,
                    decoration: InputDecoration(
                      labelText: l10n.offContributionUserId,
                      border: const OutlineInputBorder(
                        borderRadius: Dimens.borderRadiusM,
                      ),
                    ),
                    onChanged: (_) => _save(),
                  ),
                ),
                const SizedBox(height: Dimens.spacing16),
                Semantics(
                  identifier: 'off-contribution-password',
                  child: TextField(
                    controller: _password,
                    obscureText: true,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: InputDecoration(
                      labelText: l10n.offContributionPassword,
                      border: const OutlineInputBorder(
                        borderRadius: Dimens.borderRadiusM,
                      ),
                    ),
                    onChanged: (_) => _save(),
                  ),
                ),
                const SizedBox(height: Dimens.spacing8),
                Semantics(
                  identifier: 'off-contribution-test-server',
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.offContributionTestServer),
                    subtitle: Text(l10n.offContributionTestServerHelp),
                    value: settings.useTestServer,
                    onChanged: (value) => _save(
                      (current) => current.copyWith(useTestServer: value),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
