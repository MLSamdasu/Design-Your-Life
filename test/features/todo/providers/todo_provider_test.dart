// TodoProvider 단위 테스트
// StateProvider, 파생 Provider의 초기값과 상태 변경을 검증한다.
// API 의존 Provider는 override로 격리하여 테스트한다.
// P1-2: todosForDateProvider가 동기 Provider로 변경됨에 따라 테스트 업데이트
import 'package:design_your_life/features/todo/providers/todo_provider.dart';
import 'package:design_your_life/shared/models/todo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('selectedDateProvider', () {
    test('초기값은 오늘 날짜이다 (시간 제거)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final selectedDate = container.read(selectedDateProvider);
      final now = DateTime.now();

      expect(selectedDate.year, now.year);
      expect(selectedDate.month, now.month);
      expect(selectedDate.day, now.day);
      expect(selectedDate.hour, 0);
      expect(selectedDate.minute, 0);
    });

    test('날짜를 변경할 수 있다', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final newDate = DateTime(2026, 6, 15);
      container.read(selectedDateProvider.notifier).state = newDate;

      expect(container.read(selectedDateProvider), newDate);
    });

    test('다른 날짜로 여러 번 변경할 수 있다', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final date1 = DateTime(2026, 1, 1);
      final date2 = DateTime(2026, 12, 31);

      container.read(selectedDateProvider.notifier).state = date1;
      expect(container.read(selectedDateProvider), date1);

      container.read(selectedDateProvider.notifier).state = date2;
      expect(container.read(selectedDateProvider), date2);
    });
  });

  group('todoSubTabProvider', () {
    test('초기값은 dailySchedule이다', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(todoSubTabProvider), TodoSubTab.dailySchedule);
    });

    test('todoList로 전환할 수 있다', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(todoSubTabProvider.notifier).state = TodoSubTab.todoList;

      expect(container.read(todoSubTabProvider), TodoSubTab.todoList);
    });

    test('dailySchedule으로 다시 전환할 수 있다', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(todoSubTabProvider.notifier).state = TodoSubTab.todoList;
      container.read(todoSubTabProvider.notifier).state = TodoSubTab.dailySchedule;

      expect(container.read(todoSubTabProvider), TodoSubTab.dailySchedule);
    });
  });

  group('todoFocusedMonthProvider', () {
    test('selectedDateProvider와 동기화된다', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final selectedDate = container.read(selectedDateProvider);
      final focusedMonth = container.read(todoFocusedMonthProvider);

      expect(focusedMonth.year, selectedDate.year);
      expect(focusedMonth.month, selectedDate.month);
      expect(focusedMonth.day, 1);
    });

    test('selectedDate 변경 시 focusedMonth가 갱신된다', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(selectedDateProvider.notifier).state = DateTime(2026, 8, 25);
      final focusedMonth = container.read(todoFocusedMonthProvider);

      expect(focusedMonth.year, 2026);
      expect(focusedMonth.month, 8);
      expect(focusedMonth.day, 1);
    });
  });

  group('todoStatsProvider', () {
    test('todosForDateProvider가 빈 목록일 때 빈 통계를 반환한다', () {
      final container = ProviderContainer(
        overrides: [
          todosForDateProvider.overrideWith(
            (ref) => <Todo>[],
          ),
        ],
      );
      addTearDown(container.dispose);

      final stats = container.read(todoStatsProvider);

      expect(stats.totalCount, 0);
      expect(stats.completedCount, 0);
      expect(stats.completionRate, 0);
    });

    test('todosForDateProvider에 데이터가 있을 때 통계를 계산한다', () {
      final testTodos = [
        Todo(
          id: 't1',
          title: '할 일 1',
          date: DateTime(2026, 3, 9),
          isCompleted: true,
          createdAt: DateTime(2026, 3, 9),
        ),
        Todo(
          id: 't2',
          title: '할 일 2',
          date: DateTime(2026, 3, 9),
          isCompleted: false,
          createdAt: DateTime(2026, 3, 9),
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          todosForDateProvider.overrideWith(
            (ref) => testTodos,
          ),
        ],
      );
      addTearDown(container.dispose);

      final stats = container.read(todoStatsProvider);

      expect(stats.totalCount, 2);
      expect(stats.completedCount, 1);
      expect(stats.completionRate, 50.0);
    });

    test('모든 투두가 완료되었을 때 completionRate가 100이다', () {
      final testTodos = [
        Todo(
          id: 't1',
          title: '할 일',
          date: DateTime(2026, 3, 9),
          isCompleted: true,
          createdAt: DateTime(2026, 3, 9),
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          todosForDateProvider.overrideWith(
            (ref) => testTodos,
          ),
        ],
      );
      addTearDown(container.dispose);

      final stats = container.read(todoStatsProvider);

      expect(stats.completionRate, 100.0);
    });
  });

  group('sortedTodosProvider', () {
    test('todosForDateProvider가 빈 목록일 때 빈 리스트를 반환한다', () {
      final container = ProviderContainer(
        overrides: [
          todosForDateProvider.overrideWith(
            (ref) => <Todo>[],
          ),
        ],
      );
      addTearDown(container.dispose);

      final sorted = container.read(sortedTodosProvider);

      expect(sorted, isEmpty);
    });

    test('미완료 항목이 완료 항목보다 앞에 정렬된다', () {
      final testTodos = [
        Todo(
          id: 't1',
          title: '완료',
          date: DateTime(2026, 3, 9),
          isCompleted: true,
          createdAt: DateTime(2026, 3, 9),
        ),
        Todo(
          id: 't2',
          title: '미완료',
          date: DateTime(2026, 3, 9),
          isCompleted: false,
          createdAt: DateTime(2026, 3, 9),
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          todosForDateProvider.overrideWith(
            (ref) => testTodos,
          ),
        ],
      );
      addTearDown(container.dispose);

      final sorted = container.read(sortedTodosProvider);

      expect(sorted.first.title, '미완료');
      expect(sorted.last.title, '완료');
    });

    test('시간이 있는 항목이 없는 항목보다 앞에 온다', () {
      final testTodos = [
        Todo(
          id: 't1',
          title: '시간 없음',
          date: DateTime(2026, 3, 9),
          createdAt: DateTime(2026, 3, 9),
        ),
        Todo(
          id: 't2',
          title: '시간 있음',
          date: DateTime(2026, 3, 9),
          startTime: const TimeOfDay(hour: 10, minute: 0),
          createdAt: DateTime(2026, 3, 9),
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          todosForDateProvider.overrideWith(
            (ref) => testTodos,
          ),
        ],
      );
      addTearDown(container.dispose);

      final sorted = container.read(sortedTodosProvider);

      expect(sorted.first.title, '시간 있음');
    });
  });

  group('TodoSubTab enum', () {
    test('dailySchedule 값이 존재한다', () {
      expect(TodoSubTab.dailySchedule, isNotNull);
    });

    test('todoList 값이 존재한다', () {
      expect(TodoSubTab.todoList, isNotNull);
    });

    test('weeklyRoutine 값이 존재한다', () {
      expect(TodoSubTab.weeklyRoutine, isNotNull);
    });

    test('values에 3개 항목이 있다', () {
      expect(TodoSubTab.values.length, 3);
    });
  });
}
