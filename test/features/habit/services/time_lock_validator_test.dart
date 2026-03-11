// TimeLockValidator 순수 함수 테스트
// 오늘/과거/미래 날짜의 편집 가능 여부, isToday 헬퍼를 검증한다.
import 'package:design_your_life/features/habit/services/time_lock_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TimeLockValidator - validate', () {
    test('오늘 날짜는 편집 가능하다', () {
      final now = DateTime(2026, 3, 9, 14, 30);
      final target = DateTime(2026, 3, 9);
      final result = TimeLockValidator.validate(target, now);
      expect(result.isEditable, true);
      expect(result.reason, contains('오늘'));
    });

    test('오늘 날짜의 시간이 달라도 편집 가능하다', () {
      final now = DateTime(2026, 3, 9, 23, 59, 59);
      final target = DateTime(2026, 3, 9, 0, 0, 0);
      final result = TimeLockValidator.validate(target, now);
      expect(result.isEditable, true);
    });

    test('어제 날짜는 편집 불가하다', () {
      final now = DateTime(2026, 3, 9);
      final target = DateTime(2026, 3, 8);
      final result = TimeLockValidator.validate(target, now);
      expect(result.isEditable, false);
      expect(result.reason, contains('지난'));
    });

    test('일주일 전 날짜는 편집 불가하다', () {
      final now = DateTime(2026, 3, 9);
      final target = DateTime(2026, 3, 2);
      final result = TimeLockValidator.validate(target, now);
      expect(result.isEditable, false);
    });

    test('내일 날짜는 편집 불가하다', () {
      final now = DateTime(2026, 3, 9);
      final target = DateTime(2026, 3, 10);
      final result = TimeLockValidator.validate(target, now);
      expect(result.isEditable, false);
      expect(result.reason, contains('미래'));
    });

    test('한 달 후 날짜는 편집 불가하다', () {
      final now = DateTime(2026, 3, 9);
      final target = DateTime(2026, 4, 9);
      final result = TimeLockValidator.validate(target, now);
      expect(result.isEditable, false);
    });

    test('자정 직전(23:59)에서 오늘 날짜는 편집 가능하다', () {
      final now = DateTime(2026, 3, 9, 23, 59, 59);
      final target = DateTime(2026, 3, 9);
      final result = TimeLockValidator.validate(target, now);
      expect(result.isEditable, true);
    });

    test('자정 직후(00:00)에서 어제 날짜는 편집 불가하다', () {
      final now = DateTime(2026, 3, 10, 0, 0, 0);
      final target = DateTime(2026, 3, 9);
      final result = TimeLockValidator.validate(target, now);
      expect(result.isEditable, false);
    });
  });

  group('TimeLockValidator - isToday', () {
    test('같은 날이면 true를 반환한다', () {
      final now = DateTime(2026, 3, 9, 14, 30);
      final target = DateTime(2026, 3, 9, 0, 0);
      expect(TimeLockValidator.isToday(target, now), true);
    });

    test('다른 날이면 false를 반환한다', () {
      final now = DateTime(2026, 3, 9);
      final target = DateTime(2026, 3, 10);
      expect(TimeLockValidator.isToday(target, now), false);
    });

    test('같은 날 다른 시간이면 true를 반환한다', () {
      final now = DateTime(2026, 3, 9, 23, 59);
      final target = DateTime(2026, 3, 9, 0, 1);
      expect(TimeLockValidator.isToday(target, now), true);
    });

    test('연도가 다르면 false를 반환한다', () {
      final now = DateTime(2026, 3, 9);
      final target = DateTime(2025, 3, 9);
      expect(TimeLockValidator.isToday(target, now), false);
    });
  });

  group('TimeLockResult', () {
    test('isEditable과 reason이 올바르게 설정된다', () {
      const result = TimeLockResult(
        isEditable: true,
        reason: '테스트 사유',
      );
      expect(result.isEditable, true);
      expect(result.reason, '테스트 사유');
    });
  });
}
