// F1: 홈 대시보드 — 오늘 습관 요약 Provider
// allHabitsRawProvider + allHabitLogsRawProvider(Single Source of Truth)에서 파생하여
// 습관 체크/CRUD 시 자동 갱신된다.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/data_store_providers.dart';
import '../../../core/providers/global_providers.dart';
import '../../../core/error/error_handler.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/models/habit.dart';
import '../../../shared/models/habit_log.dart';
import '../../habit/providers/habit_provider.dart';
import '../../habit/services/streak_calculator.dart';
import 'home_models.dart';

/// 오늘 습관 요약 Provider (동기)
/// allHabitsRawProvider + allHabitLogsRawProvider(Single Source of Truth)에서 파생하여
/// 습관 체크/CRUD 시 자동 갱신된다
final todayHabitsProvider = Provider<HabitSummary>((ref) {
  // 단일 진실 원천(SSOT): 중앙 데이터 스토어에서 파생한다
  final allHabits = ref.watch(allHabitsRawProvider);
  final allLogs = ref.watch(allHabitLogsRawProvider);
  // 자정 경계 불일치 방지: 공유 todayDateProvider를 사용한다
  final today = ref.watch(todayDateProvider);
  final dateStr = AppDateUtils.toDateString(today);

  try {
    // 활성 습관만 필터링한다
    final activeHabits = allHabits
        .where((h) => h['is_active'] == true)
        .toList();

    // id 기준으로 정렬한다
    activeHabits.sort((a, b) {
      final aId = a['id']?.toString() ?? '';
      final bId = b['id']?.toString() ?? '';
      return aId.compareTo(bId);
    });

    // 오늘 요일에 예정된 습관만 필터링한다 (빈도 기반)
    final habits = activeHabits.where((h) {
      final habit = Habit.fromMap(h);
      return habit.isScheduledFor(today);
    }).toList();

    // 오늘의 습관 로그만 필터링한다
    final logs = allLogs
        .where((d) => d['log_date'] == dateStr)
        .toList();

    if (habits.isEmpty) return HabitSummary.empty;

    // 완료된 습관 ID 집합 추출
    final completedIds = logs
        .where((d) => d['is_completed'] == true)
        .map((d) => d['habit_id']?.toString() ?? '')
        .toSet();

    final total = habits.length;
    final completedCount = habits
        .where((h) => completedIds.contains(h['id']?.toString()))
        .length;
    final rate = total > 0 ? (completedCount / total) * 100 : 0.0;

    // 미완료 우선 최대 3개
    final preview = [
      ...habits.where((h) =>
          !completedIds.contains(h['id']?.toString())),
      ...habits.where((h) =>
          completedIds.contains(h['id']?.toString())),
    ].take(3).toList();

    // 스트릭 계산을 위해 DI된 HabitLogRepository Provider를 사용한다
    final logRepo = ref.read(habitLogRepositoryProvider);
    // 자정 경계 불일치 방지: 공유 todayDateProvider 기준 날짜를 사용한다
    final now = today;

    return HabitSummary(
      totalCount: total,
      completedCount: completedCount,
      achievementRate: rate,
      previewItems: preview.map((doc) {
        final habitId = doc['id']?.toString() ?? '';
        final habit = Habit.fromMap(doc);
        final checkedDates = logRepo.getCheckedDates(habitId);
        int streak = 0;
        if (checkedDates.isNotEmpty) {
          final habitLogs = checkedDates
              .map((date) => HabitLog(
                    id: '',
                    habitId: habitId,
                    date: date,
                    isCompleted: true,
                    checkedAt: date,
                  ))
              .toList();
          streak = StreakCalculator.calculate(
            habitLogs,
            now,
            frequency: habit.frequency,
            repeatDays: habit.repeatDays,
          ).currentStreak;
        }
        return HabitPreviewItem(
          id: habitId,
          name: doc['name'] as String? ?? '',
          icon: doc['icon'] as String?,
          isCompleted: completedIds.contains(doc['id']?.toString()),
          streak: streak,
        );
      }).toList(),
    );
  } catch (e, stack) {
    ErrorHandler.logServiceError('HomeProvider:todayHabits', e, stack);
    return HabitSummary.empty;
  }
});
