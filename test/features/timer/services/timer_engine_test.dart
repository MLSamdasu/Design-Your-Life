// TimerEngine 순수 함수 단위 테스트
// 세션 전환 로직, 시간 포맷, 진행률 계산을 검증한다.
// 외부 의존성이 없는 순수 함수이므로 모킹이 필요 없다.
import 'package:design_your_life/features/timer/models/timer_log.dart';
import 'package:design_your_life/features/timer/services/timer_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TimerEngine 상수 검증', () {
    test('focusDurationSeconds는 1500(25분)이다', () {
      expect(TimerEngine.focusDurationSeconds, 1500);
    });

    test('shortBreakSeconds는 300(5분)이다', () {
      expect(TimerEngine.shortBreakSeconds, 300);
    });

    test('longBreakSeconds는 900(15분)이다', () {
      expect(TimerEngine.longBreakSeconds, 900);
    });

    test('sessionsBeforeLongBreak는 4이다', () {
      expect(TimerEngine.sessionsBeforeLongBreak, 4);
    });
  });

  group('TimerEngine.durationForType - 세션별 시간', () {
    test('focus 세션은 1500초를 반환한다', () {
      expect(TimerEngine.durationForType(TimerSessionType.focus), 1500);
    });

    test('shortBreak 세션은 300초를 반환한다', () {
      expect(TimerEngine.durationForType(TimerSessionType.shortBreak), 300);
    });

    test('longBreak 세션은 900초를 반환한다', () {
      expect(TimerEngine.durationForType(TimerSessionType.longBreak), 900);
    });
  });

  group('TimerEngine.nextSessionType - 세션 전환 로직', () {
    test('집중 세션 완료 후 첫 번째 → shortBreak', () {
      final next = TimerEngine.nextSessionType(
        TimerSessionType.focus,
        1, // 1회 완료
      );
      expect(next, TimerSessionType.shortBreak);
    });

    test('집중 세션 완료 후 두 번째 → shortBreak', () {
      final next = TimerEngine.nextSessionType(
        TimerSessionType.focus,
        2,
      );
      expect(next, TimerSessionType.shortBreak);
    });

    test('집중 세션 완료 후 세 번째 → shortBreak', () {
      final next = TimerEngine.nextSessionType(
        TimerSessionType.focus,
        3,
      );
      expect(next, TimerSessionType.shortBreak);
    });

    test('집중 세션 4회 완료 후 → longBreak', () {
      final next = TimerEngine.nextSessionType(
        TimerSessionType.focus,
        4, // 4회 완료 → longBreak
      );
      expect(next, TimerSessionType.longBreak);
    });

    test('집중 세션 8회 완료 후 → longBreak (4의 배수)', () {
      final next = TimerEngine.nextSessionType(
        TimerSessionType.focus,
        8,
      );
      expect(next, TimerSessionType.longBreak);
    });

    test('집중 세션 5회 완료 후 → shortBreak (4의 배수 아님)', () {
      final next = TimerEngine.nextSessionType(
        TimerSessionType.focus,
        5,
      );
      expect(next, TimerSessionType.shortBreak);
    });

    test('shortBreak 완료 후 → focus', () {
      final next = TimerEngine.nextSessionType(
        TimerSessionType.shortBreak,
        3,
      );
      expect(next, TimerSessionType.focus);
    });

    test('longBreak 완료 후 → focus', () {
      final next = TimerEngine.nextSessionType(
        TimerSessionType.longBreak,
        4,
      );
      expect(next, TimerSessionType.focus);
    });

    test('completedSessions가 0이면 shortBreak 반환 (첫 번째 집중 전)', () {
      final next = TimerEngine.nextSessionType(
        TimerSessionType.focus,
        0,
      );
      // 0 % 4 == 0이지만 0은 첫 시작이므로 shortBreak로 처리한다
      // nextSessionType(focus, 0): completedSessions가 0이면 shortBreak (조건: 0 > 0이 false)
      expect(next, TimerSessionType.shortBreak);
    });
  });

  group('TimerEngine.formatTime - 시간 포맷', () {
    test('1500초를 "25:00"으로 포맷한다', () {
      expect(TimerEngine.formatTime(1500), '25:00');
    });

    test('0초를 "00:00"으로 포맷한다', () {
      expect(TimerEngine.formatTime(0), '00:00');
    });

    test('65초를 "01:05"로 포맷한다', () {
      expect(TimerEngine.formatTime(65), '01:05');
    });

    test('300초를 "05:00"으로 포맷한다', () {
      expect(TimerEngine.formatTime(300), '05:00');
    });

    test('59초를 "00:59"로 포맷한다', () {
      expect(TimerEngine.formatTime(59), '00:59');
    });

    test('3600초를 "60:00"으로 포맷한다', () {
      expect(TimerEngine.formatTime(3600), '60:00');
    });

    test('음수는 "00:00"으로 처리한다 (방어 로직)', () {
      expect(TimerEngine.formatTime(-1), '00:00');
    });
  });

  group('TimerEngine.progress - 진행률 계산', () {
    test('시작 시점 진행률은 0.0이다', () {
      final p = TimerEngine.progress(1500, 1500);
      expect(p, 0.0);
    });

    test('완료 시점 진행률은 1.0이다', () {
      final p = TimerEngine.progress(1500, 0);
      expect(p, 1.0);
    });

    test('절반 경과 시 진행률은 0.5이다', () {
      final p = TimerEngine.progress(1500, 750);
      expect(p, closeTo(0.5, 0.001));
    });

    test('totalSeconds가 0이면 0.0을 반환한다 (ZeroDivision 방어)', () {
      final p = TimerEngine.progress(0, 0);
      expect(p, 0.0);
    });

    test('진행률은 항상 0.0~1.0 범위이다', () {
      // remainingSeconds가 totalSeconds보다 큰 비정상 케이스
      final p = TimerEngine.progress(1500, 2000);
      expect(p, greaterThanOrEqualTo(0.0));
      expect(p, lessThanOrEqualTo(1.0));
    });

    test('1/4 경과 시 진행률은 0.25이다', () {
      final p = TimerEngine.progress(1500, 1125);
      expect(p, closeTo(0.25, 0.001));
    });
  });
}
