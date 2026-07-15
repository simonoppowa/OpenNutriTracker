import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:opennutritracker/core/domain/entity/calories_profile_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_gender_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/calories_profile_info_dialog.dart';
import 'package:opennutritracker/core/utils/calc/unit_calc.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

/// Daily kcal/kJ adjustment slider, paired with the TDEE reference and
/// (for non-binary users) the calorie-profile picker that decides which
/// reference equation is used. Everything in this dialog is about how
/// the daily kcal goal is computed — macro distribution, per-meal split,
/// and nutrient goals each live behind their own Settings entries.
class KcalAdjustmentDialog extends StatefulWidget {
  final SettingsBloc settingsBloc;
  final ProfileBloc profileBloc;
  final HomeBloc homeBloc;

  const KcalAdjustmentDialog({
    super.key,
    required this.settingsBloc,
    required this.profileBloc,
    required this.homeBloc,
  });

  @override
  State<KcalAdjustmentDialog> createState() => _KcalAdjustmentDialogState();
}

class _KcalAdjustmentDialogState extends State<KcalAdjustmentDialog> {
  static const double _minKcalAdjustment = -1000;
  static const double _maxKcalAdjustment = 1000;
  static const int _kcalDivisions = 200;

  double _kcalAdjustment = 0;
  UserEntity? _user;
  bool _loaded = false;

  late final TextEditingController _kcalController;

  @override
  void initState() {
    super.initState();
    _kcalController = TextEditingController(text: '0');
    _load();
  }

  @override
  void dispose() {
    _kcalController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final kcal = await widget.settingsBloc.getKcalAdjustment();
    final user = await widget.profileBloc.getUser();
    if (!mounted) return;
    final usesKj =
        Provider.of<EnergyUnitProvider>(context, listen: false).usesKilojoules;
    final display = usesKj ? UnitCalc.kcalToKj(kcal) : kcal;
    setState(() {
      _kcalAdjustment = kcal;
      _user = user;
      _kcalController.text = display.round().toString();
      _loaded = true;
    });
  }

  void _applyKcalInput() {
    // The text field always reads in whichever unit the user is
    // seeing; convert back to kcal once for storage so the persisted
    // value stays consistent across unit toggles.
    final usesKj =
        Provider.of<EnergyUnitProvider>(context, listen: false).usesKilojoules;
    final parsed = int.tryParse(_kcalController.text);
    if (parsed == null) {
      // Bad input — snap the field back to the last good value.
      final display =
          usesKj ? UnitCalc.kcalToKj(_kcalAdjustment) : _kcalAdjustment;
      _kcalController.text = display.round().toString();
      return;
    }
    final asKcal =
        usesKj ? UnitCalc.kjToKcal(parsed.toDouble()) : parsed.toDouble();
    final clamped = asKcal.clamp(_minKcalAdjustment, _maxKcalAdjustment);
    final clampedDisplay = usesKj ? UnitCalc.kcalToKj(clamped) : clamped;
    setState(() => _kcalAdjustment = clamped);
    _kcalController.text = clampedDisplay.round().toString();
  }

  Future<void> _openCaloriesProfileDialog() async {
    final user = _user;
    if (user == null) return;
    final selected = await showDialog<CaloriesProfileEntity>(
      context: context,
      builder: (ctx) => CaloriesProfileInfoDialog(
        initialProfile:
            user.caloriesProfile ?? CaloriesProfileEntity.averaged,
      ),
    );
    if (selected == null) return;
    user.caloriesProfile = selected;
    await widget.profileBloc.updateUser(user);
    if (!mounted) return;
    setState(() => _user = user);
  }

  Future<void> _save() async {
    await widget.settingsBloc.setKcalAdjustment(
      _kcalAdjustment.toInt().toDouble(),
    );
    widget.settingsBloc.add(LoadSettingsEvent());
    widget.homeBloc.add(const LoadItemsEvent());
    // Recompute today's stored kcal goal so the diary card reflects
    // the new adjustment immediately instead of waiting for tomorrow.
    await widget.settingsBloc.updateTrackedDay(DateTime.now());
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              s.settingsKcalAdjustmentLabel,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: _loaded
                ? () {
                    setState(() => _kcalAdjustment = 0);
                    _kcalController.text = '0';
                  }
                : null,
            child: Text(s.buttonResetLabel),
          ),
        ],
      ),
      content: !_loaded
          ? const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // The TDEE equation is fixed (IOM 2005 is what every
                  // build currently ships) but kept visible here as a
                  // read-only reference so the source of the kcal target
                  // doesn't feel hidden.
                  DropdownButtonFormField(
                    isExpanded: true,
                    itemHeight: null,
                    decoration: InputDecoration(
                      enabled: false,
                      filled: false,
                      labelText: s.calculationsTDEELabel,
                    ),
                    items: [
                      DropdownMenuItem(
                        child: Text(
                          '${s.calculationsTDEEIOM2006Label} ${s.calculationsRecommendedLabel}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    onChanged: null,
                  ),
                  // The calorie reference picker only shows for non-binary
                  // users since the male/female equations are unambiguous
                  // for binary ones — the picker has nothing to offer them.
                  if (_user?.gender == UserGenderEntity.nonBinary) ...[
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.tune_outlined),
                      title: Text(s.caloriesProfileInfoTitle),
                      subtitle: Text(
                        (_user?.caloriesProfile ??
                                CaloriesProfileEntity.averaged)
                            .getName(context),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _openCaloriesProfileDialog,
                    ),
                  ],
                  const SizedBox(height: 24),
                  Builder(builder: (context) {
                    final usesKj =
                        context.watch<EnergyUnitProvider>().usesKilojoules;
                    final unitLabel =
                        usesKj ? s.kjLabel : s.kcalLabel;
                    final headingLabel = usesKj
                        ? s.dailyKjAdjustmentLabel
                        : s.dailyKcalAdjustmentLabel;
                    final display = usesKj
                        ? UnitCalc.kcalToKj(_kcalAdjustment)
                        : _kcalAdjustment;
                    final displayMin = usesKj
                        ? UnitCalc.kcalToKj(_minKcalAdjustment)
                        : _minKcalAdjustment;
                    final displayMax = usesKj
                        ? UnitCalc.kcalToKj(_maxKcalAdjustment)
                        : _maxKcalAdjustment;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                headingLabel,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            SizedBox(
                              // Scale with the user's text setting so the value
                              // and unit suffix stay readable at large fonts.
                              width:
                                  MediaQuery.textScalerOf(context).scale(128),
                              child: Semantics(
                                identifier: 'kcal-adjustment-input',
                                child: TextField(
                                  controller: _kcalController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    signed: true,
                                    decimal: false,
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'^-?\d*'),
                                    ),
                                  ],
                                  textAlign: TextAlign.right,
                                  decoration: InputDecoration(
                                    suffixText: unitLabel,
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 12,
                                    ),
                                  ),
                                  onSubmitted: (_) => _applyKcalInput(),
                                  onEditingComplete: _applyKcalInput,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Semantics(
                          identifier: 'kcal-adjustment-slider',
                          child: Slider(
                            min: displayMin,
                            max: displayMax,
                            divisions: _kcalDivisions,
                            value: display.clamp(displayMin, displayMax),
                            label: '${display.round()} $unitLabel',
                            onChanged: (value) {
                              final asKcal = usesKj
                                  ? UnitCalc.kjToKcal(value)
                                  : value;
                              setState(() => _kcalAdjustment = asKcal);
                              _kcalController.text = value.round().toString();
                            },
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(s.dialogCancelLabel),
        ),
        Semantics(
          identifier: 'kcal-adjustment-save',
          child: TextButton(
            onPressed: _loaded ? _save : null,
            child: Text(s.dialogOKLabel),
          ),
        ),
      ],
    );
  }
}
