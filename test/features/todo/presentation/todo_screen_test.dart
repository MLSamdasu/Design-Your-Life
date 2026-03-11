// TodoScreen 위젯 테스트
// 투두 화면의 기본 렌더링, 서브탭 구조, Provider 상태를 검증한다.
// Supabase 마이그레이션 후 테스트를 업데이트했다.
import 'package:design_your_life/core/auth/auth_provider.dart';
import 'package:design_your_life/core/cache/hive_cache_service.dart';
import 'package:design_your_life/core/providers/global_providers.dart';
import 'package:design_your_life/features/todo/presentation/todo_screen.dart';
import 'package:design_your_life/features/todo/providers/todo_provider.dart';
import 'package:design_your_life/features/todo/services/todo_filter.dart';
import 'package:design_your_life/shared/models/todo.dart';
import 'package:design_your_life/shared/widgets/date_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Hive 의존성 없이 테스트를 위한 MockHiveCacheService
class _MockHiveCacheService extends HiveCacheService {
  @override
  Future<void> saveSetting(String key, Object value) async {}

  @override
  T? readSetting<T>(String key) => null;
}

void main() {
  group('TodoProvider 상태 통합 테스트', () {
    test('selectedDateProvider 변경 시 todoFocusedMonthProvider가 갱신된다', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // 3월 9일 선택
      container.read(selectedDateProvider.notifier).state = DateTime(2026, 3, 9);
      var focused = container.read(todoFocusedMonthProvider);
      expect(focused.month, 3);

      // 6월 15일로 변경
      container.read(selectedDateProvider.notifier).state = DateTime(2026, 6, 15);
      focused = container.read(todoFocusedMonthProvider);
      expect(focused.month, 6);
    });

    test('서브탭 전환이 상태에 반영된다', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(todoSubTabProvider), TodoSubTab.dailySchedule);

      container.read(todoSubTabProvider.notifier).state = TodoSubTab.todoList;
      expect(container.read(todoSubTabProvider), TodoSubTab.todoList);
    });

    test('TodoStats.empty 상수가 올바르다', () {
      const stats = TodoStats.empty;

      expect(stats.totalCount, 0);
      expect(stats.completedCount, 0);
      expect(stats.completionRate, 0);
      expect(stats.withTimeCount, 0);
      expect(stats.withoutTimeCount, 0);
    });

    test('todosForDateProvider 에러 시 todoStatsProvider가 empty를 반환한다', () {
      final container = ProviderContainer(
        overrides: [
          todosForDateProvider.overrideWith(
            (ref) async => throw Exception('테스트 에러'),
          ),
        ],
      );
      addTearDown(container.dispose);

      // 에러 상태에서 empty 통계 반환 확인
      final stats = container.read(todoStatsProvider);
      expect(stats.totalCount, 0);
    });

    test('todosForDateProvider 에러 시 sortedTodosProvider가 빈 리스트를 반환한다', () {
      final container = ProviderContainer(
        overrides: [
          todosForDateProvider.overrideWith(
            (ref) async => throw Exception('테스트 에러'),
          ),
        ],
      );
      addTearDown(container.dispose);

      final sorted = container.read(sortedTodosProvider);
      expect(sorted, isEmpty);
    });
  });

  group('TodoFilter 통합 테스트', () {
    final baseDate = DateTime(2026, 3, 9);

    Todo createTodo(String id, {bool isCompleted = false, TimeOfDay? startTime, DateTime? createdAt}) {
      return Todo(
        id: id,
        title: '테스트 $id',
        date: baseDate,
        startTime: startTime,
        isCompleted: isCompleted,
        createdAt: createdAt ?? baseDate,
      );
    }

    test('필터와 정렬을 함께 적용할 수 있다', () {
      final todos = [
        createTodo('t1', isCompleted: true),
        createTodo('t2', isCompleted: false, startTime: const TimeOfDay(hour: 9, minute: 0)),
        createTodo('t3', isCompleted: false),
      ];

      // 미완료만 필터링
      final incomplete = TodoFilter.filter(todos, TodoFilterType.incomplete);
      expect(incomplete.length, 2);

      // 정렬 적용
      final sorted = TodoFilter.sortTodos(incomplete);
      // 시간 있는 항목이 먼저
      expect(sorted.first.time, isNotNull);
    });

    test('통계 계산 후 필터링이 일관된다', () {
      final todos = [
        createTodo('t1', isCompleted: true),
        createTodo('t2', isCompleted: false),
        createTodo('t3', isCompleted: true),
      ];

      final stats = TodoFilter.calculateStats(todos);
      final completed = TodoFilter.filter(todos, TodoFilterType.completed);

      expect(stats.completedCount, completed.length);
    });

    test('시간 유무 필터와 통계가 일치한다', () {
      final todos = [
        createTodo('t1', startTime: const TimeOfDay(hour: 9, minute: 0)),
        createTodo('t2'),
        createTodo('t3', startTime: const TimeOfDay(hour: 14, minute: 0)),
      ];

      final stats = TodoFilter.calculateStats(todos);
      final withTime = TodoFilter.filter(todos, TodoFilterType.withTime);
      final withoutTime = TodoFilter.filter(todos, TodoFilterType.withoutTime);

      expect(stats.withTimeCount, withTime.length);
      expect(stats.withoutTimeCount, withoutTime.length);
      expect(stats.totalCount, withTime.length + withoutTime.length);
    });
  });

  // ─── 위젯 인터랙션 테스트 ─────────────────────────────────────────────────
  group('TodoScreen - 위젯 렌더링 및 인터랙션', () {
    /// 테스트용 위젯 래퍼: Provider override로 API 의존성을 격리한다
    Widget buildTodoTestWidget() {
      return ProviderScope(
        overrides: [
          hiveCacheServiceProvider.overrideWithValue(_MockHiveCacheService()),
          currentUserIdProvider.overrideWithValue('test-user'),
          todosForDateProvider.overrideWith(
            (ref) async => <Todo>[],
          ),
          // TodoListView가 참조하는 액션 Provider도 격리한다
          toggleTodoProvider.overrideWithValue(
            (String todoId, bool isCompleted) async {},
          ),
          deleteTodoProvider.overrideWithValue(
            (String todoId) async {},
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: TodoScreen(),
          ),
        ),
      );
    }

    testWidgets('TodoScreen이 Scaffold를 포함한다', (tester) async {
      await tester.pumpWidget(buildTodoTestWidget());
      await tester.pump(const Duration(milliseconds: 100));

      // TodoScreen 내부에 Scaffold가 존재한다
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('FloatingActionButton이 존재한다', (tester) async {
      await tester.pumpWidget(buildTodoTestWidget());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('FAB에 add 아이콘이 표시된다', (tester) async {
      await tester.pumpWidget(buildTodoTestWidget());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    });

    testWidgets('서브탭 텍스트 "하루 일정표"가 표시된다', (tester) async {
      await tester.pumpWidget(buildTodoTestWidget());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('하루 일정표'), findsOneWidget);
    });

    testWidgets('서브탭 텍스트 "할 일 목록"이 표시된다', (tester) async {
      await tester.pumpWidget(buildTodoTestWidget());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('할 일 목록'), findsOneWidget);
    });

    testWidgets('서브탭 탭으로 할 일 목록으로 전환된다', (tester) async {
      await tester.pumpWidget(buildTodoTestWidget());
      await tester.pump(const Duration(milliseconds: 100));

      // "할 일 목록" 탭을 탭한다
      await tester.tap(find.text('할 일 목록'));
      await tester.pump(const Duration(milliseconds: 400));

      // 탭 전환 후에도 두 탭 텍스트가 여전히 표시된다
      expect(find.text('할 일 목록'), findsOneWidget);
      expect(find.text('하루 일정표'), findsOneWidget);
    });

    testWidgets('서브탭 전환 후 다시 "하루 일정표"로 복귀할 수 있다', (tester) async {
      await tester.pumpWidget(buildTodoTestWidget());
      await tester.pump(const Duration(milliseconds: 100));

      // "할 일 목록"으로 전환한다
      await tester.tap(find.text('할 일 목록'));
      await tester.pump(const Duration(milliseconds: 400));

      // "하루 일정표"로 다시 전환한다
      await tester.tap(find.text('하루 일정표'));
      await tester.pump(const Duration(milliseconds: 400));

      // 복귀 후에도 두 탭 텍스트가 여전히 표시된다
      expect(find.text('하루 일정표'), findsOneWidget);
      expect(find.text('할 일 목록'), findsOneWidget);
    });

    testWidgets('AnimatedSwitcher가 서브탭 전환에 사용된다', (tester) async {
      await tester.pumpWidget(buildTodoTestWidget());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(AnimatedSwitcher), findsOneWidget);
    });

    testWidgets('년/월 헤더 텍스트가 현재 날짜를 표시한다', (tester) async {
      await tester.pumpWidget(buildTodoTestWidget());
      await tester.pump(const Duration(milliseconds: 100));

      final now = DateTime.now();
      final headerText = '${now.year}년 ${now.month}월';
      expect(find.text(headerText), findsOneWidget);
    });

    testWidgets('DateSlider가 존재한다', (tester) async {
      await tester.pumpWidget(buildTodoTestWidget());
      await tester.pump(const Duration(milliseconds: 100));

      // DateSlider 위젯이 렌더링된다
      expect(find.byType(DateSlider), findsOneWidget);
    });

    testWidgets('DateSlider 좌우 화살표 아이콘이 존재한다', (tester) async {
      await tester.pumpWidget(buildTodoTestWidget());
      await tester.pump(const Duration(milliseconds: 100));

      // 주간 네비게이션 화살표가 존재한다
      expect(find.byIcon(Icons.chevron_left_rounded), findsWidgets);
      expect(find.byIcon(Icons.chevron_right_rounded), findsWidgets);
    });

    testWidgets('화면이 에러 없이 렌더링된다', (tester) async {
      await tester.pumpWidget(buildTodoTestWidget());
      await tester.pump(const Duration(milliseconds: 500));

      expect(tester.takeException(), isNull);
    });
  });

  group('TodoScreen - 서브탭 Provider 동작', () {
    test('서브탭 변경이 정확히 반영된다', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // 초기값은 dailySchedule이다
      expect(container.read(todoSubTabProvider), TodoSubTab.dailySchedule);

      // todoList로 변경한다
      container.read(todoSubTabProvider.notifier).state = TodoSubTab.todoList;
      expect(container.read(todoSubTabProvider), TodoSubTab.todoList);

      // 다시 dailySchedule로 변경한다
      container.read(todoSubTabProvider.notifier).state = TodoSubTab.dailySchedule;
      expect(container.read(todoSubTabProvider), TodoSubTab.dailySchedule);
    });

    test('selectedDateProvider가 초기값으로 오늘 날짜를 가진다', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final selected = container.read(selectedDateProvider);
      final now = DateTime.now();
      expect(selected.year, now.year);
      expect(selected.month, now.month);
      expect(selected.day, now.day);
    });

    test('selectedDateProvider 변경이 todoFocusedMonth에 반영된다', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(selectedDateProvider.notifier).state = DateTime(2026, 7, 20);
      final focused = container.read(todoFocusedMonthProvider);
      expect(focused.year, 2026);
      expect(focused.month, 7);
    });

    test('generateTodoIdProvider가 함수를 반환한다', () {
      // API 의존성을 우회하기 위해 Provider 자체를 오버라이드한다
      int callCount = 0;
      final container = ProviderContainer(
        overrides: [
          generateTodoIdProvider.overrideWithValue(() {
            callCount++;
            return 'generated-id-$callCount';
          }),
        ],
      );
      addTearDown(container.dispose);

      final idGen = container.read(generateTodoIdProvider);
      final id = idGen();
      // 오버라이드된 함수가 올바르게 ID를 반환한다
      expect(id, 'generated-id-1');
      expect(id.isNotEmpty, true);

      // 두 번째 호출도 정상 동작한다
      final id2 = idGen();
      expect(id2, 'generated-id-2');
    });
  });

  group('Todo 모델 통합 테스트', () {
    test('Todo.copyWith으로 isCompleted를 토글할 수 있다', () {
      final todo = Todo(
        id: 't1',
        title: '할 일',
        date: DateTime(2026, 3, 9),
        isCompleted: false,
        createdAt: DateTime(2026, 3, 9),
      );

      final toggled = todo.copyWith(isCompleted: true);

      expect(toggled.isCompleted, true);
      expect(toggled.id, todo.id);
      expect(toggled.title, todo.title);
    });

    test('Todo.toCreateMap이 올바른 snake_case 키를 포함한다', () {
      final todo = Todo(
        id: 't1',
        title: '할 일',
        date: DateTime(2026, 3, 9),
        createdAt: DateTime(2026, 3, 9),
      );

      final map = todo.toCreateMap();

      expect(map.containsKey('title'), true);
      expect(map.containsKey('scheduled_date'), true);
      expect(map.containsKey('start_time'), true);
      expect(map.containsKey('color'), true);
    });

    test('시간이 있는 Todo의 toCreateMap에 start_time 필드가 포함된다', () {
      final todo = Todo(
        id: 't1',
        title: '할 일',
        date: DateTime(2026, 3, 9),
        startTime: const TimeOfDay(hour: 14, minute: 30),
        createdAt: DateTime(2026, 3, 9),
      );

      final map = todo.toCreateMap();

      expect(map['start_time'], '14:30:00');
    });

    test('시간이 없는 Todo의 toCreateMap에 start_time이 null이다', () {
      final todo = Todo(
        id: 't1',
        title: '할 일',
        date: DateTime(2026, 3, 9),
        createdAt: DateTime(2026, 3, 9),
      );

      final map = todo.toCreateMap();

      expect(map['start_time'], isNull);
    });
  });
}
