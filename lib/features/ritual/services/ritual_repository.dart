// F-Ritual: 리추얼 저장소 (로컬 퍼스트 아키텍처)
// DailyRitual(25/5 법칙)과 DailyThree(3의 법칙) 데이터를 Hive에 CRUD한다.
// 인터넷 없이도 완전히 동작한다.

import '../../../core/cache/hive_cache_service.dart';
import '../../../core/constants/app_constants.dart';
import '../models/daily_ritual.dart';
import '../models/daily_three.dart';

/// 리추얼 저장소 (로컬 퍼스트)
/// DailyRitual과 DailyThree를 Hive 로컬 저장소에서 관리한다
class RitualRepository {
  final HiveCacheService _cache;

  static const _ritualBox = AppConstants.dailyRitualBox;
  static const _threeBox = AppConstants.dailyThreeBox;

  RitualRepository({required HiveCacheService cache}) : _cache = cache;

  // ─── DailyRitual CRUD ──────────────────────────────────────────────────

  /// 특정 기간의 리추얼을 조회한다
  /// periodType: 'monthly' 또는 'yearly'
  /// periodKey: 'yyyy-MM' 또는 'yyyy'
  DailyRitual? getRitualForPeriod(String periodType, String periodKey) {
    final results = _cache.query(
      _ritualBox,
      (m) =>
          m['period_type'] == periodType && m['period_key'] == periodKey,
    );
    if (results.isEmpty) return null;
    return DailyRitual.fromMap(results.first);
  }

  /// 리추얼을 저장(생성 또는 덮어쓰기)한다
  Future<void> saveRitual(DailyRitual ritual) async {
    await _cache.put(_ritualBox, ritual.id, ritual.toMap());
  }

  /// 리추얼을 삭제한다
  Future<void> deleteRitual(String ritualId) async {
    await _cache.deleteById(_ritualBox, ritualId);
  }

  // ─── DailyThree CRUD ──────────────────────────────────────────────────

  /// 특정 날짜의 DailyThree를 조회한다
  /// date: 'yyyy-MM-dd' 형식
  DailyThree? getDailyThreeForDate(String date) {
    final results = _cache.query(
      _threeBox,
      (m) => m['date'] == date,
    );
    if (results.isEmpty) return null;
    return DailyThree.fromMap(results.first);
  }

  /// DailyThree를 저장(생성 또는 덮어쓰기)한다
  Future<void> saveDailyThree(DailyThree dailyThree) async {
    await _cache.put(_threeBox, dailyThree.id, dailyThree.toMap());
  }

  /// DailyThree를 삭제한다
  Future<void> deleteDailyThree(String dailyThreeId) async {
    await _cache.deleteById(_threeBox, dailyThreeId);
  }

  // ─── 편의 조회 ──────────────────────────────────────────────────────────

  /// 오늘의 리추얼(DailyThree)이 완료되었는지 확인한다
  bool hasCompletedRitualToday(String todayDate) {
    final three = getDailyThreeForDate(todayDate);
    return three?.isCompleted ?? false;
  }

  /// 전체 DailyRitual 목록을 반환한다 (백업/통계용)
  List<DailyRitual> getAllRituals() {
    final all = _cache.getAll(_ritualBox);
    return all.map((m) => DailyRitual.fromMap(m)).toList();
  }

  /// 전체 DailyThree 목록을 반환한다 (백업/통계용)
  List<DailyThree> getAllDailyThrees() {
    final all = _cache.getAll(_threeBox);
    return all.map((m) => DailyThree.fromMap(m)).toList();
  }
}
