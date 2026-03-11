// Todo 모델 단위 테스트
// fromMap, toCreateMap, copyWith, 기본값, null 처리를 검증한다.
// Supabase todos 테이블 대응 모델 — snake_case 컬럼명 사용
import 'package:design_your_life/shared/models/todo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('Todo 모델', () {
    late Todo todo;

    setUp(() {
      todo = Todo(
        id: 'todo-1',
        title: '플러터 공부',
        date: testDate,
        startTime: const TimeOfDay(hour: 14, minute: 30),
        isCompleted: false,
        color: '#FF5722',
        memo: '챕터 5 읽기',
        createdAt: testCreatedAt,
      );
    });

    test('기본값이 올바르게 설정된다', () {
      final defaultTodo = Todo(
        id: 'todo-2',
        title: '테스트',
        date: testDate,
        createdAt: testCreatedAt,
      );
      expect(defaultTodo.isCompleted, false);
      expect(defaultTodo.startTime, isNull);
      expect(defaultTodo.time, isNull);
      expect(defaultTodo.memo, isNull);
      expect(defaultTodo.color, isNull);
      expect(defaultTodo.displayOrder, 0);
    });

    test('toCreateMap이 Supabase snake_case 형식의 Map을 반환한다', () {
      final map = todo.toCreateMap();
      expect(map['title'], '플러터 공부');
      // scheduled_date는 "yyyy-MM-dd" 문자열이다
      expect(map['scheduled_date'], isA<String>());
      // start_time은 "HH:mm:ss" 문자열이다
      expect(map['start_time'], '14:30:00');
      expect(map['color'], '#FF5722');
      expect(map['memo'], '챕터 5 읽기');
    });

    test('fromMap이 올바른 Todo 객체를 생성한다', () {
      final map = <String, dynamic>{
        'title': '플러터 공부',
        'scheduled_date': '2026-03-09',
        'start_time': '14:30:00',
        'end_time': '15:30:00',
        'is_completed': false,
        'color': '#FF5722',
        'memo': '챕터 5 읽기',
        'display_order': 1,
        'tags': [],
        'created_at': '2026-01-01T00:00:00',
      };
      map['id'] = 'todo-1';
      final parsed = Todo.fromMap(map);
      expect(parsed.id, 'todo-1');
      expect(parsed.title, '플러터 공부');
      expect(parsed.startTime?.hour, 14);
      expect(parsed.startTime?.minute, 30);
      expect(parsed.endTime?.hour, 15);
      expect(parsed.endTime?.minute, 30);
      expect(parsed.color, '#FF5722');
      expect(parsed.memo, '챕터 5 읽기');
      expect(parsed.displayOrder, 1);
    });

    test('fromMap에서 선택 필드가 null일 때 기본값을 사용한다', () {
      final map = <String, dynamic>{
        'title': '테스트',
        'scheduled_date': '2026-03-09',
        'created_at': '2026-01-01T00:00:00',
      };
      map['id'] = 'todo-3';
      final parsed = Todo.fromMap(map);
      expect(parsed.isCompleted, false);
      expect(parsed.startTime, isNull);
      expect(parsed.endTime, isNull);
      expect(parsed.memo, isNull);
      expect(parsed.color, isNull);
      expect(parsed.displayOrder, 0);
    });

    test('copyWith가 지정 필드만 변경한 새 인스턴스를 반환한다', () {
      final updated = todo.copyWith(
        title: '다트 공부',
        isCompleted: true,
      );
      expect(updated.title, '다트 공부');
      expect(updated.isCompleted, true);
      // 변경하지 않은 필드는 원본 값 유지
      expect(updated.id, todo.id);
      expect(updated.color, todo.color);
      expect(updated.memo, todo.memo);
    });

    test('copyWith가 원본 객체를 변경하지 않는다', () {
      todo.copyWith(title: '변경된 제목');
      expect(todo.title, '플러터 공부');
    });

    test('copyWith clearStartTime이 startTime을 null로 초기화한다', () {
      final updated = todo.copyWith(clearStartTime: true);
      expect(updated.startTime, isNull);
      expect(updated.time, isNull);
      // 다른 필드는 유지
      expect(updated.title, todo.title);
      expect(updated.memo, todo.memo);
    });

    test('copyWith clearMemo가 memo를 null로 초기화한다', () {
      final updated = todo.copyWith(clearMemo: true);
      expect(updated.memo, isNull);
      expect(updated.title, todo.title);
    });

    test('time getter가 startTime의 별칭이다', () {
      expect(todo.time, todo.startTime);
      expect(todo.time?.hour, 14);
      expect(todo.time?.minute, 30);
    });

    test('colorIndex getter가 0을 반환한다 (UI 호환)', () {
      expect(todo.colorIndex, 0);
    });

    test('startTime이 null일 때 toCreateMap에서 null로 직렬화된다', () {
      final freshTodo = Todo(
        id: 'todo-x',
        title: 'no time',
        date: testDate,
        createdAt: testCreatedAt,
      );
      expect(freshTodo.toCreateMap()['start_time'], isNull);
    });
  });

  group('Todo 모델 - 경계값 테스트', () {
    test('title 200자가 정상 처리된다', () {
      final longTitle = 'A' * 200;
      final todo = Todo(
        id: 'edge-3',
        title: longTitle,
        date: testDate,
        createdAt: testCreatedAt,
      );
      expect(todo.title.length, 200);
      final map = todo.toCreateMap();
      expect((map['title'] as String).length, 200);
    });

    test('빈 문자열 title이 저장된다', () {
      final todo = Todo(
        id: 'edge-4',
        title: '',
        date: testDate,
        createdAt: testCreatedAt,
      );
      expect(todo.title, '');
    });

    test('자정(00:00) 시간이 정상 직렬화된다', () {
      final todo = Todo(
        id: 'edge-5',
        title: '자정',
        date: testDate,
        startTime: const TimeOfDay(hour: 0, minute: 0),
        createdAt: testCreatedAt,
      );
      expect(todo.toCreateMap()['start_time'], '00:00:00');
    });

    test('23:59 시간이 정상 직렬화된다', () {
      final todo = Todo(
        id: 'edge-6',
        title: '하루 끝',
        date: testDate,
        startTime: const TimeOfDay(hour: 23, minute: 59),
        createdAt: testCreatedAt,
      );
      expect(todo.toCreateMap()['start_time'], '23:59:00');
    });

    test('하루 시작(00:00:00) 날짜가 올바르게 처리된다', () {
      final startOfDay = DateTime(2026, 3, 9, 0, 0, 0);
      final todo = Todo(
        id: 'edge-7',
        title: '시작',
        date: startOfDay,
        createdAt: testCreatedAt,
      );
      expect(todo.date.hour, 0);
      expect(todo.date.minute, 0);
    });
  });
}
