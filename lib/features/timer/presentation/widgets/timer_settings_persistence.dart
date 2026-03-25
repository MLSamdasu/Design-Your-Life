// F6: 타이머 설정 영속화 헬퍼
// 각 설정값을 Hive에 저장하고 Provider를 갱신하는 순수 함수들을 모은다.
// TimerSettingsSheet에서 슬라이더 변경 시 호출된다.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/global_providers.dart';
import '../../models/timer_state.dart';
import '../../providers/timer_provider.dart';

/// 집중 시간을 Hive에 저장하고 Provider를 갱신한다
void saveFocusMinutes(WidgetRef ref, int value) {
  ref.read(timerFocusMinutesProvider.notifier).state = value;
  ref.read(hiveCacheServiceProvider).saveSetting(
        AppConstants.settingsKeyTimerFocusMinutes,
        value,
      );
  // idle 상태이면 타이머 표시도 갱신한다
  refreshTimerIfIdle(ref);
}

/// 짧은 휴식 시간을 Hive에 저장하고 Provider를 갱신한다
void saveShortBreak(WidgetRef ref, int value) {
  ref.read(timerShortBreakMinutesProvider.notifier).state = value;
  ref.read(hiveCacheServiceProvider).saveSetting(
        AppConstants.settingsKeyTimerShortBreakMinutes,
        value,
      );
}

/// 긴 휴식 시간을 Hive에 저장하고 Provider를 갱신한다
void saveLongBreak(WidgetRef ref, int value) {
  ref.read(timerLongBreakMinutesProvider.notifier).state = value;
  ref.read(hiveCacheServiceProvider).saveSetting(
        AppConstants.settingsKeyTimerLongBreakMinutes,
        value,
      );
}

/// 긴 휴식 전 세션 횟수를 Hive에 저장하고 Provider를 갱신한다
void saveSessionsBeforeLong(WidgetRef ref, int value) {
  ref.read(timerSessionsBeforeLongBreakProvider.notifier).state = value;
  ref.read(hiveCacheServiceProvider).saveSetting(
        AppConstants.settingsKeyTimerSessionsBeforeLongBreak,
        value,
      );
}

/// idle 상태이면 타이머 표시를 새 설정값으로 갱신한다
/// 실행 중이거나 일시정지 상태에서는 진행 상태를 보호하기 위해 리셋하지 않는다
void refreshTimerIfIdle(WidgetRef ref) {
  final phase = ref.read(timerStateProvider).phase;
  if (phase == TimerPhase.idle) {
    ref.read(timerStateProvider.notifier).reset();
  }
}

/// 모든 설정을 기본값으로 복원한다
void resetTimerSettingsToDefaults(WidgetRef ref) {
  saveFocusMinutes(ref, 25);
  saveShortBreak(ref, 5);
  saveLongBreak(ref, 15);
  saveSessionsBeforeLong(ref, 4);
}
