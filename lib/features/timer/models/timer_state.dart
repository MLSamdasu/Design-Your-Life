// F6: 타이머 런타임 상태 모델
// Riverpod StateNotifier에서 관리하는 인메모리 전용 상태이다.
// 서버에 저장하지 않는다.
import 'timer_log.dart';
import '../services/timer_engine.dart';

/// 타이머 실행 단계
enum TimerPhase {
  /// 대기 상태 (타이머가 시작되지 않은 초기 상태)
  idle,

  /// 실행 중 (카운트다운 진행 중)
  running,

  /// 일시정지 (사용자가 중단, 재개 가능)
  paused,

  /// 완료 (세션 종료, 다음 세션 전환 대기)
  completed,
}

/// 포모도로 타이머 런타임 상태 모델
/// TimerStateNotifier가 이 값을 불변적으로 갱신한다
class TimerState {
  /// 현재 타이머 실행 단계
  final TimerPhase phase;

  /// 현재 세션 유형 (집중/짧은 휴식/긴 휴식)
  final TimerSessionType sessionType;

  /// 현재 세션 전체 시간 (초)
  final int totalSeconds;

  /// 현재 세션 남은 시간 (초)
  final int remainingSeconds;

  /// 완료된 집중 세션 횟수 (4회 → 긴 휴식 트리거)
  final int completedSessions;

  /// 연결된 투두 ID (선택, 투두 없이 실행 시 null)
  final String? linkedTodoId;

  /// 연결된 투두 제목 (비정규화, 화면 표시용)
  final String? linkedTodoTitle;

  /// 현재 세션 시작 시각 (로그 저장 시 startTime으로 사용)
  final DateTime? sessionStartTime;

  const TimerState({
    required this.phase,
    required this.sessionType,
    required this.totalSeconds,
    required this.remainingSeconds,
    required this.completedSessions,
    this.linkedTodoId,
    this.linkedTodoTitle,
    this.sessionStartTime,
  });

  /// 초기 상태 팩토리 생성자
  /// 앱 시작 또는 리셋 시 이 상태로 복귀한다
  /// 중복 상수 제거: TimerEngine.focusDurationSeconds를 단일 출처로 사용한다
  factory TimerState.idle() {
    const focusDuration = TimerEngine.focusDurationSeconds;
    return const TimerState(
      phase: TimerPhase.idle,
      sessionType: TimerSessionType.focus,
      totalSeconds: focusDuration,
      remainingSeconds: focusDuration,
      completedSessions: 0,
    );
  }

  /// 불변 업데이트: 특정 필드만 변경된 새 인스턴스를 반환한다
  TimerState copyWith({
    TimerPhase? phase,
    TimerSessionType? sessionType,
    int? totalSeconds,
    int? remainingSeconds,
    int? completedSessions,
    String? linkedTodoId,
    bool clearLinkedTodoId = false,
    String? linkedTodoTitle,
    bool clearLinkedTodoTitle = false,
    DateTime? sessionStartTime,
    bool clearSessionStartTime = false,
  }) {
    return TimerState(
      phase: phase ?? this.phase,
      sessionType: sessionType ?? this.sessionType,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      completedSessions: completedSessions ?? this.completedSessions,
      linkedTodoId:
          clearLinkedTodoId ? null : (linkedTodoId ?? this.linkedTodoId),
      linkedTodoTitle:
          clearLinkedTodoTitle ? null : (linkedTodoTitle ?? this.linkedTodoTitle),
      sessionStartTime:
          clearSessionStartTime ? null : (sessionStartTime ?? this.sessionStartTime),
    );
  }
}
