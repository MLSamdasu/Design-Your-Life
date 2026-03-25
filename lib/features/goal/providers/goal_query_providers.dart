// F5: 목표 조회/파생 Provider
// 목표 목록, 하위 목표, 실천 할일, 진행률, 통계 등
// allGoalsRawProvider(Single Source of Truth)에서 파생하는 읽기 전용 Provider를 정의한다.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/data_store_providers.dart';
import '../../../shared/enums/goal_period.dart';
import '../../../shared/models/goal.dart';
import '../../../shared/models/sub_goal.dart';
import '../../../shared/models/goal_task.dart';
import '../services/progress_calculator.dart';
import 'goal_repository_providers.dart';

// ─── 목표 목록 Provider ─────────────────────────────────────────────────

/// 전체 목표 목록 Provider (동기 Provider)
/// allGoalsRawProvider(Single Source of Truth)에서 파생한다
/// goalDataVersionProvider 변경 → allGoalsRawProvider 재평가 → 자동 갱신
/// Hive 조회는 모두 동기 연산이므로 FutureProvider가 불필요하다.
final goalsStreamProvider = Provider<List<Goal>>((ref) {
  final allGoals = ref.watch(allGoalsRawProvider);
  return allGoals.map((m) => Goal.fromMap(m)).toList();
});

/// 연도/기간 유형별 목표 Provider (동기 Provider.family)
/// allGoalsRawProvider(Single Source of Truth)에서 파생하여 year + period로 필터링한다
/// Hive 조회는 모두 동기 연산이므로 FutureProvider가 불필요하다.
final goalsByYearAndPeriodStreamProvider = Provider.family<List<Goal>,
    ({int year, GoalPeriod period})>((ref, params) {
  final allGoals = ref.watch(allGoalsRawProvider);
  final filtered = allGoals.where((m) {
    // num → int 변환으로 Hive 역직렬화 타입(int/double) 불일치를 방지한다
    final year = (m['year'] as num?)?.toInt();
    final period = m['period']?.toString();
    return year == params.year && period == params.period.name;
  }).toList();
  return filtered.map((m) => Goal.fromMap(m)).toList();
});

// ─── 하위 목표 Provider ────────────────────────────────────────────

/// 특정 목표의 하위 목표 목록 Provider (동기 Provider.family)
/// allSubGoalsRawProvider(Single Source of Truth)에서 파생하여 goal_id로 필터링한다
/// Hive 조회는 모두 동기 연산이므로 FutureProvider가 불필요하다.
final subGoalsStreamProvider =
    Provider.family<List<SubGoal>, String>((ref, goalId) {
  final allSubGoals = ref.watch(allSubGoalsRawProvider);
  // goal_id 비교 시 toString()으로 타입을 통일하여 Hive 역직렬화 타입 불일치를 방지한다
  final filtered = allSubGoals
      .where((m) => m['goal_id']?.toString() == goalId)
      .toList();
  return filtered.map((m) => SubGoal.fromMap(m)).toList();
});

// ─── 실천 할일 Provider ────────────────────────────────────────────

/// 특정 목표의 전체 실천 할일 목록 Provider (동기 Provider.family)
/// allSubGoalsRawProvider + allGoalTasksRawProvider에서 파생한다
/// Hive 조회는 모두 동기 연산이므로 FutureProvider가 불필요하다.
final tasksByGoalStreamProvider =
    Provider.family<List<GoalTask>, String>((ref, goalId) {
  final allSubGoals = ref.watch(allSubGoalsRawProvider);
  final allTasks = ref.watch(allGoalTasksRawProvider);

  // 목표에 속한 하위 목표 ID 목록을 수집한다
  // id가 null이거나 비어있는 항목은 필터링한다
  // toString()으로 타입을 통일하여 Hive 역직렬화 타입 불일치를 방지한다
  final subGoalIds = allSubGoals
      .where((m) => m['goal_id']?.toString() == goalId)
      .where((m) => m['id'] != null && (m['id'].toString()).isNotEmpty)
      .map((m) => m['id'].toString())
      .toSet();

  // 해당 하위 목표들의 할일을 필터링한다
  final filtered = allTasks
      .where((m) => subGoalIds.contains(m['sub_goal_id']?.toString()))
      .toList();
  return filtered.map((m) => GoalTask.fromMap(m)).toList();
});

/// 특정 하위 목표의 실천 할일 Provider (동기 Provider.family)
/// allGoalTasksRawProvider(Single Source of Truth)에서 파생하여 sub_goal_id로 필터링한다
/// Hive 조회는 모두 동기 연산이므로 FutureProvider가 불필요하다.
final tasksBySubGoalStreamProvider =
    Provider.family<List<GoalTask>, ({String goalId, String subGoalId})>(
  (ref, params) {
    final allTasks = ref.watch(allGoalTasksRawProvider);
    // sub_goal_id 비교 시 toString()으로 타입을 통일한다
    final filtered = allTasks
        .where((m) => m['sub_goal_id']?.toString() == params.subGoalId)
        .toList();
    return filtered.map((m) => GoalTask.fromMap(m)).toList();
  },
);

// ─── 목표 진행률 Provider ─────────────────────────────────────────────────

/// 특정 목표의 진행률 Provider (0.0 ~ 1.0)
/// 하위 할일 완료율에서 자동 계산한다
final goalProgressProvider =
    Provider.family<double, ({String goalId, List<SubGoal> subGoals, List<GoalTask> tasks})>(
  (ref, params) {
    return ProgressCalculator.calcGoalProgress(
      params.goalId,
      params.subGoals,
      params.tasks,
    );
  },
);

// ─── 목표 통계 Provider ───────────────────────────────────────────────────

/// 전체 목표 통계 Provider (달성률, 평균 진행률, 총 목표 수)
/// 현재 선택된 연도/기간의 목표들을 기반으로 계산한다
/// allGoalsRawProvider, allSubGoalsRawProvider, allGoalTasksRawProvider에서 파생한다
/// goalsByYearAndPeriodStreamProvider가 동기 Provider이므로 AsyncValue 래핑 불필요
final goalStatsProvider = Provider<GoalStats>((ref) {
  final year = ref.watch(selectedGoalYearProvider);
  final period = ref.watch(selectedGoalPeriodProvider);

  final goals = ref.watch(
    goalsByYearAndPeriodStreamProvider((year: year, period: period)),
  );

  if (goals.isEmpty) {
    return const GoalStats(achievementRate: 0, avgProgress: 0, totalGoalCount: 0);
  }

  // Single Source of Truth에서 파생하여 SubGoal/Task를 필터링한다
  final allSubGoalsRaw = ref.watch(allSubGoalsRawProvider);
  final allTasksRaw = ref.watch(allGoalTasksRawProvider);

  final goalIds = goals.map((g) => g.id).toSet();

  // 해당 목표들의 SubGoal을 필터링한다
  // goal_id가 String 또는 다른 타입일 수 있으므로 toString()으로 통일한다
  final allSubGoals = allSubGoalsRaw
      .where((m) => goalIds.contains(m['goal_id']?.toString()))
      .map((m) => SubGoal.fromMap(m))
      .toList();

  // 해당 SubGoal들의 Task를 필터링한다
  final subGoalIds = allSubGoals.map((sg) => sg.id).toSet();
  final allTasks = allTasksRaw
      .where((m) => subGoalIds.contains(m['sub_goal_id']?.toString()))
      .map((m) => GoalTask.fromMap(m))
      .toList();

  // ProgressCalculator.calcStats()로 달성률 + 평균 진행률을 정확히 계산한다
  return ProgressCalculator.calcStats(goals, allSubGoals, allTasks);
});
