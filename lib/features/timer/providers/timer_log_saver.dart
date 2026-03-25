// F6: 포모도로 타이머 로그 저장 헬퍼
// 세션 완료 시 TimerLog를 Hive 로컬 저장소에 저장하고
// 연결된 투두의 자동완료 및 업적 달성 확인을 처리한다.
// TimerStateNotifier에서 분리하여 SRP를 준수한다.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/error/error_handler.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/providers/data_store_providers.dart';
import '../../../features/todo/providers/todo_provider.dart';
import '../../achievement/providers/achievement_provider.dart';
import '../models/timer_log.dart';
import '../models/timer_state.dart';
import 'timer_query_providers.dart';
import 'timer_settings_providers.dart';

/// 세션 완료 시 TimerLog를 Hive 로컬 저장소에 저장한다
/// 로컬 퍼스트: 인증 없이도 로그를 저장한다 (userId가 null이면 로컬 ID 사용)
/// [ref]: Riverpod ref — Provider 읽기에 사용한다
/// [capturedState]: _tick()에서 캡처한 상태 스냅샷 — async 갭 동안 state가 변경되어도 안전하다
Future<void> saveTimerLog(Ref ref, TimerState capturedState) async {
  // 로컬 퍼스트: 미인증 상태에서도 로컬에 저장한다
  final userId = ref.read(currentUserIdProvider) ?? AppConstants.localUserId;

  final repository = ref.read(timerRepositoryProvider);
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
      final sessionsBeforeLong = ref.read(timerSessionsBeforeLongBreakProvider);
      final nextCompleted = capturedState.completedSessions + 1;
      final isLastSession = nextCompleted % sessionsBeforeLong == 0;
      if (isLastSession) {
        try {
          await ref.read(toggleTodoProvider)(capturedState.linkedTodoId!, true);
        } catch (e, stack) {
          // V3-006: 투두 자동완료 실패를 구조화된 에러 핸들러로 기록한다
          ErrorHandler.logServiceError('TimerProvider:TodoAutoComplete', e, stack);
        }
      }
    }

    // 버전 카운터 증가 → allTimerLogsRawProvider 재평가 → 모든 파생 Provider 자동 갱신
    ref.read(timerLogDataVersionProvider.notifier).state++;

    // 타이머 로그 저장 후 업적 달성 조건을 확인한다
    await checkAchievementsAndNotify(ref);
  } catch (e, stack) {
    ErrorHandler.logServiceError('TimerLogSave', e, stack);
  }
}
