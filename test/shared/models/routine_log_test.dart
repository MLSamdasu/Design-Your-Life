// RoutineLog 모델 단위 테스트
import 'package:flutter_test/flutter_test.dart';
import 'package:design_your_life/shared/models/routine_log.dart';

void main() {
  group('RoutineLog.fromMap', () {
    test('정상 Map에서 객체를 생성한다', () {
      final map = {
        'id': 'log-1',
        'routine_id': 'routine-1',
        'log_date': '2026-03-17',
        'is_completed': true,
        'created_at': '2026-03-17T10:00:00.000Z',
        'updated_at': '2026-03-17T10:00:00.000Z',
      };
      final log = RoutineLog.fromMap(map);
      expect(log.id, 'log-1');
      expect(log.routineId, 'routine-1');
      expect(log.isCompleted, true);
    });

    test('camelCase 키도 파싱한다', () {
      final map = {
        'id': 'log-2',
        'routineId': 'routine-2',
        'logDate': '2026-03-17',
        'isCompleted': false,
        'createdAt': '2026-03-17T10:00:00.000Z',
        'updatedAt': '2026-03-17T10:00:00.000Z',
      };
      final log = RoutineLog.fromMap(map);
      expect(log.routineId, 'routine-2');
      expect(log.isCompleted, false);
    });
  });

  group('RoutineLog.toInsertMap', () {
    test('id 필드가 포함되지 않는다 (HabitLog 패턴)', () {
      final log = RoutineLog(
        id: 'log-1',
        routineId: 'routine-1',
        date: DateTime(2026, 3, 17),
        isCompleted: true,
        createdAt: DateTime(2026, 3, 17),
        updatedAt: DateTime(2026, 3, 17),
      );
      final map = log.toInsertMap('local_user');
      expect(map.containsKey('id'), false);
      expect(map['routine_id'], 'routine-1');
      expect(map['user_id'], 'local_user');
    });
  });

  group('RoutineLog.copyWith', () {
    test('isCompleted를 토글한다', () {
      final log = RoutineLog(
        id: 'log-1',
        routineId: 'routine-1',
        date: DateTime(2026, 3, 17),
        isCompleted: false,
        createdAt: DateTime(2026, 3, 17),
        updatedAt: DateTime(2026, 3, 17),
      );
      final toggled = log.copyWith(isCompleted: true);
      expect(toggled.isCompleted, true);
      expect(toggled.id, 'log-1'); // 다른 필드 불변
    });
  });
}
