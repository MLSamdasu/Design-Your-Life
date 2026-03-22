// F6: 포모도로 타이머 Riverpod Provider (Single Source of Truth 아키텍처)
// allTimerLogsRawProvider에서 파생하여 로그 저장 시 자동 갱신된다.
// dart:async Timer를 사용하여 매초 카운트다운을 수행한다.
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/error/error_handler.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/providers/data_store_providers.dart';
import '../../../core/providers/global_providers.dart';
import '../../../features/todo/providers/todo_provider.dart';
import '../../achievement/providers/achievement_provider.dart';
import '../models/timer_log.dart';
import '../models/timer_state.dart';
import '../services/timer_engine.dart';
import '../services/timer_repository.dart';

// ─── 타이머 설정 Provider ──────────────────────────────────────────────

/// 포모도로 집중 시간 설정 (분 단위, 기본 25분)
/// Hive settingsBox에서 초기값을 읽어 설정을 복원한다
final timerFocusMinutesProvider = StateProvider<int>((ref) {
  final cache = ref.watch(hiveCacheServiceProvider);
  return cache.readSetting<int>(AppConstants.settingsKeyTimerFocusMinutes) ?? 25;
});

/// 짧은 휴식 시간 설정 (분 단위, 기본 5분)
final timerShortBreakMinutesProvider = StateProvider<int>((ref) {
  final cache = ref.watch(hiveCacheServiceProvider);
  return cache.readSetting<int>(AppConstants.settingsKeyTimerShortBreakMinutes) ?? 5;
});

/// 긴 휴식 시간 설정 (분 단위, 기본 15분)
final timerLongBreakMinutesProvider = StateProvider<int>((ref) {
  final cache = ref.watch(hiveCacheServiceProvider);
  return cache.readSetting<int>(AppConstants.settingsKeyTimerLongBreakMinutes) ?? 15;
});

/// 긴 휴식 전 세션 횟수 설정 (기본 4회)
final timerSessionsBeforeLongBreakProvider = StateProvider<int>((ref) {
  final cache = ref.watch(hiveCacheServiceProvider);
  return cache.readSetting<int>(AppConstants.settingsKeyTimerSessionsBeforeLongBreak) ?? 4;
});

// ─── Repository Provider ────────────────────────────────────────────────

/// TimerRepository Provider
/// HiveCacheService를 주입받아 로컬 Hive에 타이머 로그를 저장한다
/// 로컬 퍼스트: 인증 없이도 동작한다
final timerRepositoryProvider = Provider<TimerRepository>((ref) {
  final cache = ref.watch(hiveCacheServiceProvider);
  return TimerRepository(cache: cache);
});

// ─── 타이머 상태 Provider ───────────────────────────────────────────────

/// 타이머 실행 상태 Provider
/// TimerStateNotifier를 통해 start/pause/resume/reset/nextSession 액션을 제공한다
final timerStateProvider =
    StateNotifierProvider<TimerStateNotifier, TimerState>((ref) {
  return TimerStateNotifier(ref);
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

// ─── TimerStateNotifier ────────────────────────────────────────────────

/// 타이머 상태 관리 StateNotifier
/// dart:async Timer를 사용하여 매초 카운트다운을 수행한다
class TimerStateNotifier extends StateNotifier<TimerState> {
  final Ref _ref;

  /// 매초 틱을 발생시키는 타이머 (실행 중에만 활성화)
  Timer? _ticker;

  TimerStateNotifier(this._ref) : super(TimerState.idleWith(
    focusSeconds: _ref.read(timerFocusMinutesProvider) * 60,
  ));

  /// 현재 설정에서 집중 시간(초)을 읽는다
  int get _focusSeconds => _ref.read(timerFocusMinutesProvider) * 60;

  /// 현재 설정에서 긴 휴식 전 세션 횟수를 읽는다
  int get _sessionsBeforeLong => _ref.read(timerSessionsBeforeLongBreakProvider);

  // ─── 공개 액션 ─────────────────────────────────────────────────────

  /// 타이머를 시작한다
  /// todoId와 todoTitle은 투두 연결 시에만 전달한다
  void start({String? todoId, String? todoTitle}) {
    // 이미 실행 중이면 중복 시작을 방지한다
    if (state.phase == TimerPhase.running) return;

    final now = DateTime.now();
    state = state.copyWith(
      phase: TimerPhase.running,
      linkedTodoId: todoId,
      linkedTodoTitle: todoTitle,
      sessionStartTime: now,
    );

    // 이전 ticker가 남아 있으면 취소 후 새로 시작한다
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  /// 타이머를 일시정지한다
  void pause() {
    if (state.phase != TimerPhase.running) return;
    _ticker?.cancel();
    _ticker = null;
    state = state.copyWith(phase: TimerPhase.paused);
  }

  /// 일시정지된 타이머를 재개한다
  void resume() {
    if (state.phase != TimerPhase.paused) return;
    state = state.copyWith(phase: TimerPhase.running);
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  /// 타이머를 초기 상태로 리셋한다
  /// 실행 중이거나 일시정지된 경우 로그 저장 없이 취소한다
  /// 사용자가 설정한 집중 시간으로 초기화한다
  void reset() {
    _ticker?.cancel();
    _ticker = null;
    state = TimerState.idleWith(focusSeconds: _focusSeconds);
  }

  /// 다음 세션으로 전환한다
  /// completed 상태에서 사용자가 수동으로 다음 세션을 시작할 때 호출한다
  /// 사용자가 설정한 시간 값으로 다음 세션 길이를 결정한다
  void nextSession() {
    if (state.phase != TimerPhase.completed) return;

    // 집중 세션 완료 시에만 completedSessions를 증가시킨다
    final newCompletedSessions = state.sessionType == TimerSessionType.focus
        ? state.completedSessions + 1
        : state.completedSessions;

    final nextType = TimerEngine.nextSessionType(
      state.sessionType,
      newCompletedSessions,
      sessionsBeforeLong: _sessionsBeforeLong,
    );
    final nextDuration = TimerEngine.durationForTypeCustom(
      nextType,
      focusMin: _ref.read(timerFocusMinutesProvider),
      shortBreakMin: _ref.read(timerShortBreakMinutesProvider),
      longBreakMin: _ref.read(timerLongBreakMinutesProvider),
    );

    state = state.copyWith(
      phase: TimerPhase.idle,
      sessionType: nextType,
      totalSeconds: nextDuration,
      remainingSeconds: nextDuration,
      completedSessions: newCompletedSessions,
      clearSessionStartTime: true,
    );
  }

  /// 투두 연결을 업데이트한다
  /// idle 또는 paused 상태에서만 변경 가능하다.
  void linkTodo({required String todoId, required String todoTitle}) {
    if (state.phase == TimerPhase.running || state.phase == TimerPhase.completed) return;
    state = state.copyWith(
      linkedTodoId: todoId,
      linkedTodoTitle: todoTitle,
    );
  }

  /// 투두 연결을 해제한다
  void unlinkTodo() {
    if (state.phase == TimerPhase.running || state.phase == TimerPhase.completed) return;
    state = state.copyWith(
      clearLinkedTodoId: true,
      clearLinkedTodoTitle: true,
    );
  }

  // ─── 내부 로직 ─────────────────────────────────────────────────────

  /// 매초 호출되는 틱 처리 메서드
  void _tick() {
    if (state.phase != TimerPhase.running) return;

    final newRemaining = state.remainingSeconds - 1;

    if (newRemaining <= 0) {
      // 세션 완료: 타이머를 멈추고 로그를 저장한다
      _ticker?.cancel();
      _ticker = null;
      // 상태 스냅샷을 캡처하여 async 갭에서의 race condition을 방지한다
      final snapshot = state;
      state = state.copyWith(
        phase: TimerPhase.completed,
        remainingSeconds: 0,
      );
      // 캡처된 스냅샷을 전달하여 nextSession()과의 경합을 제거한다
      _saveLog(snapshot);
    } else {
      state = state.copyWith(remainingSeconds: newRemaining);
    }
  }

  /// 세션 완료 시 TimerLog를 Hive 로컬 저장소에 저장한다
  /// 로컬 퍼스트: 인증 없이도 로그를 저장한다 (userId가 null이면 빈 문자열 사용)
  /// [capturedState]: _tick()에서 캡처한 상태 스냅샷 — async 갭 동안 state가 변경되어도 안전하다
  Future<void> _saveLog(TimerState capturedState) async {
    // 로컬 퍼스트: 미인증 상태에서도 로컬에 저장한다
    final userId = _ref.read(currentUserIdProvider) ?? AppConstants.localUserId;

    final repository = _ref.read(timerRepositoryProvider);
    final now = DateTime.now();
    final logId = const Uuid().v4();

    // sessionStartTime이 없으면 durationSeconds 기준으로 역산한다
    final startTime = capturedState.sessionStartTime ??
        now.subtract(Duration(seconds: capturedState.totalSeconds));

    final log = TimerLog(
      id: logId,
      userId: userId,
      todoId: capturedState.linkedTodoId,
      todoTitle: capturedState.linkedTodoTitle,
      startTime: startTime,
      endTime: now,
      // 일시정지 시간을 제외한 실제 집중 시간을 기록한다
      // 벽시계(now - startTime)는 일시정지 시간을 포함하므로 부풀려진다
      // totalSeconds - remainingSeconds = 카운트다운 기반 실제 경과 시간
      durationSeconds: capturedState.totalSeconds - capturedState.remainingSeconds,
      type: capturedState.sessionType,
      createdAt: now,
    );

    // 저장 실패 시 에러를 로그에 기록하되 UI 상태는 유지한다
    try {
      await repository.createLog(log);

      // P1-3: 타이머 완료 시 연결된 투두 자동 완료 처리 (마지막 집중 세션에서만)
      // 매 집중 세션마다 자동완료하면 안 되므로, 긴 휴식 직전(마지막 세션) 완료 시에만 수행한다
      // 캡처된 상태의 completedSessions를 기준으로 판단한다
      if (capturedState.linkedTodoId != null &&
          capturedState.sessionType == TimerSessionType.focus) {
        final nextCompleted = capturedState.completedSessions + 1;
        final isLastSession = nextCompleted % _sessionsBeforeLong == 0;
        if (isLastSession) {
          try {
            await _ref.read(toggleTodoProvider)(capturedState.linkedTodoId!, true);
          } catch (e, stack) {
            // V3-006: 투두 자동완료 실패를 구조화된 에러 핸들러로 기록한다
            ErrorHandler.logServiceError('TimerProvider:TodoAutoComplete', e, stack);
          }
        }
      }

      // 버전 카운터 증가 → allTimerLogsRawProvider 재평가 → 모든 파생 Provider 자동 갱신
      _ref.read(timerLogDataVersionProvider.notifier).state++;

      // 타이머 로그 저장 후 업적 달성 조건을 확인한다
      await checkAchievementsAndNotify(_ref);
    } catch (e, stack) {
      ErrorHandler.logServiceError('TimerLogSave', e, stack);
    }
  }

  @override
  void dispose() {
    // 위젯이 소멸될 때 반드시 ticker를 취소하여 메모리 누수를 방지한다
    _ticker?.cancel();
    super.dispose();
  }
}
