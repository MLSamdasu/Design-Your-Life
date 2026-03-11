// F3: 투두 Riverpod Provider (로컬 퍼스트 아키텍처)
// todosForDateProvider: 날짜별 투두 목록 (FutureProvider)
// todoStatsProvider: 파생 통계 데이터 Provider
// filteredTodosProvider: selectedTagFilterProvider 기반 태그 필터링 결과
// HiveCacheService를 직접 주입한다.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/global_providers.dart';
import '../../../shared/models/todo.dart';
import '../../../shared/providers/tag_provider.dart';
import '../services/todo_repository.dart';
import '../services/todo_filter.dart';

// ─── 날짜 선택 Provider ─────────────────────────────────────────────────────

/// 투두 탭에서 선택된 날짜 Provider
/// 초기값: 오늘 날짜
final selectedDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

// ─── 서브탭 Provider ────────────────────────────────────────────────────────

/// 투두 서브탭 유형
enum TodoSubTab {
  /// 하루 일정표 (타임라인)
  dailySchedule,

  /// 할 일 목록 (체크리스트)
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
  // HiveCacheService를 주입한다 (로컬 퍼스트 아키텍처)
  final cache = ref.watch(hiveCacheServiceProvider);
  return TodoRepository(cache: cache);
});

// ─── 투두 목록 Provider ───────────────────────────────────────────────────

/// 선택된 날짜의 투두 목록 Provider (FutureProvider)
/// Hive는 동기 API를 제공하지만 FutureProvider를 유지하여 기존 UI 코드 호환성을 보장한다
/// selectedDateProvider 변경 시 자동 재로드한다
final todosForDateProvider = FutureProvider<List<Todo>>((ref) async {
  final selectedDate = ref.watch(selectedDateProvider);
  final repository = ref.watch(todoRepositoryProvider);

  // 로컬 퍼스트: 인증 상태와 무관하게 항상 로컬 Hive에서 조회한다
  return repository.getTodosForDate(selectedDate);
});

// ─── 통계 Provider ─────────────────────────────────────────────────────────

/// 현재 날짜 투두 통계 파생 Provider (F3.3 TodoStatsCalculator)
/// todosForDateProvider 데이터를 기반으로 계산한다
final todoStatsProvider = Provider<TodoStats>((ref) {
  final todosAsync = ref.watch(todosForDateProvider);
  return todosAsync.when(
    data: (todos) => TodoFilter.calculateStats(todos),
    loading: () => TodoStats.empty,
    error: (_, __) => TodoStats.empty,
  );
});

// ─── 정렬된 투두 Provider ───────────────────────────────────────────────────

/// 정렬된 투두 목록 Provider (완료 항목 하단 배치)
final sortedTodosProvider = Provider<List<Todo>>((ref) {
  final todosAsync = ref.watch(todosForDateProvider);
  return todosAsync.when(
    data: (todos) => TodoFilter.sortTodos(todos),
    loading: () => [],
    error: (_, __) => [],
  );
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
/// 로컬 Hive에 즉시 저장하고 투두 목록을 다시 로드한다
final createTodoProvider = Provider<Future<void> Function(Todo)>((ref) {
  final repository = ref.watch(todoRepositoryProvider);

  return (Todo todo) async {
    try {
      repository.createTodo(todo);
      // 생성 후 투두 목록을 다시 로드한다
      ref.invalidate(todosForDateProvider);
    } catch (e) {
      // 호출부에서 에러를 처리할 수 있도록 다시 던진다
      rethrow;
    }
  };
});

/// 투두 완료 상태 토글 액션
/// 두 번째 파라미터 isCompleted는 하위 호환성을 위해 유지하지만 실제로는 Hive 내부 상태를 반전한다
final toggleTodoProvider =
    Provider<Future<void> Function(String, bool)>((ref) {
  final repository = ref.watch(todoRepositoryProvider);

  return (String todoId, bool isCompleted) async {
    try {
      repository.toggleTodoCompleted(todoId);
      // 토글 후 투두 목록을 다시 로드한다
      ref.invalidate(todosForDateProvider);
    } catch (e) {
      // 호출부에서 에러를 처리할 수 있도록 다시 던진다
      rethrow;
    }
  };
});

/// 투두 삭제 액션
final deleteTodoProvider = Provider<Future<void> Function(String)>((ref) {
  final repository = ref.watch(todoRepositoryProvider);

  return (String todoId) async {
    try {
      repository.deleteTodo(todoId);
      // 삭제 후 투두 목록을 다시 로드한다
      ref.invalidate(todosForDateProvider);
    } catch (e) {
      // 호출부에서 에러를 처리할 수 있도록 다시 던진다
      rethrow;
    }
  };
});

/// 새 투두 ID 생성 헬퍼
/// 로컬 퍼스트 아키텍처에서는 TodoRepository 내부에서 UUID를 생성하므로
/// 이 Provider는 하위 호환성을 위해 유지한다
final generateTodoIdProvider = Provider<String Function()>((ref) {
  return () {
    // 로컬 UUID 생성은 TodoRepository.createTodo 내부에서 처리한다
    return DateTime.now().millisecondsSinceEpoch.toString();
  };
});

// ─── 년/월 피커 Provider ────────────────────────────────────────────────────

/// 투두 화면 헤더의 년/월 표시용 포커스 날짜
/// selectedDateProvider와 동기화된다
final todoFocusedMonthProvider = StateProvider<DateTime>((ref) {
  final selected = ref.watch(selectedDateProvider);
  return DateTime(selected.year, selected.month, 1);
});
