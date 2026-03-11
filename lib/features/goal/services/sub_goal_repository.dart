// F5: SubGoalRepository (로컬 퍼스트 — Hive 기반)
// 모든 하위 목표 CRUD는 별도 Hive 박스(subGoalsBox)에서 수행한다.
// goal_id 필드로 특정 목표의 하위 목표를 필터링한다.

import 'package:uuid/uuid.dart';

import '../../../core/cache/hive_cache_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/sub_goal.dart';

/// 하위 목표 저장소 (Hive 로컬 퍼스트)
/// subGoalsBox에 goal_id 기반으로 하위 목표를 저장하고 조회한다
class SubGoalRepository {
  final HiveCacheService _cache;

  /// HiveCacheService를 의존성 주입으로 받는다
  SubGoalRepository({required HiveCacheService cache}) : _cache = cache;

  // ─── 조회 ────────────────────────────────────────────────────────────────

  /// 특정 목표의 하위 목표 목록을 로컬에서 조회한다 (order_index 오름차순)
  List<SubGoal> getSubGoals(String goalId) {
    final results = _cache
        .query(
          AppConstants.subGoalsBox,
          (m) => m['goal_id'] == goalId,
        )
        .map((m) => SubGoal.fromMap(m))
        .toList();
    // 만다라트 위치 인덱스 오름차순으로 정렬한다
    results.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return results;
  }

  // ─── 생성 ────────────────────────────────────────────────────────────────

  /// 새 하위 목표를 로컬에 생성한다
  /// ID는 UUID v4로 클라이언트에서 생성한다
  Future<SubGoal> createSubGoal(String goalId, SubGoal subGoal) async {
    final id = const Uuid().v4();
    final now = DateTime.now().toIso8601String();
    // toInsertMap()의 goal_id가 int 변환을 시도하므로,
    // 로컬에서는 String ID를 직접 저장하도록 오버라이드한다
    final map = <String, dynamic>{
      'id': id,
      'goal_id': goalId,
      'title': subGoal.title,
      'is_completed': subGoal.isCompleted,
      'order_index': subGoal.orderIndex,
      'created_at': now,
    };
    await _cache.put(AppConstants.subGoalsBox, id, map);
    return SubGoal.fromMap(map);
  }

  // ─── 수정 ────────────────────────────────────────────────────────────────

  /// 하위 목표 정보를 로컬에서 수정한다
  Future<void> updateSubGoal(String goalId, SubGoal subGoal) async {
    final existing =
        _cache.get(AppConstants.subGoalsBox, subGoal.id) ?? {};
    final updated = Map<String, dynamic>.from(existing)
      ..addAll(subGoal.toUpdateMap());
    await _cache.put(AppConstants.subGoalsBox, subGoal.id, updated);
  }

  // ─── 완료 상태 토글 ──────────────────────────────────────────────────────

  /// 하위 목표 완료 상태를 로컬에서 토글한다
  Future<void> toggleSubGoalCompletion(
    String goalId,
    String subGoalId,
    bool isCompleted,
  ) async {
    await _cache.update(AppConstants.subGoalsBox, subGoalId, {
      'is_completed': isCompleted,
    });
  }

  // ─── 삭제 ────────────────────────────────────────────────────────────────

  /// 하위 목표를 로컬에서 삭제한다
  Future<void> deleteSubGoal(String goalId, String subGoalId) async {
    await _cache.delete(AppConstants.subGoalsBox, subGoalId);
  }

  /// 특정 목표에 속한 하위 목표를 모두 삭제한다 (목표 삭제 시 연계 삭제용)
  Future<void> deleteSubGoalsByGoal(String goalId) async {
    final matching = _cache.query(
      AppConstants.subGoalsBox,
      (m) => m['goal_id'] == goalId,
    );
    for (final m in matching) {
      final id = m['id'] as String?;
      if (id != null) {
        await _cache.delete(AppConstants.subGoalsBox, id);
      }
    }
  }
}
