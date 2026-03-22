// F3: 투두 Riverpod Provider (Single Source of Truth 아키텍처)
// allTodosRawProvider를 단일 데이터 소스로 사용하여 모든 파생 Provider가 동기화된다.
// CRUD 후 todoDataVersionProvider를 증가시키면 전체 파생 체인이 자동 갱신된다.
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/providers/data_store_providers.dart';
import '../../../core/providers/global_providers.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/models/event.dart' show Event, EventType;
import '../../../shared/models/habit.dart';
import '../../../shared/models/habit_log.dart';
import '../../../shared/models/routine.dart';
import '../../../shared/models/todo.dart';
import '../../../shared/providers/tag_provider.dart';
import '../../achievement/providers/achievement_provider.dart';
import '../../timer/models/timer_log.dart';
import '../../timer/providers/timer_provider.dart';
import '../../../core/calendar_sync/calendar_sync_provider.dart';
import '../services/todo_repository.dart';
import '../services/todo_filter.dart';

// ─── 날짜 선택 Provider ─────────────────────────────────────────────────────

/// 투두 탭에서 선택된 날짜 Provider
/// 초기값: 공유 todayDateProvider에서 가져온 오늘 날짜 (자정 경계 불일치 방지)
final selectedDateProvider = StateProvider<DateTime>((ref) {
  return ref.read(todayDateProvider);
});

// ─── 서브탭 Provider ────────────────────────────────────────────────────────

/// 투두 서브탭 유형
enum TodoSubTab {
  /// 일정표 (타임라인)
  dailySchedule,

  /// 주간 루틴 (신규)
  weeklyRoutine,

  /// 할 일 (체크리스트)
  todoList,
}

/// 투두 서브탭 Provider
/// dailySchedule / todoList 전환
final todoSubTabProvider = StateProvider<TodoSubTab>((ref) {
  return TodoSubTab.dailySchedule;
});

// ─── Repository Provider ────────────────────────────────────────────────────

/// TodoRepository Provider (로컬 퍼스트)
/// HiveCacheService를 주입받아 로컬 Hive 저장소에 접근한다
final todoRepositoryProvider = Provider<TodoRepository>((ref) {
  final cache = ref.watch(hiveCacheServiceProvider);
  return TodoRepository(cache: cache);
});

// ─── 투두 목록 Provider (Single Source of Truth에서 파생) ──────────────────

/// 선택된 날짜의 투두 목록 Provider (동기 Provider)
/// P1-2: allTodosRawProvider가 동기 Provider이므로 FutureProvider로 래핑할 필요가 없다
/// 불필요한 async 오버헤드와 loading 상태 발생을 제거한다
/// todoDataVersionProvider 변경 → allTodosRawProvider 재평가 → 이 Provider 자동 갱신
final todosForDateProvider = Provider<List<Todo>>((ref) {
  final selectedDate = ref.watch(selectedDateProvider);
  // Single Source of Truth: allTodosRawProvider에서 파생한다
  final allTodos = ref.watch(allTodosRawProvider);
  final dateStr = AppDateUtils.toDateString(selectedDate);

  // 해당 날짜의 투두만 필터링한다
  // 백업 복원 데이터는 camelCase('scheduledDate')를 사용할 수 있으므로 양쪽 키를 확인한다
  final filtered = allTodos
      .where((m) =>
          ((m['scheduled_date'] ?? m['scheduledDate']) as String?)
              ?.startsWith(dateStr) ==
          true)
      .toList();

  // display_order 오름차순 정렬
  final todos = filtered.map((m) => Todo.fromMap(m)).toList();
  todos.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
  return todos;
});

// ─── 통계 Provider ─────────────────────────────────────────────────────────

/// 현재 날짜 투두 통계 파생 Provider (F3.3 TodoStatsCalculator)
/// P2-2: filteredTodosProvider 기반으로 계산하여 태그 필터와 일관성을 유지한다
final todoStatsProvider = Provider<TodoStats>((ref) {
  final filtered = ref.watch(filteredTodosProvider);
  return TodoFilter.calculateStats(filtered);
});

// ─── 정렬된 투두 Provider ───────────────────────────────────────────────────

/// 정렬된 투두 목록 Provider (완료 항목 하단 배치)
/// P1-2: todosForDateProvider가 동기 Provider로 변경되어 .when() 제거
final sortedTodosProvider = Provider<List<Todo>>((ref) {
  final todos = ref.watch(todosForDateProvider);
  return TodoFilter.sortTodos(todos);
});

// ─── 태그 필터링 투두 Provider ──────────────────────────────────────────────

/// 태그 필터가 적용된 투두 목록 Provider
/// selectedTagFilterProvider가 비어 있으면 전체 목록을 반환한다.
/// 하나 이상의 태그가 선택된 경우, 해당 태그 중 하나라도 포함된 투두를 반환한다 (OR 방식).
final filteredTodosProvider = Provider<List<Todo>>((ref) {
  final todos = ref.watch(sortedTodosProvider);
  final selectedTagIds = ref.watch(selectedTagFilterProvider);

  // 필터 없음: 전체 목록 반환
  if (selectedTagIds.isEmpty) return todos;

  // 선택된 태그 중 하나라도 포함된 투두만 반환한다 (OR 필터)
  return todos.where((todo) {
    return todo.tagIds.any((tagId) => selectedTagIds.contains(tagId));
  }).toList();
});

// ─── 투두 CRUD 액션 Provider ────────────────────────────────────────────────

/// 투두 생성 액션
/// 로컬 Hive에 즉시 저장하고 버전 카운터를 증가시켜 전체 파생 Provider를 갱신한다
final createTodoProvider = Provider<Future<void> Function(Todo)>((ref) {
  final repository = ref.watch(todoRepositoryProvider);

  return (Todo todo) async {
    try {
      await repository.createTodo(todo);
      // 버전 카운터 증가 → allTodosRawProvider 재평가 → 홈/캘린더/투두 탭 모두 자동 갱신
      ref.read(todoDataVersionProvider.notifier).state++;
    } catch (e) {
      rethrow;
    }
  };
});

/// 투두 완료 상태 설정 액션
/// isCompleted 파라미터를 그대로 전달하여 원하는 상태로 설정한다
final toggleTodoProvider =
    Provider<Future<void> Function(String, bool)>((ref) {
  final repository = ref.watch(todoRepositoryProvider);

  return (String todoId, bool isCompleted) async {
    try {
      await repository.toggleTodoCompleted(todoId, isCompleted: isCompleted);
      // 버전 카운터 증가 → 홈/캘린더/투두 탭 모두 자동 갱신
      ref.read(todoDataVersionProvider.notifier).state++;

      // 완료로 전환된 경우 업적 달성 조건을 확인한다
      if (isCompleted) {
        await checkAchievementsAndNotify(ref);
      }
    } catch (e) {
      rethrow;
    }
  };
});

/// 투두 수정 액션
/// 기존 투두의 필드를 업데이트하고 버전 카운터를 증가시킨다
final updateTodoProvider = Provider<Future<void> Function(String, Todo)>((ref) {
  final repository = ref.watch(todoRepositoryProvider);

  return (String todoId, Todo todo) async {
    try {
      await repository.updateTodo(todoId, todo);
      // 버전 카운터 증가 → 모든 파생 Provider 자동 갱신
      ref.read(todoDataVersionProvider.notifier).state++;
    } catch (e) {
      rethrow;
    }
  };
});

/// 투두 삭제 액션
final deleteTodoProvider = Provider<Future<void> Function(String)>((ref) {
  final repository = ref.watch(todoRepositoryProvider);
  final timerRepository = ref.watch(timerRepositoryProvider);

  return (String todoId) async {
    try {
      // V3-010: 고아 타이머 로그 정리를 TimerRepository에 위임한다
      await timerRepository.deleteLogsByTodoId(todoId);

      await repository.deleteTodo(todoId);
      // 버전 카운터 증가 → 모든 파생 Provider 자동 갱신
      ref.read(todoDataVersionProvider.notifier).state++;
      // 타이머 로그도 변경되었으므로 타이머 버전도 증가시킨다
      ref.read(timerLogDataVersionProvider.notifier).state++;
    } catch (e) {
      rethrow;
    }
  };
});

/// 새 투두 ID 생성 헬퍼
final generateTodoIdProvider = Provider<String Function()>((ref) {
  return () {
    return const Uuid().v4();
  };
});

// ─── 년/월 피커 Provider ────────────────────────────────────────────────────

/// 투두 화면 헤더의 년/월 표시용 포커스 날짜
/// selectedDateProvider와 동기화된다
final todoFocusedMonthProvider = StateProvider<DateTime>((ref) {
  final selected = ref.watch(selectedDateProvider);
  return DateTime(selected.year, selected.month, 1);
});

// ─── 캘린더 이벤트 → 타임라인 통합 Provider ─────────────────────────────────

/// 투두 탭의 선택된 날짜에 해당하는 캘린더 이벤트를 Todo 형태로 변환한다
/// 앱 이벤트 + Google Calendar 이벤트를 모두 포함한다
/// 종일 이벤트와 투두 소스('todo' 타입)는 제외하여 중복을 방지한다
/// id 접두사 'cal_'로 캘린더 출처 항목을 구별한다
final calendarEventsForTimelineProvider = Provider<List<Todo>>((ref) {
  final selectedDate = ref.watch(selectedDateProvider);
  // Single Source of Truth: allEventsRawProvider에서 직접 파생하여 Hive 이중 읽기를 제거한다
  final allEventsRaw = ref.watch(allEventsRawProvider);

  final target = DateTime(
    selectedDate.year,
    selectedDate.month,
    selectedDate.day,
  );

  // ── 1. 앱 로컬 이벤트 (allEventsRawProvider에서 인메모리 필터링) ─────────
  final events = allEventsRaw.map((m) => Event.fromMap(m)).toList();

  // 선택된 날짜에 해당하는 이벤트만 필터링한다
  final dayEvents = events.where((event) {
    final eventDay = DateTime(
      event.startDate.year,
      event.startDate.month,
      event.startDate.day,
    );

    // 범위 이벤트: 시작~종료 범위 내 날짜 포함
    if (event.endDate != null) {
      final endDay = DateTime(
        event.endDate!.year,
        event.endDate!.month,
        event.endDate!.day,
      );
      return !target.isBefore(eventDay) && !target.isAfter(endDay);
    }
    return eventDay == target;
  }).where((event) {
    if (event.allDay) return false;
    if (event.eventType == EventType.todo) return false;
    final hour = event.startDate.hour;
    final minute = event.startDate.minute;
    if (hour == 0 && minute == 0 && event.endDate == null) return false;
    return true;
  });

  // Event → Todo 변환 (타임라인 레이아웃 호환)
  final appTodos = dayEvents.map((event) {
    return Todo(
      id: 'cal_${event.id}',
      title: event.title,
      date: selectedDate,
      startTime: TimeOfDay(
        hour: event.startDate.hour,
        minute: event.startDate.minute,
      ),
      endTime: event.endDate != null
          ? TimeOfDay(
              hour: event.endDate!.hour,
              minute: event.endDate!.minute,
            )
          : null,
      isCompleted: false,
      color: event.colorIndex.toString(),
      memo: event.memo,
      createdAt: event.createdAt,
    );
  }).toList();

  // ── 2. Google Calendar 이벤트 ─────────────────────────────────────────────
  // googleCalendarEventsProvider를 watch하여 Google 이벤트도 타임라인에 통합한다
  final googleEventsAsync = ref.watch(googleCalendarEventsProvider);
  final googleEvents = googleEventsAsync.valueOrNull ?? const [];

  // 선택된 날짜에 해당하는 Google 이벤트만 필터링한다
  final googleTodos = googleEvents.where((e) {
    final eventDay = DateTime(e.startDate.year, e.startDate.month, e.startDate.day);
    // 범위 이벤트: 선택된 날짜가 시작~종료 범위 내에 있으면 포함한다
    if (e.endDate != null) {
      final endDay = DateTime(e.endDate!.year, e.endDate!.month, e.endDate!.day);
      return !target.isBefore(eventDay) && !target.isAfter(endDay);
    }
    return eventDay == target;
  }).where((e) {
    // 종일 이벤트는 타임라인에 표시하지 않는다
    if (e.isAllDay) return false;
    // 시간이 없는 이벤트도 제외한다
    if (e.startHour == null && e.startMinute == null) return false;
    return true;
  }).map((e) {
    return Todo(
      id: 'gcal_${e.id}',
      title: e.title,
      date: selectedDate,
      startTime: TimeOfDay(
        hour: e.startHour ?? 0,
        minute: e.startMinute ?? 0,
      ),
      endTime: (e.endHour != null)
          ? TimeOfDay(hour: e.endHour!, minute: e.endMinute ?? 0)
          : null,
      isCompleted: false,
      color: e.colorIndex.toString(),
      memo: e.memo,
      createdAt: e.startDate,
    );
  }).toList();

  // 앱 이벤트 + Google 이벤트를 병합하여 반환한다
  return [...appTodos, ...googleTodos];
});

// ─── 루틴 → 타임라인 통합 Provider ──────────────────────────────────────────

/// 투두 탭의 선택된 날짜에 해당하는 루틴을 Todo 형태로 변환한다
/// 타임라인 레이아웃과 호환되도록 id 접두사 'routine_'으로 구별한다
final routinesForTimelineProvider = Provider<List<Todo>>((ref) {
  final selectedDate = ref.watch(selectedDateProvider);
  final allRoutinesRaw = ref.watch(allRoutinesRawProvider);
  final weekday = selectedDate.weekday;

  // 활성 루틴 중 해당 요일에 예정된 루틴만 필터링한다
  final activeRoutines = allRoutinesRaw
      .map((map) => Routine.fromMap(map))
      .where((r) => r.isActive && r.repeatDays.contains(weekday))
      .toList();

  // Routine → Todo 변환 (타임라인 레이아웃 호환)
  return activeRoutines.map((routine) {
    return Todo(
      id: 'routine_${routine.id}',
      title: routine.name,
      date: selectedDate,
      startTime: routine.startTime,
      endTime: routine.endTime,
      isCompleted: false,
      color: routine.colorIndex.toString(),
      createdAt: routine.createdAt,
    );
  }).toList();
});

// ─── 타이머 세션 → 타임라인 통합 Provider ───────────────────────────────────

/// 투두 탭의 선택된 날짜에 해당하는 타이머 집중 세션을 Todo 형태로 변환한다
/// id 접두사 'timer_'으로 타이머 출처 항목을 구별한다
final timerLogsForTimelineProvider = Provider<List<Todo>>((ref) {
  final selectedDate = ref.watch(selectedDateProvider);
  final allTimerLogsRaw = ref.watch(allTimerLogsRawProvider);
  final dateStr = AppDateUtils.toDateString(selectedDate);

  final todos = <Todo>[];
  for (final logMap in allTimerLogsRaw) {
    final log = TimerLog.fromMap(logMap);
    // 집중 세션만 타임라인에 표시한다
    if (log.type != TimerSessionType.focus) continue;
    // 선택된 날짜의 로그만 필터링한다
    if (AppDateUtils.toDateString(log.startTime) != dateStr) continue;

    final durationMinutes = log.durationSeconds ~/ 60;
    final endTotalMinutes =
        log.startTime.hour * 60 + log.startTime.minute + durationMinutes;
    // 총 분을 먼저 클램프한 뒤 시/분을 산출한다 (24시간 초과 방지)
    final clampedMinutes = endTotalMinutes.clamp(0, 24 * 60 - 1);
    final endHour = clampedMinutes ~/ 60;
    final endMinute = clampedMinutes % 60;

    todos.add(Todo(
      id: 'timer_${log.id}',
      title: log.todoTitle ?? '집중 세션',
      date: selectedDate,
      startTime: TimeOfDay(
        hour: log.startTime.hour,
        minute: log.startTime.minute,
      ),
      endTime: TimeOfDay(hour: endHour, minute: endMinute),
      isCompleted: false,
      color: '3', // 초록 계열 — 타이머 세션에 적합
      createdAt: log.createdAt,
    ));
  }

  return todos;
});

// ─── 습관 → 투두 탭 통합 Provider ────────────────────────────────────────────

/// 투두 탭의 선택된 날짜에 해당하는 습관 체크리스트 Provider
/// 캘린더 DailyView의 habitsForDayProvider와 동일한 로직이지만
/// selectedDateProvider(투두 탭 날짜)를 기준으로 한다
final habitsForTodoDateProvider =
    Provider<List<({Habit habit, bool isCompleted})>>((ref) {
  final selectedDate = ref.watch(selectedDateProvider);
  final allHabitsRaw = ref.watch(allHabitsRawProvider);
  final allHabitLogsRaw = ref.watch(allHabitLogsRawProvider);

  // 활성 습관 중 해당 날짜에 예정된 것만 필터링한다
  final activeHabits = allHabitsRaw
      .map((m) => Habit.fromMap(m))
      .where((h) => h.isActive && h.isScheduledFor(selectedDate))
      .toList();

  if (activeHabits.isEmpty) return const [];

  // 해당 날짜의 완료된 습관 ID 집합을 구한다
  final dateStr = AppDateUtils.toDateString(selectedDate);
  final completedHabitIds = <String>{};
  for (final logMap in allHabitLogsRaw) {
    final log = HabitLog.fromMap(logMap);
    if (log.isCompleted && AppDateUtils.toDateString(log.date) == dateStr) {
      completedHabitIds.add(log.habitId);
    }
  }

  return activeHabits
      .map((h) => (habit: h, isCompleted: completedHabitIds.contains(h.id)))
      .toList();
});
