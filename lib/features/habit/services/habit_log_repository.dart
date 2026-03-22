// F4: HabitLogRepository (로컬 퍼스트 — Hive 기반)
// 모든 습관 로그 CRUD는 Hive 로컬 박스에서 수행한다.
// 날짜 기반 필터링은 log_date 필드로 처리한다.

import 'package:uuid/uuid.dart';

import '../../../core/cache/hive_cache_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/habit_log.dart';

/// 습관 로그 저장소 (Hive 로컬 퍼스트)
/// 로컬 Hive 박스에서 습관 체크/언체크 CRUD를 수행한다
class HabitLogRepository {
  final HiveCacheService _cache;

  /// HiveCacheService를 의존성 주입으로 받는다
  HabitLogRepository({required HiveCacheService cache}) : _cache = cache;

  // ─── 조회 ────────────────────────────────────────────────────────────────

  /// 특정 날짜의 습관 로그 목록을 로컬에서 조회한다
  List<HabitLog> getLogsForDate(DateTime date) {
    final dateStr = _formatDate(date);
    return _cache
        .query(
          AppConstants.habitLogsBox,
          (m) => m['log_date'] == dateStr,
        )
        .map((m) => HabitLog.fromMap(m))
        .toList();
  }

  /// 특정 월의 습관 로그 목록을 로컬에서 조회한다 (캘린더용)
  List<HabitLog> getLogsForMonth(int year, int month) {
    // 해당 월의 시작일~마지막일 범위로 log_date를 필터링한다
    final startStr = _formatDate(DateTime(year, month, 1));
    final endStr = _formatDate(DateTime(year, month + 1, 0));
    return _cache
        .query(
          AppConstants.habitLogsBox,
          (m) {
            final logDate = m['log_date'] as String?;
            if (logDate == null) return false;
            // 문자열 사전순 비교로 날짜 범위를 필터링한다
            return logDate.compareTo(startStr) >= 0 &&
                logDate.compareTo(endStr) <= 0;
          },
        )
        .map((m) => HabitLog.fromMap(m))
        .toList();
  }

  // ─── 체크 (생성) ─────────────────────────────────────────────────────────

  /// 특정 날짜의 습관 체크를 로컬에 생성한다
  /// [date]가 제공되면 해당 날짜로 기록하고, 없으면 오늘 날짜를 사용한다
  /// 이미 체크된 경우 기존 로그를 반환한다
  Future<HabitLog> checkHabit(String habitId, {DateTime? date}) async {
    final targetDate = date ?? DateTime.now();
    final dateStr = _formatDate(targetDate);

    // 동일 날짜 중복 체크를 방지한다
    final existing = _cache.query(
      AppConstants.habitLogsBox,
      (m) => m['habit_id'] == habitId && m['log_date'] == dateStr,
    );
    if (existing.isNotEmpty) {
      return HabitLog.fromMap(existing.first);
    }

    // 새 로그 ID를 UUID v4로 생성한다
    final id = const Uuid().v4();
    final now = DateTime.now();
    final map = <String, dynamic>{
      'id': id,
      'habit_id': habitId,
      'log_date': dateStr,
      'is_completed': true,
      'completed_at': now.toIso8601String(),
    };
    await _cache.put(AppConstants.habitLogsBox, id, map);
    return HabitLog.fromMap(map);
  }

  // ─── 언체크 (삭제) ───────────────────────────────────────────────────────

  /// 특정 날짜의 습관 체크를 로컬에서 해제한다 (해당 로그를 삭제한다)
  Future<void> uncheckHabit(String habitId, DateTime date) async {
    final dateStr = _formatDate(date);
    // habit_id와 log_date로 일치하는 로그를 찾아 삭제한다
    final matching = _cache.query(
      AppConstants.habitLogsBox,
      (m) => m['habit_id'] == habitId && m['log_date'] == dateStr,
    );
    for (final log in matching) {
      final logId = log['id'] as String?;
      if (logId != null) {
        await _cache.delete(AppConstants.habitLogsBox, logId);
      }
    }
  }

  // ─── 고아 로그 정리 ─────────────────────────────────────────────────────

  /// V3-011: 특정 습관에 연결된 모든 로그를 삭제한다 (습관 삭제 시 호출)
  Future<void> deleteLogsByHabitId(String habitId) async {
    final matching = _cache.query(
      AppConstants.habitLogsBox,
      (m) => m['habit_id'] == habitId,
    );
    for (final log in matching) {
      final logId = log['id'] as String?;
      if (logId != null) {
        await _cache.delete(AppConstants.habitLogsBox, logId);
      }
    }
  }

  // ─── 스트릭 계산 지원 ────────────────────────────────────────────────────

  /// 특정 습관의 모든 체크 날짜 목록을 반환한다 (스트릭 계산용)
  List<DateTime> getCheckedDates(String habitId) {
    return _cache
        .query(
          AppConstants.habitLogsBox,
          (m) => m['habit_id'] == habitId && m['is_completed'] == true,
        )
        .map((m) {
          final raw = m['log_date'] as String?;
          if (raw == null) return null;
          return DateTime.tryParse(raw);
        })
        .whereType<DateTime>()
        .toList();
  }

  // ─── 헬퍼 ────────────────────────────────────────────────────────────────

  /// DateTime을 'YYYY-MM-DD' 형식 문자열로 변환한다
  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
