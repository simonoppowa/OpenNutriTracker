import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/trends/presentation/trends_calc.dart';

DateTime _d(int y, int m, int day) => DateTime(y, m, day);

/// Hours in the local calendar day that starts at [day]'s midnight: 24
/// normally, 25 on a fall-back day, 23 on a spring-forward day.
int _hoursIn(DateTime day) =>
    DateTime(day.year, day.month, day.day + 1).difference(day).inHours;

/// The DST groups need a zone with both transitions; `just test` runs in the
/// process zone (UTC on CI), where they skip, and `just test_dst` reruns this
/// file under Europe/Berlin, which fell back on 2025-10-26 and springs
/// forward on 2026-03-29.
final String? _skipWithoutDst =
    _hoursIn(_d(2025, 10, 26)) == 25 && _hoursIn(_d(2026, 3, 29)) == 23
    ? null
    : 'no DST transitions in zone ${_d(2026, 1, 1).timeZoneName}; '
          'run `just test_dst` (TZ=Europe/Berlin)';

void main() {
  group('streakStats', () {
    final start = _d(2026, 5, 1);
    final today = _d(2026, 5, 10);

    test('all days on track → current and longest equal the window', () {
      final onTrack = {for (var i = 0; i <= 9; i++) _d(2026, 5, 1 + i)};
      final s = streakStats(onTrack, start, today);
      expect(s.current, 10);
      expect(s.longest, 10);
    });

    test('a gap breaks the run; longest is the best span', () {
      // on track 1-3, off 4, on 5-9, off 10 (today off)
      final onTrack = {
        _d(2026, 5, 1), _d(2026, 5, 2), _d(2026, 5, 3),
        _d(2026, 5, 5), _d(2026, 5, 6), _d(2026, 5, 7),
        _d(2026, 5, 8), _d(2026, 5, 9),
      };
      final s = streakStats(onTrack, start, today);
      expect(s.longest, 5); // 5..9
      expect(s.current, 0); // today (10th) not on track
    });

    test('current counts the run ending today', () {
      final onTrack = {_d(2026, 5, 8), _d(2026, 5, 9), _d(2026, 5, 10)};
      final s = streakStats(onTrack, start, today);
      expect(s.current, 3);
      expect(s.longest, 3);
    });

    test('empty set → zeros', () {
      final s = streakStats(<DateTime>{}, start, today);
      expect(s.current, 0);
      expect(s.longest, 0);
    });
  });

  group('weightProjection', () {
    test('fewer than two points → null', () {
      expect(weightProjection([(date: _d(2026, 5, 1), kg: 80)], 75), isNull);
      expect(weightProjection(const [], 75), isNull);
    });

    test('steady loss → negative weekly rate and a week estimate', () {
      // 80kg on day 0, 79kg on day 7 → -1 kg/week.
      final points = [
        (date: _d(2026, 5, 1), kg: 80.0),
        (date: _d(2026, 5, 8), kg: 79.0),
      ];
      final p = weightProjection(points, 77)!;
      expect(p.ratePerWeek, closeTo(-1.0, 1e-6));
      // current 79, need -2kg at -1/wk ⇒ 14 days ⇒ 2 weeks.
      expect(p.weeksToTarget, 2);
    });

    test('flat trend → zero rate, no projection', () {
      final points = [
        (date: _d(2026, 5, 1), kg: 80.0),
        (date: _d(2026, 5, 8), kg: 80.0),
      ];
      final p = weightProjection(points, 75)!;
      expect(p.ratePerWeek, closeTo(0, 1e-6));
      expect(p.weeksToTarget, isNull);
    });

    test('moving away from target → rate given but no projection', () {
      // gaining while target is below current.
      final points = [
        (date: _d(2026, 5, 1), kg: 80.0),
        (date: _d(2026, 5, 8), kg: 81.0),
      ];
      final p = weightProjection(points, 75)!;
      expect(p.ratePerWeek, closeTo(1.0, 1e-6));
      expect(p.weeksToTarget, isNull);
    });
  });

  // #1224: both spans count calendar days, so a 23-hour or 25-hour day inside
  // the window is still one day. A 24-hour span only goes wrong when the
  // window's two ends sit in different UTC offsets, so each transition gets
  // its own 30-day window: Europe/Berlin fell back on 2025-10-26 and springs
  // forward on 2026-03-29.
  final windows = {
    'a fall-back': (start: _d(2025, 10, 12), today: _d(2025, 11, 10)),
    'a spring-forward': (start: _d(2026, 3, 12), today: _d(2026, 4, 10)),
  };
  for (final MapEntry(key: name, value: w) in windows.entries) {
    group('across $name', () {
      test('streakStats counts every day of the window once', () {
        final onTrack = {
          for (var i = 0; i < 30; i++)
            _d(w.start.year, w.start.month, w.start.day + i),
        };
        expect(onTrack, hasLength(30));
        expect(onTrack, contains(w.today));
        final s = streakStats(onTrack, w.start, w.today);
        // Across the spring-forward a 24-hour span measures 29 days minus an
        // hour, truncates to 28 and stops both runs a day short.
        expect(s.current, 30);
        expect(s.longest, 30);
      });

      test('streakStats over a one-day window counts only that day', () {
        final s = streakStats({w.today}, w.today, w.today);
        expect(s.current, 1);
        expect(s.longest, 1);
      });

      test('weightProjection reads one calendar day as one x unit', () {
        // Exactly 0.1 kg a day: a 24-hour span puts every point after the
        // spring-forward one x unit early and bends the slope off 0.7.
        final points = [
          for (var i = 0; i < 30; i++)
            (
              date: _d(w.start.year, w.start.month, w.start.day + i),
              kg: 90 - i * 0.1,
            ),
        ];
        final p = weightProjection(points, null)!;
        expect(p.ratePerWeek, closeTo(-0.7, 1e-9));
      });
    }, skip: _skipWithoutDst);
  }
}
