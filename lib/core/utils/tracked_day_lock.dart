import 'package:synchronized/synchronized.dart';

/// Serialises everything that writes a tracked-day row against the passes
/// that derive the rows from the entries (#1317).
///
/// A writer stores an entry and then, after more awaits, adds it to its
/// day's row; the row is a running total. `reconcileTrackedDays` instead
/// rewrites a row as the sum of the entries listed on its day. If it ran
/// between a writer's two steps it would count the stored entry, and the
/// resumed writer would add it again: two 200-kcal entries would read 600.
/// For activities it is worse, since nothing re-derives a goal later: a
/// boundary move would subtract energy that was never credited, and the
/// resumed writer would credit the day it resolved before the move.
///
/// So each operation that writes an entry and its row — and resolves the
/// day it files them under — runs whole inside [withTrackedDayLock], and
/// so do the reconciliation, the boundary move and the profile switch.
///
/// Reentrant, because writers call writers (the workout import logs
/// through `LogUserActivityUsecase`), and the profile switch runs the
/// reconciliation. Keep the user's input and network reads outside it: a
/// held lock stalls every other writer.
final _trackedDayLock = Lock(reentrant: true);
var _profileSwitchGeneration = 0;
var _profileSwitchInProgress = false;

/// Runs [action] while no other tracked-day write or reconciliation runs.
/// See [_trackedDayLock].
Future<T> withTrackedDayLock<T>(Future<T> Function() action) =>
    _trackedDayLock.synchronized(action);

/// Identifies the profile that was active when a UI write began.
///
/// The active boxes are swapped while holding the tracked-day lock. A stamp
/// taken before a switch must not authorize a write queued behind that
/// switch, since repositories resolve their boxes dynamically.
class ProfileStamp {
  final int? _generation;

  ProfileStamp._(this._generation);

  factory ProfileStamp.now() => ProfileStamp._(
    _profileSwitchInProgress ? null : _profileSwitchGeneration,
  );

  bool get isCurrent =>
      _generation != null &&
      !_profileSwitchInProgress &&
      _generation == _profileSwitchGeneration;
}

/// Runs [action] under the tracked-day lock only if the originating profile
/// is still active once the lock is acquired. Returns null when a profile
/// switch overtook the write.
Future<T?> withTrackedDayLockOnProfile<T>(
  Future<T> Function() action, {
  ProfileStamp? startedOn,
}) {
  final stamp = startedOn ?? ProfileStamp.now();
  return withTrackedDayLock<T?>(() {
    if (!stamp.isCurrent) return Future<T?>.value(null);
    return action();
  });
}

/// Changes profiles while excluding tracked-day writes. Any UI action that
/// queued behind this switch is abandoned when it acquires the lock.
Future<T> withProfileSwitchLock<T>(Future<T> Function() action) =>
    withTrackedDayLock(() async {
      _profileSwitchGeneration++;
      _profileSwitchInProgress = true;
      try {
        return await action();
      } finally {
        _profileSwitchInProgress = false;
      }
    });
