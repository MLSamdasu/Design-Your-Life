// TimerLog 모델 단위 테스트
// fromMap/toMap/copyWith 패턴과 TimerSessionType 변환을 검증한다.
// Supabase timer_logs 테이블 대응 — snake_case 컬럼명,
// type 값은 'focus', 'short_break', 'long_break'
import 'package:design_your_life/features/timer/models/timer_log.dart';
import 'package:flutter_test/flutter_test.dart';

/// 테스트용 TimerLog 생성 헬퍼
TimerLog _makeLog({
  String id = 'log-1',
  String userId = 'user-1',
  String? todoId,
  String? todoTitle,
  TimerSessionType type = TimerSessionType.focus,
  int durationSeconds = 1500,
}) {
  final now = DateTime(2026, 3, 10, 9, 0);
  final end = now.add(Duration(seconds: durationSeconds));
  return TimerLog(
    id: id,
    userId: userId,
    todoId: todoId,
    todoTitle: todoTitle,
    startTime: now,
    endTime: end,
    durationSeconds: durationSeconds,
    type: type,
    createdAt: now,
  );
}

/// 테스트용 Supabase 응답 Map 생성 헬퍼
Map<String, dynamic> _makeMap({
  String userId = 'user-1',
  String? todoId,
  String? todoTitle,
  String type = 'focus',
  int durationSeconds = 1500,
}) {
  final now = DateTime(2026, 3, 10, 9, 0);
  final end = now.add(Duration(seconds: durationSeconds));
  return {
    'user_id': userId,
    'todo_id': todoId,
    'todo_title': todoTitle,
    'start_time': now.toIso8601String(),
    'end_time': end.toIso8601String(),
    'duration_seconds': durationSeconds,
    'type': type,
    'created_at': now.toIso8601String(),
  };
}

void main() {
  group('TimerLog.fromMap - 기본 파싱', () {
    test('정상 데이터로 TimerLog를 생성한다', () {
      final map = _makeMap();
      final log = TimerLog.fromMap({...map, 'id': 'log-1'});

      expect(log.id, 'log-1');
      expect(log.userId, 'user-1');
      expect(log.todoId, isNull);
      expect(log.type, TimerSessionType.focus);
      expect(log.durationSeconds, 1500);
    });

    test('투두 연결 정보가 있으면 올바르게 파싱한다', () {
      final map = _makeMap(todoId: 'todo-1', todoTitle: '영어 공부');
      final log = TimerLog.fromMap({...map, 'id': 'log-2'});

      expect(log.todoId, 'todo-1');
      expect(log.todoTitle, '영어 공부');
    });

    test('short_break 타입을 올바르게 파싱한다', () {
      final map = _makeMap(type: 'short_break', durationSeconds: 300);
      final log = TimerLog.fromMap({...map, 'id': 'log-3'});

      expect(log.type, TimerSessionType.shortBreak);
      expect(log.durationSeconds, 300);
    });

    test('long_break 타입을 올바르게 파싱한다', () {
      final map = _makeMap(type: 'long_break', durationSeconds: 900);
      final log = TimerLog.fromMap({...map, 'id': 'log-4'});

      expect(log.type, TimerSessionType.longBreak);
      expect(log.durationSeconds, 900);
    });

    test('알 수 없는 type 값은 focus로 기본 처리한다', () {
      final map = _makeMap(type: 'unknown');
      final log = TimerLog.fromMap({...map, 'id': 'log-5'});

      expect(log.type, TimerSessionType.focus);
    });
  });

  group('TimerLog.toMap - 직렬화', () {
    test('toMap이 올바른 snake_case 필드를 포함한다', () {
      final log = _makeLog();
      final map = log.toMap();

      expect(map['user_id'], 'user-1');
      expect(map['todo_id'], isNull);
      expect(map['type'], 'focus');
      expect(map['duration_seconds'], 1500);
      // DateTime은 ISO 8601 문자열로 반환된다
      expect(map['start_time'], isA<String>());
      expect(map['end_time'], isA<String>());
    });

    test('short_break 타입이 올바르게 직렬화된다', () {
      final log = _makeLog(type: TimerSessionType.shortBreak, durationSeconds: 300);
      final map = log.toMap();

      expect(map['type'], 'short_break');
    });

    test('long_break 타입이 올바르게 직렬화된다', () {
      final log = _makeLog(type: TimerSessionType.longBreak, durationSeconds: 900);
      final map = log.toMap();

      expect(map['type'], 'long_break');
    });

    test('투두 연결 정보가 toMap에 포함된다', () {
      final log = _makeLog(todoId: 'todo-1', todoTitle: '운동 30분');
      final map = log.toMap();

      expect(map['todo_title'], '운동 30분');
    });
  });

  group('TimerLog.copyWith - 불변 업데이트', () {
    test('durationSeconds를 변경한 새 인스턴스를 반환한다', () {
      final log = _makeLog(durationSeconds: 1500);
      final updated = log.copyWith(durationSeconds: 900);

      expect(updated.durationSeconds, 900);
      expect(log.durationSeconds, 1500); // 원본 불변
    });

    test('clearTodoId로 투두 연결을 해제한다', () {
      final log = _makeLog(todoId: 'todo-1', todoTitle: '영어 공부');
      final updated = log.copyWith(clearTodoId: true, clearTodoTitle: true);

      expect(updated.todoId, isNull);
      expect(updated.todoTitle, isNull);
    });

    test('id와 userId는 copyWith으로 변경되지 않는다', () {
      final log = _makeLog(id: 'log-1', userId: 'user-1');
      final updated = log.copyWith(durationSeconds: 300);

      expect(updated.id, 'log-1');
      expect(updated.userId, 'user-1');
    });
  });

  group('TimerSessionType 확장 메서드', () {
    test('toJsonValue가 올바른 문자열을 반환한다', () {
      expect(TimerSessionType.focus.toJsonValue(), 'focus');
      expect(TimerSessionType.shortBreak.toJsonValue(), 'short_break');
      expect(TimerSessionType.longBreak.toJsonValue(), 'long_break');
    });

    test('displayLabel이 한국어를 반환한다', () {
      expect(TimerSessionType.focus.displayLabel, '집중');
      expect(TimerSessionType.shortBreak.displayLabel, '짧은 휴식');
      expect(TimerSessionType.longBreak.displayLabel, '긴 휴식');
    });
  });

  group('timerSessionTypeFromString - 역변환', () {
    test('focus 문자열을 올바르게 변환한다', () {
      expect(timerSessionTypeFromString('focus'), TimerSessionType.focus);
    });

    test('short_break 문자열을 올바르게 변환한다', () {
      expect(timerSessionTypeFromString('short_break'), TimerSessionType.shortBreak);
    });

    test('long_break 문자열을 올바르게 변환한다', () {
      expect(timerSessionTypeFromString('long_break'), TimerSessionType.longBreak);
    });

    test('레거시 camelCase 문자열도 올바르게 변환한다', () {
      expect(timerSessionTypeFromString('shortBreak'), TimerSessionType.shortBreak);
      expect(timerSessionTypeFromString('longBreak'), TimerSessionType.longBreak);
    });
  });
}
