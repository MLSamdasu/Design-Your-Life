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

SubGoal _subGoal(String id, String goalId, {bool isCompleted = false}) {
  return SubGoal(
    id: id,
    goalId: goalId,
    title: '세부목표 $id',
    isCompleted: isCompleted,
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

    test('SubGoal과 GoalTask가 모두 완료되면 1.0을 반환한다', () {
      // SubGoal 2개 (모두 완료) + GoalTask 2개 (모두 완료) = 4/4 = 1.0
      final subGoals = [
        _subGoal('sg-1', 'g-1', isCompleted: true),
        _subGoal('sg-2', 'g-1', isCompleted: true),
      ];
      final tasks = [
        _task('t1', 'sg-1', isCompleted: true),
        _task('t2', 'sg-2', isCompleted: true),
      ];
      final result =
          ProgressCalculator.calcGoalProgress('g-1', subGoals, tasks);
      expect(result, 1.0);
    });

    test('SubGoal과 GoalTask 완료 수 합산으로 진행률을 계산한다', () {
      // SubGoal 2개 (1완료) + GoalTask 2개 (1완료) = 2/4 = 0.5
      final subGoals = [
        _subGoal('sg-1', 'g-1', isCompleted: true),
        _subGoal('sg-2', 'g-1'),
      ];
      final tasks = [
        _task('t1', 'sg-1', isCompleted: true),
        _task('t2', 'sg-2', isCompleted: false),
      ];
      final result =
          ProgressCalculator.calcGoalProgress('g-1', subGoals, tasks);
      expect(result, 0.5);
    });

    test('GoalTask만 완료되고 SubGoal은 미완료일 때 부분 진행률을 반환한다', () {
      // SubGoal 1개 (미완료) + GoalTask 2개 (모두 완료) = 2/3
      final subGoals = [_subGoal('sg-1', 'g-1')];
      final tasks = [
        _task('t1', 'sg-1', isCompleted: true),
        _task('t2', 'sg-1', isCompleted: true),
      ];
      final result =
          ProgressCalculator.calcGoalProgress('g-1', subGoals, tasks);
      // 0 + 2 = 2 completed, 1 + 2 = 3 total → 2/3
      expect(result, closeTo(0.6667, 0.001));
    });

    test('체크포인트 모드: tasks 없으면 SubGoal isCompleted로 계산한다', () {
      final subGoals = [
        _subGoal('sg-1', 'g-1', isCompleted: true),
        _subGoal('sg-2', 'g-1'),
      ];
      final result =
          ProgressCalculator.calcGoalProgress('g-1', subGoals, []);
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

    test('avgProgress가 SubGoal과 GoalTask를 포함하여 정확히 계산된다', () {
      // 목표 1개 + SubGoal 2개(1완료) + GoalTask 2개(1완료) = 2/4 = 0.5
      final goals = [_goal('g-1')];
      final subGoals = [
        _subGoal('sg-1', 'g-1', isCompleted: true),
        _subGoal('sg-2', 'g-1'),
      ];
      final tasks = [
        _task('t1', 'sg-1', isCompleted: true),
        _task('t2', 'sg-2'),
      ];
      final stats = ProgressCalculator.calcStats(goals, subGoals, tasks);
      expect(stats.avgProgress, 0.5);
      expect(stats.avgProgressPercent, 50);
    });

    test('avgProgress가 여러 목표의 진행률 평균을 반환한다', () {
      // 목표 2개:
      // g-1: SubGoal 2개(2완료) + Task 2개(2완료) = 4/4 = 1.0
      // g-2: SubGoal 1개(0완료) + Task 0개 = 체크포인트 모드 0/1 = 0.0
      // 평균: (1.0 + 0.0) / 2 = 0.5
      final goals = [_goal('g-1'), _goal('g-2')];
      final subGoals = [
        _subGoal('sg-1', 'g-1', isCompleted: true),
        _subGoal('sg-2', 'g-1', isCompleted: true),
        _subGoal('sg-3', 'g-2'),
      ];
      final tasks = [
        _task('t1', 'sg-1', isCompleted: true),
        _task('t2', 'sg-2', isCompleted: true),
      ];
      final stats = ProgressCalculator.calcStats(goals, subGoals, tasks);
      expect(stats.avgProgress, 0.5);
    });

    test('SubGoal이 없는 목표의 avgProgress는 0이다', () {
      // SubGoal이 없으면 calcGoalProgress가 0.0을 반환한다
      final goals = [_goal('g-1')];
      final stats = ProgressCalculator.calcStats(goals, [], []);
      expect(stats.avgProgress, 0.0);
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
