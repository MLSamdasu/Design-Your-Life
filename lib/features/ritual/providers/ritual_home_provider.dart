// F-Ritual: 홈 화면 위젯용 파생 Provider
// DailyThree의 각 todoId별 완료 상태와
// Top 5 목표별 Goal 진행률을 홈 대시보드에 제공한다.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/data_store_providers.dart';
import '../../../shared/models/goal.dart';
import 'ritual_provider.dart';
import '../../../shared/models/sub_goal.dart';
import '../../../shared/models/goal_task.dart';
import '../../goal/services/progress_calculator.dart';

// ─── DailyThree Todo 완료 상태 Provider ──────────────────────────────────

/// 오늘의 DailyThree todoId별 Todo 완료 상태 맵
/// key: todoId, value: isCompleted
/// todayDailyThreeProvider + allTodosRawProvider를 직접 watch하여
/// Todo 완료 시 즉시 갱신된다 (family 대신 직접 의존으로 동등성 문제 회피)
final dailyThreeTodoStatusProvider = Provider<Map<String, bool>>((ref) {
  final dailyThree = ref.watch(todayDailyThreeProvider);
  if (dailyThree == null) return {};

  final allTodos = ref.watch(allTodosRawProvider);

  // todoId → isCompleted 매핑을 생성한다
  final statusMap = <String, bool>{};
  for (final todoId in dailyThree.todoIds) {
    if (todoId.trim().isEmpty) continue;
    // allTodosRawProvider에서 해당 id의 Todo를 찾는다
    final todoMap = allTodos.cast<Map<String, dynamic>?>().firstWhere(
          (m) => m?['id'] == todoId,
          orElse: () => null,
        );
    final completed = todoMap?['is_completed'] as bool? ??
        todoMap?['isCompleted'] as bool? ??
        false;
    statusMap[todoId] = completed;
  }
  return statusMap;
});

// ─── Top 5 Goal 진행률 Provider ─────────────────────────────────────────

/// Top 5 목표 제목별 Goal 진행률 (0.0 ~ 1.0)
/// key: 목표 텍스트, value: 진행률 (null이면 매칭되는 Goal 없음)
/// goalDataVersionProvider + goalTaskDataVersionProvider 변경 시 자동 갱신
final top5GoalProgressProvider = Provider.family<
    Map<String, double?>,
    ({List<String> top5Texts})>((ref, params) {
  final allGoalsRaw = ref.watch(allGoalsRawProvider);
  final allSubGoalsRaw = ref.watch(allSubGoalsRawProvider);
  final allTasksRaw = ref.watch(allGoalTasksRawProvider);

  // 전체 Goal 파싱
  final allGoals = allGoalsRaw.map((m) => Goal.fromMap(m)).toList();
  // 제목(소문자) → Goal 매핑
  final titleMap = <String, Goal>{};
  for (final goal in allGoals) {
    titleMap[goal.title.toLowerCase().trim()] = goal;
  }

  // SubGoal, GoalTask 전체 파싱
  final allSubGoals =
      allSubGoalsRaw.map((m) => SubGoal.fromMap(m)).toList();
  final allTasks =
      allTasksRaw.map((m) => GoalTask.fromMap(m)).toList();

  // Top 5 각 텍스트에 대해 진행률 계산
  final progressMap = <String, double?>{};
  for (final text in params.top5Texts) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) continue;

    final goal = titleMap[trimmed.toLowerCase()];
    if (goal == null) {
      // 매칭되는 Goal 없음
      progressMap[trimmed] = null;
    } else if (goal.isCompleted) {
      // 완료된 Goal → 100%
      progressMap[trimmed] = 1.0;
    } else {
      // ProgressCalculator로 진행률 계산
      final progress = ProgressCalculator.calcGoalProgress(
        goal.id,
        allSubGoals,
        allTasks,
      );
      progressMap[trimmed] = progress;
    }
  }
  return progressMap;
});
