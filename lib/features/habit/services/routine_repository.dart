// F4: RoutineRepository (로컬 퍼스트 — Hive 기반)
// 모든 루틴 CRUD는 Hive 로컬 박스에서 수행한다.
// 백업은 별도 백업 서비스에서 담당한다.

import 'package:uuid/uuid.dart';

import '../../../core/cache/hive_cache_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/routine.dart';

/// 루틴 저장소 (Hive 로컬 퍼스트)
/// 로컬 Hive 박스에서 루틴 CRUD 작업을 수행한다
class RoutineRepository {
  final HiveCacheService _cache;

  /// HiveCacheService를 의존성 주입으로 받는다
  RoutineRepository({required HiveCacheService cache}) : _cache = cache;

  // ─── 조회 ────────────────────────────────────────────────────────────────

  /// 전체 루틴 목록을 로컬에서 조회한다
  List<Routine> getRoutines() {
    final all = _cache.getAll(AppConstants.routinesBox);
    return all.map((m) => Routine.fromMap(m)).toList();
  }

  /// 활성 루틴만 로컬에서 조회한다 (캘린더 타임라인 연동용)
  List<Routine> getActiveRoutines() {
    return _cache
        .query(
          AppConstants.routinesBox,
          (m) => m['is_active'] == true,
        )
        .map((m) => Routine.fromMap(m))
        .toList();
  }

  /// 특정 요일의 활성 루틴 목록을 로컬에서 조회한다
  /// dayStr: 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN' 중 하나
  List<Routine> getRoutinesForDay(String dayStr) {
    return _cache
        .query(
          AppConstants.routinesBox,
          (m) {
            if (m['is_active'] != true) return false;
            // days_of_week 필드가 List 형태로 저장되어 있다
            final days = m['days_of_week'];
            if (days is! List) return false;
            return days.contains(dayStr);
          },
        )
        .map((m) => Routine.fromMap(m))
        .toList();
  }

  // ─── 생성 ────────────────────────────────────────────────────────────────

  /// 새 루틴을 로컬에 생성한다
  /// ID는 UUID v4로 클라이언트에서 생성한다
  Future<Routine> createRoutine(Routine routine) async {
    final id = const Uuid().v4();
    final now = DateTime.now().toIso8601String();
    final map = routine.toInsertMap('local_user')
      ..['id'] = id
      ..['created_at'] = now
      ..['updated_at'] = now;
    await _cache.put(AppConstants.routinesBox, id, map);
    return Routine.fromMap(map);
  }

  // ─── 수정 ────────────────────────────────────────────────────────────────

  /// 루틴 정보를 로컬에서 수정한다
  Future<Routine> updateRoutine(String routineId, Routine routine) async {
    final existing = _cache.get(AppConstants.routinesBox, routineId) ?? {};
    final updated = Map<String, dynamic>.from(existing)
      ..addAll(routine.toUpdateMap())
      ..['updated_at'] = DateTime.now().toIso8601String();
    await _cache.put(AppConstants.routinesBox, routineId, updated);
    return Routine.fromMap(updated);
  }

  // ─── 활성/비활성 토글 ────────────────────────────────────────────────────

  /// 루틴 활성/비활성 상태를 로컬에서 토글한다
  Future<void> toggleRoutineActive(String routineId, bool isActive) async {
    await _cache.update(AppConstants.routinesBox, routineId, {
      'is_active': isActive,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  // ─── 완료 토글 ───────────────────────────────────────────────────────────

  /// 루틴 완료 상태를 로컬에서 토글한다
  Future<void> toggleRoutineCompleted(
      String routineId, bool isCompleted) async {
    await _cache.update(AppConstants.routinesBox, routineId, {
      'is_completed': isCompleted,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  // ─── 삭제 ────────────────────────────────────────────────────────────────

  /// 루틴을 로컬에서 삭제한다
  Future<void> deleteRoutine(String routineId) async {
    await _cache.delete(AppConstants.routinesBox, routineId);
  }
}
