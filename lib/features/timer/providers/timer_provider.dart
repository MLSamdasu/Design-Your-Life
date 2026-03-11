// F6: 포모도로 타이머 Riverpod Provider
// Hive 로컬 저장소를 통해 타이머 로그를 조회/저장한다 (로컬 퍼스트).
// dart:async Timer를 사용하여 매초 카운트다운을 수행한다.
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/error_handler.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/providers/global_providers.dart';
import '../../../features/todo/providers/todo_provider.dart';
import '../models/timer_log.dart';
import '../models/timer_state.dart';
import '../services/timer_engine.dart';
import '../services/timer_repository.dart';

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

// ─── 오늘 타이머 로그 Provider ─────────────────────────────────────

/// 오늘의 타이머 로그 Provider (FutureProvider)
/// selectedDateProvider를 watch하여 날짜가 바뀌면 자동으로 재로드한다.
/// 로컬 퍼스트: 인증 없이도 로컬 데이터를 반환한다
final todayTimerLogsProvider = FutureProvider<List<TimerLog>>((ref) async {
  final repository = ref.watch(timerRepositoryProvider);
  // selectedDateProvider를 watch하여 날짜 변경 시 재로드한다
  final selectedDate = ref.watch(selectedDateProvider);
  return repository.getTodayLogs(selectedDate);
});

// ─── 오늘 총 집중 시간 파생 Provider ─────────────────────────────────

/// 오늘의 총 집중 시간(분) 파생 Provider
/// todayTimerLogsProvider에서 focus 타입만 필터링하여 분 단위로 계산한다
final todayFocusMinutesProvider = Provider<int>((ref) {
  final logsAsync = ref.watch(todayTimerLogsProvider);
  return logsAsync.when(
    data: (logs) {
      // focus 타입 로그의 durationSeconds 합계를 분으로 변환한다
      final focusSeconds = logs
          .where((log) => log.type == TimerSessionType.focus)
          .fold<int>(0, (sum, log) => sum + log.durationSeconds);
      return focusSeconds ~/ 60;
    },
    loading: () => 0,
    error: (_, __) => 0,
  );
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

  TimerStateNotifier(this._ref) : super(TimerState.idle());

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
  void reset() {
    _ticker?.cancel();
    _ticker = null;
    state = TimerState.idle();
  }

  /// 다음 세션으로 전환한다
  /// completed 상태에서 사용자가 수동으로 다음 세션을 시작할 때 호출한다
  void nextSession() {
    if (state.phase != TimerPhase.completed) return;

    // 집중 세션 완료 시에만 completedSessions를 증가시킨다
    final newCompletedSessions = state.sessionType == TimerSessionType.focus
        ? state.completedSessions + 1
        : state.completedSessions;

    final nextType = TimerEngine.nextSessionType(
      state.sessionType,
      newCompletedSessions,
    );
    final nextDuration = TimerEngine.durationForType(nextType);

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
      state = state.copyWith(
        phase: TimerPhase.completed,
        remainingSeconds: 0,
      );
      // 로그 저장은 비동기로 처리하여 UI를 블록하지 않는다
      _saveLog();
    } else {
      state = state.copyWith(remainingSeconds: newRemaining);
    }
  }

  /// 세션 완료 시 TimerLog를 Hive 로컬 저장소에 저장한다
  /// 로컬 퍼스트: 인증 없이도 로그를 저장한다 (userId가 null이면 빈 문자열 사용)
  Future<void> _saveLog() async {
    // 로컬 퍼스트: 미인증 상태에서도 로컬에 저장한다
    final userId = _ref.read(currentUserIdProvider) ?? '';

    final repository = _ref.read(timerRepositoryProvider);
    final now = DateTime.now();
    final logId = DateTime.now().millisecondsSinceEpoch.toString();

    // sessionStartTime이 없으면 durationSeconds 기준으로 역산한다
    final startTime = state.sessionStartTime ??
        now.subtract(Duration(seconds: state.totalSeconds));

    final log = TimerLog(
      id: logId,
      userId: userId,
      todoId: state.linkedTodoId,
      todoTitle: state.linkedTodoTitle,
      startTime: startTime,
      endTime: now,
      durationSeconds: state.totalSeconds,
      type: state.sessionType,
      createdAt: now,
    );

    // 저장 실패 시 에러를 로그에 기록하되 UI 상태는 유지한다
    try {
      await repository.createLog(log);
      // 저장 성공 후 오늘 타이머 로그를 다시 로드한다
      _ref.invalidate(todayTimerLogsProvider);
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
