// F5: TaskRepository (로컬 퍼스트 — Hive 기반)
// 모든 실천 할일 CRUD는 별도 Hive 박스(goalTasksBox)에서 수행한다.
// sub_goal_id 필드로 특정 하위 목표의 할일을 필터링한다.
// goal_id는 SubGoalRepository를 통해 간접 조회하여 goal 단위 집계를 지원한다.

import 'package:uuid/uuid.dart';

import '../../../core/cache/hive_cache_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/goal_task.dart';

/// 실천 할일 저장소 (Hive 로컬 퍼스트)
/// goalTasksBox에 sub_goal_id 기반으로 실천 할일을 저장하고 조회한다
class TaskRepository {
  final HiveCacheService _cache;

  /// HiveCacheService를 의존성 주입으로 받는다
  TaskRepository({required HiveCacheService cache}) : _cache = cache;

  // ─── 조회 ────────────────────────────────────────────────────────────────

  /// 특정 목표에 속한 모든 실천 할일을 로컬에서 조회한다 (진행률 계산용)
  /// subGoalIds: 해당 목표에 속한 하위 목표 ID 목록
  List<GoalTask> getTasksByGoal(List<String> subGoalIds) {
    if (subGoalIds.isEmpty) return const [];
    return _cache
        .query(
          AppConstants.goalTasksBox,
          (m) => subGoalIds.contains(m['sub_goal_id'] as String?),
        )
        .map((m) => GoalTask.fromMap(m))
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
  }

  /// 특정 하위 목표의 실천 할일 목록을 로컬에서 조회한다 (order_index 오름차순)
  List<GoalTask> getTasksBySubGoal(String goalId, String subGoalId) {
    return _cache
        .query(
          AppConstants.goalTasksBox,
          (m) => m['sub_goal_id'] == subGoalId,
        )
        .map((m) => GoalTask.fromMap(m))
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
  }

  // ─── 생성 ────────────────────────────────────────────────────────────────

  /// 새 실천 할일을 로컬에 생성한다
  /// ID는 UUID v4로 클라이언트에서 생성한다
  Future<GoalTask> createTask(String goalId, GoalTask task) async {
    final id = const Uuid().v4();
    final now = DateTime.now().toIso8601String();
    // toInsertMap()의 sub_goal_id가 int 변환을 시도하므로,
    // 로컬에서는 String ID를 직접 저장하도록 오버라이드한다
    final map = <String, dynamic>{
      'id': id,
      'sub_goal_id': task.subGoalId,
      'title': task.title,
      'is_completed': task.isCompleted,
      'order_index': task.orderIndex,
      'created_at': now,
    };
    await _cache.put(AppConstants.goalTasksBox, id, map);
    return GoalTask.fromMap(map);
  }

  // ─── 완료 상태 토글 ──────────────────────────────────────────────────────

  /// 실천 할일 완료 상태를 로컬에서 토글한다
  Future<void> toggleTaskCompletion(
    String goalId,
    String taskId,
    bool isCompleted,
  ) async {
    await _cache.update(AppConstants.goalTasksBox, taskId, {
      'is_completed': isCompleted,
    });
  }

  // ─── 삭제 ────────────────────────────────────────────────────────────────

  /// 실천 할일을 로컬에서 삭제한다
  Future<void> deleteTask(String goalId, String taskId) async {
    await _cache.delete(AppConstants.goalTasksBox, taskId);
  }

  /// 특정 하위 목표에 속한 실천 할일을 모두 삭제한다 (하위 목표 삭제 시 연계 삭제용)
  Future<void> deleteTasksBySubGoal(String subGoalId) async {
    final matching = _cache.query(
      AppConstants.goalTasksBox,
      (m) => m['sub_goal_id'] == subGoalId,
    );
    for (final m in matching) {
      final id = m['id'] as String?;
      if (id != null) {
        await _cache.delete(AppConstants.goalTasksBox, id);
      }
    }
  }
}
