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
  /// 날짜 비교는 로컬 타임존 기준으로 수행한다
  Future<List<TimerLog>> getTodayLogs(DateTime today) async {
    // 해당 날짜의 시작과 끝 경계 계산
    final dayStart = DateTime(today.year, today.month, today.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    // Hive에서 전체 로그를 조회하고 TimerLog.fromMap으로 파싱한다
    // fromMap은 camelCase/snake_case 양쪽 키를 모두 처리한다
    final all = _cache.getAll(AppConstants.timerLogsBox);
    final logs = <TimerLog>[];
    for (final map in all) {
      try {
        final log = TimerLog.fromMap(map);
        // 해당 날짜 범위에 속하는 로그만 추가한다
        if (!log.startTime.isBefore(dayStart) && log.startTime.isBefore(dayEnd)) {
          logs.add(log);
        }
      } catch (e, stack) {
        // V3-008: 파싱 실패를 로깅하여 손상된 데이터 추적을 가능하게 한다
        ErrorHandler.logServiceError('TimerRepository:parseLog', e, stack);
        continue;
      }
    }

    // startTime 오름차순 정렬
    logs.sort((a, b) => a.startTime.compareTo(b.startTime));

    return logs;
  }

  // ─── 기간별 로그 조회 ──────────────────────────────────────────────────────
  /// 특정 기간의 타이머 로그를 조회한다
  /// [from] ~ [to] 범위의 로그를 반환한다 (양 끝 포함)
  Future<List<TimerLog>> getLogsForPeriod(DateTime from, DateTime to) async {
    // Hive에서 전체 로그를 조회하고 TimerLog.fromMap으로 파싱한다
    // fromMap은 camelCase/snake_case 양쪽 키를 모두 처리한다
    final all = _cache.getAll(AppConstants.timerLogsBox);
    final logs = <TimerLog>[];
    for (final map in all) {
      try {
        final log = TimerLog.fromMap(map);
        if (!log.startTime.isBefore(from) && !log.startTime.isAfter(to)) {
          logs.add(log);
        }
      } catch (e, stack) {
        // V3-008: 파싱 실패를 로깅하여 손상된 데이터 추적을 가능하게 한다
        ErrorHandler.logServiceError('TimerRepository:parseLog', e, stack);
        continue;
      }
    }

    // startTime 오름차순 정렬
    logs.sort((a, b) => a.startTime.compareTo(b.startTime));

    return logs;
  }

  // ─── 통계 조회 ───────────────────────────────────────────────────────────
  /// 특정 투두의 총 집중 시간(초)을 계산한다
  /// Hive에서 해당 todoId를 가진 focus 타입 로그의 합계를 반환한다
  Future<int> getTotalFocusSeconds(String todoId) async {
    final all = _cache.getAll(AppConstants.timerLogsBox);
    int total = 0;
    for (final map in all) {
      try {
        // fromMap은 camelCase/snake_case 양쪽 키를 모두 처리한다
        final log = TimerLog.fromMap(map);
        if (log.todoId == todoId && log.type == TimerSessionType.focus) {
          total += log.durationSeconds;
        }
      } catch (e, stack) {
        // V3-008: 파싱 실패를 로깅하여 손상된 데이터 추적을 가능하게 한다
        ErrorHandler.logServiceError('TimerRepository:parseLog', e, stack);
        continue;
      }
    }
    return total;
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
