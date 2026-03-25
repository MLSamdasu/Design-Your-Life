// F2 위젯: WeeklyView - 주간 타임라인 뷰
// 7일 수평 열 + 수직 시간 타임라인 (00:00~23:59)
// 선택된 날짜 기준 해당 주(월~일)의 일정을 열 별로 배치한다 (AC-CL-05)
// SRP 분리: 이벤트/시간 위젯 → weekly_view_widgets.dart, 헤더 → weekly_day_header.dart
//           단일 날짜 열 → weekly_day_column.dart
// F17: Google Calendar 이벤트를 병합하여 주간 뷰에 표시한다
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../sync/calendar_sync_provider.dart';
import '../../providers/calendar_provider.dart';
import '../../providers/event_provider.dart';
import 'weekly_day_header.dart';
import '../utils/event_dialog_utils.dart';
import 'weekly_view_widgets.dart';
import 'weekly_day_column.dart';
import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';

// barrel re-export: 분리된 하위 위젯을 이 파일을 통해 접근할 수 있도록 한다
export 'weekly_day_column.dart';

/// 주간 타임라인 뷰
class WeeklyView extends ConsumerStatefulWidget {
  const WeeklyView({super.key});

  @override
  ConsumerState<WeeklyView> createState() => _WeeklyViewState();
}

class _WeeklyViewState extends ConsumerState<WeeklyView> {
  static const double _timeColumnWidth = TimelineLayout.timelineTimeColumnMd;

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
    final scrollOffset = (now.hour * kWeeklyHourHeight) - TimelineLayout.weeklyScrollOffset;
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
                      child: WeeklyDayColumn(
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
