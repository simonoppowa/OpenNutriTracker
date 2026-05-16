import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/dbo/app_theme_dbo.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/features/fasting/data/repository/fasting_repository.dart';
import 'package:opennutritracker/features/fasting/domain/entity/fasting_session_entity.dart';
import 'package:opennutritracker/features/fasting/domain/usecase/acknowledge_fasting_warning_usecase.dart';
import 'package:opennutritracker/features/fasting/domain/usecase/cancel_fasting_usecase.dart';
import 'package:opennutritracker/features/fasting/domain/usecase/complete_fasting_usecase.dart';
import 'package:opennutritracker/features/fasting/domain/usecase/get_active_fasting_session_usecase.dart';
import 'package:opennutritracker/features/fasting/domain/usecase/start_fasting_usecase.dart';
import 'package:opennutritracker/features/fasting/presentation/bloc/fasting_bloc.dart';

/// In-memory fake of [FastingRepository]. Holds sessions by id and tracks
/// add/update calls so the bloc tests can assert side-effects without needing
/// Hive or a mocking library.
class _FakeFastingRepository implements FastingRepository {
  final Map<String, FastingSessionEntity> _sessions = {};
  int addCalls = 0;
  int updateCalls = 0;
  FastingSessionEntity? lastUpdated;

  @override
  Future<void> addSession(FastingSessionEntity session) async {
    addCalls++;
    _sessions[session.id] = session;
  }

  @override
  Future<void> updateSession(FastingSessionEntity session) async {
    updateCalls++;
    lastUpdated = session;
    _sessions[session.id] = session;
  }

  @override
  Future<FastingSessionEntity?> getActiveSession() async {
    for (final s in _sessions.values) {
      if (s.isActive) return s;
    }
    return null;
  }

  @override
  Future<FastingSessionEntity?> getSession(String id) async => _sessions[id];

  @override
  Future<List<FastingSessionEntity>> allSessions() async =>
      _sessions.values.toList();
}

/// Minimal stub for [ConfigRepository] — only the surface the bloc reaches
/// (getConfig + setFastingWarningAcknowledged) needs to behave.
class _FakeConfigRepository implements ConfigRepository {
  bool acknowledged;

  _FakeConfigRepository(this.acknowledged);

  @override
  Future<ConfigEntity> getConfig() async {
    return ConfigEntity(
      true,
      true,
      false,
      AppThemeEntity.system,
      fastingWarningAcknowledged: acknowledged,
    );
  }

  @override
  Future<void> setFastingWarningAcknowledged(bool value) async {
    acknowledged = value;
  }

  // The bloc never touches anything else, so satisfy the remaining surface
  // with noClassReflection-style no-ops.
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  // Hide an unused import warning by mentioning the symbol where the
  // analyzer can see it. AppThemeDBO is reachable via fromConfigDBO but not
  // otherwise referenced in this file.
  // ignore: unused_local_variable
  final _ = AppThemeDBO.system;

  group('FastingBloc', () {
    late _FakeFastingRepository fastingRepo;
    late _FakeConfigRepository configRepo;
    late FastingBloc bloc;

    setUp(() {
      fastingRepo = _FakeFastingRepository();
      configRepo = _FakeConfigRepository(true);
      bloc = FastingBloc(
        GetConfigUsecase(configRepo),
        GetActiveFastingSessionUseCase(fastingRepo),
        StartFastingUseCase(fastingRepo),
        CancelFastingUseCase(fastingRepo),
        CompleteFastingUseCase(fastingRepo),
        AcknowledgeFastingWarningUseCase(configRepo),
      );
    });

    tearDown(() async {
      await bloc.close();
    });

    test('initial state is FastingInitial', () {
      expect(bloc.state, isA<FastingInitial>());
    });

    test('start then cancel records cancelledAt, not completedAt', () async {
      bloc.add(const FastingStartRequested(60));
      // Wait for the event loop to process.
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(bloc.state, isA<FastingActive>());
      expect(fastingRepo.addCalls, 1);

      bloc.add(const FastingCancelRequested());
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(bloc.state, isA<FastingIdle>());
      expect(fastingRepo.updateCalls, 1);
      expect(fastingRepo.lastUpdated, isNotNull);
      expect(fastingRepo.lastUpdated!.cancelledAt, isNotNull);
      expect(
        fastingRepo.lastUpdated!.completedAt,
        isNull,
        reason:
            'A user-cancelled session must not be recorded as completed; '
            'the two outcomes are tracked separately so neither path reads '
            'as failure.',
      );
    });

    test('reaching target naturally records completedAt', () async {
      // 0-minute target so the very first tick fires the completion path.
      bloc.add(const FastingStartRequested(0));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(bloc.state, isA<FastingActive>());

      // Drive a synthetic tick at "now + 1 second" so the bloc believes the
      // target has been reached without waiting on the wall-clock timer.
      bloc.add(FastingTicked(DateTime.now().add(const Duration(seconds: 1))));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(bloc.state, isA<FastingCompleted>());
      expect(fastingRepo.updateCalls, 1);
      expect(fastingRepo.lastUpdated!.completedAt, isNotNull);
      expect(fastingRepo.lastUpdated!.cancelledAt, isNull);
    });

    test(
      'load with un-acknowledged warning emits FastingWarningRequired',
      () async {
        configRepo.acknowledged = false;
        bloc.add(const FastingLoadRequested());
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(bloc.state, isA<FastingWarningRequired>());

        bloc.add(const FastingWarningAcknowledged());
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(bloc.state, isA<FastingIdle>());
        expect(configRepo.acknowledged, isTrue);
      },
    );
  });
}
