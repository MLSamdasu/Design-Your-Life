// F6: TimerRepository (로컬 퍼스트 아키텍처)
// Hive를 기본 저장소로 사용한다.
// 인증 없이도 타이머 기능이 정상 동작한다.

import '../../../core/cache/hive_cache_service.dart';
import '../../../core/constants/app_constants.dart';
import '../models/timer_log.dart';

/// 타이머 로그 저장소 (로컬 퍼스트)
/// Hive timerLogsBox에 읽기/쓰기를 수행한다
/// 인증 상태와 무관하게 로컬 데이터를 유지한다
class TimerRepository {
  final HiveCacheService _cache;

  TimerRepository({required HiveCacheService cache}) : _cache = cache;

  // ─── 로그 생성 ────────────────────────────────────────────────────────────
  /// 타이머 세션 완료 시 로그를 Hive에 저장한다
  Future<void> createLog(TimerLog log) async {
    // TimerLog → Map<String, dynamic> 변환 후 Hive에 저장한다
    await _cache.put(
      AppConstants.timerLogsBox,
      log.id,
      _toHiveMap(log),
    );
  }

  // ─── 날짜별 로그 조회 ──────────────────────────────────────────────────────
  /// 특정 날짜의 타이머 로그를 조회한다
  /// 날짜 비교는 로컬 타임존 기준으로 수행한다
  Future<List<TimerLog>> getTodayLogs(DateTime today) async {
    // 해당 날짜의 시작과 끝 경계 계산
    final dayStart = DateTime(today.year, today.month, today.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    // Hive에서 전체 로그를 조회한 뒤 날짜 필터링한다
    final all = _cache.getAll(AppConstants.timerLogsBox);
    final filtered = all.where((map) {
      final startTimeRaw = map['startTime'] as String?;
      if (startTimeRaw == null) return false;
      final startTime = DateTime.tryParse(startTimeRaw);
      if (startTime == null) return false;
      // 해당 날짜 범위에 속하는 로그만 반환한다
      return startTime.isAfter(dayStart.subtract(const Duration(milliseconds: 1))) &&
          startTime.isBefore(dayEnd);
    }).toList();

    // start_time 오름차순 정렬
    filtered.sort((a, b) {
      final aTime = DateTime.tryParse(a['startTime'] as String? ?? '') ?? DateTime(0);
      final bTime = DateTime.tryParse(b['startTime'] as String? ?? '') ?? DateTime(0);
      return aTime.compareTo(bTime);
    });

    return filtered.map(_fromHiveMap).toList();
  }

  // ─── 기간별 로그 조회 ──────────────────────────────────────────────────────
  /// 특정 기간의 타이머 로그를 조회한다
  /// [from] ~ [to] 범위의 로그를 반환한다 (양 끝 포함)
  Future<List<TimerLog>> getLogsForPeriod(DateTime from, DateTime to) async {
    final all = _cache.getAll(AppConstants.timerLogsBox);
    final filtered = all.where((map) {
      final startTimeRaw = map['startTime'] as String?;
      if (startTimeRaw == null) return false;
      final startTime = DateTime.tryParse(startTimeRaw);
      if (startTime == null) return false;
      return !startTime.isBefore(from) && !startTime.isAfter(to);
    }).toList();

    filtered.sort((a, b) {
      final aTime = DateTime.tryParse(a['startTime'] as String? ?? '') ?? DateTime(0);
      final bTime = DateTime.tryParse(b['startTime'] as String? ?? '') ?? DateTime(0);
      return aTime.compareTo(bTime);
    });

    return filtered.map(_fromHiveMap).toList();
  }

  // ─── 통계 조회 ───────────────────────────────────────────────────────────
  /// 특정 투두의 총 집중 시간(초)을 계산한다
  /// Hive에서 해당 todoId를 가진 focus 타입 로그의 합계를 반환한다
  Future<int> getTotalFocusSeconds(String todoId) async {
    final all = _cache.getAll(AppConstants.timerLogsBox);
    int total = 0;
    for (final map in all) {
      // todoId가 일치하고 focus 타입인 로그만 합산한다
      if ((map['todoId'] as String?) == todoId &&
          (map['type'] as String?) == 'focus') {
        total += (map['durationSeconds'] as int?) ?? 0;
      }
    }
    return total;
  }

  // ─── 백업 전용 직렬화 ─────────────────────────────────────────────────────
  /// Hive에서 읽은 모든 로그를 백업용 Map 목록으로 변환한다
  /// BackupService에서 호출한다
  List<Map<String, dynamic>> getAllForBackup() {
    return _cache.getAll(AppConstants.timerLogsBox);
  }

  /// 백업에서 복원한 데이터로 Hive를 덮어쓴다
  /// BackupService의 restoreFromCloud에서 호출한다
  Future<void> restoreFromBackup(List<Map<String, dynamic>> logs) async {
    // 기존 데이터를 먼저 초기화한다
    await _cache.clearBox(AppConstants.timerLogsBox);
    for (final log in logs) {
      final id = log['id']?.toString();
      if (id == null || id.isEmpty) continue;
      await _cache.put(AppConstants.timerLogsBox, id, log);
    }
  }

  // ─── 내부 직렬화 헬퍼 ────────────────────────────────────────────────────
  /// TimerLog → Hive 저장용 Map 변환
  /// camelCase 키를 사용하여 Hive 내부 포맷을 통일한다
  Map<String, dynamic> _toHiveMap(TimerLog log) {
    return {
      'id': log.id,
      'userId': log.userId,
      'todoId': log.todoId,
      'todoTitle': log.todoTitle,
      'startTime': log.startTime.toIso8601String(),
      'endTime': log.endTime.toIso8601String(),
      'durationSeconds': log.durationSeconds,
      'type': log.type.toJsonValue(),
      'createdAt': log.createdAt.toIso8601String(),
    };
  }

  /// Hive Map → TimerLog 변환
  TimerLog _fromHiveMap(Map<String, dynamic> map) {
    return TimerLog.fromMap(map);
  }
}
