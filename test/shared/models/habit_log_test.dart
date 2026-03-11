// HabitLog 모델 단위 테스트
// ID 형식, fromMap 변환, copyWith를 검증한다.
// 백엔드 HabitLogDto 대응 모델로 전환 후 테스트를 업데이트했다.
import 'package:design_your_life/shared/models/habit_log.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('HabitLog 모델', () {
    late HabitLog log;

    setUp(() {
      log = HabitLog(
        id: 'habit-1_2026-03-09',
        habitId: 'habit-1',
        date: testDate,
        isCompleted: true,
        checkedAt: testDate,
      );
    });

    test('ID 형식이 {habitId}_{date}를 따른다', () {
      expect(log.id, 'habit-1_2026-03-09');
      expect(log.id, contains(log.habitId));
    });

    test('기본값이 올바르게 설정된다', () {
      final defaultLog = HabitLog(
        id: 'habit-2_2026-03-09',
        habitId: 'habit-2',
        date: testDate,
        checkedAt: testDate,
      );
      expect(defaultLog.isCompleted, false);
    });

    test('userId getter가 빈 문자열을 반환한다 (UI 호환)', () {
      expect(log.userId, '');
    });

    test('fromMap이 올바른 HabitLog 객체를 생성한다 (백엔드 필드명)', () {
      final map = <String, dynamic>{
        'habitId': 'habit-1',
        'logDate': '2026-03-09',
        'completed': true,
        'completedAt': '2026-03-09T10:00:00',
      };
      map['id'] = 'habit-1_2026-03-09';
      final parsed = HabitLog.fromMap(map);
      expect(parsed.id, 'habit-1_2026-03-09');
      expect(parsed.habitId, 'habit-1');
      expect(parsed.isCompleted, true);
    });

    test('fromMap이 레거시 필드명도 지원한다', () {
      final map = <String, dynamic>{
        'habitId': 'habit-1',
        'date': testDate.toIso8601String(),
        'isCompleted': true,
        'checkedAt': testDate.toIso8601String(),
      };
      map['id'] = 'log-legacy';
      final parsed = HabitLog.fromMap(map);
      expect(parsed.habitId, 'habit-1');
      expect(parsed.isCompleted, true);
    });

    test('fromMap에서 isCompleted/completed가 null이면 false로 처리한다', () {
      final map = <String, dynamic>{
        'habitId': 'habit-1',
        'logDate': '2026-03-09',
        'completedAt': '2026-03-09T10:00:00',
      };
      map['id'] = 'log-x';
      final parsed = HabitLog.fromMap(map);
      expect(parsed.isCompleted, false);
    });

    test('copyWith가 지정 필드만 변경한 새 인스턴스를 반환한다', () {
      final updated = log.copyWith(isCompleted: false);
      expect(updated.isCompleted, false);
      expect(updated.id, log.id);
      expect(updated.habitId, log.habitId);
    });

    test('copyWith가 원본 객체를 변경하지 않는다', () {
      log.copyWith(isCompleted: false);
      expect(log.isCompleted, true);
    });
  });
}
