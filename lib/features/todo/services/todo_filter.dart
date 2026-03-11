// F3: TodoFilter (F3.2)
// List<Todo>를 filterType(전체/완료/미완료)에 따라 필터링한다.
// 순수 함수로 구현한다.
import '../../../shared/models/todo.dart';

/// 투두 필터 유형
enum TodoFilterType {
  /// 전체 투두
  all,

  /// 완료된 투두만
  completed,

  /// 미완료 투두만
  incomplete,

  /// 시간이 지정된 투두만 (타임라인 표시용)
  withTime,

  /// 시간 미지정 투두만 (체크리스트 표시용)
  withoutTime,
}

/// 투두 통계 데이터 (F3.3 TodoStatsCalculator OUT)
class TodoStats {
  final int totalCount;
  final int completedCount;
  final double completionRate;
  final int withTimeCount;
  final int withoutTimeCount;

  const TodoStats({
    required this.totalCount,
    required this.completedCount,
    required this.completionRate,
    required this.withTimeCount,
    required this.withoutTimeCount,
  });

  /// 빈 통계 (데이터 없을 때)
  static const empty = TodoStats(
    totalCount: 0,
    completedCount: 0,
    completionRate: 0,
    withTimeCount: 0,
    withoutTimeCount: 0,
  );
}

/// 투두 필터 및 통계 계산 (F3.2 + F3.3 구현)
/// 순수 함수: 외부 상태에 의존하지 않는다
abstract class TodoFilter {
  /// 필터 유형에 따라 투두 목록을 필터링한다
  static List<Todo> filter(List<Todo> todos, TodoFilterType type) {
    switch (type) {
      case TodoFilterType.all:
        return todos;
      case TodoFilterType.completed:
        return todos.where((t) => t.isCompleted).toList();
      case TodoFilterType.incomplete:
        return todos.where((t) => !t.isCompleted).toList();
      case TodoFilterType.withTime:
        return todos.where((t) => t.time != null).toList();
      case TodoFilterType.withoutTime:
        return todos.where((t) => t.time == null).toList();
    }
  }

  /// 투두 통계를 계산한다 (F3.3 TodoStatsCalculator)
  static TodoStats calculateStats(List<Todo> todos) {
    final total = todos.length;
    final completed = todos.where((t) => t.isCompleted).length;
    final withTime = todos.where((t) => t.time != null).length;
    final withoutTime = todos.where((t) => t.time == null).length;
    final rate =
        total > 0 ? (completed / total * 100).clamp(0.0, 100.0) : 0.0;

    return TodoStats(
      totalCount: total,
      completedCount: completed,
      completionRate: rate,
      withTimeCount: withTime,
      withoutTimeCount: withoutTime,
    );
  }

  /// 완료 투두는 하단으로, 같은 완료 상태 내에서는 시간 순 정렬한다
  static List<Todo> sortTodos(List<Todo> todos) {
    final sorted = List<Todo>.from(todos);
    sorted.sort((a, b) {
      // 완료 여부 우선 정렬: 미완료(false) 먼저
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }
      // 시간 있는 것 먼저
      if (a.time != null && b.time == null) return -1;
      if (a.time == null && b.time != null) return 1;
      // 동일 조건이면 생성 시간 순
      return a.createdAt.compareTo(b.createdAt);
    });
    return sorted;
  }
}
