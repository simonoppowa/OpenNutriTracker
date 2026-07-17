import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/trends/presentation/trends_calc.dart';

DateTime _d(int y, int m, int day) => DateTime(y, m, day);

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
}
