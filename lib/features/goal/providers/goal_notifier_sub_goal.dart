// F5: GoalNotifier 하위 목표(SubGoal) CRUD 믹스인
// goal_crud_notifier.dart에서 사용한다.
// 하위 목표 생성/수정/삭제/토글 메서드를 정의한다.
// 체크포인트 토글 시 부모 Goal 자동 완료/해제 로직을 포함한다.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/error_handler.dart';
import '../../../shared/models/sub_goal.dart';
import '../../achievement/providers/achievement_provider.dart';
import 'goal_notifier_base.dart';

/// GoalNotifier에서 하위 목표(SubGoal) CRUD 로직을 분리한 믹스인
/// GoalNotifierBaseMixin 위에 적용한다
mixin GoalNotifierSubGoalMixin
    on StateNotifier<AsyncValue<void>>, GoalNotifierBaseMixin {
  /// 새 하위 목표를 생성한다
  Future<String?> createSubGoal(String goalId, SubGoal subGoal) async {
    state = const AsyncLoading();
    try {
      final created = await subGoalRepo.createSubGoal(goalId, subGoal);
      state = const AsyncData(null);
      bumpSubGoalVersions();
      return created.id;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  /// 하위 목표를 수정한다
  Future<void> updateSubGoal(
    String goalId,
    String subGoalId,
    SubGoal subGoal,
  ) async {
    state = const AsyncLoading();
    try {
      await subGoalRepo.updateSubGoal(goalId, subGoal);
      state = const AsyncData(null);
      bumpSubGoalVersions();
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// 체크포인트(하위 목표) 완료 상태만 토글한다
  /// 전체 화면 깜빡임을 방지하기 위해 AsyncLoading을 설정하지 않고,
  /// subGoalDataVersionProvider만 증가시켜 최소한의 리빌드만 발생시킨다.
  /// 모든 체크포인트가 완료되면 부모 Goal을 자동 완료하고,
  /// 하나라도 해제되면 부모 Goal을 자동 해제한다.
  Future<bool> toggleSubGoalCompletion(
    String goalId,
    String subGoalId,
    bool isCompleted,
  ) async {
    try {
      // 1. 체크포인트 상태를 변경한다
      final existing = subGoalRepo.getSubGoals(goalId);
      final idx = existing.indexWhere((sg) => sg.id == subGoalId);
      if (idx == -1) return false;
      final target = existing[idx];
      final updated = target.copyWith(isCompleted: isCompleted);
      await subGoalRepo.updateSubGoal(goalId, updated);

      // 2. 부모 Goal 자동 완료/해제를 판단한다
      //    변경 후 전체 체크포인트 상태를 다시 조회한다
      final refreshed = subGoalRepo.getSubGoals(goalId);
      final allCompleted =
          refreshed.isNotEmpty && refreshed.every((sg) => sg.isCompleted);

      // 현재 Goal 완료 상태를 조회한다
      final goals = goalRepo.getGoals();
      final goalIdx = goals.indexWhere((g) => g.id == goalId);
      if (goalIdx != -1) {
        final currentGoal = goals[goalIdx];
        if (allCompleted && !currentGoal.isCompleted) {
          // 모든 체크포인트 완료 → Goal 자동 완료
          await goalRepo.toggleGoalCompletion(goalId, true);
          await checkAchievementsAndNotify(notifierRef);
        } else if (!allCompleted && currentGoal.isCompleted) {
          // 체크포인트 하나라도 미완료 → Goal 자동 해제
          await goalRepo.toggleGoalCompletion(goalId, false);
        }
      }

      bumpSubGoalVersions();
      return true;
    } catch (e, stack) {
      ErrorHandler.logServiceError(
        'GoalProvider:toggleSubGoalCompletion', e, stack,
      );
      return false;
    }
  }

  /// 하위 목표를 삭제한다 (연계 삭제: 실천 할일 → 하위 목표)
  Future<void> deleteSubGoal(String goalId, String subGoalId) async {
    state = const AsyncLoading();
    try {
      await taskRepo.deleteTasksBySubGoal(subGoalId);
      await subGoalRepo.deleteSubGoal(goalId, subGoalId);
      state = const AsyncData(null);
      bumpAllVersions();
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
