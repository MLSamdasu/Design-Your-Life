// F5: 만다라트 Riverpod Provider
// mandalartViewStateProvider: MandalartMapper(F5.5)를 통해 MandalartGrid를 생성한다.
// 서버에 저장하지 않고 Goal/SubGoal/GoalTask 데이터에서 실시간 파생한다.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/layout_tokens.dart';
import '../../../shared/models/mandalart_grid.dart';
import '../services/mandalart_mapper.dart';
import 'goal_provider.dart';

// ─── 선택된 목표 Provider ─────────────────────────────────────────────────

/// 현재 만다라트에서 선택된 목표 ID Provider
/// null이면 만다라트가 없는 상태
final selectedMandalartGoalIdProvider = StateProvider<String?>((ref) => null);

/// 현재 만다라트에서 확대된 세부목표 인덱스 Provider (AN-11 줌)
/// null이면 전체 9x9 뷰
final zoomedSubGoalIndexProvider = StateProvider<int?>((ref) => null);

// ─── 만다라트 그리드 Provider ─────────────────────────────────────────────

/// 특정 목표 ID로 MandalartGrid를 생성하는 Provider
/// Goal + SubGoal + GoalTask를 MandalartMapper로 변환한다
/// 특정 목표 ID로 MandalartGrid를 생성하는 Provider
/// Goal + SubGoal + GoalTask는 모두 동기 Provider이므로 AsyncValue 래핑이 불필요하다
final mandalartGridProvider =
    Provider.family<MandalartGrid?, String>((ref, goalId) {
  // 목표 데이터 watch — 모두 동기 Provider이므로 직접 사용한다
  final goals = ref.watch(goalsStreamProvider);
  final subGoals = ref.watch(subGoalsStreamProvider(goalId));
  final tasks = ref.watch(tasksByGoalStreamProvider(goalId));

  // 해당 목표 찾기
  final goal = goals.where((g) => g.id == goalId).firstOrNull;
  if (goal == null) return null;

  // MandalartMapper로 그리드 생성
  return MandalartMapper.map(
    goal: goal,
    subGoals: subGoals,
    tasks: tasks,
  );
});

/// 현재 선택된 목표의 MandalartGrid Provider — 동기 Provider
final currentMandalartGridProvider = Provider<MandalartGrid?>((ref) {
  final selectedGoalId = ref.watch(selectedMandalartGoalIdProvider);
  if (selectedGoalId == null) return null;

  return ref.watch(mandalartGridProvider(selectedGoalId));
});

// ─── 만다라트 위저드 상태 Provider ───────────────────────────────────────

/// 위저드 현재 단계 Provider (1: 핵심 목표, 2: 세부 목표, 3: 실천 과제)
final wizardStepProvider = StateProvider<int>((ref) => 1);

/// 위저드 핵심 목표 입력 Provider
final wizardCoreGoalProvider = StateProvider<String>((ref) => '');

/// 위저드 세부 목표 8개 입력 Provider (index: 0~7)
final wizardSubGoalInputsProvider =
    StateProvider<List<String>>((ref) => List.filled(AppLayout.mandalartSubGoalCount, ''));

/// 위저드 실천 과제 입력 Provider (subGoalIndex: 0~7, taskIndex: 0~7)
final wizardTaskInputsProvider =
    StateProvider<Map<int, List<String>>>((ref) => {
      for (int i = 0; i < AppLayout.mandalartSubGoalCount; i++) i: List.filled(AppLayout.mandalartSubGoalCount, ''),
    });

/// 위저드 상태를 초기화한다
void resetWizard(WidgetRef ref) {
  ref.read(wizardStepProvider.notifier).state = 1;
  ref.read(wizardCoreGoalProvider.notifier).state = '';
  ref.read(wizardSubGoalInputsProvider.notifier).state = List.filled(AppLayout.mandalartSubGoalCount, '');
  ref.read(wizardTaskInputsProvider.notifier).state = {
    for (int i = 0; i < AppLayout.mandalartSubGoalCount; i++) i: List.filled(AppLayout.mandalartSubGoalCount, ''),
  };
}
