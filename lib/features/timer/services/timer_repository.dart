// F6: TimerRepository (로컬 퍼스트 아키텍처)
// Hive를 기본 저장소로 사용한다.
// 인증 없이도 타이머 기능이 정상 동작한다.

import '../../../core/cache/hive_cache_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/error/error_handler.dart';
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
  /// 최적화: start_time 문자열 프리픽스로 사전 필터링하여 불필요한 깊은 복사를 생략한다
  Future<List<TimerLog>> getTodayLogs(DateTime today) async {
    final dayStart = DateTime(today.year, today.month, today.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final datePrefix = _datePrefix(today);

    // query()로 날짜 프리픽스 일치 항목만 깊은 복사한다
    final filtered = _cache.query(
      AppConstants.timerLogsBox,
      (m) => _startTimePrefix(m) == datePrefix,
    );

    final logs = _parseLogs(filtered, (log) =>
        !log.startTime.isBefore(dayStart) && log.startTime.isBefore(dayEnd));

    logs.sort((a, b) => a.startTime.compareTo(b.startTime));
    return logs;
  }

  // ─── 기간별 로그 조회 ──────────────────────────────────────────────────────
  /// 특정 기간의 타이머 로그를 조회한다
  /// 최적화: start_time 문자열 범위로 사전 필터링하여 불필요한 깊은 복사를 생략한다
  Future<List<TimerLog>> getLogsForPeriod(DateTime from, DateTime to) async {
    final fromPrefix = _datePrefix(from);
    final toPrefix = _datePrefix(to);

    // query()로 날짜 범위 내 항목만 깊은 복사한다
    final filtered = _cache.query(
      AppConstants.timerLogsBox,
      (m) {
        final prefix = _startTimePrefix(m);
        return prefix.compareTo(fromPrefix) >= 0 &&
            prefix.compareTo(toPrefix) <= 0;
      },
    );

    final logs = _parseLogs(filtered, (log) =>
        !log.startTime.isBefore(from) && !log.startTime.isAfter(to));

    logs.sort((a, b) => a.startTime.compareTo(b.startTime));
    return logs;
  }

  // ─── 통계 조회 ───────────────────────────────────────────────────────────
  /// 특정 투두의 총 집중 시간(초)을 계산한다
  /// 최적화: todoId 필터를 query()에 위임하여 불필요한 깊은 복사를 생략한다
  Future<int> getTotalFocusSeconds(String todoId) async {
    final filtered = _cache.query(
      AppConstants.timerLogsBox,
      (m) => (m['todo_id'] ?? m['todoId'])?.toString() == todoId,
    );

    int total = 0;
    for (final map in filtered) {
      try {
        final log = TimerLog.fromMap(map);
        if (log.type == TimerSessionType.focus) {
          total += log.durationSeconds;
        }
      } catch (e, stack) {
        ErrorHandler.logServiceError('TimerRepository:parseLog', e, stack);
      }
    }
    return total;
  }

  // ─── 내부 헬퍼 ────────────────────────────────────────────────────────────

  /// start_time 필드에서 YYYY-MM-DD 프리픽스를 추출한다
  String _startTimePrefix(Map<String, dynamic> m) {
    final raw = (m['start_time'] ?? m['startTime'])?.toString() ?? '';
    return raw.length >= 10 ? raw.substring(0, 10) : raw;
  }

  /// DateTime을 YYYY-MM-DD 문자열로 변환한다
  String _datePrefix(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Map 목록을 TimerLog로 파싱하고 추가 조건으로 필터링한다
  List<TimerLog> _parseLogs(
    List<Map<String, dynamic>> maps,
    bool Function(TimerLog) predicate,
  ) {
    final logs = <TimerLog>[];
    for (final map in maps) {
      try {
        final log = TimerLog.fromMap(map);
        if (predicate(log)) logs.add(log);
      } catch (e, stack) {
        ErrorHandler.logServiceError('TimerRepository:parseLog', e, stack);
      }
    }
    return logs;
  }

  // ─── 로그 삭제 ──────────────────────────────────────────────────────────────

  /// 타이머 로그 단건 삭제
  Future<void> deleteLog(String logId) async {
    await _cache.deleteById(AppConstants.timerLogsBox, logId);
  }

  /// 특정 투두에 연결된 모든 타이머 로그 삭제
  Future<void> deleteLogsByTodoId(String todoId) async {
    final all = _cache.getAll(AppConstants.timerLogsBox);
    for (final log in all) {
      // camelCase/snake_case 양쪽 키를 모두 확인한다
      if (log['todoId']?.toString() == todoId || log['todo_id']?.toString() == todoId) {
        final logId = log['id']?.toString();
        if (logId != null) {
          await _cache.deleteById(AppConstants.timerLogsBox, logId);
        }
      }
    }
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
  /// snake_case 키를 사용하여 다른 Repository와 포맷을 통일한다
  Map<String, dynamic> _toHiveMap(TimerLog log) {
    return {
      'id': log.id,
      'user_id': log.userId,
      'todo_id': log.todoId,
      'todo_title': log.todoTitle,
      'start_time': log.startTime.toIso8601String(),
      'end_time': log.endTime.toIso8601String(),
      'duration_seconds': log.durationSeconds,
      'type': log.type.toJsonValue(),
      'created_at': log.createdAt.toIso8601String(),
    };
  }

}
