// F8: 업적 Riverpod Provider
// achievementRepositoryProvider, userAchievementsProvider,
// unlockedAchievementIdsProvider 등을 정의한다.
// Hive 로컬 저장소를 통해 데이터를 조회한다 (로컬 퍼스트).
import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/data_store_providers.dart';
import '../../../core/providers/global_providers.dart';
import '../models/achievement.dart';
import '../services/achievement_repository.dart';
import '../services/achievement_checker.dart';
import '../services/achievement_stats_collector.dart';

// ─── Repository Provider ────────────────────────────────────────────────────

/// AchievementRepository Provider
/// HiveCacheService를 주입받아 로컬 Hive에 업적 데이터를 저장한다
/// 로컬 퍼스트: 인증 없이도 동작한다
final achievementRepositoryProvider = Provider<AchievementRepository>((ref) {
  final cache = ref.watch(hiveCacheServiceProvider);
  return AchievementRepository(cache: cache);
});

// ─── 업적 목록 Provider ────────────────────────────────────────────────────

/// 사용자 달성 업적 목록 Provider (동기 Provider)
/// allAchievementsRawProvider(Single Source of Truth)에서 파생한다
/// achievementDataVersionProvider 변경 → allAchievementsRawProvider 재평가 → 자동 갱신
/// Hive 조회는 모두 동기 연산이므로 FutureProvider가 불필요하다.
final userAchievementsProvider = Provider<List<Achievement>>((ref) {
  final allAchievements = ref.watch(allAchievementsRawProvider);
  return allAchievements.map((m) => Achievement.fromMap(m)).toList();
});

// ─── 편의 파생 Provider ────────────────────────────────────────────────────

/// 달성된 업적 ID 집합 파생 Provider
/// allAchievementsRawProvider(Single Source of Truth)에서 파생한다
final unlockedAchievementIdsProvider = Provider<Set<String>>((ref) {
  final allAchievements = ref.watch(allAchievementsRawProvider);
  // id가 null이거나 String이 아닌 경우를 방어하여 TypeError를 방지한다
  return allAchievements
      .map((m) => m['id']?.toString() ?? '')
      .where((id) => id.isNotEmpty)
      .toSet();
});

// ─── 대기 중인 업적 알림 Provider ──────────────────────────────────────────────

/// 새로 달성된 업적 큐를 저장하는 Provider
/// UI(MainShell)에서 listen하여 하나씩 다이얼로그를 표시한 뒤 큐에서 제거한다
/// 동시에 여러 업적이 달성되어도 순차적으로 모두 알림한다
final pendingAchievementProvider = StateProvider<List<Achievement>>((ref) => []);

/// 업적 다이얼로그 표시 중 여부 (P1-10: 다이얼로그 중첩 방지)
/// true이면 현재 다이얼로그가 표시 중이므로 추가 다이얼로그를 열지 않는다
final isShowingAchievementDialogProvider = StateProvider<bool>((ref) => false);

// ─── 업적 달성 확인 및 잠금 해제 ─────────────────────────────────────────────

/// 업적 달성 조건을 확인하고 새로 달성한 업적을 저장하는 함수
/// 투두 완료, 습관 체크, 목표 생성 등의 액션 후 호출해야 한다
/// 로컬 퍼스트: 인증 없이도 로컬에 업적을 저장한다
///
/// 반환값: 새로 달성된 업적 목록 (알림 표시에 활용)
Future<List<Achievement>> checkAndUnlockAchievements(
  Ref ref, {
  required int totalCompletedTodos,
  required int longestHabitStreak,
  required int totalHabitsCreated,
  required int totalGoalsCreated,
  required int completedMandalarts,
  required bool allHabitsCompletedToday,
  required bool isEarlyBird,
}) async {
  final repository = ref.read(achievementRepositoryProvider);
  final alreadyUnlockedIds = ref.read(unlockedAchievementIdsProvider);

  // 로컬 퍼스트: userId가 null이면 로컬 사용자 ID를 사용한다
  final userId = ref.read(currentUserIdProvider) ?? AppConstants.localUserId;

  // 순수 함수로 새로 달성할 업적을 계산한다
  final newDefs = AchievementChecker.checkNewAchievements(
    alreadyUnlockedIds: alreadyUnlockedIds,
    totalCompletedTodos: totalCompletedTodos,
    longestHabitStreak: longestHabitStreak,
    totalHabitsCreated: totalHabitsCreated,
    totalGoalsCreated: totalGoalsCreated,
    completedMandalarts: completedMandalarts,
    allHabitsCompletedToday: allHabitsCompletedToday,
    isEarlyBird: isEarlyBird,
  );

  if (newDefs.isEmpty) return [];

  // 새 업적을 Achievement 객체로 변환하여 Hive에 저장한다
  final now = DateTime.now();
  final newAchievements = <Achievement>[];

  for (final def in newDefs) {
    final achievement = Achievement(
      id: def.id,
      userId: userId,
      type: def.type,
      title: def.title,
      description: def.description,
      iconName: def.iconName,
      xpReward: def.xpReward,
      unlockedAt: now,
      createdAt: now,
    );
    await repository.unlockAchievement(achievement);
    newAchievements.add(achievement);
  }

  // 버전 카운터 증가 → allAchievementsRawProvider 재평가 → 모든 파생 Provider 자동 갱신
  ref.read(achievementDataVersionProvider.notifier).state++;

  return newAchievements;
}

// ─── 업적 체크 원샷 헬퍼 ───────────────────────────────────────────────────

/// 통계 수집 → 업적 체크 → 알림 큐 갱신을 원샷으로 수행하는 헬퍼
/// 투두 완료, 습관 체크, 목표 완료, 타이머 종료 시 호출한다
/// 4곳에서 반복되던 ~15줄 패턴을 단일 함수로 추출했다
Future<void> checkAchievementsAndNotify(Ref ref) async {
  // 업적 체크 실패가 주 작업(투두 완료, 습관 체크 등)을 방해하지 않도록
  // try-catch로 감싸서 에러를 안전하게 처리한다
  try {
    final cache = ref.read(hiveCacheServiceProvider);
    final stats = AchievementStatsCollector.collect(cache);
    final newAchievements = await checkAndUnlockAchievements(
      ref,
      totalCompletedTodos: stats.totalCompletedTodos,
      longestHabitStreak: stats.longestHabitStreak,
      totalHabitsCreated: stats.totalHabitsCreated,
      totalGoalsCreated: stats.totalGoalsCreated,
      completedMandalarts: stats.completedMandalarts,
      allHabitsCompletedToday: stats.allHabitsCompletedToday,
      isEarlyBird: stats.isEarlyBird,
    );
    // P1-12: 레이스 컨디션 방지를 위해 notifier.update로 이전 상태에 안전하게 추가한다
    // 여러 액션이 동시에 호출되어도 각각의 결과가 큐에서 누락되지 않는다
    if (newAchievements.isNotEmpty) {
      ref.read(pendingAchievementProvider.notifier).update(
        (current) => [...current, ...newAchievements],
      );
    }
  } catch (e, st) {
    // 업적 체크 오류는 로그로 기록하고 조용히 무시한다
    developer.log('[AchievementCheck] 업적 체크 중 오류: $e',
        name: 'achievement', error: e, stackTrace: st);
  }
}
