// F5: ProgressCalculator (F5.4) - 순수 함수
// List<Goal>, List<SubGoal>, List<GoalTask>를 받아
// achievementRate, avgProgress, totalGoalCount, 목표별 진행률을 계산한다.
// 하위 할일 완료율 → 상위 목표 진행률 자동 집계 로직을 구현한다.
import '../../../shared/models/goal.dart';
import '../../../shared/models/sub_goal.dart';
import '../../../shared/models/goal_task.dart';

/// 목표 통계 결과 데이터
class GoalStats {
  /// 달성률: 완료된 목표 수 / 전체 목표 수 (0.0 ~ 1.0)
  final double achievementRate;

  /// 평균 진행률: 각 목표의 진행률 평균 (0.0 ~ 1.0)
  final double avgProgress;

  /// 전체 목표 수
  final int totalGoalCount;

  const GoalStats({
    required this.achievementRate,
    required this.avgProgress,
    required this.totalGoalCount,
  });

  /// 퍼센트로 변환 (0 ~ 100)
  int get achievementPercent => (achievementRate * 100).round();

  /// 평균 진행률 퍼센트 (0 ~ 100)
  int get avgProgressPercent => (avgProgress * 100).round();
}

/// 목표 진행률 계산기 (F5.4 ProgressCalculator)
/// 순수 함수로만 구성되어 외부 의존성이 없다
/// 하위 할일 완료율 → 세부목표 진행률 → 년간 목표 진행률 순서로 집계한다
abstract class ProgressCalculator {
  // ─── 실천 할일 단위 계산 ─────────────────────────────────────────────────

  /// 특정 하위 목표의 tasks에서 진행률을 계산한다 (0.0 ~ 1.0)
  static double calcSubGoalProgress(
    String subGoalId,
    List<GoalTask> allTasks,
  ) {
    // 해당 하위 목표 소속 tasks만 필터링
    final tasks = allTasks.where((t) => t.subGoalId == subGoalId).toList();
    if (tasks.isEmpty) return 0.0;

    final completedCount = tasks.where((t) => t.isCompleted).length;
    return completedCount / tasks.length;
  }

  // ─── 목표 단위 계산 ───────────────────────────────────────────────────────

  /// 목표 하나의 진행률을 계산한다 (하위 목표들의 평균, 0.0 ~ 1.0)
  static double calcGoalProgress(
    String goalId,
    List<SubGoal> subGoals,
    List<GoalTask> allTasks,
  ) {
    // 해당 목표 소속 하위 목표만 필터링
    final goalSubGoals = subGoals.where((sg) => sg.goalId == goalId).toList();
    if (goalSubGoals.isEmpty) return 0.0;

    // 각 하위 목표의 진행률 평균
    final totalProgress = goalSubGoals.fold<double>(
      0.0,
      (sum, subGoal) => sum + calcSubGoalProgress(subGoal.id, allTasks),
    );
    return totalProgress / goalSubGoals.length;
  }

  // ─── 전체 통계 계산 ───────────────────────────────────────────────────────

  /// 전체 목표 목록으로 통계를 계산한다
  /// achievementRate: 완료된 목표 수 / 전체 목표 수
  /// avgProgress: 각 목표 진행률의 평균
  static GoalStats calcStats(
    List<Goal> goals,
    List<SubGoal> subGoals,
    List<GoalTask> tasks,
  ) {
    if (goals.isEmpty) {
      return const GoalStats(
        achievementRate: 0,
        avgProgress: 0,
        totalGoalCount: 0,
      );
    }

    // 달성률: 완료 목표 수 / 전체 목표 수
    final completedGoals = goals.where((g) => g.isCompleted).length;
    final achievementRate = completedGoals / goals.length;

    // 평균 진행률: 각 목표의 진행률 평균
    final totalProgress = goals.fold<double>(
      0.0,
      (sum, goal) => sum + calcGoalProgress(goal.id, subGoals, tasks),
    );
    final avgProgress = totalProgress / goals.length;

    return GoalStats(
      achievementRate: achievementRate,
      avgProgress: avgProgress,
      totalGoalCount: goals.length,
    );
  }

  /// 진행률에 따라 색상 채도를 결정하는 비율 (0.0 ~ 1.0)
  /// 만다라트 셀 색상 계산에 사용한다
  static double progressToSaturation(double progress) {
    // 진행률이 높을수록 더 진한(채도 높은) MAIN 색상으로 표시
    return progress.clamp(0.0, 1.0);
  }
}
