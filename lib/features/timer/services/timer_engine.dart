// F6: TimerEngine (순수 함수 모듈)
// StreakCalculator와 동일한 abstract class 패턴을 사용한다.
// 모든 메서드는 외부 상태에 의존하지 않는 순수 함수로 구현한다.
import '../models/timer_log.dart';

/// 포모도로 타이머 엔진 (순수 함수)
/// 타이머 로직을 상태 변환 함수로 캡슐화한다
abstract class TimerEngine {
  // ─── 포모도로 기본 시간 상수 (기본값, 설정 미저장 시 사용) ─────────────────

  /// 집중 세션 시간 기본값 (25분 = 1500초)
  static const int focusDurationSeconds = 25 * 60;

  /// 짧은 휴식 시간 기본값 (5분 = 300초)
  static const int shortBreakSeconds = 5 * 60;

  /// 긴 휴식 시간 기본값 (15분 = 900초, 4회차 포모도로 후 제공)
  static const int longBreakSeconds = 15 * 60;

  /// 긴 휴식 전 필요한 집중 세션 완료 횟수 기본값
  static const int sessionsBeforeLongBreak = 4;

  // ─── 세션 전환 로직 ──────────────────────────────────────────────────────

  /// 현재 세션 종료 후 다음 세션 유형을 결정한다
  /// sessionsBeforeLong: 사용자가 설정한 긴 휴식 전 세션 횟수 (기본 4)
  /// 집중 세션 완료 후: completedSessions가 sessionsBeforeLong의 배수이면 긴 휴식, 아니면 짧은 휴식
  /// 휴식 세션 완료 후: 항상 집중 세션으로 전환한다
  static TimerSessionType nextSessionType(
    TimerSessionType currentType,
    int completedSessions, {
    int sessionsBeforeLong = sessionsBeforeLongBreak,
  }) {
    // 휴식 세션이 끝나면 항상 집중 세션으로 돌아간다
    if (currentType == TimerSessionType.shortBreak ||
        currentType == TimerSessionType.longBreak) {
      return TimerSessionType.focus;
    }

    // 집중 세션이 끝난 경우: sessionsBeforeLong 완료마다 긴 휴식 제공
    if (completedSessions > 0 &&
        completedSessions % sessionsBeforeLong == 0) {
      return TimerSessionType.longBreak;
    }

    return TimerSessionType.shortBreak;
  }

  // ─── 시간 계산 ───────────────────────────────────────────────────────────

  /// 세션 유형에 따른 총 시간(초)을 반환한다 (기본값 사용)
  static int durationForType(TimerSessionType type) {
    return durationForTypeCustom(type);
  }

  /// 세션 유형에 따른 총 시간(초)을 반환한다 (사용자 설정값 사용)
  /// focusMin/shortBreakMin/longBreakMin: 사용자 설정 분 단위 값
  static int durationForTypeCustom(
    TimerSessionType type, {
    int focusMin = 25,
    int shortBreakMin = 5,
    int longBreakMin = 15,
  }) {
    switch (type) {
      case TimerSessionType.focus:
        return focusMin * 60;
      case TimerSessionType.shortBreak:
        return shortBreakMin * 60;
      case TimerSessionType.longBreak:
        return longBreakMin * 60;
    }
  }

  // ─── 표시 포맷 ───────────────────────────────────────────────────────────

  /// 남은 초를 "MM:SS" 포맷 문자열로 변환한다
  /// 예: 1500 → "25:00", 65 → "01:05"
  static String formatTime(int remainingSeconds) {
    // 음수 방어 처리: 0 이하는 "00:00"으로 표시한다
    final safeSeconds = remainingSeconds.clamp(0, double.maxFinite.toInt());
    final minutes = safeSeconds ~/ 60;
    final seconds = safeSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // ─── 진행률 계산 ─────────────────────────────────────────────────────────

  /// 타이머 진행률을 0.0~1.0 범위로 반환한다
  /// totalSeconds가 0이면 0.0을 반환한다 (ZeroDivision 방어)
  static double progress(int totalSeconds, int remainingSeconds) {
    if (totalSeconds <= 0) return 0.0;
    // 경과 시간 비율 = (전체 - 남은) / 전체
    final elapsed = totalSeconds - remainingSeconds;
    return (elapsed / totalSeconds).clamp(0.0, 1.0);
  }
}
