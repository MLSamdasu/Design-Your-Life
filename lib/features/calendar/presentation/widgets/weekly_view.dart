// F2 위젯: WeeklyView - 주간 타임라인 뷰
// 7일 수평 열 + 수직 시간 타임라인 (00:00~23:59)
// 선택된 날짜 기준 해당 주(월~일)의 일정을 열 별로 배치한다 (AC-CL-05)
// SRP 분리: 이벤트/시간 위젯 → weekly_view_widgets.dart, 헤더 → weekly_day_header.dart
// F17: Google Calendar 이벤트를 병합하여 주간 뷰에 표시한다
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/calendar_sync/calendar_sync_provider.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../providers/calendar_provider.dart';
import '../../providers/event_provider.dart';
import '../../../habit/providers/routine_log_provider.dart';
import '../../../todo/providers/todo_provider.dart';
import 'weekly_day_header.dart';
import '../utils/event_dialog_utils.dart';
import 'weekly_view_widgets.dart';
import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';

/// 주간 타임라인 뷰
class WeeklyView extends ConsumerStatefulWidget {
  const WeeklyView({super.key});

  @override
  ConsumerState<WeeklyView> createState() => _WeeklyViewState();
}

class _WeeklyViewState extends ConsumerState<WeeklyView> {
  static const double _timeColumnWidth = AppLayout.timelineTimeColumnMd;

  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    // 현재 시간으로 자동 스크롤
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentTime();
    });
  }

  void _scrollToCurrentTime() {
    final now = DateTime.now();
    final scrollOffset = (now.hour * kWeeklyHourHeight) - AppLayout.weeklyScrollOffset;
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        scrollOffset.clamp(0, _scrollController.position.maxScrollExtent),
        duration: AppAnimation.medium,
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 이벤트 편집 다이얼로그를 열고, 저장 후 목록을 갱신한다
  void _openEditDialog(CalendarEvent calendarEvent) {
    // 투두/Google 이벤트는 편집 대상이 아니다
    if (calendarEvent.isTodoEvent || calendarEvent.isGoogleEvent) return;

    // 반복 이벤트 인스턴스 ID에서 원본 ID를 추출한다
    // UUID v4: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx (36자)
    // 반복 인스턴스: {uuid}_{yyyymmdd} (45자)
    String baseEventId = calendarEvent.id;
    if (baseEventId.length > 36 && baseEventId.contains('_')) {
      final lastUnderscoreIdx = baseEventId.lastIndexOf('_');
      final candidate = baseEventId.substring(0, lastUnderscoreIdx);
      if (candidate.length == 36) {
        baseEventId = candidate;
      }
    }

    final repository = ref.read(eventRepositoryProvider);
    final event = repository.getEventById(baseEventId);
    if (event == null) return;

    showEventEditDialog(context: context, ref: ref, event: event);
  }

  /// 선택된 날짜 기준 해당 주의 월요일 계산
  DateTime _weekStart(DateTime date) {
    // weekday: 1=월, 7=일
    return date.subtract(Duration(days: date.weekday - 1));
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedCalendarDateProvider);
    // F17: 앱 이벤트 + Google Calendar 이벤트를 병합한 월별 Provider를 사용한다
    // 직접 병합하지 않고 mergedEventsForMonthProvider를 통해 중복 없이 조회한다
    final allEvents = ref.watch(mergedEventsForMonthProvider);
    // 주간 루틴 데이터: 각 날짜별 활성 루틴 목록
    final routinesByDay = ref.watch(routinesForWeekProvider);
    // 주간 습관 완료율: 각 날짜별 (완료수, 전체수)
    final habitCompletion = ref.watch(habitCompletionForWeekProvider);

    final now = DateTime.now();
    final weekStart = _weekStart(selectedDate);
    // 해당 주의 7일 (월~일)
    final weekDays = List.generate(AppLayout.daysInWeek, (i) => weekStart.add(Duration(days: i)));

    // 날짜 헤더를 스크롤 영역 밖에 고정하여 항상 보이도록 한다
    return Column(
      children: [
        // 날짜 헤더 행 (스크롤과 무관하게 상단 고정)
        WeeklyDayHeader(
          weekDays: weekDays,
          selectedDate: selectedDate,
          now: now,
          timeColumnWidth: _timeColumnWidth,
          habitCompletion: habitCompletion,
        ),

        // 타임라인 본문 (스크롤 가능)
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            // 하단 스크롤 여백 (사이드 네비게이션 전환 후 최소 마진)
            padding: const EdgeInsets.only(bottom: AppLayout.bottomNavArea),
            child: SizedBox(
              height: AppLayout.hoursInDay * kWeeklyHourHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 시간 레이블 열 (공용 위젯 사용)
                  WeeklyTimeColumn(width: _timeColumnWidth),

                  // 7일 열
                  ...weekDays.map((day) {
                    final isToday = now.year == day.year &&
                        now.month == day.month &&
                        now.day == day.day;
                    final isSelected = selectedDate.year == day.year &&
                        selectedDate.month == day.month &&
                        selectedDate.day == day.day;

                    // 해당 날짜의 이벤트 필터링
                    // 시간 컴포넌트를 제거하여 날짜 비교의 정확성을 보장한다
                    final dayOnly = DateTime(day.year, day.month, day.day);
                    final dayEvents = allEvents.where((e) {
                      final startOnly = DateTime(e.startDate.year, e.startDate.month, e.startDate.day);
                      final sameDay = startOnly == dayOnly;
                      if (e.endDate != null) {
                        final endOnly = DateTime(e.endDate!.year, e.endDate!.month, e.endDate!.day);
                        return !dayOnly.isBefore(startOnly) &&
                            !dayOnly.isAfter(endOnly);
                      }
                      return sameDay;
                    }).toList();

                    // 해당 날짜의 루틴 목록
                    final dayKey = DateTime(day.year, day.month, day.day);
                    final dayRoutines = routinesByDay[dayKey] ?? const [];

                    return Expanded(
                      child: _DayColumn(
                        day: day,
                        events: dayEvents,
                        routines: dayRoutines,
                        isToday: isToday,
                        isSelected: isSelected,
                        now: now,
                        onEventTap: _openEditDialog,
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 단일 날짜 열 (시간 구분선 + 루틴 블록 + 이벤트 블록 + 현재 시간선)
/// ConsumerWidget으로 변환하여 투두/루틴 완료 토글 Provider에 접근한다
class _DayColumn extends ConsumerWidget {
  final DateTime day;
  final List<CalendarEvent> events;
  final List<RoutineEntry> routines;
  final bool isToday;
  final bool isSelected;
  final DateTime now;
  final void Function(CalendarEvent)? onEventTap;

  const _DayColumn({
    required this.day,
    required this.events,
    required this.routines,
    required this.isToday,
    required this.isSelected,
    required this.now,
    this.onEventTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        // 시간 구분선 그리드
        Column(
          children: List.generate(AppLayout.hoursInDay, (i) {
            return Container(
              height: kWeeklyHourHeight,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: context.themeColors.textPrimaryWithAlpha(0.14),
                    width: AppLayout.borderThin,
                  ),
                  left: BorderSide(
                    color: context.themeColors.textPrimaryWithAlpha(0.10),
                    width: AppLayout.borderThin,
                  ),
                ),
                // 선택된 날짜 열 배경 미세 하이라이트
                color: isSelected
                    ? context.themeColors.textPrimaryWithAlpha(0.03)
                    : ColorTokens.transparent,
              ),
            );
          }),
        ),

        // 루틴 블록 (이벤트 아래 레이어에 반투명 배경으로 표시)
        ...routines.map((r) {
          // 해당 날짜의 루틴 완료 상태를 Provider에서 감시한다
          final isCompleted = ref.watch(routineCompletionProvider(
            (routineId: r.id, date: day),
          ));
          return WeeklyRoutineBlock(
            routine: r,
            isCompleted: isCompleted,
            onToggle: () {
              ref.read(toggleRoutineLogProvider)(r.id, day, !isCompleted);
            },
          );
        }),

        // 이벤트 블록 (공용 위젯 사용, 루틴 위에 표시)
        ...events
            .where((e) => e.startHour != null)
            .map((e) => WeeklyEventBlock(
              event: e,
              onTap: onEventTap != null ? () => onEventTap!(e) : null,
              // 투두 이벤트: 완료 토글 콜백 전달
              onToggleTodo: e.isTodoEvent
                  ? () {
                      final todoId = e.id.replaceFirst('todo_', '');
                      ref.read(toggleTodoProvider)(
                        todoId,
                        !e.isTodoCompleted,
                      );
                    }
                  : null,
            )),

        // 현재 시간 빨간 가로선 - 오늘 열에만 표시 (공용 위젯 사용)
        if (isToday) WeeklyCurrentTimeLine(now: now),
      ],
    );
  }
}
