import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/features/fasting/domain/entity/fasting_session_entity.dart';
import 'package:opennutritracker/features/fasting/domain/usecase/acknowledge_fasting_warning_usecase.dart';
import 'package:opennutritracker/features/fasting/domain/usecase/cancel_fasting_usecase.dart';
import 'package:opennutritracker/features/fasting/domain/usecase/complete_fasting_usecase.dart';
import 'package:opennutritracker/features/fasting/domain/usecase/get_active_fasting_session_usecase.dart';
import 'package:opennutritracker/features/fasting/domain/usecase/start_fasting_usecase.dart';

// TODO(#84 follow-up): optional local notification when the timer reaches its
// target. The existing `NotificationService` is wired to flutter_local_notifications;
// a follow-up PR can schedule a one-shot at startedAt + targetDuration so the
// user can dismiss the app without losing the chime. Skipped in v1 to keep the
// initial surface area small and the no-streaks framing unambiguous.

sealed class FastingEvent extends Equatable {
  const FastingEvent();

  @override
  List<Object?> get props => [];
}

class FastingLoadRequested extends FastingEvent {
  const FastingLoadRequested();
}

class FastingWarningAcknowledged extends FastingEvent {
  const FastingWarningAcknowledged();
}

class FastingStartRequested extends FastingEvent {
  final int targetDurationMinutes;

  const FastingStartRequested(this.targetDurationMinutes);

  @override
  List<Object?> get props => [targetDurationMinutes];
}

class FastingCancelRequested extends FastingEvent {
  const FastingCancelRequested();
}

/// Internal tick driven by the bloc's own periodic timer. Surfaces so the UI
/// can re-render the elapsed/remaining strings every second and so the bloc
/// can detect when the target duration has been reached.
class FastingTicked extends FastingEvent {
  final DateTime now;

  const FastingTicked(this.now);

  @override
  List<Object?> get props => [now];
}

sealed class FastingState extends Equatable {
  const FastingState();

  @override
  List<Object?> get props => [];
}

class FastingInitial extends FastingState {
  const FastingInitial();
}

class FastingWarningRequired extends FastingState {
  const FastingWarningRequired();
}

class FastingIdle extends FastingState {
  const FastingIdle();
}

class FastingActive extends FastingState {
  final FastingSessionEntity session;
  final DateTime now;

  const FastingActive({required this.session, required this.now});

  Duration get elapsed => session.elapsedAt(now);
  Duration get target => session.targetDuration;
  Duration get remaining {
    final diff = target - elapsed;
    return diff.isNegative ? Duration.zero : diff;
  }

  bool get hasReachedTarget => elapsed >= target;

  @override
  List<Object?> get props => [session, now];
}

class FastingCompleted extends FastingState {
  final FastingSessionEntity session;

  const FastingCompleted(this.session);

  @override
  List<Object?> get props => [session];
}

class FastingBloc extends Bloc<FastingEvent, FastingState> {
  final GetConfigUsecase _getConfig;
  final GetActiveFastingSessionUseCase _getActive;
  final StartFastingUseCase _start;
  final CancelFastingUseCase _cancel;
  final CompleteFastingUseCase _complete;
  final AcknowledgeFastingWarningUseCase _acknowledge;

  Timer? _ticker;

  FastingBloc(
    this._getConfig,
    this._getActive,
    this._start,
    this._cancel,
    this._complete,
    this._acknowledge,
  ) : super(const FastingInitial()) {
    on<FastingLoadRequested>(_onLoad);
    on<FastingWarningAcknowledged>(_onAcknowledged);
    on<FastingStartRequested>(_onStart);
    on<FastingCancelRequested>(_onCancel);
    on<FastingTicked>(_onTick);
  }

  Future<void> _onLoad(
    FastingLoadRequested event,
    Emitter<FastingState> emit,
  ) async {
    final config = await _getConfig.getConfig();
    if (!config.fastingWarningAcknowledged) {
      emit(const FastingWarningRequired());
      return;
    }
    await _emitFromCurrentSession(emit);
  }

  Future<void> _onAcknowledged(
    FastingWarningAcknowledged event,
    Emitter<FastingState> emit,
  ) async {
    await _acknowledge();
    await _emitFromCurrentSession(emit);
  }

  Future<void> _emitFromCurrentSession(Emitter<FastingState> emit) async {
    final active = await _getActive();
    if (active == null) {
      _ticker?.cancel();
      emit(const FastingIdle());
      return;
    }
    final now = DateTime.now();
    emit(FastingActive(session: active, now: now));
    _startTicker();
  }

  Future<void> _onStart(
    FastingStartRequested event,
    Emitter<FastingState> emit,
  ) async {
    final session = await _start(
      targetDurationMinutes: event.targetDurationMinutes,
    );
    emit(FastingActive(session: session, now: DateTime.now()));
    _startTicker();
  }

  Future<void> _onCancel(
    FastingCancelRequested event,
    Emitter<FastingState> emit,
  ) async {
    final current = state;
    if (current is! FastingActive) return;
    _ticker?.cancel();
    await _cancel(current.session);
    emit(const FastingIdle());
  }

  Future<void> _onTick(FastingTicked event, Emitter<FastingState> emit) async {
    final current = state;
    if (current is! FastingActive) return;
    final updated = FastingActive(session: current.session, now: event.now);
    if (updated.hasReachedTarget) {
      _ticker?.cancel();
      final completed = await _complete(current.session, now: event.now);
      emit(FastingCompleted(completed));
    } else {
      emit(updated);
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      add(FastingTicked(DateTime.now()));
    });
  }

  @override
  Future<void> close() {
    _ticker?.cancel();
    return super.close();
  }
}
