// F5: 목표 Riverpod Provider
// goalsProvider, subGoalsProvider, tasksByGoalProvider,
// goalProgressProvider, goalStatsProvider 등을 정의한다.
// 로컬 퍼스트 아키텍처: Hive 로컬 박스에서 데이터를 조회한다.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../core/providers/global_providers.dart';
import '../../../shared/models/goal.dart';
import '../../../shared/models/sub_goal.dart';
import '../../../shared/models/goal_task.dart';
import '../../../shared/enums/goal_period.dart';
import '../services/goal_repository.dart';
import '../services/sub_goal_repository.dart';
import '../services/task_repository.dart';
import '../services/progress_calculator.dart';

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

// ─── 목표 목록 Provider ─────────────────────────────────────────────────

/// 전체 목표 목록 Provider (FutureProvider)
/// 로컬 Hive에서 동기적으로 읽되 FutureProvider 인터페이스를 유지한다
final goalsStreamProvider = FutureProvider<List<Goal>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const [];

  // 로컬 퍼스트: Hive에서 동기 조회한다
  return ref.watch(goalRepositoryProvider).getGoals();
});

/// 연도별 목표 Provider (FutureProvider.family)
/// 로컬 Hive에서 year 필드로 필터링하여 조회한다
final goalsByYearStreamProvider =
    FutureProvider.family<List<Goal>, int>((ref, year) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const [];

  // 로컬 퍼스트: Hive에서 year 필드로 필터링하여 동기 조회한다
  return ref.watch(goalRepositoryProvider).getGoalsByYear(year);
});

/// 연도/기간 유형별 목표 Provider (FutureProvider.family)
/// 로컬 Hive에서 year + period 복합 필터링하여 조회한다
final goalsByYearAndPeriodStreamProvider = FutureProvider.family<List<Goal>,
    ({int year, GoalPeriod period})>((ref, params) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const [];

  // 로컬 퍼스트: Hive에서 year + period로 필터링하여 동기 조회한다
  return ref
      .watch(goalRepositoryProvider)
      .getGoalsByYearAndPeriod(params.year, params.period);
});

// ─── 하위 목표 Provider ────────────────────────────────────────────

/// 특정 목표의 하위 목표 목록 Provider (FutureProvider.family)
/// 로컬 subGoalsBox에서 goal_id로 필터링하여 조회한다
final subGoalsStreamProvider =
    FutureProvider.family<List<SubGoal>, String>((ref, goalId) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const [];

  // 로컬 퍼스트: Hive subGoalsBox에서 goal_id로 필터링하여 동기 조회한다
  return ref.watch(subGoalRepositoryProvider).getSubGoals(goalId);
});

// ─── 실천 할일 Provider ────────────────────────────────────────────

/// 특정 목표의 전체 실천 할일 목록 Provider (FutureProvider.family)
/// 해당 목표의 하위 목표 ID 목록을 조회한 뒤 goalTasksBox에서 일괄 필터링한다
final tasksByGoalStreamProvider =
    FutureProvider.family<List<GoalTask>, String>((ref, goalId) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const [];

  // 목표에 속한 하위 목표 ID 목록을 먼저 수집한다
  final subGoals =
      ref.watch(subGoalRepositoryProvider).getSubGoals(goalId);
  final subGoalIds = subGoals.map((sg) => sg.id).toList();
  // goalTasksBox에서 해당 하위 목표들의 할일을 일괄 조회한다
  return ref.watch(taskRepositoryProvider).getTasksByGoal(subGoalIds);
});

/// 특정 하위 목표의 실천 할일 Provider (FutureProvider.family)
/// 로컬 goalTasksBox에서 sub_goal_id로 필터링하여 조회한다
final tasksBySubGoalStreamProvider =
    FutureProvider.family<List<GoalTask>, ({String goalId, String subGoalId})>(
  (ref, params) async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return const [];

    // 로컬 퍼스트: Hive goalTasksBox에서 sub_goal_id로 필터링하여 동기 조회한다
    return ref
        .watch(taskRepositoryProvider)
        .getTasksBySubGoal(params.goalId, params.subGoalId);
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
final goalStatsProvider = Provider<AsyncValue<GoalStats>>((ref) {
  final year = ref.watch(selectedGoalYearProvider);
  final period = ref.watch(selectedGoalPeriodProvider);

  final goalsAsync = ref.watch(
    goalsByYearAndPeriodStreamProvider((year: year, period: period)),
  );

  return goalsAsync.when(
    data: (goals) {
      if (goals.isEmpty) {
        return const AsyncData(
          GoalStats(achievementRate: 0, avgProgress: 0, totalGoalCount: 0),
        );
      }

      // 달성률: 완료 표시된 목표 수 / 전체 목표 수
      final completedCount = goals.where((g) => g.isCompleted).length;
      final achievementRate =
          goals.isEmpty ? 0.0 : completedCount / goals.length;

      return AsyncData(
        GoalStats(
          achievementRate: achievementRate,
          avgProgress: achievementRate,
          totalGoalCount: goals.length,
        ),
      );
    },
    loading: () => const AsyncLoading(),
    error: (e, st) => AsyncError(e, st),
  );
});

// ─── 목표 CRUD Notifier ───────────────────────────────────────────────────

/// 목표 생성/수정/삭제 작업을 처리하는 Notifier
class GoalNotifier extends StateNotifier<AsyncValue<void>> {
  final GoalRepository _goalRepo;
  final SubGoalRepository _subGoalRepo;
  final TaskRepository _taskRepo;
  final Ref _ref;

  GoalNotifier({
    required GoalRepository goalRepo,
    required SubGoalRepository subGoalRepo,
    required TaskRepository taskRepo,
    required Ref ref,
  })  : _goalRepo = goalRepo,
        _subGoalRepo = subGoalRepo,
        _taskRepo = taskRepo,
        _ref = ref,
        super(const AsyncData(null));

  /// 새 목표를 생성한다
  Future<String?> createGoal(Goal goal) async {
    state = const AsyncLoading();
    try {
      final created = await _goalRepo.createGoal(goal);
      state = const AsyncData(null);
      // 생성 후 목표 목록을 다시 로드한다
      _ref.invalidate(goalsStreamProvider);
      return created.id;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  /// 목표 완료 상태를 토글한다
  Future<void> toggleGoalCompletion(String goalId, bool isCompleted) async {
    state = const AsyncLoading();
    try {
      await _goalRepo.toggleGoalCompletion(goalId, isCompleted);
      state = const AsyncData(null);
      _ref.invalidate(goalsStreamProvider);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// 새 하위 목표를 생성한다
  Future<String?> createSubGoal(String goalId, SubGoal subGoal) async {
    state = const AsyncLoading();
    try {
      final created = await _subGoalRepo.createSubGoal(goalId, subGoal);
      state = const AsyncData(null);
      // 하위 목표 목록과 관련 통계/진행률을 모두 갱신한다
      _ref.invalidate(subGoalsStreamProvider(goalId));
      _ref.invalidate(tasksByGoalStreamProvider(goalId));
      _ref.invalidate(goalsStreamProvider);
      return created.id;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  /// 새 실천 할일을 생성한다
  Future<String?> createTask(String goalId, GoalTask task) async {
    state = const AsyncLoading();
    try {
      final created = await _taskRepo.createTask(goalId, task);
      state = const AsyncData(null);
      _ref.invalidate(tasksByGoalStreamProvider(goalId));
      return created.id;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  /// 실천 할일 완료 상태를 토글한다
  Future<void> toggleTaskCompletion(
    String goalId,
    String taskId,
    bool isCompleted,
  ) async {
    state = const AsyncLoading();
    try {
      await _taskRepo.toggleTaskCompletion(goalId, taskId, isCompleted);
      state = const AsyncData(null);
      // 할일 목록과 관련 진행률/통계를 모두 갱신한다
      _ref.invalidate(tasksByGoalStreamProvider(goalId));
      _ref.invalidate(goalsStreamProvider);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

/// 목표 Notifier Provider
final goalNotifierProvider =
    StateNotifierProvider<GoalNotifier, AsyncValue<void>>((ref) {
  return GoalNotifier(
    goalRepo: ref.watch(goalRepositoryProvider),
    subGoalRepo: ref.watch(subGoalRepositoryProvider),
    taskRepo: ref.watch(taskRepositoryProvider),
    ref: ref,
  );
});
