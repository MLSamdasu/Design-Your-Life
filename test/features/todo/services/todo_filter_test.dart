// TodoFilter 순수 함수 테스트
// 필터링(전체/완료/미완료/시간 유무), 통계 계산, 정렬을 검증한다.
// 백엔드 TodoDto 대응 모델로 전환 후 테스트를 업데이트했다.
import 'package:design_your_life/features/todo/services/todo_filter.dart';
import 'package:design_your_life/shared/models/todo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2026, 3, 9);

/// 테스트용 Todo 생성 헬퍼
Todo _todo(
  String id, {
  bool isCompleted = false,
  TimeOfDay? startTime,
  DateTime? createdAt,
}) {
  return Todo(
    id: id,
    title: '테스트 $id',
    date: _now,
    startTime: startTime,
    isCompleted: isCompleted,
    createdAt: createdAt ?? _now,
  );
}

void main() {
  group('TodoFilter - filter', () {
    late List<Todo> todos;

    setUp(() {
      todos = [
        _todo('t1', isCompleted: true, startTime: const TimeOfDay(hour: 9, minute: 0)),
        _todo('t2', isCompleted: false, startTime: const TimeOfDay(hour: 14, minute: 0)),
        _todo('t3', isCompleted: false),
        _todo('t4', isCompleted: true),
      ];
    });

    test('all 필터가 전체 목록을 반환한다', () {
      final result = TodoFilter.filter(todos, TodoFilterType.all);
      expect(result.length, 4);
    });

    test('completed 필터가 완료된 항목만 반환한다', () {
      final result = TodoFilter.filter(todos, TodoFilterType.completed);
      expect(result.length, 2);
      expect(result.every((t) => t.isCompleted), true);
    });

    test('incomplete 필터가 미완료 항목만 반환한다', () {
      final result = TodoFilter.filter(todos, TodoFilterType.incomplete);
      expect(result.length, 2);
      expect(result.every((t) => !t.isCompleted), true);
    });

    test('withTime 필터가 시간 지정 항목만 반환한다', () {
      final result = TodoFilter.filter(todos, TodoFilterType.withTime);
      expect(result.length, 2);
      expect(result.every((t) => t.time != null), true);
    });

    test('withoutTime 필터가 시간 미지정 항목만 반환한다', () {
      final result = TodoFilter.filter(todos, TodoFilterType.withoutTime);
      expect(result.length, 2);
      expect(result.every((t) => t.time == null), true);
    });

    test('빈 목록에 필터를 적용해도 오류 없이 빈 목록을 반환한다', () {
      final result = TodoFilter.filter([], TodoFilterType.completed);
      expect(result.isEmpty, true);
    });
  });

  group('TodoFilter - calculateStats', () {
    test('빈 목록의 통계는 모두 0이다', () {
      final stats = TodoFilter.calculateStats([]);
      expect(stats.totalCount, 0);
      expect(stats.completedCount, 0);
      expect(stats.completionRate, 0.0);
    });

    test('전체 완료 시 completionRate가 100이다', () {
      final todos = [
        _todo('t1', isCompleted: true),
        _todo('t2', isCompleted: true),
      ];
      final stats = TodoFilter.calculateStats(todos);
      expect(stats.totalCount, 2);
      expect(stats.completedCount, 2);
      expect(stats.completionRate, 100.0);
    });

    test('전체 미완료 시 completionRate가 0이다', () {
      final todos = [_todo('t1'), _todo('t2')];
      final stats = TodoFilter.calculateStats(todos);
      expect(stats.completionRate, 0.0);
    });

    test('반 완료 시 completionRate가 50이다', () {
      final todos = [
        _todo('t1', isCompleted: true),
        _todo('t2'),
      ];
      final stats = TodoFilter.calculateStats(todos);
      expect(stats.completionRate, 50.0);
    });

    test('시간 유무 카운트가 정확하다', () {
      final todos = [
        _todo('t1', startTime: const TimeOfDay(hour: 9, minute: 0)),
        _todo('t2'),
        _todo('t3', startTime: const TimeOfDay(hour: 14, minute: 0)),
      ];
      final stats = TodoFilter.calculateStats(todos);
      expect(stats.withTimeCount, 2);
      expect(stats.withoutTimeCount, 1);
    });
  });

  group('TodoFilter - sortTodos', () {
    test('미완료 항목이 완료 항목보다 앞에 온다', () {
      final todos = [
        _todo('t1', isCompleted: true),
        _todo('t2', isCompleted: false),
      ];
      final sorted = TodoFilter.sortTodos(todos);
      expect(sorted.first.isCompleted, false);
      expect(sorted.last.isCompleted, true);
    });

    test('같은 완료 상태에서 시간 있는 항목이 먼저 온다', () {
      final todos = [
        _todo('t1'),
        _todo('t2', startTime: const TimeOfDay(hour: 10, minute: 0)),
      ];
      final sorted = TodoFilter.sortTodos(todos);
      expect(sorted.first.time, isNotNull);
    });

    test('빈 목록 정렬 시 오류가 발생하지 않는다', () {
      final sorted = TodoFilter.sortTodos([]);
      expect(sorted.isEmpty, true);
    });
  });

  group('TodoStats', () {
    test('empty 상수가 모두 0이다', () {
      expect(TodoStats.empty.totalCount, 0);
      expect(TodoStats.empty.completedCount, 0);
      expect(TodoStats.empty.completionRate, 0);
      expect(TodoStats.empty.withTimeCount, 0);
      expect(TodoStats.empty.withoutTimeCount, 0);
    });
  });
}
