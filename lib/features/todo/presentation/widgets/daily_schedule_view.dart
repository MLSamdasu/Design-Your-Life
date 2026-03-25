// F3 위젯: DailyScheduleView - 하루 일정표
// 좌: 완료율 DonutChart + 오늘 일정 수 + 유형별 카운트 (고정, 스크롤 안 됨)
// 우: 시간별 타임라인 (시간 지정 투두를 Stack+Positioned으로 배치, 겹침 레이아웃 적용)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../shared/widgets/glassmorphic_card.dart';
import '../../providers/todo_provider.dart';
import 'timeline_constants.dart';
import 'timeline_panel.dart';
import 'todo_stats_card.dart';

/// 하루 일정표 뷰 (서브탭 1)
/// 좌측: 통계 패널 (고정) / 우측: 시간별 타임라인 (수직 스크롤)
class DailyScheduleView extends ConsumerStatefulWidget {
  const DailyScheduleView({super.key});

  @override
  ConsumerState<DailyScheduleView> createState() => _DailyScheduleViewState();
}

class _DailyScheduleViewState extends ConsumerState<DailyScheduleView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // 빌드 완료 후 현재 시간 위치로 자동 스크롤한다
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrentTime());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 현재 시간 기준으로 타임라인을 자동 스크롤한다
  void _scrollToCurrentTime() {
    final now = DateTime.now();
    final scrollOffset =
        (now.hour * timelineHourHeight) - TimelineLayout.scheduleAutoScrollOffset;
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        scrollOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: AppAnimation.slower,
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(todoStatsProvider);
    final todos = ref.watch(filteredTodosProvider);
    // 캘린더 이벤트 + 루틴 + 타이머를 투두 형태로 변환하여 병합한다
    final calendarEvents = ref.watch(calendarEventsForTimelineProvider);
    final routineEvents = ref.watch(routinesForTimelineProvider);
    final timerEvents = ref.watch(timerLogsForTimelineProvider);
    final timedTodos = [
      ...todos.where((t) => t.time != null),
      ...calendarEvents.where((t) => t.time != null),
      ...routineEvents.where((t) => t.time != null),
      ...timerEvents.where((t) => t.time != null),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final leftWidth = (constraints.maxWidth *
                  TimelineLayout.scheduleStatsPanelRatio)
              .clamp(
                TimelineLayout.scheduleStatsPanelMinWidth,
                TimelineLayout.scheduleStatsPanelMaxWidth,
              );
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 좌측: 통계 패널 (고정)
              SizedBox(
                width: leftWidth,
                child: GlassmorphicCard(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: TodoStatsCard(
                    stats: stats,
                    totalScheduleCount: todos.length,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              // 우측: 타임라인 패널
              Expanded(
                child: GlassmorphicCard(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: TimelinePanel(
                    timedTodos: timedTodos,
                    scrollController: _scrollController,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
