import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// Shared orientation behaviour for the barcode-scanner screens (issue #165).
///
/// The live camera preview tips sideways when the phone rotates, so by default
/// the scanner locks to portrait on phone-sized screens. Tablets are left free
/// to rotate, because a tablet held in landscape shouldn't be forced upright.
/// The user can override either way with the in-scanner toggle; that choice is
/// sticky, persisted via [ConfigRepository.setConfigScannerPortraitLock] so it
/// survives leaving and reopening the scanner.
mixin ScannerOrientationMixin<T extends StatefulWidget> on State<T> {
  /// Material's tablet breakpoint. At or above this shortest-side width we
  /// treat the device as a tablet and leave rotation free by default.
  static const _tabletShortestSideDp = 600.0;

  /// Resolved lazily and defensively: production always registers it in
  /// `initLocator`, but a bare widget-test harness that only exercises the
  /// scanner's navigation shouldn't have to wire config just to mount the
  /// screen. When it's absent the scanner simply follows the device default.
  ConfigRepository? get _configRepository =>
      locator.isRegistered<ConfigRepository>()
          ? locator<ConfigRepository>()
          : null;

  /// Persisted user override. Null until the user taps the toggle, at which
  /// point the scanner stops following the device default and obeys this.
  bool? _userOverride;

  @override
  void initState() {
    super.initState();
    _loadOverride();
  }

  Future<void> _loadOverride() async {
    final config = await _configRepository?.getConfig();
    if (!mounted ||
        config == null ||
        config.scannerPortraitLock == _userOverride) {
      return;
    }
    setState(() => _userOverride = config.scannerPortraitLock);
    _applyOrientation();
  }

  bool get _deviceDefaultsToPortrait =>
      MediaQuery.of(context).size.shortestSide < _tabletShortestSideDp;

  /// Whether the scanner is currently holding the screen in portrait.
  bool get isPortraitLocked => _userOverride ?? _deviceDefaultsToPortrait;

  void _applyOrientation() {
    SystemChrome.setPreferredOrientations(
      isPortraitLocked
          ? const [DeviceOrientation.portraitUp]
          : DeviceOrientation.values,
    );
  }

  Future<void> _togglePortraitLock() async {
    final locked = !isPortraitLocked;
    setState(() => _userOverride = locked);
    _applyOrientation();
    await _configRepository?.setConfigScannerPortraitLock(locked);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // MediaQuery is first available here, so this is the earliest point we can
    // resolve the device default. Re-applying on every call is idempotent.
    _applyOrientation();
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  /// The appbar action that flips the lock. Each scanner screen drops this
  /// into its `AppBar.actions`.
  Widget buildPortraitLockAction(BuildContext context) {
    final locked = isPortraitLocked;
    return Semantics(
      identifier: 'scanner-orientation-lock',
      child: IconButton(
        icon: Icon(
          locked ? Icons.screen_lock_rotation : Icons.screen_rotation,
        ),
        tooltip: locked
            ? S.of(context).scannerUnlockOrientationTooltip
            : S.of(context).scannerLockOrientationTooltip,
        onPressed: _togglePortraitLock,
      ),
    );
  }
}
