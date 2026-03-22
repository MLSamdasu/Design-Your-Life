// F5: 목표 Riverpod Provider
// goalsProvider, subGoalsProvider, tasksByGoalProvider,
// goalProgressProvider, goalStatsProvider 등을 정의한다.
// 로컬 퍼스트 아키텍처: Hive 로컬 박스에서 데이터를 조회한다.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/error/error_handler.dart';
import '../../../core/providers/data_store_providers.dart';
import '../../../core/providers/global_providers.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/models/goal.dart';
import '../../../shared/models/sub_goal.dart';
import '../../../shared/models/goal_task.dart';
import '../../../shared/enums/goal_period.dart';
import '../../achievement/providers/achievement_provider.dart';
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
    final year = m['year'] as int?;
    final period = m['period'] as String?;
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
  final filtered = allSubGoals.where((m) => m['goal_id'] == goalId).toList();
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
  final subGoalIds = allSubGoals
      .where((m) => m['goal_id'] == goalId)
      .map((m) => m['id'] as String)
      .toSet();

  // 해당 하위 목표들의 할일을 필터링한다
  final filtered = allTasks
      .where((m) => subGoalIds.contains(m['sub_goal_id']))
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
    final filtered = allTasks
        .where((m) => m['sub_goal_id'] == params.subGoalId)
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
  final allSubGoals = allSubGoalsRaw
      .where((m) => goalIds.contains(m['goal_id']))
      .map((m) => SubGoal.fromMap(m))
      .toList();

  // 해당 SubGoal들의 Task를 필터링한다
  final subGoalIds = allSubGoals.map((sg) => sg.id).toSet();
  final allTasks = allTasksRaw
      .where((m) => subGoalIds.contains(m['sub_goal_id']))
      .map((m) => GoalTask.fromMap(m))
      .toList();

  // ProgressCalculator.calcStats()로 달성률 + 평균 진행률을 정확히 계산한다
  return ProgressCalculator.calcStats(goals, allSubGoals, allTasks);
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

  /// 목표 + 하위 목표 + 실천 할일 버전 카운터를 모두 증가시킨다
  /// 목표 삭제 등 모든 계층에 영향을 주는 작업에서 사용한다
  void _bumpAllGoalVersions() {
    _ref.read(goalDataVersionProvider.notifier).state++;
    _ref.read(subGoalDataVersionProvider.notifier).state++;
    _ref.read(goalTaskDataVersionProvider.notifier).state++;
  }

  /// P1-7: 목표 데이터만 변경된 경우 goal 버전만 증가시킨다
  void _bumpGoalVersion() {
    _ref.read(goalDataVersionProvider.notifier).state++;
  }

  /// P1-7: 하위 목표 데이터가 변경된 경우 subGoal + goal 버전을 증가시킨다
  /// (통계/진행률이 goal 파생 Provider에 포함되므로 goal도 함께 갱신)
  void _bumpSubGoalVersions() {
    _ref.read(goalDataVersionProvider.notifier).state++;
    _ref.read(subGoalDataVersionProvider.notifier).state++;
  }

  /// P1-7: 실천 할일 데이터가 변경된 경우 goalTask + goal 버전을 증가시킨다
  /// (진행률 재계산을 위해 goal도 함께 갱신)
  void _bumpTaskVersions() {
    _ref.read(goalDataVersionProvider.notifier).state++;
    _ref.read(goalTaskDataVersionProvider.notifier).state++;
  }

  /// 새 목표를 생성한다
  Future<String?> createGoal(Goal goal) async {
    state = const AsyncLoading();
    try {
      final created = await _goalRepo.createGoal(goal);
      state = const AsyncData(null);
      // P1-7: 목표만 생성했으므로 goal 버전만 증가시킨다
      _bumpGoalVersion();
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
      // P1-7: 목표 상태만 변경했으므로 goal 버전만 증가시킨다
      _bumpGoalVersion();

      // 완료로 전환된 경우 업적 달성 조건을 확인한다
      if (isCompleted) {
        await checkAchievementsAndNotify(_ref);
      }
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// 목표와 체크포인트를 원자적으로 생성한다
  /// state 변경(AsyncLoading/AsyncData)과 버전 갱신을 딱 한 번만 수행하여
  /// 다이얼로그에서 연속 호출 시 _dependents.isEmpty 크래시를 방지한다
  ///
  /// [checkpointTitles]가 비어있으면 목표만 생성한다
  Future<String?> createGoalWithCheckpoints(
    Goal goal,
    List<String> checkpointTitles,
  ) async {
    try {
      // 1. 목표 생성 (state 변경 없이 Hive에만 저장)
      final created = await _goalRepo.createGoal(goal);
      final goalId = created.id;

      // 2. 체크포인트 일괄 생성 (state 변경 없이 Hive에만 저장)
      final now = DateTime.now();
      for (int i = 0; i < checkpointTitles.length; i++) {
        final subGoal = SubGoal(
          id: '',
          goalId: goalId,
          title: checkpointTitles[i],
          isCompleted: false,
          orderIndex: i,
          createdAt: now,
        );
        await _subGoalRepo.createSubGoal(goalId, subGoal);
      }

      // 3. 모든 Hive 쓰기 완료 후 한 번만 버전 갱신
      // 목표 + 하위 목표를 함께 생성했으므로 양쪽 버전을 증가시킨다
      _bumpSubGoalVersions();
      return goalId;
    } catch (e, stack) {
      // 에러를 기록하여 프로덕션 환경에서도 원인 추적이 가능하도록 한다
      ErrorHandler.logServiceError('GoalProvider:createGoalWithCheckpoints', e, stack);
      return null;
    }
  }

  /// 만다라트 전체(핵심 목표 + 8 세부 목표 + 64 실천 과제)를 원자적으로 생성한다
  /// state 변경 없이 Hive에 모두 저장한 뒤 한 번만 버전을 갱신하여
  /// _dependents.isEmpty 크래시를 방지한다
  Future<String?> createMandalart(
    Goal goal,
    List<String> subGoalTitles,
    List<List<String>> taskTitles,
  ) async {
    // 롤백을 위해 생성된 ID를 추적한다
    final createdSubGoalIds = <String>[];
    final createdTaskIds = <String>[];
    String? createdGoalId;

    try {
      // 1. 핵심 목표 생성
      final created = await _goalRepo.createGoal(goal);
      final goalId = created.id;
      createdGoalId = goalId;
      final now = DateTime.now();

      // 2. 세부 목표 8개 + 각각의 실천 과제 8개 생성
      for (int i = 0; i < subGoalTitles.length; i++) {
        final subGoal = SubGoal(
          id: '',
          goalId: goalId,
          title: subGoalTitles[i],
          isCompleted: false,
          orderIndex: i,
          createdAt: now,
        );
        final createdSg = await _subGoalRepo.createSubGoal(goalId, subGoal);
        createdSubGoalIds.add(createdSg.id);

        // 해당 세부 목표의 실천 과제 생성
        if (i < taskTitles.length) {
          for (int j = 0; j < taskTitles[i].length; j++) {
            final task = GoalTask(
              id: '',
              subGoalId: createdSg.id,
              title: taskTitles[i][j],
              isCompleted: false,
              orderIndex: j,
              createdAt: now,
            );
            final createdTask = await _taskRepo.createTask(goalId, task);
            createdTaskIds.add(createdTask.id);
          }
        }
      }

      // 3. 모든 Hive 쓰기 완료 후 한 번만 버전 갱신
      // 만다라트는 목표 + 하위 목표 + 실천 할일을 모두 생성하므로 전체 갱신
      _bumpAllGoalVersions();
      return goalId;
    } catch (e, stack) {
      // 실패 시 이미 생성된 항목을 역순으로 삭제하여 고아 데이터를 방지한다
      for (final taskId in createdTaskIds) {
        try {
          await _taskRepo.deleteTask(createdGoalId ?? '', taskId);
        } catch (_) {
          // 클린업 실패는 무시한다 (원본 에러가 우선)
        }
      }
      for (final sgId in createdSubGoalIds) {
        try {
          await _subGoalRepo.deleteSubGoal(createdGoalId ?? '', sgId);
        } catch (_) {
          // 클린업 실패는 무시한다
        }
      }
      if (createdGoalId != null) {
        try {
          await _goalRepo.deleteGoal(createdGoalId);
        } catch (_) {
          // 클린업 실패는 무시한다
        }
      }

      ErrorHandler.logServiceError('GoalProvider:createMandalart', e, stack);
      return null;
    }
  }

  /// 새 하위 목표를 생성한다
  Future<String?> createSubGoal(String goalId, SubGoal subGoal) async {
    state = const AsyncLoading();
    try {
      final created = await _subGoalRepo.createSubGoal(goalId, subGoal);
      state = const AsyncData(null);
      // P1-7: 하위 목표를 생성했으므로 subGoal + goal 버전을 증가시킨다
      _bumpSubGoalVersions();
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
      // P1-7: 실천 할일을 생성했으므로 goalTask + goal 버전을 증가시킨다
      _bumpTaskVersions();
      return created.id;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  /// 목표를 수정한다
  Future<void> updateGoal(String goalId, Goal goal) async {
    state = const AsyncLoading();
    try {
      await _goalRepo.updateGoal(goalId, goal);
      state = const AsyncData(null);
      // P1-7: 목표만 수정했으므로 goal 버전만 증가시킨다
      _bumpGoalVersion();
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// 하위 목표를 수정한다
  Future<void> updateSubGoal(
    String goalId,
    String subGoalId,
    SubGoal subGoal,
  ) async {
    state = const AsyncLoading();
    try {
      await _subGoalRepo.updateSubGoal(goalId, subGoal);
      state = const AsyncData(null);
      // P1-7: 하위 목표를 수정했으므로 subGoal + goal 버전을 증가시킨다
      _bumpSubGoalVersions();
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// 체크포인트(하위 목표) 완료 상태만 토글한다
  /// 전체 화면 깜빡임을 방지하기 위해 AsyncLoading을 설정하지 않고,
  /// subGoalDataVersionProvider만 증가시켜 최소한의 리빌드만 발생시킨다
  Future<bool> toggleSubGoalCompletion(
    String goalId,
    String subGoalId,
    bool isCompleted,
  ) async {
    try {
      // 기존 하위 목표를 읽어 isCompleted만 변경한다
      final existing = _subGoalRepo.getSubGoals(goalId);
      // orElse로 StateError 크래시를 방지한다
      final idx = existing.indexWhere((sg) => sg.id == subGoalId);
      if (idx == -1) return false;
      final target = existing[idx];
      final updated = target.copyWith(isCompleted: isCompleted);
      await _subGoalRepo.updateSubGoal(goalId, updated);
      // 하위 목표 완료 토글 시 진행률 재계산을 위해 subGoal + goal 버전을 함께 증가시킨다
      _bumpSubGoalVersions();
      return true;
    } catch (e, stack) {
      ErrorHandler.logServiceError('GoalProvider:toggleSubGoalCompletion', e, stack);
      return false;
    }
  }

  /// 목표를 삭제한다 (연계 삭제: 실천 할일 → 하위 목표 → 목표)
  Future<void> deleteGoal(String goalId) async {
    state = const AsyncLoading();
    try {
      // 하위 목표 목록을 먼저 조회하여 연계 할일을 삭제한다
      final subGoals = _subGoalRepo.getSubGoals(goalId);
      for (final sg in subGoals) {
        await _taskRepo.deleteTasksBySubGoal(sg.id);
      }
      await _subGoalRepo.deleteSubGoalsByGoal(goalId);
      await _goalRepo.deleteGoal(goalId);
      state = const AsyncData(null);
      // 목표 삭제는 모든 계층에 영향을 주므로 전체 버전을 증가시킨다
      _bumpAllGoalVersions();
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// 하위 목표를 삭제한다 (연계 삭제: 실천 할일 → 하위 목표)
  Future<void> deleteSubGoal(String goalId, String subGoalId) async {
    state = const AsyncLoading();
    try {
      await _taskRepo.deleteTasksBySubGoal(subGoalId);
      await _subGoalRepo.deleteSubGoal(goalId, subGoalId);
      state = const AsyncData(null);
      // 하위 목표 삭제 시 연계 할일도 삭제하므로 전체 버전을 증가시킨다
      _bumpAllGoalVersions();
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// 실천 할일을 수정한다
  Future<void> updateTask(String goalId, String taskId, GoalTask task) async {
    state = const AsyncLoading();
    try {
      await _taskRepo.updateTask(goalId, taskId, task);
      state = const AsyncData(null);
      // P1-7: 실천 할일을 수정했으므로 goalTask + goal 버전을 증가시킨다
      _bumpTaskVersions();
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// 실천 할일을 삭제한다
  Future<void> deleteTask(String goalId, String taskId) async {
    state = const AsyncLoading();
    try {
      await _taskRepo.deleteTask(goalId, taskId);
      state = const AsyncData(null);
      // P1-7: 실천 할일을 삭제했으므로 goalTask + goal 버전을 증가시킨다
      _bumpTaskVersions();
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// 실천 할일 완료 상태를 토글한다
  /// P1-6: UI flicker 방지를 위해 AsyncLoading 설정 없이 Hive에 저장한 뒤
  /// goalTaskDataVersionProvider만 증가시켜 최소한의 리빌드만 발생시킨다
  Future<void> toggleTaskCompletion(
    String goalId,
    String taskId,
    bool isCompleted,
  ) async {
    try {
      await _taskRepo.toggleTaskCompletion(goalId, taskId, isCompleted);
      // 실천 할일 완료 토글 시 진행률 재계산을 위해 goalTask + goal 버전을 함께 증가시킨다
      _bumpTaskVersions();

      // Bug 6 Fix: 실천 할일 완료 시 업적 달성 조건을 확인한다
      if (isCompleted) {
        await checkAchievementsAndNotify(_ref);
      }
    } catch (e, stack) {
      // 토글 실패를 구조화된 에러 핸들러로 기록한다
      ErrorHandler.logServiceError('GoalProvider:toggleTaskCompletion', e, stack);
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

// ─── GoalTask → Todo 변환 Provider ──────────────────────────────────────────

/// GoalTask → Todo 변환 액션 Provider
/// 목표의 실천 과제를 투두로 변환하여 todosBox에 저장한다
/// 변환된 투두의 scheduled_date는 오늘, 제목은 GoalTask.title을 사용한다
final exportGoalTaskAsTodoProvider =
    Provider<Future<void> Function(GoalTask task)>((ref) {
  return (GoalTask task) async {
    final cacheService = ref.read(hiveCacheServiceProvider);
    final now = DateTime.now();
    final todoId = const Uuid().v4();

    // Bug 3 Fix: user_id 누락 방지 — 로컬 퍼스트에서도 user_id를 설정한다
    final userId = ref.read(currentUserIdProvider) ?? AppConstants.localUserId;

    // Bug 5 Fix: 기존 투두 수를 세어 display_order를 마지막에 배치한다
    final existingTodos = cacheService.getAll(AppConstants.todosBox);
    final displayOrder = existingTodos.length;

    final todoMap = {
      'id': todoId,
      'user_id': userId,
      'title': task.title,
      'scheduled_date': AppDateUtils.toDateString(now),
      'is_completed': false,
      'display_order': displayOrder,
      'created_at': now.toIso8601String(),
    };

    await cacheService.put(AppConstants.todosBox, todoId, todoMap);
    // 투두 데이터 버전을 증가시켜 UI 갱신을 트리거한다
    ref.read(todoDataVersionProvider.notifier).state++;
  };
});
