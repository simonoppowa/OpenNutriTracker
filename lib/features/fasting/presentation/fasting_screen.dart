import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/core/presentation/widgets/app_card.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/notification_service.dart';
import 'package:opennutritracker/features/fasting/presentation/bloc/fasting_bloc.dart';
import 'package:opennutritracker/features/fasting/presentation/widgets/fasting_warning_dialog.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// Preset fasting windows offered in the UI. Kept here rather than in the
/// bloc because they are purely a presentation concern — the data layer only
/// cares about target minutes, not which preset the minutes came from.
const List<int> _presetHours = [13, 16, 18, 20, 36];

class FastingScreen extends StatefulWidget {
  const FastingScreen({super.key});

  @override
  State<FastingScreen> createState() => _FastingScreenState();
}

class _FastingScreenState extends State<FastingScreen> {
  late FastingBloc _bloc;
  int _selectedHours = 16;
  int? _customHours;
  bool _warningHandled = false;

  @override
  void initState() {
    super.initState();
    _bloc = locator<FastingBloc>();
    _bloc.add(const FastingLoadRequested());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  Future<void> _handleWarning(BuildContext context) async {
    if (_warningHandled) return;
    _warningHandled = true;
    final navigator = Navigator.of(context);
    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const FastingWarningDialog(),
    );
    if (!mounted) return;
    if (accepted == true) {
      _bloc.add(const FastingWarningAcknowledged());
    } else {
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = isDark ? AppPalette.dark : AppPalette.light;
    return Scaffold(
      backgroundColor: palette.canvas,
      appBar: AppBar(
        backgroundColor: palette.canvas,
        title: Text(l10n.fastingTitle),
      ),
      body: BlocConsumer<FastingBloc, FastingState>(
        bloc: _bloc,
        listenWhen: (prev, curr) {
          // Schedule on enter-Active; cancel on enter-Idle (user ended the
          // fast). FastingCompleted intentionally not listened for here —
          // the OS-scheduled alarm is firing at exactly that moment.
          if (curr is FastingWarningRequired) return true;
          if (curr is FastingActive && prev is! FastingActive) return true;
          if (curr is FastingIdle && prev is! FastingIdle) return true;
          return false;
        },
        listener: (context, state) {
          if (state is FastingWarningRequired) {
            _handleWarning(context);
          }
          if (state is FastingActive) {
            _scheduleCompleteNotification(context, state);
          }
          if (state is FastingIdle) {
            _cancelCompleteNotification();
          }
        },
        builder: (context, state) {
          if (state is FastingInitial || state is FastingWarningRequired) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is FastingIdle) {
            return _buildIdle(context, l10n);
          }
          if (state is FastingActive) {
            return _buildActive(context, l10n, state);
          }
          if (state is FastingCompleted) {
            return _buildCompleted(context, l10n);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildIdle(BuildContext context, S l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = isDark ? AppPalette.dark : AppPalette.light;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(Dimens.spacing20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.fastingSubtitle,
            style: textTheme.bodyMedium?.copyWith(color: palette.textMuted),
          ),
          const SizedBox(height: Dimens.spacing24),
          AppCard(
            padding: const EdgeInsets.all(Dimens.spacing20),
            child: Wrap(
              spacing: Dimens.spacing8,
              runSpacing: Dimens.spacing8,
              children: [
                for (final h in _presetHours)
                  Semantics(
                    identifier: 'fasting-preset-${h}h',
                    child: ChoiceChip(
                      label: Text('${h}h'),
                      selected: _selectedHours == h && _customHours == null,
                      onSelected: (_) {
                        setState(() {
                          _selectedHours = h;
                          _customHours = null;
                        });
                      },
                    ),
                  ),
                Semantics(
                  identifier: 'fasting-preset-custom',
                  child: ChoiceChip(
                    label: Text(
                      _customHours == null
                          ? l10n.fastingPresetCustom
                          : '${_customHours}h',
                    ),
                    selected: _customHours != null,
                    onSelected: (_) => _pickCustomHours(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Dimens.spacing32),
          Center(
            child: Semantics(
              identifier: 'fasting-start',
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  shape: Dimens.shapeM,
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimens.spacing32,
                    vertical: Dimens.spacing16,
                  ),
                ),
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(l10n.fastingStart),
                onPressed: () {
                  final hours = _customHours ?? _selectedHours;
                  _bloc.add(FastingStartRequested(hours * 60));
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickCustomHours(BuildContext context) async {
    final controller = TextEditingController(
      text: (_customHours ?? _selectedHours).toString(),
    );
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: Dimens.shapeL,
          title: Text(S.of(ctx).fastingPresetCustom),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(suffixText: S.of(ctx).hoursLabel),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(S.of(ctx).dialogCancelLabel),
            ),
            Semantics(
              identifier: 'fasting-custom-confirm',
              child: TextButton(
                onPressed: () {
                  final v = int.tryParse(controller.text.trim());
                  if (v != null && v > 0 && v <= 96) {
                    Navigator.of(ctx).pop(v);
                  }
                },
                child: Text(S.of(ctx).dialogOKLabel),
              ),
            ),
          ],
        );
      },
    );
    if (result != null) {
      setState(() {
        _customHours = result;
      });
    }
  }

  Widget _buildActive(BuildContext context, S l10n, FastingActive state) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = isDark ? AppPalette.dark : AppPalette.light;
    final accent = Theme.of(context).colorScheme.primary;
    final elapsed = _formatDuration(state.elapsed);
    final remaining = _formatDuration(state.remaining);
    final progress = state.target.inSeconds == 0
        ? 0.0
        : (state.elapsed.inSeconds / state.target.inSeconds).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.all(Dimens.spacing24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: Dimens.spacing24),
          Center(
            child: SizedBox(
              width: 220,
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 12,
                      strokeCap: StrokeCap.round,
                      color: accent,
                      backgroundColor: palette.surfaceMuted,
                    ),
                  ),
                  // The ring is a fixed 220px, but the time text scales with
                  // the user's font setting. Scale the centre content down to
                  // fit so a large font never overflows the ring.
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Dimens.spacing24,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            elapsed,
                            style: textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: palette.textStrong,
                            ),
                          ),
                          const SizedBox(height: Dimens.spacing4),
                          Text(
                            l10n.fastingElapsedLabel,
                            style: textTheme.bodySmall?.copyWith(
                              color: palette.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Dimens.spacing24),
          AppCard(
            padding: const EdgeInsets.all(Dimens.spacing20),
            child: Column(
              children: [
                Text(
                  l10n.fastingRemainingValue(remaining),
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: Dimens.spacing4),
                Text(
                  l10n.fastingTargetValue(_formatDuration(state.target)),
                  style: textTheme.bodyMedium?.copyWith(
                    color: palette.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Dimens.spacing32),
          Semantics(
            identifier: 'fasting-cancel',
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                shape: Dimens.shapeM,
                side: BorderSide(color: palette.border, width: Dimens.hairline),
                padding: const EdgeInsets.symmetric(vertical: Dimens.spacing16),
              ),
              icon: const Icon(Icons.stop_circle_outlined),
              label: Text(l10n.fastingCancel),
              onPressed: () => _confirmCancel(context, l10n),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompleted(BuildContext context, S l10n) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = isDark ? AppPalette.dark : AppPalette.light;
    final accent = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.all(Dimens.spacing24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(Dimens.spacing24),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_rounded, size: 64, color: accent),
          ),
          const SizedBox(height: Dimens.spacing24),
          Text(
            l10n.fastingComplete,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: palette.textStrong,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Dimens.spacing32),
          Semantics(
            identifier: 'fasting-complete-close',
            child: FilledButton(
              style: FilledButton.styleFrom(
                shape: Dimens.shapeM,
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimens.spacing32,
                  vertical: Dimens.spacing16,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.dialogCloseLabel),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmCancel(BuildContext context, S l10n) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: Dimens.shapeL,
        title: Text(l10n.fastingCancelConfirmTitle),
        content: Text(l10n.fastingCancelConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.dialogCancelLabel),
          ),
          Semantics(
            identifier: 'fasting-cancel-confirm',
            child: TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.fastingCancel),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      _bloc.add(const FastingCancelRequested());
    }
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  Future<void> _scheduleCompleteNotification(
    BuildContext context,
    FastingActive state,
  ) async {
    final notificationService = locator<NotificationService>();
    final permitted = await notificationService.requestPermission();
    if (!permitted) return;
    final when = state.session.startedAt.add(state.session.targetDuration);
    if (!when.isAfter(DateTime.now())) return;
    if (!context.mounted) return;
    final l10n = S.of(context);
    await notificationService.scheduleFastingComplete(
      when: when,
      title: l10n.fastingNotificationCompleteTitle,
      body: l10n.fastingNotificationCompleteBody,
      channelName: l10n.fastingNotificationChannelName,
      channelDescription: l10n.fastingNotificationChannelDescription,
    );
  }

  Future<void> _cancelCompleteNotification() async {
    await locator<NotificationService>().cancelFastingComplete();
  }
}
