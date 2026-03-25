// F3: 루틴/타이머/습관 → 타임라인 통합 Provider
// 루틴, 타이머 집중 세션, 습관을 Todo 형태로 변환하여
// 타임라인 레이아웃에서 통합 표시할 수 있게 한다.
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/data_store_providers.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/models/habit.dart';
import '../../../shared/models/habit_log.dart';
import '../../../shared/models/routine.dart';
import '../../../shared/models/todo.dart';
import '../../timer/models/timer_log.dart';
import 'todo_state_providers.dart';

// ─── 루틴 → 타임라인 통합 Provider ──────────────────────────────────────────

/// 투두 탭의 선택된 날짜에 해당하는 루틴을 Todo 형태로 변환한다
/// 타임라인 레이아웃과 호환되도록 id 접두사 'routine_'으로 구별한다
final routinesForTimelineProvider = Provider<List<Todo>>((ref) {
  final selectedDate = ref.watch(selectedDateProvider);
  final allRoutinesRaw = ref.watch(allRoutinesRawProvider);
  final weekday = selectedDate.weekday;

  // 활성 루틴 중 해당 요일에 예정된 루틴만 필터링한다
  final activeRoutines = allRoutinesRaw
      .map((map) => Routine.fromMap(map))
      .where((r) => r.isActive && r.repeatDays.contains(weekday))
      .toList();

  // Routine → Todo 변환 (타임라인 레이아웃 호환)
  return activeRoutines.map((routine) {
    return Todo(
      id: 'routine_${routine.id}',
      title: routine.name,
      date: selectedDate,
      startTime: routine.startTime,
      endTime: routine.endTime,
      isCompleted: false,
      color: routine.colorIndex.toString(),
      createdAt: routine.createdAt,
    );
  }).toList();
});

// ─── 타이머 세션 → 타임라인 통합 Provider ───────────────────────────────────

/// 투두 탭의 선택된 날짜에 해당하는 타이머 집중 세션을 Todo 형태로 변환한다
/// id 접두사 'timer_'으로 타이머 출처 항목을 구별한다
final timerLogsForTimelineProvider = Provider<List<Todo>>((ref) {
  final selectedDate = ref.watch(selectedDateProvider);
  final allTimerLogsRaw = ref.watch(allTimerLogsRawProvider);
  final dateStr = AppDateUtils.toDateString(selectedDate);

  final todos = <Todo>[];
  for (final logMap in allTimerLogsRaw) {
    final log = TimerLog.fromMap(logMap);
    // 집중 세션만 타임라인에 표시한다
    if (log.type != TimerSessionType.focus) continue;
    // 선택된 날짜의 로그만 필터링한다
    if (AppDateUtils.toDateString(log.startTime) != dateStr) continue;

    final durationMinutes = log.durationSeconds ~/ 60;
    final endTotalMinutes =
        log.startTime.hour * 60 + log.startTime.minute + durationMinutes;
    // 총 분을 먼저 클램프한 뒤 시/분을 산출한다 (24시간 초과 방지)
    final clampedMinutes = endTotalMinutes.clamp(0, 24 * 60 - 1);
    final endHour = clampedMinutes ~/ 60;
    final endMinute = clampedMinutes % 60;

    todos.add(Todo(
      id: 'timer_${log.id}',
      title: log.todoTitle ?? '집중 세션',
      date: selectedDate,
      startTime: TimeOfDay(
        hour: log.startTime.hour,
        minute: log.startTime.minute,
      ),
      endTime: TimeOfDay(hour: endHour, minute: endMinute),
      isCompleted: false,
      color: '3', // 초록 계열 — 타이머 세션에 적합
      createdAt: log.createdAt,
    ));
  }

  return todos;
});

// ─── 습관 → 투두 탭 통합 Provider ────────────────────────────────────────────

/// 투두 탭의 선택된 날짜에 해당하는 습관 체크리스트 Provider
/// 캘린더 DailyView의 habitsForDayProvider와 동일한 로직이지만
/// selectedDateProvider(투두 탭 날짜)를 기준으로 한다
final habitsForTodoDateProvider =
    Provider<List<({Habit habit, bool isCompleted})>>((ref) {
  final selectedDate = ref.watch(selectedDateProvider);
  final allHabitsRaw = ref.watch(allHabitsRawProvider);
  final allHabitLogsRaw = ref.watch(allHabitLogsRawProvider);

  // 활성 습관 중 해당 날짜에 예정된 것만 필터링한다
  final activeHabits = allHabitsRaw
      .map((m) => Habit.fromMap(m))
      .where((h) => h.isActive && h.isScheduledFor(selectedDate))
      .toList();

  if (activeHabits.isEmpty) return const [];

  // 해당 날짜의 완료된 습관 ID 집합을 구한다
  final dateStr = AppDateUtils.toDateString(selectedDate);
  final completedHabitIds = <String>{};
  for (final logMap in allHabitLogsRaw) {
    final log = HabitLog.fromMap(logMap);
    if (log.isCompleted && AppDateUtils.toDateString(log.date) == dateStr) {
      completedHabitIds.add(log.habitId);
    }
  }

  return activeHabits
      .map((h) => (habit: h, isCompleted: completedHabitIds.contains(h.id)))
      .toList();
});
