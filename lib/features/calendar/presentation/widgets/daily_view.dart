// F2 위젯: DailyView - 일간 타임라인 뷰
// 00:00~23:59 수직 타임라인 + 현재 시간 빨간 가로선 (AC-CL-03)
// 이벤트는 시간 위치에 배치, 루틴도 타임라인에 표시 (AC-CL-07)
// F17: Google Calendar 이벤트를 포함한 병합 이벤트를 표시한다
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../sync/calendar_sync_provider.dart';
import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../providers/event_provider.dart';
import '../../providers/calendar_provider.dart';
import '../../../todo/providers/todo_provider.dart';
import 'daily_allday_section.dart';
import 'daily_current_time_line.dart';
import 'daily_event_block.dart';
import 'daily_habit_section.dart';
import 'daily_routine_block.dart';
import 'daily_time_column.dart';
import 'daily_time_lines.dart';
import '../utils/event_dialog_utils.dart';

/// 일간 타임라인 뷰
class DailyView extends ConsumerStatefulWidget {
  const DailyView({super.key});

  @override
  ConsumerState<DailyView> createState() => _DailyViewState();
}

class _DailyViewState extends ConsumerState<DailyView>
    with TickerProviderStateMixin {
  static const double _hourHeight = TimelineLayout.timelineHourHeight;
  static const double _timeColumnWidth = TimelineLayout.timelineTimeColumnLg;

  late final ScrollController _scrollController;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    // 빨간 점 펄스: 1.0 → 1.2 → 1.0 반복 (2초 주기)
    _pulseController = AnimationController(
      vsync: this,
      duration: AppAnimation.snackBar,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: AppAnimation.bounceScale,
    ).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    // 현재 시간으로 자동 스크롤
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrentTime());
  }

  void _scrollToCurrentTime() {
    final now = DateTime.now();
    final offset = (now.hour * _hourHeight) - TimelineLayout.dailyScrollOffset;
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        offset.clamp(0, _scrollController.position.maxScrollExtent),
        duration: AppAnimation.medium,
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedCalendarDateProvider);
    final events = ref.watch(mergedEventsForDayProvider);
    final routines = ref.watch(routinesForDayProvider);
    final habitsForDay = ref.watch(habitsForDayProvider);

    final now = DateTime.now();
    final isToday = now.year == selectedDate.year &&
        now.month == selectedDate.month &&
        now.day == selectedDate.day;

    final allDayEvents = events.where((e) => e.isAllDay).toList();
    final timedEvents = events.where((e) => !e.isAllDay).toList();

    return Column(
      children: [
        // 종일 이벤트 + 습관 섹션 — 최대 높이를 제한하여 타임라인 영역 오버플로를 방지한다
        Flexible(
          flex: 0,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.3,
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  DailyAllDaySection(
                    allDayEvents: allDayEvents,
                    onEventTap: _openEditDialog,
                    onToggleTodo: (todoId, isCompleted) {
                      ref.read(toggleTodoProvider)(todoId, isCompleted);
                    },
                  ),
                  DailyHabitSection(habitsForDay: habitsForDay),
                ],
              ),
            ),
          ),
        ),
        // 타임라인 영역
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(
              bottom: TimelineLayout.timelineBottomPadding,
            ),
            child: SizedBox(
              height: AppLayout.hoursInDay * _hourHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DailyTimeColumn(
                    hourHeight: _hourHeight,
                    timeColumnWidth: _timeColumnWidth,
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        DailyTimeLines(hourHeight: _hourHeight),
                        ...routines.map((r) => DailyRoutineBlock(
                              routine: r,
                              hourHeight: _hourHeight,
                            )),
                        ...timedEvents
                            .where((e) => e.startHour != null)
                            .map((e) => DailyEventBlock(
                                  event: e,
                                  hourHeight: _hourHeight,
                                  onTap: () => _handleEventTap(e),
                                )),
                        if (isToday)
                          DailyCurrentTimeLine(
                            now: now,
                            hourHeight: _hourHeight,
                            pulseAnimation: _pulseAnimation,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 이벤트 블록 탭: 투두는 완료 토글, 일반 이벤트는 편집 다이얼로그
  void _handleEventTap(CalendarEvent calendarEvent) {
    if (calendarEvent.isTodoEvent) {
      final todoId = calendarEvent.id.replaceFirst('todo_', '');
      ref.read(toggleTodoProvider)(todoId, !calendarEvent.isTodoCompleted);
      return;
    }
    _openEditDialog(calendarEvent);
  }

  /// 이벤트 편집 다이얼로그를 열고, 저장 후 목록을 갱신한다
  void _openEditDialog(CalendarEvent calendarEvent) {
    // 투두/Google 이벤트는 편집 대상이 아니다
    if (calendarEvent.isTodoEvent || calendarEvent.isGoogleEvent) return;

    // 반복 이벤트 인스턴스 ID에서 원본 ID를 추출한다
    String baseEventId = calendarEvent.id;
    if (baseEventId.length > 36 && baseEventId.contains('_')) {
      final idx = baseEventId.lastIndexOf('_');
      final candidate = baseEventId.substring(0, idx);
      if (candidate.length == 36) baseEventId = candidate;
    }

    final repository = ref.read(eventRepositoryProvider);
    final event = repository.getEventById(baseEventId);
    if (event == null) return;

    showEventEditDialog(context: context, ref: ref, event: event);
  }
}
