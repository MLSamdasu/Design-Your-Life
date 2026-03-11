// DateTime 확장 메서드 단위 테스트
// isToday, isSameDay, dDayCount, startOfWeek, toKoreanDate 등을 검증한다.
// 주의: intl 패키지의 로케일 초기화가 필요한 메서드는 별도 처리한다.
import 'package:design_your_life/core/utils/date_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppDateUtils - 날짜 비교', () {
    test('isToday가 오늘 날짜에 대해 true를 반환한다', () {
      final now = DateTime.now();
      expect(AppDateUtils.isToday(now), true);
    });

    test('isToday가 어제 날짜에 대해 false를 반환한다', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(AppDateUtils.isToday(yesterday), false);
    });

    test('isSameDay가 같은 날을 비교하면 true를 반환한다', () {
      final a = DateTime(2026, 3, 9, 10, 30);
      final b = DateTime(2026, 3, 9, 23, 59);
      expect(AppDateUtils.isSameDay(a, b), true);
    });

    test('isSameDay가 다른 날을 비교하면 false를 반환한다', () {
      final a = DateTime(2026, 3, 9);
      final b = DateTime(2026, 3, 10);
      expect(AppDateUtils.isSameDay(a, b), false);
    });

    test('isPast가 어제 날짜에 대해 true를 반환한다', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(AppDateUtils.isPast(yesterday), true);
    });

    test('isPast가 오늘 날짜에 대해 false를 반환한다', () {
      final today = DateTime.now();
      expect(AppDateUtils.isPast(today), false);
    });

    test('isFuture가 내일 날짜에 대해 true를 반환한다', () {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      expect(AppDateUtils.isFuture(tomorrow), true);
    });

    test('isFuture가 오늘 날짜에 대해 false를 반환한다', () {
      final today = DateTime.now();
      expect(AppDateUtils.isFuture(today), false);
    });
  });

  group('AppDateUtils - D-day 계산', () {
    test('dDayCount가 오늘에 대해 0을 반환한다', () {
      final today = DateTime.now();
      expect(AppDateUtils.dDayCount(today), 0);
    });

    test('dDayCount가 미래 날짜에 대해 양수를 반환한다', () {
      final future = DateTime.now().add(const Duration(days: 5));
      expect(AppDateUtils.dDayCount(future), 5);
    });

    test('dDayCount가 과거 날짜에 대해 음수를 반환한다', () {
      final past = DateTime.now().subtract(const Duration(days: 3));
      expect(AppDateUtils.dDayCount(past), -3);
    });

    test('dDayString이 오늘에 대해 D-Day를 반환한다', () {
      final today = DateTime.now();
      expect(AppDateUtils.dDayString(today), 'D-Day');
    });

    test('dDayString이 미래 날짜에 대해 D-N 형식을 반환한다', () {
      final future = DateTime.now().add(const Duration(days: 3));
      expect(AppDateUtils.dDayString(future), 'D-3');
    });

    test('dDayString이 과거 날짜에 대해 D+N 형식을 반환한다', () {
      final past = DateTime.now().subtract(const Duration(days: 2));
      expect(AppDateUtils.dDayString(past), 'D+2');
    });
  });

  group('AppDateUtils - 주간 범위', () {
    test('startOfWeek가 월요일을 반환한다', () {
      // 2026-03-09은 월요일이다
      final monday = DateTime(2026, 3, 9);
      final result = AppDateUtils.startOfWeek(monday);
      expect(result.weekday, DateTime.monday);
      expect(result.day, 9);
    });

    test('startOfWeek가 수요일에서 해당 주 월요일을 반환한다', () {
      final wednesday = DateTime(2026, 3, 11);
      final result = AppDateUtils.startOfWeek(wednesday);
      expect(result.weekday, DateTime.monday);
      expect(result.day, 9);
    });

    test('startOfWeek가 일요일에서 해당 주 월요일을 반환한다', () {
      final sunday = DateTime(2026, 3, 15);
      final result = AppDateUtils.startOfWeek(sunday);
      expect(result.weekday, DateTime.monday);
      expect(result.day, 9);
    });

    test('endOfWeek가 일요일을 반환한다', () {
      final wednesday = DateTime(2026, 3, 11);
      final result = AppDateUtils.endOfWeek(wednesday);
      expect(result.weekday, DateTime.sunday);
      expect(result.day, 15);
    });

    test('weekDays가 7일을 반환한다', () {
      final wednesday = DateTime(2026, 3, 11);
      final days = AppDateUtils.weekDays(wednesday);
      expect(days.length, 7);
      expect(days.first.weekday, DateTime.monday);
      expect(days.last.weekday, DateTime.sunday);
    });
  });

  group('AppDateUtils - 날짜 이동', () {
    test('startOfMonth가 1일을 반환한다', () {
      final date = DateTime(2026, 3, 15);
      final result = AppDateUtils.startOfMonth(date);
      expect(result.day, 1);
      expect(result.month, 3);
    });

    test('endOfMonth가 해당 월의 마지막 날을 반환한다', () {
      final march = DateTime(2026, 3, 15);
      expect(AppDateUtils.endOfMonth(march).day, 31);

      final february = DateTime(2026, 2, 10);
      expect(AppDateUtils.endOfMonth(february).day, 28);
    });

    test('startOfDay가 자정을 반환한다', () {
      final date = DateTime(2026, 3, 9, 15, 30, 45);
      final result = AppDateUtils.startOfDay(date);
      expect(result.hour, 0);
      expect(result.minute, 0);
      expect(result.second, 0);
    });
  });

  group('AppDateUtils - 포맷 변환', () {
    test('toDateString이 yyyy-MM-dd 형식을 반환한다', () {
      final date = DateTime(2026, 3, 9);
      expect(AppDateUtils.toDateString(date), '2026-03-09');
    });

    test('toDateString이 한 자리 월/일에 패딩을 추가한다', () {
      final date = DateTime(2026, 1, 5);
      expect(AppDateUtils.toDateString(date), '2026-01-05');
    });
  });

  group('AppDateUtils - UTC 변환', () {
    test('toUtcMidnight가 UTC 자정을 반환한다', () {
      final local = DateTime(2026, 3, 9, 15, 30);
      final utc = AppDateUtils.toUtcMidnight(local);
      expect(utc.isUtc, true);
      expect(utc.hour, 0);
      expect(utc.minute, 0);
      expect(utc.year, 2026);
      expect(utc.month, 3);
      expect(utc.day, 9);
    });
  });

  group('AppDateUtils - HabitLog ID', () {
    test('habitLogId가 {habitId}_{yyyy-MM-dd} 형식을 따른다', () {
      final date = DateTime(2026, 3, 9);
      final id = AppDateUtils.habitLogId('habit-1', date);
      expect(id, 'habit-1_2026-03-09');
    });

    test('habitLogId에 habitId가 포함된다', () {
      final date = DateTime(2026, 12, 25);
      final id = AppDateUtils.habitLogId('my-habit', date);
      expect(id, startsWith('my-habit_'));
      expect(id, 'my-habit_2026-12-25');
    });
  });
}
