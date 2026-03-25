// 주간 캘린더 파생 Providers
// 주간 뷰용 루틴 + 습관 완료율 데이터를 제공한다
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/data_store_providers.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/models/habit.dart';
import '../../../shared/models/habit_log.dart';
import '../../../shared/models/routine.dart';
import 'event_models.dart';
import 'calendar_provider.dart';

/// 주간 뷰용 루틴 데이터: 주의 각 날짜에 해당하는 RoutineEntry 목록
final routinesForWeekProvider =
    Provider<Map<DateTime, List<RoutineEntry>>>((ref) {
  final selectedDate = ref.watch(selectedCalendarDateProvider);
  final allRoutinesRaw = ref.watch(allRoutinesRawProvider);

  final weekStart =
      selectedDate.subtract(Duration(days: selectedDate.weekday - 1));

  final activeRoutines = allRoutinesRaw
      .map((map) => Routine.fromMap(map))
      .where((r) => r.isActive)
      .toList();

  final result = <DateTime, List<RoutineEntry>>{};

  for (var i = 0; i < 7; i++) {
    final day = weekStart.add(Duration(days: i));
    final weekday = day.weekday;

    final dayRoutines = activeRoutines
        .where((r) => r.repeatDays.contains(weekday))
        .map((r) => RoutineEntry(
              id: r.id,
              name: r.name,
              startHour: r.startTime.hour,
              startMinute: r.startTime.minute,
              endHour: r.endTime.hour,
              endMinute: r.endTime.minute,
              colorIndex: r.colorIndex,
            ))
        .toList()
      ..sort((a, b) {
        final aMin = a.startHour * 60 + a.startMinute;
        final bMin = b.startHour * 60 + b.startMinute;
        return aMin.compareTo(bMin);
      });

    result[DateTime(day.year, day.month, day.day)] = dayRoutines;
  }

  return result;
});

/// 주간 뷰 헤더용 습관 완료율: 주의 각 날짜별 (완료수, 전체수)
final habitCompletionForWeekProvider =
    Provider<Map<DateTime, ({int completed, int total})>>((ref) {
  final selectedDate = ref.watch(selectedCalendarDateProvider);
  final allHabitsRaw = ref.watch(allHabitsRawProvider);
  final allHabitLogsRaw = ref.watch(allHabitLogsRawProvider);

  final weekStart =
      selectedDate.subtract(Duration(days: selectedDate.weekday - 1));

  final activeHabits = allHabitsRaw
      .map((m) => Habit.fromMap(m))
      .where((h) => h.isActive)
      .toList();

  final result = <DateTime, ({int completed, int total})>{};

  for (var i = 0; i < 7; i++) {
    final day = weekStart.add(Duration(days: i));
    final dayKey = DateTime(day.year, day.month, day.day);
    final scheduledHabits =
        activeHabits.where((h) => h.isScheduledFor(day)).toList();
    if (scheduledHabits.isEmpty) {
      result[dayKey] = (completed: 0, total: 0);
      continue;
    }

    final dateStr = AppDateUtils.toDateString(day);
    final completedIds = <String>{};
    for (final logMap in allHabitLogsRaw) {
      final log = HabitLog.fromMap(logMap);
      if (log.isCompleted &&
          AppDateUtils.toDateString(log.date) == dateStr) {
        completedIds.add(log.habitId);
      }
    }

    final completedCount = scheduledHabits
        .where((h) => completedIds.contains(h.id))
        .length;
    result[dayKey] =
        (completed: completedCount, total: scheduledHabits.length);
  }

  return result;
});
