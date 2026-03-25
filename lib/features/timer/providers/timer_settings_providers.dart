// F6: 포모도로 타이머 설정 Provider
// Hive settingsBox에서 초기값을 읽어 사용자 타이머 설정을 관리한다.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/global_providers.dart';

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
