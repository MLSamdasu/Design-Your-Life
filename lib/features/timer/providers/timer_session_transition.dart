// F6: 포모도로 타이머 세션 전환 로직
// nextSession 호출 시 다음 세션 타입과 시간을 결정하는 헬퍼 함수이다.
// TimerStateNotifier에서 분리하여 SRP를 준수한다.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/timer_log.dart';
import '../models/timer_state.dart';
import '../services/timer_engine.dart';
import 'timer_settings_providers.dart';

/// 다음 세션 전환 결과를 담는 불변 데이터 클래스
class NextSessionResult {
  /// 다음 세션 유형 (집중/짧은 휴식/긴 휴식)
  final TimerSessionType sessionType;

  /// 다음 세션의 총 시간(초)
  final int durationSeconds;

  /// 갱신된 완료 세션 횟수
  final int completedSessions;

  const NextSessionResult({
    required this.sessionType,
    required this.durationSeconds,
    required this.completedSessions,
  });
}

/// 현재 상태를 기반으로 다음 세션 정보를 계산한다
/// [ref]: 사용자 설정값 읽기에 사용한다
/// [currentState]: 현재 타이머 상태 (세션 타입, 완료 횟수 참조)
NextSessionResult calculateNextSession(Ref ref, TimerState currentState) {
  // 집중 세션 완료 시에만 completedSessions를 증가시킨다
  final newCompletedSessions =
      currentState.sessionType == TimerSessionType.focus
          ? currentState.completedSessions + 1
          : currentState.completedSessions;

  final sessionsBeforeLong =
      ref.read(timerSessionsBeforeLongBreakProvider);

  final nextType = TimerEngine.nextSessionType(
    currentState.sessionType,
    newCompletedSessions,
    sessionsBeforeLong: sessionsBeforeLong,
  );

  final nextDuration = TimerEngine.durationForTypeCustom(
    nextType,
    focusMin: ref.read(timerFocusMinutesProvider),
    shortBreakMin: ref.read(timerShortBreakMinutesProvider),
    longBreakMin: ref.read(timerLongBreakMinutesProvider),
  );

  return NextSessionResult(
    sessionType: nextType,
    durationSeconds: nextDuration,
    completedSessions: newCompletedSessions,
  );
}
