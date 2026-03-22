// F1: 홈 대시보드 투두 + 습관 + 루틴 + 다가오는 일정 Riverpod Provider (Single Source of Truth)
// allTodosRawProvider, allHabitsRawProvider, allHabitLogsRawProvider, allRoutinesRawProvider,
// allEventsRawProvider에서 파생하여 CRUD 시 자동으로 홈 대시보드가 갱신된다.
// SRP 분리: 뷰 데이터 모델 → home_models.dart, D-Day/주간 → home_dday_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/data_store_providers.dart';
import '../../../core/providers/global_providers.dart';
import '../../../core/error/error_handler.dart';
import '../../../core/utils/date_utils.dart';
import '../../goal/services/progress_calculator.dart';
import '../../habit/providers/habit_provider.dart';
import '../../habit/services/streak_calculator.dart';
import '../../../shared/models/event.dart';
import '../../../shared/models/goal.dart';
import '../../../shared/models/goal_task.dart';
import '../../../shared/models/habit.dart';
import '../../../shared/models/habit_log.dart';
import '../../../shared/models/routine.dart';
import '../../../shared/models/sub_goal.dart';
import 'home_models.dart';

export 'home_models.dart';

// ─── Provider ────────────────────────────────────────────────────────────────

/// 오늘 투두 요약 Provider (동기)
/// allTodosRawProvider(Single Source of Truth)에서 파생하여
/// 투두 CRUD 시 todoDataVersionProvider 증가 → 이 Provider 자동 갱신
final todayTodosProvider = Provider<TodoSummary>((ref) {
  // Single Source of Truth: allTodosRawProvider에서 파생한다
  final allTodos = ref.watch(allTodosRawProvider);
  // 자정 경계 불일치 방지: 공유 todayDateProvider를 사용한다
  final today = ref.watch(todayDateProvider);
  final dateStr = AppDateUtils.toDateString(today);

  try {
    // 오늘 날짜의 투두만 필터링한다
    final docs = allTodos
        .where((d) =>
            (d['scheduled_date'] as String?)?.startsWith(dateStr) == true)
        .toList();

    // display_order로 정렬한다
    docs.sort((a, b) {
      final orderA = (a['display_order'] as num?)?.toInt() ?? 0;
      final orderB = (b['display_order'] as num?)?.toInt() ?? 0;
      return orderA.compareTo(orderB);
    });

    final total = docs.length;
    final completed = docs
        .where((d) => d['is_completed'] == true)
        .length;
    final rate = total > 0 ? (completed / total) * 100 : 0.0;

    // 미완료 우선 정렬 후 최대 5개
    final previewDocs = [
      ...docs.where((d) => d['is_completed'] != true),
      ...docs.where((d) => d['is_completed'] == true),
    ].take(5).toList();

    return TodoSummary(
      totalCount: total,
      completedCount: completed,
      completionRate: rate,
      previewItems: previewDocs.map((doc) {
        return TodoPreviewItem(
          id: doc['id']?.toString() ?? '',
          title: doc['title'] as String? ?? '',
          isCompleted: doc['is_completed'] as bool? ?? false,
        );
      }).toList(),
    );
  } catch (e, stack) {
    ErrorHandler.logServiceError('HomeProvider:todayTodos', e, stack);
    return TodoSummary.empty;
  }
});

/// 오늘 습관 요약 Provider (동기)
/// allHabitsRawProvider + allHabitLogsRawProvider(Single Source of Truth)에서 파생하여
/// 습관 체크/CRUD 시 자동 갱신된다
final todayHabitsProvider = Provider<HabitSummary>((ref) {
  // Single Source of Truth: 중앙 데이터 스토어에서 파생한다
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

/// 오늘의 루틴 요약 Provider (동기)
/// allRoutinesRawProvider(Single Source of Truth)에서 파생하여
/// 루틴 CRUD 시 routineDataVersionProvider 증가 → 이 Provider 자동 갱신
final todayRoutinesProvider = Provider<RoutineSummary>((ref) {
  // Single Source of Truth: 중앙 데이터 스토어에서 파생한다
  final allRoutines = ref.watch(allRoutinesRawProvider);
  // 자정 경계 불일치 방지: 공유 todayDateProvider를 사용한다
  final today = ref.watch(todayDateProvider);

  try {
    // 활성 루틴만 필터링한다
    final activeRoutines = allRoutines
        .where((r) => r['is_active'] == true || r['isActive'] == true)
        .toList();

    // 오늘 요일 (ISO 8601: 1=월~7=일)
    final todayWeekday = today.weekday;

    // 오늘 요일에 해당하는 루틴만 필터링한다
    final todayRoutines = activeRoutines.where((r) {
      final routine = Routine.fromMap(r);
      return routine.repeatDays.contains(todayWeekday);
    }).toList();

    if (todayRoutines.isEmpty) return RoutineSummary.empty;

    // Routine 객체로 변환 후 startTime 기준 시간순 정렬한다
    final routines = todayRoutines
        .map((r) => Routine.fromMap(r))
        .toList()
      ..sort((a, b) {
        final aMinutes = a.startTime.hour * 60 + a.startTime.minute;
        final bMinutes = b.startTime.hour * 60 + b.startTime.minute;
        return aMinutes.compareTo(bMinutes);
      });

    /// TimeOfDay를 "HH:mm" 형식 문자열로 변환한다
    String formatTime(TimeOfDay t) {
      final h = t.hour.toString().padLeft(2, '0');
      final m = t.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }

    return RoutineSummary(
      total: routines.length,
      routineItems: routines.map((routine) {
        return RoutinePreviewItem(
          id: routine.id,
          name: routine.name,
          startTime: formatTime(routine.startTime),
          endTime: formatTime(routine.endTime),
          colorIndex: routine.colorIndex,
        );
      }).toList(),
    );
  } catch (e, stack) {
    ErrorHandler.logServiceError('HomeProvider:todayRoutines', e, stack);
    return RoutineSummary.empty;
  }
});

/// 다가오는 일정 Provider (동기)
/// allEventsRawProvider + allTodosRawProvider(Single Source of Truth)에서 파생하여
/// 이벤트/투두 CRUD 시 자동 갱신된다.
/// 오늘의 아직 끝나지 않은 이벤트 + 미완료 투두를 시간순으로 최대 5개 반환한다.
final upcomingEventsProvider = Provider<List<UpcomingEventItem>>((ref) {
  // Single Source of Truth: 중앙 데이터 스토어에서 파생한다
  final allEventsRaw = ref.watch(allEventsRawProvider);
  final allTodosRaw = ref.watch(allTodosRawProvider);
  // 자정 경계 불일치 방지: 공유 todayDateProvider를 사용한다
  final today = ref.watch(todayDateProvider);
  // 시간 비교용 now는 별도로 캡처한다 (이벤트 종료 시간 비교에 필요)
  final now = DateTime.now();
  final dateStr = AppDateUtils.toDateString(today);

  try {
    final items = <_UpcomingRawItem>[];

    // ─── 1. eventsBox에서 오늘의 이벤트를 필터링한다 ───────────────────────
    for (final map in allEventsRaw) {
      final event = Event.fromMap(map);
      final eventDay = AppDateUtils.startOfDay(event.startDate);
      final eventEndDay = event.endDate != null
          ? AppDateUtils.startOfDay(event.endDate!)
          : eventDay;

      // 오늘 날짜에 해당하는 이벤트인지 확인한다
      final isToday = eventDay == today ||
          (eventDay.isBefore(today) && !eventEndDay.isBefore(today));
      if (!isToday) continue;

      // 종일 이벤트는 항상 포함한다
      if (event.allDay) {
        items.add(_UpcomingRawItem(
          id: event.id,
          title: event.title,
          timeLabel: '종일',
          colorIndex: event.colorIndex,
          isTodoEvent: false,
          sortMinutes: -1, // 종일 이벤트는 목록 최상단에 배치한다
        ));
        continue;
      }

      // 시간 있는 이벤트: 아직 끝나지 않은 것만 포함한다
      final endDateTime = event.endDate ?? event.startDate;
      if (endDateTime.isBefore(now) && eventDay == today) continue;

      final startH = event.startDate.hour.toString().padLeft(2, '0');
      final startM = event.startDate.minute.toString().padLeft(2, '0');
      final endH = endDateTime.hour.toString().padLeft(2, '0');
      final endM = endDateTime.minute.toString().padLeft(2, '0');
      final timeLabel = '$startH:$startM ~ $endH:$endM';

      items.add(_UpcomingRawItem(
        id: event.id,
        title: event.title,
        timeLabel: timeLabel,
        colorIndex: event.colorIndex,
        isTodoEvent: false,
        sortMinutes: event.startDate.hour * 60 + event.startDate.minute,
      ));
    }

    // ─── 2. todosBox에서 오늘의 미완료 투두를 필터링한다 ──────────────────
    final todayTodos = allTodosRaw.where((d) {
      final scheduled = d['scheduled_date'] as String?;
      if (scheduled == null) return false;
      final datePart = scheduled.length >= 10
          ? scheduled.substring(0, 10)
          : scheduled;
      return datePart == dateStr && d['is_completed'] != true;
    });

    for (final map in todayTodos) {
      final id = map['id']?.toString() ?? '';
      final title = map['title'] as String? ?? '';
      final colorStr = map['color'] as String?;
      final colorIdx = colorStr != null ? (int.tryParse(colorStr) ?? 0) : 0;

      // start_time 파싱: "HH:mm:ss" 또는 "HH:mm" 형식
      final startRaw = map['start_time'] as String?;
      final endRaw = map['end_time'] as String?;

      if (startRaw != null) {
        // 시간이 있는 투두: 아직 끝나지 않은 것만 포함한다
        final startParts = startRaw.split(':');
        final startH = int.tryParse(startParts[0]) ?? 0;
        final startM = startParts.length > 1 ? (int.tryParse(startParts[1]) ?? 0) : 0;

        // 종료 시간 계산 (없으면 시작 시간 기준)
        int endH = startH;
        int endM = startM;
        if (endRaw != null) {
          final endParts = endRaw.split(':');
          endH = int.tryParse(endParts[0]) ?? startH;
          endM = endParts.length > 1 ? (int.tryParse(endParts[1]) ?? 0) : 0;
        }

        final endMinutes = endH * 60 + endM;
        final nowMinutes = now.hour * 60 + now.minute;
        if (endMinutes < nowMinutes && endRaw != null) continue;

        final sH = startH.toString().padLeft(2, '0');
        final sM = startM.toString().padLeft(2, '0');
        final eH = endH.toString().padLeft(2, '0');
        final eM = endM.toString().padLeft(2, '0');
        final timeLabel = endRaw != null ? '$sH:$sM ~ $eH:$eM' : '$sH:$sM';

        items.add(_UpcomingRawItem(
          id: id,
          title: title,
          timeLabel: timeLabel,
          colorIndex: colorIdx,
          isTodoEvent: true,
          sortMinutes: startH * 60 + startM,
        ));
      } else {
        // 시간이 없는 투두: 종일 항목으로 표시한다
        items.add(_UpcomingRawItem(
          id: id,
          title: title,
          timeLabel: '종일',
          colorIndex: colorIdx,
          isTodoEvent: true,
          sortMinutes: -1,
        ));
      }
    }

    // ─── 3. 시간순 정렬 후 최대 5개 반환한다 ─────────────────────────────
    items.sort((a, b) => a.sortMinutes.compareTo(b.sortMinutes));

    return items.take(5).map((raw) {
      return UpcomingEventItem(
        id: raw.id,
        title: raw.title,
        timeLabel: raw.timeLabel,
        colorIndex: raw.colorIndex,
        isTodoEvent: raw.isTodoEvent,
      );
    }).toList();
  } catch (e, stack) {
    ErrorHandler.logServiceError('HomeProvider:upcomingEvents', e, stack);
    return const [];
  }
});

// ─── 목표 통계 Provider ───────────────────────────────────────────────────

/// 홈 대시보드용 목표 통계 Provider
/// 현재 연도의 전체 목표에서 달성률과 평균 진행률을 계산한다
/// ProgressCalculator 순수 함수를 사용한다
final todayGoalStatsProvider = Provider<GoalSummary>((ref) {
  final allGoalsRaw = ref.watch(allGoalsRawProvider);
  final allSubGoalsRaw = ref.watch(allSubGoalsRawProvider);
  final allGoalTasksRaw = ref.watch(allGoalTasksRawProvider);

  if (allGoalsRaw.isEmpty) return GoalSummary.empty;

  final goals = allGoalsRaw.map((m) => Goal.fromMap(m)).toList();
  final subGoals = allSubGoalsRaw.map((m) => SubGoal.fromMap(m)).toList();
  final tasks = allGoalTasksRaw.map((m) => GoalTask.fromMap(m)).toList();

  // 현재 연도 목표만 필터링한다 — 공유 todayDateProvider를 사용한다
  final currentYear = ref.watch(todayDateProvider).year;
  final yearGoals = goals.where((g) => g.year == currentYear).toList();

  if (yearGoals.isEmpty) return GoalSummary.empty;

  final stats = ProgressCalculator.calcStats(yearGoals, subGoals, tasks);

  return GoalSummary(
    totalCount: stats.totalGoalCount,
    completedCount: yearGoals.where((g) => g.isCompleted).length,
    achievementRate: stats.achievementRate,
    avgProgress: stats.avgProgress,
  );
});

/// 다가오는 일정 정렬용 내부 모델
/// 정렬 키(sortMinutes)를 포함하여 시간순 정렬을 수행한 뒤 UpcomingEventItem으로 변환한다
class _UpcomingRawItem {
  final String id;
  final String title;
  final String timeLabel;
  final int colorIndex;
  final bool isTodoEvent;
  /// 정렬 기준 (분 단위). 종일 이벤트는 -1로 최상단 배치한다
  final int sortMinutes;

  const _UpcomingRawItem({
    required this.id,
    required this.title,
    required this.timeLabel,
    required this.colorIndex,
    required this.isTodoEvent,
    required this.sortMinutes,
  });
}
