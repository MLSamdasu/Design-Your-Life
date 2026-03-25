// F6: 포모도로 타이머 StateNotifier — 매초 카운트다운, 세션 완료 시 로그 저장
// 세션 전환 로직은 timer_session_transition.dart로 분리하였다.
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/timer_state.dart';
import 'timer_log_saver.dart';
import 'timer_session_transition.dart';
import 'timer_settings_providers.dart';

/// 타이머 실행 상태 Provider
final timerStateProvider =
    StateNotifierProvider<TimerStateNotifier, TimerState>((ref) {
  return TimerStateNotifier(ref);
});

/// 타이머 상태 관리 StateNotifier — dart:async Timer로 매초 카운트다운한다
class TimerStateNotifier extends StateNotifier<TimerState> {
  final Ref _ref;

  /// 매초 틱을 발생시키는 타이머 (실행 중에만 활성화)
  Timer? _ticker;

  /// _tick 세션 완료 시 로그 저장 Future — nextSession/stop에서 await한다
  Future<void>? _saveCompleted;

  TimerStateNotifier(this._ref) : super(TimerState.idleWith(
    focusSeconds: _ref.read(timerFocusMinutesProvider) * 60,
  ));

  /// 현재 설정에서 집중 시간(초)을 읽는다
  int get _focusSeconds => _ref.read(timerFocusMinutesProvider) * 60;

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

  /// 타이머를 정지하고 경과 시간을 로그로 저장한다
  /// running 또는 paused 상태에서만 동작한다
  /// 경과 시간이 0초이면 로그를 저장하지 않는다
  /// await로 로그 저장 완료 후 idle로 전환하여 홈 화면 반영을 보장한다
  Future<void> stop() async {
    // completed 상태에서 stop 호출 시: _tick에서 시작된 비동기 로그 저장을 기다린다
    if (state.phase == TimerPhase.completed) {
      if (_saveCompleted != null) {
        await _saveCompleted;
        _saveCompleted = null;
      }
      state = TimerState.idleWith(focusSeconds: _focusSeconds);
      return;
    }

    if (state.phase != TimerPhase.running &&
        state.phase != TimerPhase.paused) {
      return;
    }

    _ticker?.cancel();
    _ticker = null;

    final elapsed = state.totalSeconds - state.remainingSeconds;

    // 경과 시간이 0이면 로그 저장 없이 리셋만 한다
    if (elapsed > 0) {
      final snapshot = state;
      // await로 Hive 저장 + 버전 범프 완료를 보장한다
      await saveTimerLog(_ref, snapshot);
    }

    // 로그 저장 완료 후 idle로 복귀한다
    state = TimerState.idleWith(focusSeconds: _focusSeconds);
  }

  /// 타이머를 초기 상태로 리셋한다
  /// 실행 중이거나 일시정지된 경우 로그 저장 없이 취소한다
  /// 사용자가 설정한 집중 시간으로 초기화한다
  void reset() {
    _ticker?.cancel();
    _ticker = null;
    _saveCompleted = null;
    state = TimerState.idleWith(focusSeconds: _focusSeconds);
  }

  /// 다음 세션으로 전환한다
  /// completed 상태에서 사용자가 수동으로 다음 세션을 시작할 때 호출한다
  /// 사용자가 설정한 시간 값으로 다음 세션 길이를 결정한다
  /// _saveCompleted를 await하여 이전 세션 로그 저장 완료를 보장한다
  Future<void> nextSession() async {
    if (state.phase != TimerPhase.completed) return;

    // _tick에서 시작된 비동기 로그 저장이 있으면 완료를 기다린다
    if (_saveCompleted != null) {
      await _saveCompleted;
      _saveCompleted = null;
    }

    // 세션 전환 계산을 외부 헬퍼에 위임한다 (SRP)
    final next = calculateNextSession(_ref, state);

    state = state.copyWith(
      phase: TimerPhase.idle,
      sessionType: next.sessionType,
      totalSeconds: next.durationSeconds,
      remainingSeconds: next.durationSeconds,
      completedSessions: next.completedSessions,
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
  /// 세션 완료 시 로그를 저장하고, 완료 후 상태를 갱신한다
  void _tick() {
    if (state.phase != TimerPhase.running) return;

    final newRemaining = state.remainingSeconds - 1;

    if (newRemaining <= 0) {
      // 세션 완료: 타이머를 멈추고 로그를 저장한다
      _ticker?.cancel();
      _ticker = null;
      // remainingSeconds=0으로 보정한 스냅샷으로 정확한 durationSeconds를 보장
      final snapshot = state.copyWith(remainingSeconds: 0);
      state = state.copyWith(
        phase: TimerPhase.completed,
        remainingSeconds: 0,
      );
      // await로 Hive 저장 + 버전 범프 완료 → 홈 화면 즉시 반영
      // _saveCompleted를 통해 비동기 저장 완료를 추적하여 홈 화면 전환 시 데이터 반영을 보장한다
      _saveCompleted = saveTimerLog(_ref, snapshot);
    } else {
      state = state.copyWith(remainingSeconds: newRemaining);
    }
  }

  @override
  void dispose() {
    // 위젯이 소멸될 때 반드시 ticker를 취소하여 메모리 누수를 방지한다
    _ticker?.cancel();
    super.dispose();
  }
}
