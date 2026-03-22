// F8: AchievementRepository (로컬 퍼스트 아키텍처)
// Hive achievementsBox에 달성 업적을 저장/조회한다.
// 인증 없이도 업적 기능이 정상 동작한다.

import '../../../core/cache/hive_cache_service.dart';
import '../../../core/constants/app_constants.dart';
import '../models/achievement.dart';

/// 업적 저장소 (로컬 퍼스트)
/// Hive achievementsBox에 달성한 업적 데이터를 저장한다
/// 인증 상태와 무관하게 로컬 데이터를 유지한다
class AchievementRepository {
  final HiveCacheService _cache;

  AchievementRepository({required HiveCacheService cache}) : _cache = cache;

  // ─── 업적 목록 조회 ───────────────────────────────────────────────────────
  /// 달성한 업적 목록을 Hive에서 조회한다
  /// unlocked_at 내림차순으로 정렬하여 반환한다
  Future<List<Achievement>> getAchievements() async {
    final all = _cache.getAll(AppConstants.achievementsBox);

    // unlockedAt 내림차순 정렬 (최근 달성 업적이 상단에 위치)
    // 백업 복원 시 snake_case 키가 유입될 수 있으므로 양쪽 모두 확인한다
    all.sort((a, b) {
      final aTime = DateTime.tryParse(
              (a['unlockedAt'] ?? a['unlocked_at']) as String? ?? '') ??
          DateTime(0);
      final bTime = DateTime.tryParse(
              (b['unlockedAt'] ?? b['unlocked_at']) as String? ?? '') ??
          DateTime(0);
      // 내림차순이므로 b - a 순서로 비교한다
      return bTime.compareTo(aTime);
    });

    return all.map(_fromHiveMap).toList();
  }

  // ─── 달성 업적 ID 집합 조회 ──────────────────────────────────────────────
  /// 달성한 업적 ID 집합을 반환한다
  /// AchievementChecker에서 alreadyUnlockedIds로 활용한다
  Set<String> getUnlockedAchievementIds() {
    final all = _cache.getAll(AppConstants.achievementsBox);
    return all.map((map) => (map['id'] ?? '').toString()).toSet();
  }

  // ─── 업적 달성 저장 ──────────────────────────────────────────────────────
  /// 업적을 달성 처리하여 Hive에 저장한다
  Future<void> unlockAchievement(Achievement achievement) async {
    await _cache.put(
      AppConstants.achievementsBox,
      achievement.id,
      _toHiveMap(achievement),
    );
  }

  // ─── 백업 전용 직렬화 ─────────────────────────────────────────────────────
  /// Hive에서 읽은 모든 업적을 백업용 Map 목록으로 변환한다
  /// BackupService에서 호출한다
  List<Map<String, dynamic>> getAllForBackup() {
    return _cache.getAll(AppConstants.achievementsBox);
  }

  /// 백업에서 복원한 데이터로 Hive를 덮어쓴다
  /// BackupService의 restoreFromCloud에서 호출한다
  Future<void> restoreFromBackup(List<Map<String, dynamic>> achievements) async {
    // 기존 데이터를 먼저 초기화한다
    await _cache.clearBox(AppConstants.achievementsBox);
    for (final achievement in achievements) {
      final id = achievement['id']?.toString();
      if (id == null || id.isEmpty) continue;
      await _cache.put(AppConstants.achievementsBox, id, achievement);
    }
  }

  // ─── 내부 직렬화 헬퍼 ────────────────────────────────────────────────────
  /// Achievement → Hive 저장용 Map 변환
  /// snake_case 키를 사용하여 다른 Repository와 포맷을 통일한다
  Map<String, dynamic> _toHiveMap(Achievement achievement) {
    return {
      'id': achievement.id,
      'user_id': achievement.userId,
      'type': achievement.type,
      'title': achievement.title,
      'description': achievement.description,
      'icon_name': achievement.iconName,
      'xp_reward': achievement.xpReward,
      'unlocked_at': achievement.unlockedAt.toIso8601String(),
      'created_at': achievement.createdAt.toIso8601String(),
    };
  }

  /// Hive Map → Achievement 변환
  Achievement _fromHiveMap(Map<String, dynamic> map) {
    return Achievement.fromMap(map);
  }
}
