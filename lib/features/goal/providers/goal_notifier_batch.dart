// F5: GoalNotifier 일괄 생성 믹스인 (만다라트/체크포인트)
// goal_crud_notifier.dart에서 사용한다.
// 목표 + 체크포인트, 만다라트 전체를 원자적으로 생성하는 메서드를 정의한다.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/error_handler.dart';
import '../../../shared/models/goal.dart';
import '../../../shared/models/sub_goal.dart';
import '../../../shared/models/goal_task.dart';
import 'goal_notifier_base.dart';

/// GoalNotifier에서 일괄 생성 로직을 분리한 믹스인
/// 만다라트 전체 생성, 목표+체크포인트 원자적 생성을 담당한다
mixin GoalNotifierBatchMixin
    on StateNotifier<AsyncValue<void>>, GoalNotifierBaseMixin {
  /// 목표와 체크포인트를 원자적으로 생성한다
  /// state 변경과 버전 갱신을 딱 한 번만 수행하여
  /// 다이얼로그에서 연속 호출 시 _dependents.isEmpty 크래시를 방지한다
  ///
  /// [checkpointTitles]가 비어있으면 목표만 생성한다
  Future<String?> createGoalWithCheckpoints(
    Goal goal,
    List<String> checkpointTitles,
  ) async {
    try {
      // 1. 목표 생성 (state 변경 없이 Hive에만 저장)
      final created = await goalRepo.createGoal(goal);
      final goalId = created.id;

      // 2. 체크포인트 일괄 생성 (state 변경 없이 Hive에만 저장)
      final now = DateTime.now();
      for (int i = 0; i < checkpointTitles.length; i++) {
        final sg = SubGoal(
          id: '',
          goalId: goalId,
          title: checkpointTitles[i],
          isCompleted: false,
          orderIndex: i,
          createdAt: now,
        );
        await subGoalRepo.createSubGoal(goalId, sg);
      }

      // 3. 모든 Hive 쓰기 완료 후 한 번만 버전 갱신
      bumpSubGoalVersions();
      return goalId;
    } catch (e, stack) {
      ErrorHandler.logServiceError(
        'GoalProvider:createGoalWithCheckpoints', e, stack,
      );
      return null;
    }
  }

  /// 만다라트 전체(핵심 목표 + 8 세부 목표 + 64 실천 과제)를 원자적으로 생성한다
  Future<String?> createMandalart(
    Goal goal,
    List<String> subGoalTitles,
    List<List<String>> taskTitles,
  ) async {
    final createdSubGoalIds = <String>[];
    final createdTaskIds = <String>[];
    String? createdGoalId;

    try {
      final created = await goalRepo.createGoal(goal);
      final goalId = created.id;
      createdGoalId = goalId;
      final now = DateTime.now();

      for (int i = 0; i < subGoalTitles.length; i++) {
        final sg = SubGoal(
          id: '',
          goalId: goalId,
          title: subGoalTitles[i],
          isCompleted: false,
          orderIndex: i,
          createdAt: now,
        );
        final createdSg = await subGoalRepo.createSubGoal(goalId, sg);
        createdSubGoalIds.add(createdSg.id);

        // 해당 세부 목표의 실천 과제 생성
        if (i < taskTitles.length) {
          for (int j = 0; j < taskTitles[i].length; j++) {
            final task = GoalTask(
              id: '',
              subGoalId: createdSg.id,
              title: taskTitles[i][j],
              isCompleted: false,
              orderIndex: j,
              createdAt: now,
            );
            final createdTask = await taskRepo.createTask(goalId, task);
            createdTaskIds.add(createdTask.id);
          }
        }
      }

      bumpAllVersions();
      return goalId;
    } catch (e, stack) {
      // 실패 시 이미 생성된 항목을 역순으로 삭제하여 고아 데이터를 방지한다
      await _rollbackMandalart(
        createdGoalId, createdSubGoalIds, createdTaskIds,
      );
      ErrorHandler.logServiceError(
        'GoalProvider:createMandalart', e, stack,
      );
      return null;
    }
  }

  /// 만다라트 생성 실패 시 이미 저장된 항목을 역순으로 삭제한다
  Future<void> _rollbackMandalart(
    String? goalId,
    List<String> subGoalIds,
    List<String> taskIds,
  ) async {
    for (final taskId in taskIds) {
      try {
        await taskRepo.deleteTask(goalId ?? '', taskId);
      } catch (_) {
        // 클린업 실패는 무시한다 (원본 에러가 우선)
      }
    }
    for (final sgId in subGoalIds) {
      try {
        await subGoalRepo.deleteSubGoal(goalId ?? '', sgId);
      } catch (_) {
        // 클린업 실패는 무시한다
      }
    }
    if (goalId != null) {
      try {
        await goalRepo.deleteGoal(goalId);
      } catch (_) {
        // 클린업 실패는 무시한다
      }
    }
  }
}
