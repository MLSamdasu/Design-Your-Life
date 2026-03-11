// F3: TodoRepository (로컬 퍼스트 아키텍처)
// 모든 CRUD는 Hive 로컬 저장소에서 수행한다.
// 인터넷 없이도 완전히 동작한다.

import 'package:uuid/uuid.dart';

import '../../../core/cache/hive_cache_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/todo.dart';

/// 투두 저장소 (로컬 퍼스트 아키텍처)
/// Hive 로컬 저장소를 기본 저장소로 사용하여 오프라인에서도 완전히 동작한다
class TodoRepository {
  final HiveCacheService _cache;

  /// Hive에서 투두 데이터를 저장하는 박스 이름
  static const _boxName = AppConstants.todosBox;

  /// UUID 생성기 (로컬에서 UUID를 생성한다)
  static const _uuid = Uuid();

  TodoRepository({required HiveCacheService cache}) : _cache = cache;

  // ─── 조회 ──────────────────────────────────────────────────────────────────

  /// 특정 날짜의 투두 목록을 로컬 Hive에서 조회한다
  /// scheduled_date 필드의 "YYYY-MM-DD" 접두사로 날짜를 비교한다
  List<Todo> getTodosForDate(DateTime date) {
    // "YYYY-MM-DD" 형식의 날짜 문자열을 생성한다
    final dateStr =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    // 전체 박스를 스캔하여 해당 날짜의 투두만 필터링한다
    final items = _cache.query(
      _boxName,
      (map) =>
          (map['scheduled_date'] as String?)?.startsWith(dateStr) == true,
    );

    // display_order 오름차순으로 정렬하여 반환한다
    final todos = items.map((m) => Todo.fromMap(m)).toList();
    todos.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return todos;
  }

  // ─── 생성 ──────────────────────────────────────────────────────────────────

  /// 새 투두를 로컬 Hive에 생성한다
  /// 클라이언트에서 UUID v4를 생성하여 ID로 사용한다
  Todo createTodo(Todo todo) {
    // 로컬에서 고유 ID를 생성한다
    final id = _uuid.v4();
    final now = DateTime.now();

    // INSERT용 맵을 생성하고 로컬 전용 필드를 추가한다
    final map = todo.toInsertMap('local_user')
      ..['id'] = id
      ..['created_at'] = now.toIso8601String()
      ..['updated_at'] = now.toIso8601String();

    // Hive에 저장한다
    _cache.put(_boxName, id, map);

    return Todo.fromMap(map);
  }

  // ─── 완료 상태 토글 ──────────────────────────────────────────────────────

  /// 투두의 완료 상태를 반전시킨다
  /// Hive에서 현재 상태를 읽어 반전하고 저장한다
  Todo? toggleTodoCompleted(String todoId) {
    final existing = _cache.get(_boxName, todoId);
    // 해당 ID의 항목이 없으면 null을 반환한다
    if (existing == null) return null;

    // 현재 완료 상태를 반전한다
    final newCompleted = !(existing['is_completed'] as bool? ?? false);
    existing['is_completed'] = newCompleted;
    existing['updated_at'] = DateTime.now().toIso8601String();

    _cache.put(_boxName, todoId, existing);
    return Todo.fromMap(existing);
  }

  // ─── 수정 ──────────────────────────────────────────────────────────────────

  /// 투두를 수정한다
  /// 기존 id와 created_at을 유지하고 나머지 필드를 업데이트한다
  Todo? updateTodo(String todoId, Todo todo) {
    final existing = _cache.get(_boxName, todoId);
    // 해당 ID의 항목이 없으면 null을 반환한다
    if (existing == null) return null;

    // UPDATE용 맵에 메타 필드를 추가한다
    final updatedMap = todo.toUpdateMap()
      ..['id'] = todoId
      ..['user_id'] = existing['user_id'] ?? 'local_user'
      ..['created_at'] = existing['created_at']
      ..['updated_at'] = DateTime.now().toIso8601String();

    _cache.put(_boxName, todoId, updatedMap);
    return Todo.fromMap(updatedMap);
  }

  // ─── 삭제 ──────────────────────────────────────────────────────────────────

  /// 투두를 로컬 Hive에서 삭제한다
  void deleteTodo(String todoId) {
    _cache.deleteById(_boxName, todoId);
  }
}
