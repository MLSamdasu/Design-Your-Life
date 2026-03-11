// StreakCalculator 순수 함수 테스트
// 현재 스트릭, 최장 스트릭 계산, 빈 로그, 갭 있는 로그 등 엣지 케이스를 검증한다.
// 백엔드 HabitLogDto 대응 모델로 전환 후 userId 제거.
import 'package:design_your_life/features/habit/services/streak_calculator.dart';
import 'package:design_your_life/shared/models/habit_log.dart';
import 'package:flutter_test/flutter_test.dart';

/// 테스트용 HabitLog 생성 헬퍼
HabitLog _log(DateTime date, {bool isCompleted = true}) {
  return HabitLog(
    id: 'habit-1_${date.toIso8601String().substring(0, 10)}',
    habitId: 'habit-1',
    date: date,
    isCompleted: isCompleted,
    checkedAt: date,
  );
}

void main() {
  group('StreakCalculator - 기본 동작', () {
    test('빈 로그 목록이면 스트릭이 0이다', () {
      final result = StreakCalculator.calculate([], DateTime(2026, 3, 9));
      expect(result.currentStreak, 0);
      expect(result.longestStreak, 0);
    });

    test('미완료 로그만 있으면 스트릭이 0이다', () {
      final logs = [
        _log(DateTime(2026, 3, 9), isCompleted: false),
        _log(DateTime(2026, 3, 8), isCompleted: false),
      ];
      final result = StreakCalculator.calculate(logs, DateTime(2026, 3, 9));
      expect(result.currentStreak, 0);
      expect(result.longestStreak, 0);
    });

    test('오늘만 체크하면 currentStreak이 1이다', () {
      final today = DateTime(2026, 3, 9);
      final logs = [_log(today)];
      final result = StreakCalculator.calculate(logs, today);
      expect(result.currentStreak, 1);
      expect(result.longestStreak, 1);
    });

    test('어제만 체크하면 currentStreak이 1이다', () {
      final today = DateTime(2026, 3, 9);
      final yesterday = DateTime(2026, 3, 8);
      final logs = [_log(yesterday)];
      final result = StreakCalculator.calculate(logs, today);
      expect(result.currentStreak, 1);
      expect(result.longestStreak, 1);
    });
  });

  group('StreakCalculator - 연속 스트릭', () {
    test('3일 연속 체크의 currentStreak이 3이다', () {
      final today = DateTime(2026, 3, 9);
      final logs = [
        _log(DateTime(2026, 3, 7)),
        _log(DateTime(2026, 3, 8)),
        _log(today),
      ];
      final result = StreakCalculator.calculate(logs, today);
      expect(result.currentStreak, 3);
      expect(result.longestStreak, 3);
    });

    test('어제까지 5일 연속이면 currentStreak이 5이다', () {
      final today = DateTime(2026, 3, 9);
      final logs = [
        _log(DateTime(2026, 3, 4)),
        _log(DateTime(2026, 3, 5)),
        _log(DateTime(2026, 3, 6)),
        _log(DateTime(2026, 3, 7)),
        _log(DateTime(2026, 3, 8)),
      ];
      final result = StreakCalculator.calculate(logs, today);
      expect(result.currentStreak, 5);
      expect(result.longestStreak, 5);
    });
  });

  group('StreakCalculator - 갭 처리', () {
    test('오늘도 어제도 체크 없으면 currentStreak이 0이다', () {
      final today = DateTime(2026, 3, 9);
      final logs = [
        _log(DateTime(2026, 3, 5)),
        _log(DateTime(2026, 3, 6)),
      ];
      final result = StreakCalculator.calculate(logs, today);
      expect(result.currentStreak, 0);
      // 최장 스트릭은 과거 연속 2일
      expect(result.longestStreak, 2);
    });

    test('중간에 갭이 있으면 갭 이후부터 카운트한다', () {
      final today = DateTime(2026, 3, 9);
      final logs = [
        _log(DateTime(2026, 3, 3)),
        _log(DateTime(2026, 3, 4)),
        _log(DateTime(2026, 3, 5)),
        // 6, 7 갭
        _log(DateTime(2026, 3, 8)),
        _log(today),
      ];
      final result = StreakCalculator.calculate(logs, today);
      expect(result.currentStreak, 2);
      expect(result.longestStreak, 3);
    });
  });

  group('StreakCalculator - 최장 스트릭', () {
    test('과거의 긴 스트릭이 longestStreak에 반영된다', () {
      final today = DateTime(2026, 3, 9);
      final logs = [
        // 과거 4일 연속
        _log(DateTime(2026, 2, 20)),
        _log(DateTime(2026, 2, 21)),
        _log(DateTime(2026, 2, 22)),
        _log(DateTime(2026, 2, 23)),
        // 오늘만 (현재 스트릭 1)
        _log(today),
      ];
      final result = StreakCalculator.calculate(logs, today);
      expect(result.currentStreak, 1);
      expect(result.longestStreak, 4);
    });
  });

  group('StreakResult', () {
    test('zero 상수가 0/0이다', () {
      expect(StreakResult.zero.currentStreak, 0);
      expect(StreakResult.zero.longestStreak, 0);
    });
  });
}
