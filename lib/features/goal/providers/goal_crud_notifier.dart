// F5: 목표 CRUD Notifier (메인 파일)
// GoalNotifier 클래스 선언부 + 목표(Goal) 레벨 CRUD를 정의한다.
// 하위 목표/실천 할일/일괄 생성 메서드는 믹스인으로 분리한다.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/data_store_providers.dart';
import '../../../shared/models/goal.dart';
import '../../achievement/providers/achievement_provider.dart';
import '../services/goal_repository.dart';
import '../services/sub_goal_repository.dart';
import '../services/task_repository.dart';
import 'goal_notifier_base.dart';
import 'goal_notifier_sub_goal.dart';
import 'goal_notifier_task.dart';
import 'goal_notifier_batch.dart';
import 'goal_repository_providers.dart';

// ─── 목표 CRUD Notifier ───────────────────────────────────────────────────

/// 목표 생성/수정/삭제 작업을 처리하는 Notifier
/// 하위 목표 메서드: GoalNotifierSubGoalMixin (goal_notifier_sub_goal.dart)
/// 실천 할일 메서드: GoalNotifierTaskMixin (goal_notifier_task.dart)
/// 일괄 생성 메서드: GoalNotifierBatchMixin (goal_notifier_batch.dart)
class GoalNotifier extends StateNotifier<AsyncValue<void>>
    with
        GoalNotifierBaseMixin,
        GoalNotifierSubGoalMixin,
        GoalNotifierTaskMixin,
        GoalNotifierBatchMixin {
  final GoalRepository _goalRepo;
  final SubGoalRepository _subGoalRepo;
  final TaskRepository _taskRepo;
  final Ref _ref;

  GoalNotifier({
    required GoalRepository goalRepoParam,
    required SubGoalRepository subGoalRepoParam,
    required TaskRepository taskRepoParam,
    required Ref ref,
  })  : _goalRepo = goalRepoParam,
        _subGoalRepo = subGoalRepoParam,
        _taskRepo = taskRepoParam,
        _ref = ref,
        super(const AsyncData(null));

  /// 기반 믹스인에서 사용하는 리포지토리/Ref getter
  @override
  GoalRepository get goalRepo => _goalRepo;
  @override
  SubGoalRepository get subGoalRepo => _subGoalRepo;
  @override
  TaskRepository get taskRepo => _taskRepo;
  @override
  Ref get notifierRef => _ref;

  /// 목표 데이터만 변경된 경우 goal 버전만 증가시킨다
  void _bumpGoalVersion() {
    _ref.read(goalDataVersionProvider.notifier).state++;
  }

  /// 새 목표를 생성한다
  Future<String?> createGoal(Goal goal) async {
    state = const AsyncLoading();
    try {
      final created = await _goalRepo.createGoal(goal);
      state = const AsyncData(null);
      _bumpGoalVersion();
      return created.id;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  /// 목표 완료 상태를 토글하며, 모든 체크포인트(SubGoal)도 연쇄 변경한다
  /// isCompleted=true → 모든 체크포인트 완료, false → 모든 체크포인트 해제
  Future<void> toggleGoalCompletion(
    String goalId,
    bool isCompleted,
  ) async {
    state = const AsyncLoading();
    try {
      // 1. 목표 완료 상태를 변경한다
      await _goalRepo.toggleGoalCompletion(goalId, isCompleted);

      // 2. 소속 체크포인트(SubGoal)를 모두 같은 상태로 연쇄 변경한다
      final subGoals = _subGoalRepo.getSubGoals(goalId);
      for (final sg in subGoals) {
        if (sg.isCompleted != isCompleted) {
          final updated = sg.copyWith(isCompleted: isCompleted);
          await _subGoalRepo.updateSubGoal(goalId, updated);
        }
      }

      state = const AsyncData(null);
      // 목표 + 하위 목표 버전을 모두 증가시켜 달성률이 즉시 반영되도록 한다
      bumpSubGoalVersions();

      // 완료로 전환된 경우 업적 달성 조건을 확인한다
      if (isCompleted) {
        await checkAchievementsAndNotify(_ref);
      }
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// 목표를 수정한다
  Future<void> updateGoal(String goalId, Goal goal) async {
    state = const AsyncLoading();
    try {
      await _goalRepo.updateGoal(goalId, goal);
      state = const AsyncData(null);
      _bumpGoalVersion();
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// 목표를 삭제한다 (연계 삭제: 실천 할일 → 하위 목표 → 목표)
  Future<void> deleteGoal(String goalId) async {
    state = const AsyncLoading();
    try {
      // 하위 목표 목록을 먼저 조회하여 연계 할일을 삭제한다
      final subGoals = _subGoalRepo.getSubGoals(goalId);
      for (final sg in subGoals) {
        await _taskRepo.deleteTasksBySubGoal(sg.id);
      }
      await _subGoalRepo.deleteSubGoalsByGoal(goalId);
      await _goalRepo.deleteGoal(goalId);
      state = const AsyncData(null);
      // 목표 삭제는 모든 계층에 영향을 주므로 전체 버전을 증가시킨다
      bumpAllVersions();
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

/// 목표 Notifier Provider
final goalNotifierProvider =
    StateNotifierProvider<GoalNotifier, AsyncValue<void>>((ref) {
  return GoalNotifier(
    goalRepoParam: ref.watch(goalRepositoryProvider),
    subGoalRepoParam: ref.watch(subGoalRepositoryProvider),
    taskRepoParam: ref.watch(taskRepositoryProvider),
    ref: ref,
  );
});
