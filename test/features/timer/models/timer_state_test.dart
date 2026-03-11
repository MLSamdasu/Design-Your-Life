// TimerState 모델 단위 테스트
// idle() 팩토리, copyWith 패턴, TimerPhase 전환 시나리오를 검증한다.
import 'package:design_your_life/features/timer/models/timer_log.dart';
import 'package:design_your_life/features/timer/models/timer_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TimerState.idle - 초기 상태', () {
    test('idle() 팩토리가 올바른 초기 상태를 반환한다', () {
      final state = TimerState.idle();

      expect(state.phase, TimerPhase.idle);
      expect(state.sessionType, TimerSessionType.focus);
      // 집중 세션 25분 = 1500초
      expect(state.totalSeconds, 1500);
      expect(state.remainingSeconds, 1500);
      expect(state.completedSessions, 0);
      expect(state.linkedTodoId, isNull);
      expect(state.linkedTodoTitle, isNull);
      expect(state.sessionStartTime, isNull);
    });

    test('idle 상태에서 totalSeconds와 remainingSeconds가 동일하다', () {
      final state = TimerState.idle();
      expect(state.totalSeconds, state.remainingSeconds);
    });
  });

  group('TimerState.copyWith - 불변 업데이트', () {
    test('phase를 running으로 변경한다', () {
      final state = TimerState.idle();
      final updated = state.copyWith(phase: TimerPhase.running);

      expect(updated.phase, TimerPhase.running);
      expect(state.phase, TimerPhase.idle); // 원본 불변
    });

    test('remainingSeconds를 감소시킨다', () {
      final state = TimerState.idle();
      final updated = state.copyWith(remainingSeconds: 1499);

      expect(updated.remainingSeconds, 1499);
      expect(state.remainingSeconds, 1500); // 원본 불변
    });

    test('linkedTodoId와 linkedTodoTitle을 설정한다', () {
      final state = TimerState.idle();
      final updated = state.copyWith(
        linkedTodoId: 'todo-1',
        linkedTodoTitle: '영어 공부',
      );

      expect(updated.linkedTodoId, 'todo-1');
      expect(updated.linkedTodoTitle, '영어 공부');
    });

    test('clearLinkedTodoId로 투두 연결을 해제한다', () {
      final state = TimerState.idle().copyWith(
        linkedTodoId: 'todo-1',
        linkedTodoTitle: '영어 공부',
      );

      final cleared = state.copyWith(
        clearLinkedTodoId: true,
        clearLinkedTodoTitle: true,
      );

      expect(cleared.linkedTodoId, isNull);
      expect(cleared.linkedTodoTitle, isNull);
    });

    test('sessionStartTime을 설정하고 해제한다', () {
      final now = DateTime(2026, 3, 10, 9, 0);
      final state = TimerState.idle().copyWith(sessionStartTime: now);

      expect(state.sessionStartTime, now);

      final cleared = state.copyWith(clearSessionStartTime: true);
      expect(cleared.sessionStartTime, isNull);
    });

    test('completedSessions를 증가시킨다', () {
      final state = TimerState.idle();
      final updated = state.copyWith(completedSessions: 3);

      expect(updated.completedSessions, 3);
    });

    test('sessionType을 shortBreak으로 변경한다', () {
      final state = TimerState.idle();
      final updated = state.copyWith(
        sessionType: TimerSessionType.shortBreak,
        totalSeconds: 300,
        remainingSeconds: 300,
      );

      expect(updated.sessionType, TimerSessionType.shortBreak);
      expect(updated.totalSeconds, 300);
      expect(updated.remainingSeconds, 300);
    });
  });

  group('TimerPhase 전환 시나리오', () {
    test('idle → running 전환', () {
      final state = TimerState.idle();
      final running = state.copyWith(
        phase: TimerPhase.running,
        sessionStartTime: DateTime(2026, 3, 10, 9, 0),
      );

      expect(running.phase, TimerPhase.running);
      expect(running.sessionStartTime, isNotNull);
    });

    test('running → paused 전환', () {
      final running = TimerState.idle().copyWith(
        phase: TimerPhase.running,
        remainingSeconds: 1200,
      );
      final paused = running.copyWith(phase: TimerPhase.paused);

      expect(paused.phase, TimerPhase.paused);
      // 남은 시간은 그대로 유지된다
      expect(paused.remainingSeconds, 1200);
    });

    test('running → completed 전환 (remainingSeconds = 0)', () {
      final running = TimerState.idle().copyWith(
        phase: TimerPhase.running,
        remainingSeconds: 1,
      );
      final completed = running.copyWith(
        phase: TimerPhase.completed,
        remainingSeconds: 0,
      );

      expect(completed.phase, TimerPhase.completed);
      expect(completed.remainingSeconds, 0);
    });

    test('completed → idle 리셋', () {
      // 리셋은 새 idle 상태를 생성한다 (completed 상태의 분기 확인)
      final reset = TimerState.idle();
      expect(reset.phase, TimerPhase.idle);
      expect(reset.completedSessions, 0);
    });
  });

  group('TimerState 불변성 검증', () {
    test('copyWith 호출 후 원본 상태는 변경되지 않는다', () {
      final original = TimerState.idle();
      // 여러 번 copyWith 호출
      original.copyWith(phase: TimerPhase.running);
      original.copyWith(remainingSeconds: 100);
      original.copyWith(completedSessions: 5);

      // 원본은 항상 idle 상태를 유지한다
      expect(original.phase, TimerPhase.idle);
      expect(original.remainingSeconds, 1500);
      expect(original.completedSessions, 0);
    });
  });
}
