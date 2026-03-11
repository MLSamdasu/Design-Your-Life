// F8: 업적 Riverpod Provider
// achievementRepositoryProvider, userAchievementsProvider,
// unlockedAchievementIdsProvider 등을 정의한다.
// Hive 로컬 저장소를 통해 데이터를 조회한다 (로컬 퍼스트).
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../core/providers/global_providers.dart';
import '../models/achievement.dart';
import '../services/achievement_repository.dart';
import '../services/achievement_checker.dart';

// ─── Repository Provider ────────────────────────────────────────────────────

/// AchievementRepository Provider
/// HiveCacheService를 주입받아 로컬 Hive에 업적 데이터를 저장한다
/// 로컬 퍼스트: 인증 없이도 동작한다
final achievementRepositoryProvider = Provider<AchievementRepository>((ref) {
  final cache = ref.watch(hiveCacheServiceProvider);
  return AchievementRepository(cache: cache);
});

// ─── 업적 목록 Provider ────────────────────────────────────────────────────

/// 사용자 달성 업적 목록 Provider (FutureProvider)
/// 로컬 퍼스트: 인증 없이도 로컬 Hive에서 업적 목록을 반환한다
final userAchievementsProvider = FutureProvider<List<Achievement>>((ref) async {
  final repository = ref.watch(achievementRepositoryProvider);
  return repository.getAchievements();
});

// ─── 편의 파생 Provider ────────────────────────────────────────────────────

/// 달성된 업적 ID 집합 파생 Provider
/// AchievementChecker.checkNewAchievements에서 alreadyUnlockedIds로 활용한다
/// 로컬 퍼스트: Hive에서 동기 읽기로 반환하여 FutureProvider 의존을 제거한다
final unlockedAchievementIdsProvider = Provider<Set<String>>((ref) {
  final repository = ref.watch(achievementRepositoryProvider);
  // Hive 동기 읽기로 달성된 업적 ID 집합을 반환한다
  return repository.getUnlockedAchievementIds();
});

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

  // 로컬 퍼스트: userId가 null이면 빈 문자열을 사용한다
  final userId = ref.read(currentUserIdProvider) ?? '';

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

  // 업적 목록을 다시 로드한다
  ref.invalidate(userAchievementsProvider);

  return newAchievements;
}
