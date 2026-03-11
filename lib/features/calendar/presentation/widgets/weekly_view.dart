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
import 'weekly_day_header.dart';
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
  static const double _timeColumnWidth = 44.0;

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
    final scrollOffset = (now.hour * kWeeklyHourHeight) - 120;
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

  /// 선택된 날짜 기준 해당 주의 월요일 계산
  DateTime _weekStart(DateTime date) {
    // weekday: 1=월, 7=일
    return date.subtract(Duration(days: date.weekday - 1));
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedCalendarDateProvider);
    // F17: 앱 이벤트와 Google Calendar 이벤트를 모두 포함하는 병합 이벤트 사용
    final eventsAsync = ref.watch(eventsForMonthProvider);
    final appEvents = eventsAsync.valueOrNull ?? const [];
    final googleEventsAsync = ref.watch(googleCalendarEventsProvider);
    final googleEvents = googleEventsAsync.valueOrNull ?? const [];
    // 앱 이벤트 + Google 이벤트를 합쳐 주간 뷰에 표시한다
    final allEvents = [...appEvents, ...googleEvents];

    final now = DateTime.now();
    final weekStart = _weekStart(selectedDate);
    // 해당 주의 7일 (월~일)
    final weekDays = List.generate(AppLayout.daysInWeek, (i) => weekStart.add(Duration(days: i)));

    return SingleChildScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // 날짜 헤더 행 (공용 위젯 사용)
          WeeklyDayHeader(
            weekDays: weekDays,
            selectedDate: selectedDate,
            now: now,
            timeColumnWidth: _timeColumnWidth,
          ),

          // 타임라인 본문
          SizedBox(
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
                  final dayEvents = allEvents.where((e) {
                    final sameDay = e.startDate.year == day.year &&
                        e.startDate.month == day.month &&
                        e.startDate.day == day.day;
                    if (e.endDate != null) {
                      return !day.isBefore(e.startDate) &&
                          !day.isAfter(e.endDate!);
                    }
                    return sameDay;
                  }).toList();

                  return Expanded(
                    child: _DayColumn(
                      day: day,
                      events: dayEvents,
                      isToday: isToday,
                      isSelected: isSelected,
                      now: now,
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 단일 날짜 열 (시간 구분선 + 이벤트 블록 + 현재 시간선)
class _DayColumn extends StatelessWidget {
  final DateTime day;
  final List<CalendarEvent> events;
  final bool isToday;
  final bool isSelected;
  final DateTime now;

  const _DayColumn({
    required this.day,
    required this.events,
    required this.isToday,
    required this.isSelected,
    required this.now,
  });

  @override
  Widget build(BuildContext context) {
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
                    color: context.themeColors.textPrimaryWithAlpha(0.08),
                    width: 1,
                  ),
                  left: BorderSide(
                    color: context.themeColors.textPrimaryWithAlpha(0.06),
                    width: 1,
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

        // 이벤트 블록 (공용 위젯 사용)
        ...events
            .where((e) => e.startHour != null)
            .map((e) => WeeklyEventBlock(event: e)),

        // 현재 시간 빨간 가로선 - 오늘 열에만 표시 (공용 위젯 사용)
        if (isToday) WeeklyCurrentTimeLine(now: now),
      ],
    );
  }
}
