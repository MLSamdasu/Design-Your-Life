// F5: GoalNotifier 실천 할일(GoalTask) CRUD 믹스인
// goal_crud_notifier.dart에서 사용한다.
// 실천 할일 생성/수정/삭제/완료 토글 메서드를 정의한다.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/error_handler.dart';
import '../../../shared/models/goal_task.dart';
import '../../achievement/providers/achievement_provider.dart';
import 'goal_notifier_base.dart';

/// GoalNotifier에서 실천 할일(GoalTask) CRUD 로직을 분리한 믹스인
/// GoalNotifierBaseMixin 위에 적용한다
mixin GoalNotifierTaskMixin
    on StateNotifier<AsyncValue<void>>, GoalNotifierBaseMixin {
  /// 새 실천 할일을 생성한다
  Future<String?> createTask(String goalId, GoalTask task) async {
    state = const AsyncLoading();
    try {
      final created = await taskRepo.createTask(goalId, task);
      state = const AsyncData(null);
      bumpTaskVersions();
      return created.id;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  /// 실천 할일을 수정한다
  Future<void> updateTask(
    String goalId,
    String taskId,
    GoalTask task,
  ) async {
    state = const AsyncLoading();
    try {
      await taskRepo.updateTask(goalId, taskId, task);
      state = const AsyncData(null);
      bumpTaskVersions();
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// 실천 할일을 삭제한다
  Future<void> deleteTask(String goalId, String taskId) async {
    state = const AsyncLoading();
    try {
      await taskRepo.deleteTask(goalId, taskId);
      state = const AsyncData(null);
      bumpTaskVersions();
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// 실천 할일 완료 상태를 토글한다
  /// P1-6: UI flicker 방지를 위해 AsyncLoading 설정 없이 Hive에 저장한 뒤
  /// goalTaskDataVersionProvider만 증가시켜 최소한의 리빌드만 발생시킨다
  Future<void> toggleTaskCompletion(
    String goalId,
    String taskId,
    bool isCompleted,
  ) async {
    try {
      await taskRepo.toggleTaskCompletion(goalId, taskId, isCompleted);
      bumpTaskVersions();

      // Bug 6 Fix: 실천 할일 완료 시 업적 달성 조건을 확인한다
      if (isCompleted) {
        await checkAchievementsAndNotify(notifierRef);
      }
    } catch (e, stack) {
      // 토글 실패를 구조화된 에러 핸들러로 기록한다
      ErrorHandler.logServiceError(
        'GoalProvider:toggleTaskCompletion', e, stack,
      );
    }
  }
}
