// F3: 투두 조회/필터 Provider
// 날짜별 투두 목록, 정렬, 태그 필터링, 통계를 제공한다.
// allTodosRawProvider를 Single Source of Truth로 사용한다.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/data_store_providers.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/models/todo.dart';
import '../../../shared/providers/tag_provider.dart';
import '../services/todo_filter.dart';
import 'todo_state_providers.dart';

// ─── 투두 목록 Provider (Single Source of Truth에서 파생) ──────────────────

/// 선택된 날짜의 투두 목록 Provider (동기 Provider)
/// P1-2: allTodosRawProvider가 동기 Provider이므로 FutureProvider로 래핑할 필요가 없다
/// 불필요한 async 오버헤드와 loading 상태 발생을 제거한다
/// todoDataVersionProvider 변경 → allTodosRawProvider 재평가 → 이 Provider 자동 갱신
final todosForDateProvider = Provider<List<Todo>>((ref) {
  final selectedDate = ref.watch(selectedDateProvider);
  // 단일 진실 원천(SSOT): allTodosRawProvider에서 파생한다
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

// ─── 통계 Provider ─────────────────────────────────────────────────────────

/// 현재 날짜 투두 통계 파생 Provider (F3.3 TodoStatsCalculator)
/// P2-2: filteredTodosProvider 기반으로 계산하여 태그 필터와 일관성을 유지한다
final todoStatsProvider = Provider<TodoStats>((ref) {
  final filtered = ref.watch(filteredTodosProvider);
  return TodoFilter.calculateStats(filtered);
});
