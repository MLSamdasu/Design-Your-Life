// F6: 포모도로 타이머 쿼리/파생 Provider
// allTimerLogsRawProvider(Single Source of Truth)에서 파생하여
// 날짜별·투두별 타이머 로그와 집중 시간을 계산한다.
// Hive 조회는 모두 동기 연산이므로 FutureProvider가 불필요하다.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/data_store_providers.dart';
import '../../../core/providers/global_providers.dart';
import '../../../features/todo/providers/todo_provider.dart';
import '../models/timer_log.dart';
import '../services/timer_repository.dart';

// ─── Repository Provider ────────────────────────────────────────────────

/// TimerRepository Provider
/// HiveCacheService를 주입받아 로컬 Hive에 타이머 로그를 저장한다
/// 로컬 퍼스트: 인증 없이도 동작한다
final timerRepositoryProvider = Provider<TimerRepository>((ref) {
  final cache = ref.watch(hiveCacheServiceProvider);
  return TimerRepository(cache: cache);
});

// ─── 선택된 날짜 타이머 로그 Provider ──────────────────────────────────

/// P1-14: 선택된 날짜(selectedDateProvider)의 타이머 로그 Provider (동기 Provider)
/// allTimerLogsRawProvider(Single Source of Truth)에서 파생하여 날짜별 필터링한다
/// timerLogDataVersionProvider 변경 → allTimerLogsRawProvider 재평가 → 이 Provider 자동 갱신
/// 이전 이름 todayTimerLogsProvider에서 변경: 실제로는 selectedDate 기준으로 필터링한다
/// Hive 조회는 모두 동기 연산이므로 FutureProvider가 불필요하다.
final selectedDateTimerLogsProvider = Provider<List<TimerLog>>((ref) {
  final allLogs = ref.watch(allTimerLogsRawProvider);
  final selectedDate = ref.watch(selectedDateProvider);
  final dateStr =
      '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';

  // 선택된 날짜의 로그만 필터링한다
  final filtered = allLogs.where((m) {
    // Hive에는 camelCase('startTime')로 저장되므로 양쪽 키를 모두 확인한다
    final startTime = (m['start_time'] ?? m['startTime']) as String?;
    if (startTime == null) return false;
    return startTime.startsWith(dateStr);
  }).toList();

  return filtered.map((m) => TimerLog.fromMap(m)).toList();
});

/// P1-14: 하위 호환 별칭 — 기존 todayTimerLogsProvider 참조를 유지한다
/// 추후 전체 리팩토링 시 이 별칭을 제거하고 selectedDateTimerLogsProvider만 사용한다
/// 동기 Provider로 전환 완료 — FutureProvider에서 Provider로 변경됨
@Deprecated('selectedDateTimerLogsProvider를 사용하세요')
final todayTimerLogsProvider = selectedDateTimerLogsProvider;

// ─── 선택된 날짜 총 집중 시간 파생 Provider ──────────────────────────

/// P1-14: 선택된 날짜의 총 집중 시간(분) 파생 Provider
/// selectedDateTimerLogsProvider에서 focus 타입만 필터링하여 분 단위로 계산한다
/// 이전 이름 todayFocusMinutesProvider에서 변경: 실제로는 selectedDate 기준으로 계산한다
/// selectedDateTimerLogsProvider가 동기 Provider이므로 직접 데이터를 사용한다
final selectedDateFocusMinutesProvider = Provider<int>((ref) {
  final logs = ref.watch(selectedDateTimerLogsProvider);
  // focus 타입 로그의 durationSeconds 합계를 분으로 변환한다
  final focusSeconds = logs
      .where((log) => log.type == TimerSessionType.focus)
      .fold<int>(0, (sum, log) => sum + log.durationSeconds);
  return focusSeconds ~/ 60;
});

/// P1-14: 하위 호환 별칭 — 기존 todayFocusMinutesProvider 참조를 유지한다
/// 추후 전체 리팩토링 시 이 별칭을 제거하고 selectedDateFocusMinutesProvider만 사용한다
@Deprecated('selectedDateFocusMinutesProvider를 사용하세요')
final todayFocusMinutesProvider = selectedDateFocusMinutesProvider;

// ─── 오늘(Today) 전용 타이머 Provider ──────────────────────────────────

/// 홈 대시보드 전용: 항상 오늘 날짜 기준으로 타이머 로그를 필터링한다
/// selectedDateProvider(Todo 탭)에 의존하지 않으므로 탭 전환 영향을 받지 않는다
/// Hive 조회는 모두 동기 연산이므로 FutureProvider가 불필요하다.
final todayOnlyTimerLogsProvider = Provider<List<TimerLog>>((ref) {
  final allLogs = ref.watch(allTimerLogsRawProvider);
  // 자정 경계 불일치 방지: 공유 todayDateProvider를 사용한다
  final today = ref.watch(todayDateProvider);
  final dateStr =
      '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

  final filtered = allLogs.where((m) {
    final startTime = (m['start_time'] ?? m['startTime']) as String?;
    if (startTime == null) return false;
    return startTime.startsWith(dateStr);
  }).toList();

  return filtered.map((m) => TimerLog.fromMap(m)).toList();
});

/// 홈 대시보드 전용: 항상 오늘 날짜 기준으로 총 집중 시간(분)을 계산한다
/// todayOnlyTimerLogsProvider가 동기 Provider이므로 직접 데이터를 사용한다
final todayOnlyFocusMinutesProvider = Provider<int>((ref) {
  final logs = ref.watch(todayOnlyTimerLogsProvider);
  final focusSeconds = logs
      .where((log) => log.type == TimerSessionType.focus)
      .fold<int>(0, (sum, log) => sum + log.durationSeconds);
  return focusSeconds ~/ 60;
});

// ─── 투두별 집중 시간 Provider (Family) ──────────────────────────────

/// 특정 투두 ID에 대한 총 집중 시간(분) Provider
/// FutureProvider.family를 사용하여 todoId별로 캐시된 결과를 제공한다
/// 로컬 퍼스트: 인증 없이도 로컬 데이터를 반환한다
final todoFocusMinutesProvider =
    FutureProvider.family<int, String>((ref, todoId) async {
  final repository = ref.watch(timerRepositoryProvider);
  final seconds = await repository.getTotalFocusSeconds(todoId);
  return seconds ~/ 60;
});
