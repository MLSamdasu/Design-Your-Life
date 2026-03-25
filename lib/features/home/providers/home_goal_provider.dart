// F1: 홈 대시보드 — 목표 통계 Provider
// allGoalsRawProvider + allSubGoalsRawProvider + allGoalTasksRawProvider에서 파생하여
// 목표 CRUD 시 자동 갱신된다. ProgressCalculator 순수 함수를 사용한다.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/data_store_providers.dart';
import '../../../core/providers/global_providers.dart';
import '../../../shared/models/goal.dart';
import '../../../shared/models/goal_task.dart';
import '../../../shared/models/sub_goal.dart';
import '../../goal/services/progress_calculator.dart';
import 'home_models.dart';

/// 홈 대시보드용 목표 통계 Provider
/// 현재 연도의 전체 목표에서 달성률과 평균 진행률을 계산한다
/// goalStatsProvider(목표 화면)와 동일한 패턴으로 SubGoal/GoalTask를
/// 해당 목표 ID 기준으로 필터링한 후 calcStats에 전달한다
final todayGoalStatsProvider = Provider<GoalSummary>((ref) {
  final allGoalsRaw = ref.watch(allGoalsRawProvider);
  final allSubGoalsRaw = ref.watch(allSubGoalsRawProvider);
  final allGoalTasksRaw = ref.watch(allGoalTasksRawProvider);

  if (allGoalsRaw.isEmpty) return GoalSummary.empty;

  // 현재 연도 목표만 필터링한다 — 공유 todayDateProvider를 사용한다
  final currentYear = ref.watch(todayDateProvider).year;

  // Raw Map에서 현재 연도 목표만 파싱한다
  final yearGoals = allGoalsRaw
      .where((m) => (m['year'] as num?)?.toInt() == currentYear)
      .map((m) => Goal.fromMap(m))
      .toList();

  if (yearGoals.isEmpty) return GoalSummary.empty;

  // 해당 목표 ID 집합을 생성한다
  final goalIds = yearGoals.map((g) => g.id).toSet();

  // 해당 목표에 속한 SubGoal만 필터링한다 (Raw Map의 goal_id로 비교)
  // goal_id가 String 또는 다른 타입일 수 있으므로 toString()으로 통일한다
  final yearSubGoals = allSubGoalsRaw
      .where((m) => goalIds.contains(m['goal_id']?.toString()))
      .map((m) => SubGoal.fromMap(m))
      .toList();

  // 해당 SubGoal에 속한 GoalTask만 필터링한다
  final subGoalIds = yearSubGoals.map((sg) => sg.id).toSet();
  final yearTasks = allGoalTasksRaw
      .where((m) => subGoalIds.contains(m['sub_goal_id']?.toString()))
      .map((m) => GoalTask.fromMap(m))
      .toList();

  final stats = ProgressCalculator.calcStats(
    yearGoals,
    yearSubGoals,
    yearTasks,
  );

  return GoalSummary(
    totalCount: stats.totalGoalCount,
    completedCount: yearGoals.where((g) => g.isCompleted).length,
    achievementRate: stats.achievementRate,
    avgProgress: stats.avgProgress,
  );
});
