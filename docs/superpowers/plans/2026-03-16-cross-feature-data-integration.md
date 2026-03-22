# Cross-Feature Data Integration Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Connect all features (Routine, Habit, Goal, Timer) into the Calendar and Home screens so that data flows seamlessly between tabs.

**Architecture:** Each integration adds computed providers that derive from existing raw data providers (Single Source of Truth pattern). New view models (CalendarEvent, RoutineEntry) are produced by mapping from domain models. UI widgets watch these providers to render blocks, dots, and cards. No schema changes — all data already exists in Hive.

**Tech Stack:** Flutter 3.29, Dart, Riverpod 2.6, Hive (local-first), existing CalendarEvent/RoutineEntry view models

---

## File Structure

| File | Responsibility | Created/Modified |
|---|---|---|
| `lib/features/calendar/providers/event_provider.dart` | Add `routinesForWeekProvider`, `habitsForDayProvider`, `habitsForMonthProvider`, `timerLogsForDayProvider` | Modified |
| `lib/core/calendar_sync/calendar_sync_provider.dart` | Extend merged providers to include routines, habits, timer data | Modified |
| `lib/features/calendar/presentation/widgets/weekly_view.dart` | Render routine blocks in weekly day columns | Modified |
| `lib/features/calendar/presentation/widgets/weekly_view_widgets.dart` | Add `WeeklyRoutineBlock` widget | Modified |
| `lib/features/calendar/presentation/widgets/monthly_view.dart` | Add habit achievement dots alongside event dots | Modified |
| `lib/features/calendar/presentation/widgets/daily_view.dart` | Add habit checklist section + timer session blocks | Modified |
| `lib/features/home/presentation/widgets/goal_summary_card.dart` | New GoalSummaryCard widget for home dashboard | Created |
| `lib/features/home/presentation/home_screen.dart` | Insert GoalSummaryCard into widget list | Modified |
| `lib/features/home/providers/home_provider.dart` | Add `todayGoalStatsProvider` | Modified |
| `lib/features/home/providers/home_models.dart` | Add `GoalSummary` model | Modified |
| `lib/features/goal/providers/goal_provider.dart` | Add `goalTasksAsTodosProvider` for GoalTask→Todo conversion | Modified |

---

## Chunk 1: Routine → Calendar Weekly View + Monthly View Dots

### Task 1: Add `routinesForWeekProvider` to event_provider.dart

This provider fetches active routines and filters by each day's weekday for the current week. The weekly view needs routine data for all 7 days simultaneously.

**Files:**
- Modify: `lib/features/calendar/providers/event_provider.dart` (after `routinesForDayProvider`, ~line 484)

- [ ] **Step 1: Add `routinesForWeekProvider`**

Insert after `routinesForDayProvider` at the end of the file:

```dart
/// 주간 뷰용 루틴 데이터: 주의 각 날짜에 해당하는 RoutineEntry 목록을 반환한다
/// 키: DateTime (해당 날짜), 값: List<RoutineEntry> (해당 요일의 활성 루틴)
/// selectedCalendarDateProvider의 주 기준으로 7일간 데이터를 생성한다
final routinesForWeekProvider =
    Provider<Map<DateTime, List<RoutineEntry>>>((ref) {
  final selectedDate = ref.watch(selectedCalendarDateProvider);
  final allRoutinesRaw = ref.watch(allRoutinesRawProvider);

  // 주 시작일(월요일) 계산
  final weekStart =
      selectedDate.subtract(Duration(days: selectedDate.weekday - 1));

  // 활성 루틴만 파싱한다
  final activeRoutines = allRoutinesRaw
      .map((map) => Routine.fromMap(map))
      .where((r) => r.isActive)
      .toList();

  final result = <DateTime, List<RoutineEntry>>{};

  for (var i = 0; i < 7; i++) {
    final day = weekStart.add(Duration(days: i));
    // ISO 8601 weekday: 1=월 ~ 7=일
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

    result[day] = dayRoutines;
  }

  return result;
});
```

- [ ] **Step 2: Add required import**

At the top of `event_provider.dart`, ensure `Routine` model import exists:

```dart
import '../../../shared/models/routine.dart';
```

Also ensure `allRoutinesRawProvider` is imported (it should be through `data_store_providers.dart`).

- [ ] **Step 3: Run `flutter analyze` to verify no issues**

Run: `cd /Users/kimtaekyu/Documents/Develop_Fold/03_ToDoList_Web && flutter analyze lib/features/calendar/providers/event_provider.dart`
Expected: No issues found

- [ ] **Step 4: Commit**

```bash
git add lib/features/calendar/providers/event_provider.dart
git commit -m "feat: add routinesForWeekProvider for weekly view routine integration"
```

---

### Task 2: Add `WeeklyRoutineBlock` widget to weekly_view_widgets.dart

A translucent routine block (similar to `DailyView._buildRoutineBlock`) that renders in weekly day columns alongside event blocks.

**Files:**
- Modify: `lib/features/calendar/presentation/widgets/weekly_view_widgets.dart` (add after `WeeklyTimeColumn`, ~line 139)

- [ ] **Step 1: Add `WeeklyRoutineBlock` widget**

Insert before the `_WeeklyAnimatedStrikethrough` class:

```dart
/// 주간 뷰 루틴 블록 위젯
/// 루틴의 시간 범위에 따라 Positioned로 배치된다
/// 이벤트 블록과 겹치지 않도록 오른쪽 영역에 표시한다
class WeeklyRoutineBlock extends StatelessWidget {
  final RoutineEntry routine;

  const WeeklyRoutineBlock({super.key, required this.routine});

  @override
  Widget build(BuildContext context) {
    final startMin = routine.startHour * 60 + routine.startMinute;
    final endMin = routine.endHour * 60 + routine.endMinute;
    final duration = endMin - startMin;

    final top = startMin * (kWeeklyHourHeight / 60);
    final height = (duration * kWeeklyHourHeight / 60)
        .clamp(AppLayout.weeklyEventMinHeight, double.infinity);
    final routineColor = ColorTokens.eventColor(routine.colorIndex);

    return Positioned(
      top: top,
      left: AppSpacing.xxs,
      right: AppSpacing.xxs,
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          // 루틴은 이벤트보다 연한 배경으로 구분한다
          color: routineColor.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border(
            left: BorderSide(
              color: routineColor.withValues(alpha: 0.6),
              width: AppLayout.borderThick,
            ),
          ),
        ),
        child: Text(
          routine.name,
          style: AppTypography.captionLg.copyWith(
            color: context.themeColors.textPrimaryWithAlpha(0.7),
          ),
          maxLines: height > AppLayout.weeklyEventMultiLineThreshold ? 2 : 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Run `flutter analyze`**

Run: `cd /Users/kimtaekyu/Documents/Develop_Fold/03_ToDoList_Web && flutter analyze lib/features/calendar/presentation/widgets/weekly_view_widgets.dart`
Expected: No issues found

- [ ] **Step 3: Commit**

```bash
git add lib/features/calendar/presentation/widgets/weekly_view_widgets.dart
git commit -m "feat: add WeeklyRoutineBlock widget for routine display in weekly view"
```

---

### Task 3: Integrate routine blocks into WeeklyView

Modify `weekly_view.dart` to watch `routinesForWeekProvider` and render `WeeklyRoutineBlock` widgets in each day column alongside existing event blocks.

**Files:**
- Modify: `lib/features/calendar/presentation/widgets/weekly_view.dart`

- [ ] **Step 1: Add routine provider watch and render routine blocks in `_DayColumn`**

In the `build()` method of `WeeklyView` (around line 96), add the routine data watch:

```dart
final routinesByDay = ref.watch(routinesForWeekProvider);
```

Pass `routinesByDay` to `_DayColumn` by adding a new parameter. In `_DayColumn`'s builder, add `WeeklyRoutineBlock` widgets to the Stack alongside event blocks.

The `_DayColumn` widget (around line 172) needs to accept a `routines` parameter:

```dart
class _DayColumn extends StatelessWidget {
  final DateTime date;
  final List<CalendarEvent> events;
  final List<RoutineEntry> routines;  // 추가
  final bool isToday;
  final Function(CalendarEvent) onEventTap;
```

In the `_DayColumn.build()` Stack children, add routine blocks before event blocks (so events render on top):

```dart
// 루틴 블록 (이벤트 아래 레이어에 반투명 배경으로 표시)
...routines.map((routine) => WeeklyRoutineBlock(routine: routine)),
// 이벤트 블록 (기존 코드)
...dayEvents.map((event) => WeeklyEventBlock(...)),
```

In the `WeeklyView.build()` where `_DayColumn` is created (around line 133-148), pass the routines for that specific day:

```dart
_DayColumn(
  date: dayDate,
  events: dayEvents,
  routines: routinesByDay[DateTime(dayDate.year, dayDate.month, dayDate.day)] ?? const [],
  isToday: /* existing */,
  onEventTap: /* existing */,
)
```

- [ ] **Step 2: Run `flutter analyze`**

Run: `cd /Users/kimtaekyu/Documents/Develop_Fold/03_ToDoList_Web && flutter analyze lib/features/calendar/presentation/widgets/weekly_view.dart`
Expected: No issues found

- [ ] **Step 3: Commit**

```bash
git add lib/features/calendar/presentation/widgets/weekly_view.dart
git commit -m "feat: render routine blocks in weekly view day columns"
```

---

### Task 4: Add routine dates to `mergedEventsByDateMapProvider` for monthly view dots

Routine days should show dots in the monthly view. Modify `calendar_sync_provider.dart` to include routine dates in the date map.

**Files:**
- Modify: `lib/core/calendar_sync/calendar_sync_provider.dart` (at `mergedEventsByDateMapProvider`, ~line 174)

- [ ] **Step 1: Extend `mergedEventsByDateMapProvider` to include routine dates**

Add routine date calculation inside `mergedEventsByDateMapProvider`:

```dart
final mergedEventsByDateMapProvider = Provider<Map<String, bool>>((ref) {
  // 앱 이벤트 날짜 맵 (기존 provider 재사용)
  final appMap = ref.watch(eventsByDateMapProvider);
  // Google 이벤트 목록
  final googleEventsAsync = ref.watch(googleCalendarEventsProvider);
  final googleEvents = googleEventsAsync.valueOrNull ?? const [];
  // 활성 루틴 목록
  final allRoutinesRaw = ref.watch(allRoutinesRawProvider);
  final focusedMonth = ref.watch(focusedCalendarMonthProvider);

  // 앱 이벤트 맵을 기반으로 Google 이벤트 날짜를 추가한다
  final merged = Map<String, bool>.from(appMap);
  for (final event in googleEvents) {
    final key = AppDateUtils.toDateString(event.startDate);
    merged[key] = true;
  }

  // 활성 루틴의 해당 월 날짜를 추가한다
  final activeRoutines = allRoutinesRaw
      .map((map) => Routine.fromMap(map))
      .where((r) => r.isActive)
      .toList();

  if (activeRoutines.isNotEmpty) {
    // 포커스된 월의 모든 날짜를 순회하며 루틴 요일과 매칭한다
    final firstDay = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final lastDay = DateTime(focusedMonth.year, focusedMonth.month + 1, 0);

    for (var day = firstDay;
        !day.isAfter(lastDay);
        day = day.add(const Duration(days: 1))) {
      final weekday = day.weekday;
      final hasRoutine =
          activeRoutines.any((r) => r.repeatDays.contains(weekday));
      if (hasRoutine) {
        final key = AppDateUtils.toDateString(day);
        merged[key] = true;
      }
    }
  }

  return merged;
});
```

- [ ] **Step 2: Add required imports at top of file**

```dart
import '../../shared/models/routine.dart';
import '../providers/global_providers.dart';  // allRoutinesRawProvider가 여기에 없으면
```

Check which file exports `allRoutinesRawProvider` — it's in `data_store_providers.dart`:

```dart
import '../../core/providers/data_store_providers.dart';
```

Also need `focusedCalendarMonthProvider`:

```dart
import '../../features/calendar/providers/calendar_provider.dart';
```

Verify these imports already exist in the file (they likely do based on existing usage).

- [ ] **Step 3: Run `flutter analyze`**

Run: `cd /Users/kimtaekyu/Documents/Develop_Fold/03_ToDoList_Web && flutter analyze lib/core/calendar_sync/calendar_sync_provider.dart`
Expected: No issues found

- [ ] **Step 4: Commit**

```bash
git add lib/core/calendar_sync/calendar_sync_provider.dart
git commit -m "feat: include routine dates in monthly view dot indicators"
```

---

## Chunk 2: Goal → Home Summary Card

### Task 5: Add `GoalSummary` model to home_models.dart

**Files:**
- Modify: `lib/features/home/providers/home_models.dart` (add after `RoutinePreviewItem`, ~line 127)

- [ ] **Step 1: Add `GoalSummary` model class**

```dart
/// 오늘의 목표 요약 (현재 연도/기간 기준)
class GoalSummary {
  /// 전체 목표 수
  final int totalCount;

  /// 완료된 목표 수
  final int completedCount;

  /// 달성률 (0.0 ~ 1.0)
  final double achievementRate;

  /// 평균 진행률 (0.0 ~ 1.0)
  final double avgProgress;

  const GoalSummary({
    required this.totalCount,
    required this.completedCount,
    required this.achievementRate,
    required this.avgProgress,
  });

  static const empty = GoalSummary(
    totalCount: 0,
    completedCount: 0,
    achievementRate: 0,
    avgProgress: 0,
  );
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/home/providers/home_models.dart
git commit -m "feat: add GoalSummary model for home dashboard goal card"
```

---

### Task 6: Add `todayGoalStatsProvider` to home_provider.dart

This provider reads goal data from the Single Source of Truth and computes a `GoalSummary` for the home screen.

**Files:**
- Modify: `lib/features/home/providers/home_provider.dart` (add after `upcomingEventsProvider`)

- [ ] **Step 1: Add `todayGoalStatsProvider`**

```dart
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

  // 현재 연도 목표만 필터링한다
  final currentYear = DateTime.now().year;
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
```

- [ ] **Step 2: Add required imports**

```dart
import '../../../shared/models/goal.dart';
import '../../../shared/models/sub_goal.dart';
import '../../../shared/models/goal_task.dart';
import '../../goal/services/progress_calculator.dart';
```

Also verify `allGoalsRawProvider`, `allSubGoalsRawProvider`, `allGoalTasksRawProvider` are accessible (from `data_store_providers.dart`).

- [ ] **Step 3: Run `flutter analyze`**

Run: `cd /Users/kimtaekyu/Documents/Develop_Fold/03_ToDoList_Web && flutter analyze lib/features/home/providers/home_provider.dart`
Expected: No issues found

- [ ] **Step 4: Commit**

```bash
git add lib/features/home/providers/home_provider.dart
git commit -m "feat: add todayGoalStatsProvider for home dashboard goal summary"
```

---

### Task 7: Create `GoalSummaryCard` widget

A new summary card for the home screen showing goal achievement rate and progress. Follows the same design pattern as `TodoSummaryCard` and `HabitSummaryCard` (donut chart + text).

**Files:**
- Create: `lib/features/home/presentation/widgets/goal_summary_card.dart`

- [ ] **Step 1: Create `GoalSummaryCard` widget**

```dart
// F1 위젯: GoalSummaryCard — 홈 대시보드 목표 요약 카드
// 현재 연도의 목표 달성률과 평균 진행률을 도넛 차트로 표시한다.
// TodoSummaryCard와 동일한 레이아웃 패턴을 따른다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../shared/widgets/donut_chart.dart';
import '../../providers/home_provider.dart';

/// 홈 대시보드 목표 요약 카드
/// 현재 연도의 목표 달성률을 도넛 차트로, 평균 진행률을 텍스트로 표시한다
/// 탭 시 목표 화면으로 이동한다
class GoalSummaryCard extends ConsumerWidget {
  const GoalSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(todayGoalStatsProvider);

    return GestureDetector(
      onTap: () => context.go('/goal'),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: context.themeColors.cardSurface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더: 타이틀 + "전체 보기" 링크
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '목표',
                  style: AppTypography.headingSm.copyWith(
                    color: context.themeColors.textPrimary,
                  ),
                ),
                Text(
                  '전체 보기',
                  style: AppTypography.captionLg.copyWith(
                    color: context.themeColors.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            if (summary.totalCount == 0)
              // 빈 상태: 목표 추가 유도
              _buildEmptyState(context)
            else
              // 데이터 있을 때: 도넛 차트 + 통계 텍스트
              _buildContent(context, summary),
          ],
        ),
      ),
    );
  }

  /// 목표가 없을 때 빈 상태 표시
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Column(
          children: [
            Icon(
              Icons.flag_outlined,
              size: AppLayout.iconXl,
              color: context.themeColors.textPrimaryWithAlpha(0.3),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '목표를 추가해보세요',
              style: AppTypography.bodyMd.copyWith(
                color: context.themeColors.textPrimaryWithAlpha(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 도넛 차트 + 통계 콘텐츠
  Widget _buildContent(BuildContext context, dynamic summary) {
    return Row(
      children: [
        // 도넛 차트: 달성률 표시
        DonutChart(
          percentage: summary.achievementRate,
          size: AppLayout.donutChartSize,
          strokeWidth: AppLayout.donutChartStrokeWidth,
          color: context.themeColors.accent,
          backgroundColor:
              context.themeColors.textPrimaryWithAlpha(0.08),
          child: Text(
            '${(summary.achievementRate * 100).round()}%',
            style: AppTypography.headingSm.copyWith(
              color: context.themeColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        // 텍스트 통계
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${summary.completedCount}/${summary.totalCount} 달성',
                style: AppTypography.bodyLg.copyWith(
                  color: context.themeColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '평균 진행률 ${(summary.avgProgress * 100).round()}%',
                style: AppTypography.bodySm.copyWith(
                  color: context.themeColors.textPrimaryWithAlpha(0.6),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              // 평균 진행률 프로그레스 바
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.xs),
                child: LinearProgressIndicator(
                  value: summary.avgProgress,
                  backgroundColor:
                      context.themeColors.textPrimaryWithAlpha(0.08),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    context.themeColors.accent,
                  ),
                  minHeight: AppLayout.progressBarHeight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Verify `DonutChart` widget and `AppLayout` constants exist**

Check that `DonutChart`, `AppLayout.donutChartSize`, `AppLayout.donutChartStrokeWidth`, `AppLayout.progressBarHeight` exist. If `progressBarHeight` doesn't exist, use a hardcoded `4.0` wrapped in an AppLayout constant or use an existing token.

Run: `grep -r 'donutChartSize\|progressBarHeight' lib/core/theme/layout_tokens.dart`

- [ ] **Step 3: Run `flutter analyze`**

Run: `cd /Users/kimtaekyu/Documents/Develop_Fold/03_ToDoList_Web && flutter analyze lib/features/home/presentation/widgets/goal_summary_card.dart`
Expected: No issues found

- [ ] **Step 4: Commit**

```bash
git add lib/features/home/presentation/widgets/goal_summary_card.dart
git commit -m "feat: create GoalSummaryCard widget for home dashboard"
```

---

### Task 8: Insert `GoalSummaryCard` into home screen

Add the card between `HabitSummaryCard` and `TimerSummaryCard` in the home screen layout.

**Files:**
- Modify: `lib/features/home/presentation/home_screen.dart`

- [ ] **Step 1: Import and add GoalSummaryCard**

Add import:
```dart
import 'widgets/goal_summary_card.dart';
```

In the `CustomScrollView` children list (around line 139-203), insert `GoalSummaryCard` after `HabitSummaryCard` (staggered index 3) and before `TimerSummaryCard`:

```dart
// 기존: HabitSummaryCard (index 3)
_staggeredCard(3, const HabitSummaryCard()),
// 추가: GoalSummaryCard (index 4)
_staggeredCard(4, const GoalSummaryCard()),
// 기존: TimerSummaryCard (index 5, 기존 4에서 변경)
_staggeredCard(5, const TimerSummaryCard()),
// 기존: RoutineSummaryCard (index 6, 기존 5에서 변경)
_staggeredCard(6, const RoutineSummaryCard()),
// 기존: TodaySummarySection (index 7, 기존 6에서 변경)
_staggeredCard(7, const TodaySummarySection()),
```

- [ ] **Step 2: Run `flutter analyze`**

Run: `cd /Users/kimtaekyu/Documents/Develop_Fold/03_ToDoList_Web && flutter analyze lib/features/home/presentation/home_screen.dart`
Expected: No issues found

- [ ] **Step 3: Commit**

```bash
git add lib/features/home/presentation/home_screen.dart
git commit -m "feat: add GoalSummaryCard to home dashboard between habits and timer"
```

---

## Chunk 3: Habit → Calendar Views (Monthly Dots + Daily Checklist + Weekly Headers)

### Task 9: Add habit achievement data to monthly view dots

Extend `mergedEventsByDateMapProvider` to include dates where habits were completed (dots in monthly view).

**Files:**
- Modify: `lib/core/calendar_sync/calendar_sync_provider.dart` (at `mergedEventsByDateMapProvider`)

- [ ] **Step 1: Add habit log dates to `mergedEventsByDateMapProvider`**

Inside the same `mergedEventsByDateMapProvider` (after the routine section added in Task 4), add:

```dart
  // 습관 로그(완료된 날짜)를 추가한다
  final allHabitLogsRaw = ref.watch(allHabitLogsRawProvider);
  for (final logMap in allHabitLogsRaw) {
    final log = HabitLog.fromMap(logMap);
    if (log.isCompleted) {
      final logDateStr = AppDateUtils.toDateString(log.date);
      // 포커스된 월에 해당하는 로그만 추가한다
      if (log.date.year == focusedMonth.year &&
          log.date.month == focusedMonth.month) {
        merged[logDateStr] = true;
      }
    }
  }
```

- [ ] **Step 2: Add required imports**

```dart
import '../../shared/models/habit_log.dart';
```

Verify `allHabitLogsRawProvider` is accessible.

- [ ] **Step 3: Run `flutter analyze`**

Run: `cd /Users/kimtaekyu/Documents/Develop_Fold/03_ToDoList_Web && flutter analyze lib/core/calendar_sync/calendar_sync_provider.dart`
Expected: No issues found

- [ ] **Step 4: Commit**

```bash
git add lib/core/calendar_sync/calendar_sync_provider.dart
git commit -m "feat: include habit completion dates in monthly view dot indicators"
```

---

### Task 10: Add `habitsForDayProvider` to event_provider.dart

For the daily view, we need today's scheduled habits with their completion status.

**Files:**
- Modify: `lib/features/calendar/providers/event_provider.dart`

- [ ] **Step 1: Add `habitsForDayProvider`**

Insert after `routinesForWeekProvider`:

```dart
/// 일간 뷰용 습관 데이터: 선택된 날짜에 예정된 습관 목록과 완료 상태를 반환한다
/// 반환 타입: List<({Habit habit, bool isCompleted})>
final habitsForDayProvider =
    Provider<List<({Habit habit, bool isCompleted})>>((ref) {
  final selectedDate = ref.watch(selectedCalendarDateProvider);
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
```

- [ ] **Step 2: Add required imports**

```dart
import '../../../shared/models/habit.dart';
import '../../../shared/models/habit_log.dart';
```

Verify `allHabitsRawProvider`, `allHabitLogsRawProvider` are accessible.

- [ ] **Step 3: Run `flutter analyze`**

Run: `cd /Users/kimtaekyu/Documents/Develop_Fold/03_ToDoList_Web && flutter analyze lib/features/calendar/providers/event_provider.dart`
Expected: No issues found

- [ ] **Step 4: Commit**

```bash
git add lib/features/calendar/providers/event_provider.dart
git commit -m "feat: add habitsForDayProvider for daily view habit checklist"
```

---

### Task 11: Add habit checklist to DailyView

Add a habit checklist section in the daily view's all-day area (above the timeline), showing today's scheduled habits with check/uncheck toggles.

**Files:**
- Modify: `lib/features/calendar/presentation/widgets/daily_view.dart`

- [ ] **Step 1: Watch `habitsForDayProvider` and add habit section**

In the `build()` method (around line 85), add:

```dart
final habitsForDay = ref.watch(habitsForDayProvider);
```

In the all-day section (the top area before the scrollable timeline, around lines 98-110), add a habit checklist after the all-day event cards:

```dart
// 습관 체크리스트 (일간 뷰 상단 종일 영역에 표시)
if (habitsForDay.isNotEmpty) ...[
  Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.xs,
    ),
    child: Text(
      '오늘의 습관',
      style: AppTypography.captionLg.copyWith(
        color: context.themeColors.textPrimaryWithAlpha(0.6),
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
  ...habitsForDay.map((entry) => _buildHabitCheckItem(
    context, ref, entry.habit, entry.isCompleted,
  )),
  const Divider(height: 1),
],
```

- [ ] **Step 2: Add `_buildHabitCheckItem` helper method**

Add as a method in the `_DailyViewState` class:

```dart
/// 습관 체크 아이템 위젯 (일간 뷰 종일 영역)
Widget _buildHabitCheckItem(
  BuildContext context,
  WidgetRef ref,
  Habit habit,
  bool isCompleted,
) {
  return Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.xxs,
    ),
    child: Row(
      children: [
        // 체크박스
        GestureDetector(
          onTap: () {
            ref.read(toggleHabitProvider)(habit.id);
          },
          child: AnimatedContainer(
            duration: AppAnimation.normal,
            width: AppLayout.checkboxSize,
            height: AppLayout.checkboxSize,
            decoration: BoxDecoration(
              color: isCompleted
                  ? context.themeColors.accent
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.xs),
              border: Border.all(
                color: isCompleted
                    ? context.themeColors.accent
                    : context.themeColors.textPrimaryWithAlpha(0.3),
                width: AppLayout.borderDefault,
              ),
            ),
            child: isCompleted
                ? Icon(
                    Icons.check,
                    size: AppLayout.iconXs,
                    color: context.themeColors.cardSurface,
                  )
                : null,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        // 습관 아이콘
        if (habit.icon != null)
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: Text(habit.icon!, style: AppTypography.bodyMd),
          ),
        // 습관 이름
        Expanded(
          child: Text(
            habit.name,
            style: AppTypography.bodySm.copyWith(
              color: context.themeColors.textPrimary,
              decoration:
                  isCompleted ? TextDecoration.lineThrough : null,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}
```

- [ ] **Step 3: Add required imports**

```dart
import '../../../habit/providers/habit_provider.dart';  // toggleHabitProvider
import '../../../../shared/models/habit.dart';
```

- [ ] **Step 4: Run `flutter analyze`**

Run: `cd /Users/kimtaekyu/Documents/Develop_Fold/03_ToDoList_Web && flutter analyze lib/features/calendar/presentation/widgets/daily_view.dart`
Expected: No issues found

- [ ] **Step 5: Commit**

```bash
git add lib/features/calendar/presentation/widgets/daily_view.dart
git commit -m "feat: add habit checklist section to daily view all-day area"
```

---

### Task 12: Add habit status indicators to WeeklyView day headers

Show a small habit completion indicator (e.g., fraction or mini progress bar) in each day header of the weekly view.

**Files:**
- Modify: `lib/features/calendar/providers/event_provider.dart` (add `habitCompletionForWeekProvider`)
- Modify: `lib/features/calendar/presentation/widgets/weekly_view.dart` (update `WeeklyDayHeader`)

- [ ] **Step 1: Add `habitCompletionForWeekProvider`**

In `event_provider.dart`, add after `habitsForDayProvider`:

```dart
/// 주간 뷰 헤더용 습관 완료율: 주의 각 날짜별 (완료수, 전체수) 반환
/// 키: DateTime (날짜), 값: ({int completed, int total})
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
    // 해당 날짜에 예정된 습관만 필터링한다
    final scheduledHabits =
        activeHabits.where((h) => h.isScheduledFor(day)).toList();
    if (scheduledHabits.isEmpty) {
      result[day] = (completed: 0, total: 0);
      continue;
    }

    // 해당 날짜의 완료된 습관 ID 집합
    final dateStr = AppDateUtils.toDateString(day);
    final completedIds = <String>{};
    for (final logMap in allHabitLogsRaw) {
      final log = HabitLog.fromMap(logMap);
      if (log.isCompleted && AppDateUtils.toDateString(log.date) == dateStr) {
        completedIds.add(log.habitId);
      }
    }

    final completedCount =
        scheduledHabits.where((h) => completedIds.contains(h.id)).length;
    result[day] = (completed: completedCount, total: scheduledHabits.length);
  }

  return result;
});
```

- [ ] **Step 2: Update WeeklyDayHeader in weekly_view.dart**

In `weekly_view.dart`, watch `habitCompletionForWeekProvider` and pass data to `WeeklyDayHeader`. Add a small text or dot indicator below the day number showing habit completion status (e.g., "2/3" or a colored dot).

In the build method, add:
```dart
final habitCompletion = ref.watch(habitCompletionForWeekProvider);
```

Update the `WeeklyDayHeader` widget to accept an optional habit completion count and render it:

```dart
// 헤더에 습관 완료율 텍스트 표시 (예: "2/3")
if (habitData.total > 0)
  Text(
    '${habitData.completed}/${habitData.total}',
    style: AppTypography.captionSm.copyWith(
      color: habitData.completed == habitData.total
          ? ColorTokens.success
          : context.themeColors.textPrimaryWithAlpha(0.4),
    ),
  ),
```

- [ ] **Step 3: Run `flutter analyze`**

Run: `cd /Users/kimtaekyu/Documents/Develop_Fold/03_ToDoList_Web && flutter analyze lib/features/calendar/`
Expected: No issues found

- [ ] **Step 4: Commit**

```bash
git add lib/features/calendar/providers/event_provider.dart lib/features/calendar/presentation/widgets/weekly_view.dart
git commit -m "feat: add habit completion indicators to weekly view day headers"
```

---

## Chunk 4: Timer → Calendar Daily View + GoalTask → Todo Conversion

### Task 13: Add `timerLogsForCalendarDayProvider` to event_provider.dart

For the daily view, show timer sessions as timeline blocks.

**Files:**
- Modify: `lib/features/calendar/providers/event_provider.dart`

- [ ] **Step 1: Add timer log provider for calendar**

```dart
/// 일간 뷰 타임라인용 타이머 세션 데이터
/// focus 타입의 TimerLog를 CalendarEvent으로 변환하여 타임라인에 표시한다
/// 선택된 날짜의 집중 세션만 반환한다
final timerLogsForCalendarDayProvider =
    Provider<List<CalendarEvent>>((ref) {
  final selectedDate = ref.watch(selectedCalendarDateProvider);
  final allTimerLogsRaw = ref.watch(allTimerLogsRawProvider);

  final dateStr = AppDateUtils.toDateString(selectedDate);
  final events = <CalendarEvent>[];

  for (final logMap in allTimerLogsRaw) {
    final log = TimerLog.fromMap(logMap);
    // 집중 세션만 표시한다 (휴식은 표시하지 않는다)
    if (log.type != TimerSessionType.focus) continue;
    // 시작 시간 기준으로 해당 날짜인지 확인한다
    if (AppDateUtils.toDateString(log.startTime) != dateStr) continue;

    final durationMinutes = log.durationSeconds ~/ 60;
    final endHour = log.startTime.hour + (log.startTime.minute + durationMinutes) ~/ 60;
    final endMinute = (log.startTime.minute + durationMinutes) % 60;

    events.add(CalendarEvent(
      id: 'timer_${log.id}',
      title: log.todoTitle ?? '집중 세션',
      startDate: selectedDate,
      startHour: log.startTime.hour,
      startMinute: log.startTime.minute,
      endHour: endHour.clamp(0, 23),
      endMinute: endMinute,
      colorIndex: 8, // 타이머 전용 색상 인덱스 (또는 기존 팔레트에서 선택)
      type: CalendarEventType.normal,
      source: 'timer',
    ));
  }

  // 시간순 정렬
  events.sort((a, b) {
    final aMin = (a.startHour ?? 0) * 60 + (a.startMinute ?? 0);
    final bMin = (b.startHour ?? 0) * 60 + (b.startMinute ?? 0);
    return aMin.compareTo(bMin);
  });

  return events;
});
```

- [ ] **Step 2: Add required imports**

```dart
import '../../timer/models/timer_log.dart';
```

- [ ] **Step 3: Check if `CalendarEvent` source field accepts 'timer' and `CalendarEventType` enum has `normal`**

Read the `CalendarEvent` class definition. If `source` is just a `String` field, 'timer' works. If it's an enum, add a new value. Based on the exploration, `source` is a `String` field with values 'app', 'google', 'todo', 'todo_completed' — so 'timer' is fine.

- [ ] **Step 4: Run `flutter analyze`**

Run: `cd /Users/kimtaekyu/Documents/Develop_Fold/03_ToDoList_Web && flutter analyze lib/features/calendar/providers/event_provider.dart`
Expected: No issues found

- [ ] **Step 5: Commit**

```bash
git add lib/features/calendar/providers/event_provider.dart
git commit -m "feat: add timerLogsForCalendarDayProvider for timer sessions on daily timeline"
```

---

### Task 14: Render timer session blocks in DailyView

Add timer session blocks to the daily view timeline (distinct visual style from events).

**Files:**
- Modify: `lib/features/calendar/presentation/widgets/daily_view.dart`
- Modify: `lib/core/calendar_sync/calendar_sync_provider.dart` (add timer to `mergedEventsForDayProvider`)

- [ ] **Step 1: Add timer events to `mergedEventsForDayProvider`**

In `calendar_sync_provider.dart`, modify `mergedEventsForDayProvider` to include timer sessions:

```dart
final mergedEventsForDayProvider = Provider<List<CalendarEvent>>((ref) {
  final appEvents = ref.watch(eventsForDayProvider);
  final googleEventsAsync = ref.watch(googleCalendarEventsProvider);
  final selectedDate = ref.watch(selectedCalendarDateProvider);
  final timerEvents = ref.watch(timerLogsForCalendarDayProvider);  // 추가

  // Google 이벤트 로딩 실패 또는 비활성화 시 빈 목록 사용
  final googleEvents = googleEventsAsync.valueOrNull ?? const [];

  // 선택된 날짜에 해당하는 Google 이벤트만 필터링한다
  final filteredGoogleEvents = googleEvents.where((e) {
    // ... 기존 필터 로직 유지 ...
  }).toList();

  // 앱 이벤트 + Google 이벤트 + 타이머 세션을 병합하여 시간순으로 정렬한다
  final merged = [...appEvents, ...filteredGoogleEvents, ...timerEvents];
  merged.sort((a, b) {
    final aTime = (a.startHour ?? 24) * 60 + (a.startMinute ?? 0);
    final bTime = (b.startHour ?? 24) * 60 + (b.startMinute ?? 0);
    return aTime.compareTo(bTime);
  });

  return merged;
});
```

- [ ] **Step 2: Add import for `timerLogsForCalendarDayProvider`**

In `calendar_sync_provider.dart`:
```dart
import '../../features/calendar/providers/event_provider.dart';
```
(This import likely already exists.)

- [ ] **Step 3: Update DailyView `_buildEventBlock` to style timer blocks differently**

In `daily_view.dart`, add a check for timer events in the event block builder:

```dart
// 타이머 세션은 별도 색상으로 표시한다
final isTimerEvent = event.source == 'timer';
final blockColor = isTimerEvent
    ? ColorTokens.timerSession  // 타이머 전용 색상 토큰
    : event.isTodoEvent
        ? _todoCardColor
        : ColorTokens.eventColor(event.colorIndex);
```

If `ColorTokens.timerSession` doesn't exist, use `const Color(0xFF10B981)` (emerald green) or add a constant to `ColorTokens`.

- [ ] **Step 4: Run `flutter analyze`**

Run: `cd /Users/kimtaekyu/Documents/Develop_Fold/03_ToDoList_Web && flutter analyze lib/`
Expected: No issues found

- [ ] **Step 5: Commit**

```bash
git add lib/core/calendar_sync/calendar_sync_provider.dart lib/features/calendar/presentation/widgets/daily_view.dart
git commit -m "feat: render timer focus sessions as blocks on daily view timeline"
```

---

### Task 15: Add GoalTask → Todo conversion provider

Allow users to export goal tasks as todos. This creates a provider that converts a GoalTask into a Todo and saves it.

**Files:**
- Modify: `lib/features/goal/providers/goal_provider.dart` (add `exportGoalTaskAsTodoProvider`)

- [ ] **Step 1: Add export provider**

```dart
/// GoalTask → Todo 변환 액션 Provider
/// 목표의 실천 과제를 투두로 변환하여 todosBox에 저장한다
/// 변환된 투두의 scheduled_date는 오늘, 제목은 GoalTask.title을 사용한다
final exportGoalTaskAsTodoProvider = Provider<Future<void> Function(GoalTask task)>((ref) {
  return (GoalTask task) async {
    final cacheService = ref.read(hiveCacheServiceProvider);
    final now = DateTime.now();
    final todoId = const Uuid().v4();

    final todoMap = {
      'id': todoId,
      'title': task.title,
      'scheduled_date': AppDateUtils.toDateString(now),
      'is_completed': false,
      'display_order': 0,
      'created_at': now.toIso8601String(),
    };

    await cacheService.writeRecord(AppConstants.todosBox, todoId, todoMap);
    // 투두 데이터 버전을 증가시켜 UI 갱신을 트리거한다
    ref.read(todoDataVersionProvider.notifier).state++;
  };
});
```

- [ ] **Step 2: Add required imports**

```dart
import 'package:uuid/uuid.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/global_providers.dart';  // hiveCacheServiceProvider
import '../../../core/providers/data_store_providers.dart';  // todoDataVersionProvider
```

Verify which of these are already imported.

- [ ] **Step 3: Add "투두로 변환" button to GoalTaskItem widget**

In `lib/features/goal/presentation/widgets/goal_task_item.dart`, add a trailing action button:

```dart
IconButton(
  icon: Icon(
    Icons.add_task,
    size: AppLayout.iconSm,
    color: context.themeColors.textPrimaryWithAlpha(0.5),
  ),
  tooltip: '투두로 변환',
  onPressed: () {
    ref.read(exportGoalTaskAsTodoProvider)(task);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('\"${task.title}\" 투두에 추가됨')),
    );
  },
)
```

- [ ] **Step 4: Run `flutter analyze`**

Run: `cd /Users/kimtaekyu/Documents/Develop_Fold/03_ToDoList_Web && flutter analyze lib/features/goal/`
Expected: No issues found

- [ ] **Step 5: Commit**

```bash
git add lib/features/goal/providers/goal_provider.dart lib/features/goal/presentation/widgets/goal_task_item.dart
git commit -m "feat: add GoalTask to Todo conversion with export button"
```

---

### Task 16: Final integration test — full `flutter analyze`

**Files:** All modified files

- [ ] **Step 1: Run full flutter analyze**

Run: `cd /Users/kimtaekyu/Documents/Develop_Fold/03_ToDoList_Web && flutter analyze`
Expected: No issues found

- [ ] **Step 2: Run flutter build (dry run)**

Run: `cd /Users/kimtaekyu/Documents/Develop_Fold/03_ToDoList_Web && flutter build apk --debug 2>&1 | tail -5`
Expected: BUILD SUCCESSFUL

- [ ] **Step 3: Final commit**

```bash
git add -A
git commit -m "chore: complete cross-feature data integration (routines, habits, goals, timer → calendar + home)"
```
