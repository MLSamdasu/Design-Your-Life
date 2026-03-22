// F4: HabitRepository (로컬 퍼스트 — Hive 기반)
// 모든 CRUD 작업은 Hive 로컬 박스에서 수행한다.
// 백업은 별도 백업 서비스에서 담당한다.

import 'package:uuid/uuid.dart';

import '../../../core/cache/hive_cache_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/habit.dart';

/// 습관 저장소 (Hive 로컬 퍼스트)
/// 로컬 Hive 박스에서 습관 CRUD 작업을 수행한다
class HabitRepository {
  final HiveCacheService _cache;

  /// HiveCacheService를 의존성 주입으로 받는다
  HabitRepository({required HiveCacheService cache}) : _cache = cache;

  // ─── 조회 ────────────────────────────────────────────────────────────────

  /// 모든 습관 목록을 로컬에서 조회한다 (활성+비활성 모두)
  List<Habit> getAllHabits() {
    final all = _cache.getAll(AppConstants.habitsBox);
    // 생성 시각 오름차순으로 정렬하여 반환한다
    final habits = all.map((m) => Habit.fromMap(m)).toList();
    habits.sort((a, b) => a.id.compareTo(b.id));
    return habits;
  }

  /// 활성 습관 목록만 로컬에서 조회한다
  List<Habit> getActiveHabits() {
    final all = _cache.getAll(AppConstants.habitsBox);
    // is_active가 true인 항목만 필터링한다
    return all
        .where((m) => m['is_active'] == true)
        .map((m) => Habit.fromMap(m))
        .toList();
  }

  // ─── 생성 ────────────────────────────────────────────────────────────────

  /// 새 습관을 로컬에 생성한다
  /// ID는 UUID v4로 클라이언트에서 생성한다
  Future<Habit> createHabit(Habit habit) async {
    // 로컬 저장용 ID를 UUID v4로 생성한다
    final id = const Uuid().v4();
    final map = habit.toInsertMap(AppConstants.localUserId)
      ..['id'] = id
      ..['current_streak'] = 0
      ..['longest_streak'] = 0;
    await _cache.put(AppConstants.habitsBox, id, map);
    return Habit.fromMap(map);
  }

  // ─── 수정 ────────────────────────────────────────────────────────────────

  /// 습관 정보를 로컬에서 수정한다
  Future<Habit> updateHabit(String habitId, Habit habit) async {
    // 기존 데이터를 읽어 업데이트 맵과 병합한다
    final existing = _cache.get(AppConstants.habitsBox, habitId) ?? {};
    final updated = Map<String, dynamic>.from(existing)
      ..addAll(habit.toUpdateMap());
    await _cache.put(AppConstants.habitsBox, habitId, updated);
    return Habit.fromMap(updated);
  }

  // ─── 삭제 ────────────────────────────────────────────────────────────────

  /// 습관을 로컬에서 삭제한다
  /// 고아 로그 정리는 호출부(deleteHabitProvider)에서 HabitLogRepository를 통해 수행한다
  Future<void> deleteHabit(String habitId) async {
    await _cache.delete(AppConstants.habitsBox, habitId);
  }

  // ─── 활성 상태 토글 ───────────────────────────────────────────────────────

  /// 습관의 활성/비활성 상태를 토글한다
  Future<void> toggleActive(String habitId, bool isActive) async {
    await _cache.update(AppConstants.habitsBox, habitId, {
      'is_active': isActive,
    });
  }

  // ─── 스트릭 갱신 ─────────────────────────────────────────────────────────

  /// 습관의 연속 달성일(streak)을 업데이트한다
  Future<void> updateStreak(
      String habitId, int currentStreak, int longestStreak) async {
    await _cache.update(AppConstants.habitsBox, habitId, {
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
    });
  }
}
