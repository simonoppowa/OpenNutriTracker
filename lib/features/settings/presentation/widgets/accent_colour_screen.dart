import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/theme_mode_provider.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// Sixteen hand-picked accent colours that span the wheel and read well as
/// circular swatches in a 4×4 grid. Each one drives `ColorScheme.fromSeed`
/// to produce a coherent Material 3 palette.
const List<Color> _presetColors = <Color>[
  Color(0xFFE53935), // red
  Color(0xFFFF6F61), // coral
  Color(0xFFFB8C00), // orange
  Color(0xFFFFB300), // amber
  Color(0xFFFDD835), // yellow
  Color(0xFFC0CA33), // chartreuse
  Color(0xFF7CB342), // lime
  Color(0xFF43A047), // green
  Color(0xFF00897B), // teal
  Color(0xFF00ACC1), // cyan
  Color(0xFF039BE5), // sky
  Color(0xFF1E88E5), // blue
  Color(0xFF3949AB), // indigo
  Color(0xFF8E24AA), // violet
  Color(0xFFD81B60), // magenta
  Color(0xFFEC407A), // pink
];

class AccentColourScreen extends StatefulWidget {
  const AccentColourScreen({super.key});

  @override
  State<AccentColourScreen> createState() => _AccentColourScreenState();
}

class _AccentColourScreenState extends State<AccentColourScreen> {
  late final SettingsBloc _settingsBloc;

  @override
  void initState() {
    _settingsBloc = locator<SettingsBloc>();
    _settingsBloc.add(LoadSettingsEvent());
    super.initState();
  }

  void _selectMaterialYou() {
    _settingsBloc.setUseMaterialYou(true);
    _settingsBloc.setAccentColor(null);
    final theme = Provider.of<ThemeModeProvider>(context, listen: false);
    theme.updateUseMaterialYou(true);
    theme.updateAccentColor(null);
    _settingsBloc.add(LoadSettingsEvent());
  }

  void _selectColor(Color color) {
    final argb = color.toARGB32();
    _settingsBloc.setAccentColor(argb);
    // A custom colour should win over Material You; otherwise the picked
    // shade silently does nothing on Android 12+.
    _settingsBloc.setUseMaterialYou(false);
    final theme = Provider.of<ThemeModeProvider>(context, listen: false);
    theme.updateAccentColor(argb);
    theme.updateUseMaterialYou(false);
    _settingsBloc.add(LoadSettingsEvent());
  }

  @override
  Widget build(BuildContext context) {
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).settingsAccentColourTitle)),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        bloc: _settingsBloc,
        builder: (context, state) {
          if (state is! SettingsLoadedState) {
            return const Center(child: CircularProgressIndicator());
          }
          final materialYouActive = isAndroid && state.useMaterialYou;
          final currentArgb = state.accentColor;
          return ListView(
            children: [
              if (isAndroid)
                Semantics(
                  identifier: 'accent-option-material-you',
                  child: ListTile(
                    leading: const Icon(Icons.auto_awesome_outlined),
                    title: Text(S.of(context).settingsMaterialYouTitle),
                    subtitle:
                        Text(S.of(context).settingsMaterialYouSubtitle),
                    trailing: materialYouActive
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const Icon(Icons.circle_outlined),
                    onTap: _selectMaterialYou,
                  ),
                ),
              if (isAndroid) const Divider(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  S.of(context).settingsAccentPresetsHeader,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _presetColors.length,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 1,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemBuilder: (context, index) {
                    final color = _presetColors[index];
                    final selected =
                        !materialYouActive && currentArgb == color.toARGB32();
                    return Semantics(
                      identifier:
                          'accent-preset-${index.toString().padLeft(2, '0')}',
                      child: InkWell(
                        onTap: () => _selectColor(color),
                        customBorder: const CircleBorder(),
                        child: Container(
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: selected
                                ? Border.all(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface,
                                    width: 3,
                                  )
                                : null,
                          ),
                          child: selected
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              Semantics(
                identifier: 'accent-custom-colour',
                child: ListTile(
                  leading: const Icon(Icons.colorize_outlined),
                  title: Text(S.of(context).settingsAccentCustomColour),
                  subtitle: Text(S.of(context).settingsAccentCustomSubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openCustomColourDialog(currentArgb),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openCustomColourDialog(int? initialArgb) async {
    final picked = await showDialog<Color?>(
      context: context,
      builder: (_) => _CustomColourDialog(
        initialColor: initialArgb != null
            ? Color(initialArgb)
            : _presetColors.first,
      ),
    );
    if (picked != null) {
      _selectColor(picked);
    }
  }
}

class _CustomColourDialog extends StatefulWidget {
  final Color initialColor;

  const _CustomColourDialog({required this.initialColor});

  @override
  State<_CustomColourDialog> createState() => _CustomColourDialogState();
}

class _CustomColourDialogState extends State<_CustomColourDialog> {
  late double _hue;
  late TextEditingController _hexController;
  String? _hexError;

  @override
  void initState() {
    final hsl = HSLColor.fromColor(widget.initialColor);
    _hue = hsl.hue;
    _hexController = TextEditingController(text: _toHex(widget.initialColor));
    super.initState();
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  String _toHex(Color color) {
    // Render as RRGGBB (no alpha) — that's what people type and recognise.
    final argb = color.toARGB32();
    final rgb = argb & 0xFFFFFF;
    return rgb.toRadixString(16).padLeft(6, '0').toUpperCase();
  }

  Color get _currentColor =>
      HSLColor.fromAHSL(1, _hue, 0.7, 0.5).toColor();

  void _onHueChanged(double value) {
    setState(() {
      _hue = value;
      _hexError = null;
      _hexController.text = _toHex(_currentColor);
    });
  }

  void _onHexSubmitted(String raw) {
    final cleaned = raw.trim().replaceAll('#', '').toUpperCase();
    if (!RegExp(r'^[0-9A-F]{6}$').hasMatch(cleaned)) {
      setState(() => _hexError = S.of(context).settingsAccentHexInvalid);
      return;
    }
    final value = int.parse(cleaned, radix: 16) | 0xFF000000;
    final color = Color(value);
    setState(() {
      _hue = HSLColor.fromColor(color).hue;
      _hexError = null;
      _hexController.text = cleaned;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show whatever the hex field would resolve to: typed hex (if valid)
    // wins over the slider, so the preview always matches what would be
    // saved on confirm.
    final previewColor = _previewColor();
    return AlertDialog(
      title: Text(S.of(context).settingsAccentCustomColour),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: previewColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 16),
          Semantics(
            identifier: 'accent-custom-slider',
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 16,
                thumbColor: previewColor,
                overlayColor: previewColor.withValues(alpha: 0.2),
                trackShape: const _HueGradientTrackShape(_hueTrackColors),
              ),
              child: Slider(
                value: _hue,
                min: 0,
                max: 360,
                onChanged: _onHueChanged,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Semantics(
            identifier: 'accent-custom-hex-field',
            child: TextField(
              controller: _hexController,
              maxLength: 7,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[#0-9A-Fa-f]')),
              ],
              decoration: InputDecoration(
                prefixText: '#',
                labelText: S.of(context).settingsAccentHexLabel,
                hintText: 'FF5733',
                errorText: _hexError,
                counterText: '',
              ),
              onSubmitted: _onHexSubmitted,
              onChanged: (_) => setState(() => _hexError = null),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(S.of(context).dialogCancelLabel),
        ),
        FilledButton(
          onPressed: _onConfirm,
          child: Text(S.of(context).dialogOKLabel),
        ),
      ],
    );
  }

  Color _previewColor() {
    final raw = _hexController.text.trim().replaceAll('#', '').toUpperCase();
    if (RegExp(r'^[0-9A-F]{6}$').hasMatch(raw)) {
      return Color(int.parse(raw, radix: 16) | 0xFF000000);
    }
    return HSLColor.fromAHSL(1, _hue, 0.7, 0.5).toColor();
  }

  void _onConfirm() {
    final raw = _hexController.text.trim().replaceAll('#', '').toUpperCase();
    if (raw.isNotEmpty && !RegExp(r'^[0-9A-F]{6}$').hasMatch(raw)) {
      setState(() => _hexError = S.of(context).settingsAccentHexInvalid);
      return;
    }
    final color = _previewColor();
    Navigator.of(context).pop(color);
  }
}

const List<Color> _hueTrackColors = <Color>[
  Color(0xFFFF0000),
  Color(0xFFFFFF00),
  Color(0xFF00FF00),
  Color(0xFF00FFFF),
  Color(0xFF0000FF),
  Color(0xFFFF00FF),
  Color(0xFFFF0000),
];

class _HueGradientTrackShape extends RoundedRectSliderTrackShape {
  final List<Color> colors;
  const _HueGradientTrackShape(this.colors);

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 0,
  }) {
    final trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );
    final paint = Paint()
      ..shader = LinearGradient(colors: colors).createShader(trackRect);
    final rrect = RRect.fromRectAndRadius(
      trackRect,
      Radius.circular(trackRect.height / 2),
    );
    context.canvas.drawRRect(rrect, paint);
  }
}
