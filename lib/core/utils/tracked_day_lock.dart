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

/// Runs [action] while no other tracked-day write or reconciliation runs.
/// See [_trackedDayLock].
Future<T> withTrackedDayLock<T>(Future<T> Function() action) =>
    _trackedDayLock.synchronized(action);
