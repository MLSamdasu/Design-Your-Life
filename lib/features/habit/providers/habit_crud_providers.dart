// F4-CRUD: 습관 생성/수정/삭제/토글 액션 Provider
// 상태 변경을 수행하는 Provider를 정의한다.
// 각 액션 후 버전 카운터를 증가시켜 홈/습관 탭 자동 갱신을 트리거한다.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/providers/data_store_providers.dart';
import '../../../core/error/error_handler.dart';
import '../../../shared/models/habit.dart';
import '../../../shared/models/habit_log.dart';
import '../../achievement/providers/achievement_provider.dart';
import '../services/streak_calculator.dart';
import '../services/time_lock_validator.dart';
import 'habit_state_providers.dart';

// ─── 습관 체크 Provider ─────────────────────────────────────────────────────

/// 습관 체크 토글 액션
/// 시간 잠금 검증 후 로컬 Hive에서 체크/체크 해제를 수행한다
/// 시간 잠금으로 거부된 경우 TimeLockResult를 반환하여 UI에서 사유를 표시할 수 있다
final toggleHabitProvider =
    Provider<Future<TimeLockResult?> Function(String, DateTime, bool)>((ref) {
  final repository = ref.watch(habitLogRepositoryProvider);

  return (String habitId, DateTime date, bool isCompleted) async {
    // F4.4 시간 잠금 검증 (과거 날짜 편집 방지)
    final lockResult = TimeLockValidator.validate(date, DateTime.now());
    if (!lockResult.isEditable) return lockResult; // 잠금 사유를 반환한다

    // isCompleted가 true면 체크 생성, false면 체크 해제 (로그 삭제)
    if (isCompleted) {
      await repository.checkHabit(habitId, date: date);
    } else {
      await repository.uncheckHabit(habitId, date);
    }
    // 로그 변경 버전 카운터 증가 → 홈/습관 탭 로그 관련 UI 자동 갱신
    ref.read(habitLogDataVersionProvider.notifier).state++;

    // 스트릭을 재계산하여 Hive에 영구 저장한다
    // AchievementStatsCollector가 longest_streak를 Hive에서 읽으므로
    // 여기서 영구화하지 않으면 스트릭 기반 업적이 달성 불가능하다
    try {
      final habitRepo = ref.read(habitRepositoryProvider);
      final logRepo = ref.read(habitLogRepositoryProvider);
      final checkedDates = logRepo.getCheckedDates(habitId);
      final habits = habitRepo.getActiveHabits();
      final habit = habits.where((h) => h.id == habitId).firstOrNull;
      final logs = checkedDates
          .map((d) => HabitLog(
              id: '',
              habitId: habitId,
              date: d,
              isCompleted: true,
              checkedAt: d))
          .toList();
      final result = StreakCalculator.calculate(
        logs,
        DateTime.now(),
        frequency: habit?.frequency ?? HabitFrequency.daily,
        repeatDays: habit?.repeatDays ?? const [],
      );
      await habitRepo.updateStreak(
          habitId, result.currentStreak, result.longestStreak);
      // 스트릭 영구화 성공 시에만 습관 데이터 버전을 범프한다
      // (습관 자체의 streak 필드가 변경되었으므로)
      ref.read(habitDataVersionProvider.notifier).state++;
    } catch (e, stack) {
      // 스트릭 영구화 실패는 주 기능을 차단하지 않지만 에러를 기록한다
      ErrorHandler.logServiceError(
          'HabitProvider:StreakPersistence', e, stack);
    }

    // 체크 완료 시 업적 달성 조건을 확인한다
    if (isCompleted) {
      await checkAchievementsAndNotify(ref);
    }

    // 성공 시 null 반환 (시간 잠금 거부 없음)
    return null;
  };
});

/// 새 습관 생성 액션
final createHabitProvider = Provider<Future<void> Function(Habit)>((ref) {
  final repository = ref.watch(habitRepositoryProvider);

  return (Habit habit) async {
    try {
      await repository.createHabit(habit);
      // 버전 카운터 증가 → 홈/습관 탭 모두 자동 갱신
      ref.read(habitDataVersionProvider.notifier).state++;
    } catch (e, st) {
      Error.throwWithStackTrace(e, st);
    }
  };
});

/// 습관 수정 액션
final updateHabitProvider =
    Provider<Future<void> Function(String, Habit)>((ref) {
  final repository = ref.watch(habitRepositoryProvider);

  return (String habitId, Habit habit) async {
    try {
      await repository.updateHabit(habitId, habit);
      // 버전 카운터 증가 → 홈/습관 탭 모두 자동 갱신
      ref.read(habitDataVersionProvider.notifier).state++;
    } catch (e, st) {
      Error.throwWithStackTrace(e, st);
    }
  };
});

/// 습관 삭제 액션
/// 삭제 시 HabitLogRepository를 통해 해당 습관의 고아 로그도 함께 정리한다
final deleteHabitProvider = Provider<Future<void> Function(String)>((ref) {
  final repository = ref.watch(habitRepositoryProvider);
  final logRepository = ref.watch(habitLogRepositoryProvider);

  return (String habitId) async {
    try {
      // V3-011: 고아 습관 로그 정리를 HabitLogRepository에 위임한다
      await logRepository.deleteLogsByHabitId(habitId);
      await repository.deleteHabit(habitId);
      // 버전 카운터 증가 → 홈/습관 탭 모두 자동 갱신
      ref.read(habitDataVersionProvider.notifier).state++;
      ref.read(habitLogDataVersionProvider.notifier).state++;
    } catch (e, st) {
      Error.throwWithStackTrace(e, st);
    }
  };
});

/// 새 습관 ID 생성 헬퍼
/// 로컬 퍼스트에서 클라이언트가 UUID v4로 고유 ID를 생성한다
/// HabitRepository.createHabit()가 내부에서 UUID를 재생성하므로 이 ID는 임시이다
final generateHabitIdProvider = Provider<String Function()>((ref) {
  return () {
    return const Uuid().v4();
  };
});
