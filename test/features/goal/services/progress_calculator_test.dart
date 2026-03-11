// ProgressCalculator 순수 함수 테스트
// 하위 목표 진행률, 목표 진행률, 전체 통계 계산을 검증한다.
import 'package:design_your_life/features/goal/services/progress_calculator.dart';
import 'package:design_your_life/shared/enums/goal_period.dart';
import 'package:design_your_life/shared/models/goal.dart';
import 'package:design_your_life/shared/models/goal_task.dart';
import 'package:design_your_life/shared/models/sub_goal.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2026, 3, 9);

GoalTask _task(String id, String subGoalId, {bool isCompleted = false}) {
  return GoalTask(
    id: id,
    subGoalId: subGoalId,
    title: '할일 $id',
    isCompleted: isCompleted,
    orderIndex: 0,
    createdAt: _now,
  );
}

SubGoal _subGoal(String id, String goalId) {
  return SubGoal(
    id: id,
    goalId: goalId,
    title: '세부목표 $id',
    orderIndex: 0,
    createdAt: _now,
  );
}

Goal _goal(String id, {bool isCompleted = false}) {
  return Goal(
    id: id,
    userId: 'user-1',
    title: '목표 $id',
    period: GoalPeriod.yearly,
    year: 2026,
    isCompleted: isCompleted,
    createdAt: _now,
    updatedAt: _now,
  );
}

void main() {
  group('ProgressCalculator - calcSubGoalProgress', () {
    test('tasks가 없으면 0.0을 반환한다', () {
      final result = ProgressCalculator.calcSubGoalProgress('sg-1', []);
      expect(result, 0.0);
    });

    test('모든 tasks가 완료되면 1.0을 반환한다', () {
      final tasks = [
        _task('t1', 'sg-1', isCompleted: true),
        _task('t2', 'sg-1', isCompleted: true),
      ];
      final result = ProgressCalculator.calcSubGoalProgress('sg-1', tasks);
      expect(result, 1.0);
    });

    test('반만 완료되면 0.5를 반환한다', () {
      final tasks = [
        _task('t1', 'sg-1', isCompleted: true),
        _task('t2', 'sg-1', isCompleted: false),
      ];
      final result = ProgressCalculator.calcSubGoalProgress('sg-1', tasks);
      expect(result, 0.5);
    });

    test('다른 subGoalId의 tasks는 무시한다', () {
      final tasks = [
        _task('t1', 'sg-1', isCompleted: true),
        _task('t2', 'sg-2', isCompleted: false),
      ];
      final result = ProgressCalculator.calcSubGoalProgress('sg-1', tasks);
      expect(result, 1.0);
    });
  });

  group('ProgressCalculator - calcGoalProgress', () {
    test('하위 목표가 없으면 0.0을 반환한다', () {
      final result = ProgressCalculator.calcGoalProgress('g-1', [], []);
      expect(result, 0.0);
    });

    test('모든 하위 목표의 tasks가 완료되면 1.0을 반환한다', () {
      final subGoals = [_subGoal('sg-1', 'g-1'), _subGoal('sg-2', 'g-1')];
      final tasks = [
        _task('t1', 'sg-1', isCompleted: true),
        _task('t2', 'sg-2', isCompleted: true),
      ];
      final result =
          ProgressCalculator.calcGoalProgress('g-1', subGoals, tasks);
      expect(result, 1.0);
    });

    test('하위 목표별 진행률 평균을 반환한다', () {
      final subGoals = [_subGoal('sg-1', 'g-1'), _subGoal('sg-2', 'g-1')];
      final tasks = [
        _task('t1', 'sg-1', isCompleted: true),
        _task('t2', 'sg-1', isCompleted: true),
        // sg-2는 tasks 없음 -> 진행률 0
      ];
      final result =
          ProgressCalculator.calcGoalProgress('g-1', subGoals, tasks);
      // sg-1: 1.0, sg-2: 0.0 -> 평균 0.5
      expect(result, 0.5);
    });
  });

  group('ProgressCalculator - calcStats', () {
    test('목표가 없으면 모든 통계가 0이다', () {
      final stats = ProgressCalculator.calcStats([], [], []);
      expect(stats.achievementRate, 0);
      expect(stats.avgProgress, 0);
      expect(stats.totalGoalCount, 0);
    });

    test('achievementRate가 완료 목표 비율을 반환한다', () {
      final goals = [
        _goal('g-1', isCompleted: true),
        _goal('g-2', isCompleted: false),
      ];
      final stats = ProgressCalculator.calcStats(goals, [], []);
      expect(stats.achievementRate, 0.5);
      expect(stats.achievementPercent, 50);
    });

    test('totalGoalCount가 정확하다', () {
      final goals = [_goal('g-1'), _goal('g-2'), _goal('g-3')];
      final stats = ProgressCalculator.calcStats(goals, [], []);
      expect(stats.totalGoalCount, 3);
    });
  });

  group('ProgressCalculator - progressToSaturation', () {
    test('0.0 이하를 0.0으로 클램핑한다', () {
      expect(ProgressCalculator.progressToSaturation(-0.5), 0.0);
    });

    test('1.0 이상을 1.0으로 클램핑한다', () {
      expect(ProgressCalculator.progressToSaturation(1.5), 1.0);
    });

    test('범위 내 값을 그대로 반환한다', () {
      expect(ProgressCalculator.progressToSaturation(0.5), 0.5);
    });
  });

  group('GoalStats', () {
    test('achievementPercent가 정수 퍼센트를 반환한다', () {
      const stats = GoalStats(
        achievementRate: 0.333,
        avgProgress: 0.666,
        totalGoalCount: 3,
      );
      expect(stats.achievementPercent, 33);
      expect(stats.avgProgressPercent, 67);
    });
  });
}
