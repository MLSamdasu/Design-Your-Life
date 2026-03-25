// F5: 목표 리포지토리 + UI 상태 Provider
// GoalRepository, SubGoalRepository, TaskRepository Provider를 정의한다.
// 목표 화면 서브탭(GoalSubTab) 및 연도/기간 선택 상태도 포함한다.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/global_providers.dart';
import '../../../shared/enums/goal_period.dart';
import '../services/goal_repository.dart';
import '../services/sub_goal_repository.dart';
import '../services/task_repository.dart';

// ─── Repository Provider ─────────────────────────────────────────────────

/// 목표 리포지토리 Provider
/// HiveCacheService를 주입하여 로컬 퍼스트로 동작한다
final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  final cache = ref.watch(hiveCacheServiceProvider);
  return GoalRepository(cache: cache);
});

/// 하위 목표 리포지토리 Provider
/// HiveCacheService를 주입하여 로컬 퍼스트로 동작한다
final subGoalRepositoryProvider = Provider<SubGoalRepository>((ref) {
  final cache = ref.watch(hiveCacheServiceProvider);
  return SubGoalRepository(cache: cache);
});

/// 실천 할일 리포지토리 Provider
/// HiveCacheService를 주입하여 로컬 퍼스트로 동작한다
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final cache = ref.watch(hiveCacheServiceProvider);
  return TaskRepository(cache: cache);
});

// ─── 목표 서브탭 상태 Provider ────────────────────────────────────────────

/// 목표 화면 서브탭 유형
enum GoalSubTab { goalList, mandalart }

/// 목표 화면 서브탭 Provider (goalList / mandalart)
final goalSubTabProvider = StateProvider<GoalSubTab>((ref) {
  return GoalSubTab.goalList;
});

// ─── 목표 연도 선택 Provider ─────────────────────────────────────────────

/// 현재 선택된 연도 Provider
final selectedGoalYearProvider = StateProvider<int>((ref) {
  return DateTime.now().year;
});

/// 현재 선택된 기간 유형 Provider (년간/월간)
final selectedGoalPeriodProvider = StateProvider<GoalPeriod>((ref) {
  return GoalPeriod.yearly;
});
