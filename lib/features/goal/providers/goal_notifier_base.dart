// F5: GoalNotifier 기반 믹스인
// 모든 GoalNotifier 믹스인이 공유하는 리포지토리 접근자와 버전 관리 메서드를 정의한다.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/data_store_providers.dart';
import '../services/goal_repository.dart';
import '../services/sub_goal_repository.dart';
import '../services/task_repository.dart';

/// GoalNotifier 믹스인들이 공유하는 기반 인터페이스
/// 리포지토리 접근자와 데이터 버전 갱신 헬퍼를 정의한다
mixin GoalNotifierBaseMixin on StateNotifier<AsyncValue<void>> {
  /// 구현체에서 주입받는 리포지토리
  GoalRepository get goalRepo;
  SubGoalRepository get subGoalRepo;
  TaskRepository get taskRepo;
  Ref get notifierRef;

  /// 목표 + 하위 목표 + 실천 할일 버전 카운터를 모두 증가시킨다
  void bumpAllVersions() {
    notifierRef.read(goalDataVersionProvider.notifier).state++;
    notifierRef.read(subGoalDataVersionProvider.notifier).state++;
    notifierRef.read(goalTaskDataVersionProvider.notifier).state++;
  }

  /// 하위 목표 데이터가 변경된 경우 subGoal + goal 버전을 증가시킨다
  void bumpSubGoalVersions() {
    notifierRef.read(goalDataVersionProvider.notifier).state++;
    notifierRef.read(subGoalDataVersionProvider.notifier).state++;
  }

  /// 실천 할일 데이터가 변경된 경우 goalTask + goal 버전을 증가시킨다
  void bumpTaskVersions() {
    notifierRef.read(goalDataVersionProvider.notifier).state++;
    notifierRef.read(goalTaskDataVersionProvider.notifier).state++;
  }
}
