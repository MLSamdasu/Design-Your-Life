// F5: GoalRepository (로컬 퍼스트 — Hive 기반)
// 모든 목표 CRUD는 Hive 로컬 박스에서 수행한다.
// 백업은 별도 백업 서비스에서 담당한다.

import 'package:uuid/uuid.dart';

import '../../../core/cache/hive_cache_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/goal.dart';
import '../../../shared/enums/goal_period.dart';

/// 목표 저장소 (Hive 로컬 퍼스트)
/// 로컬 Hive 박스에서 목표 CRUD 작업을 수행한다
class GoalRepository {
  final HiveCacheService _cache;

  /// HiveCacheService를 의존성 주입으로 받는다
  GoalRepository({required HiveCacheService cache}) : _cache = cache;

  // ─── 조회 ────────────────────────────────────────────────────────────────

  /// 사용자의 모든 목표를 로컬에서 조회한다 (생성 시각 내림차순)
  List<Goal> getGoals() {
    final all = _cache.getAll(AppConstants.goalsBox);
    final goals = all.map((m) => Goal.fromMap(m)).toList();
    // 생성 시각 내림차순 정렬 (최신 목표가 먼저 표시된다)
    goals.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return goals;
  }

  /// 특정 연도의 목표를 로컬에서 조회한다
  List<Goal> getGoalsByYear(int year) {
    return _cache
        .query(
          AppConstants.goalsBox,
          (m) => m['year'] == year,
        )
        .map((m) => Goal.fromMap(m))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// 특정 연도/기간 유형의 목표를 로컬에서 조회한다
  List<Goal> getGoalsByYearAndPeriod(int year, GoalPeriod period) {
    return _cache
        .query(
          AppConstants.goalsBox,
          (m) => m['year'] == year && m['period'] == period.name,
        )
        .map((m) => Goal.fromMap(m))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // ─── 생성 ────────────────────────────────────────────────────────────────

  /// 새 목표를 로컬에 생성한다
  /// ID는 UUID v4로 클라이언트에서 생성한다
  Future<Goal> createGoal(Goal goal) async {
    final id = const Uuid().v4();
    final now = DateTime.now().toIso8601String();
    final map = goal.toInsertMap('local_user')
      ..['id'] = id
      ..['created_at'] = now
      ..['updated_at'] = now;
    await _cache.put(AppConstants.goalsBox, id, map);
    return Goal.fromMap(map);
  }

  // ─── 수정 ────────────────────────────────────────────────────────────────

  /// 목표 정보를 로컬에서 수정한다
  Future<Goal> updateGoal(String goalId, Goal goal) async {
    final existing = _cache.get(AppConstants.goalsBox, goalId) ?? {};
    final updated = Map<String, dynamic>.from(existing)
      ..addAll(goal.toUpdateMap())
      ..['updated_at'] = DateTime.now().toIso8601String();
    await _cache.put(AppConstants.goalsBox, goalId, updated);
    return Goal.fromMap(updated);
  }

  // ─── 완료 상태 토글 ──────────────────────────────────────────────────────

  /// 목표 완료 상태를 로컬에서 토글한다
  Future<void> toggleGoalCompletion(String goalId, bool isCompleted) async {
    await _cache.update(AppConstants.goalsBox, goalId, {
      'is_completed': isCompleted,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  // ─── 삭제 ────────────────────────────────────────────────────────────────

  /// 목표를 로컬에서 삭제한다
  Future<void> deleteGoal(String goalId) async {
    await _cache.delete(AppConstants.goalsBox, goalId);
  }
}
