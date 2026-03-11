// F2 위젯: DailyView - 일간 타임라인 뷰
// 00:00~23:59 수직 타임라인 + 현재 시간 빨간 가로선 (AC-CL-03)
// 이벤트는 시간 위치에 배치, 루틴도 타임라인에 표시 (AC-CL-07)
// F17: Google Calendar 이벤트를 포함한 병합 이벤트를 표시한다
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/calendar_sync/calendar_sync_provider.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../providers/event_provider.dart';
import '../../providers/calendar_provider.dart';
import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';

/// 일간 타임라인 뷰
class DailyView extends ConsumerStatefulWidget {
  const DailyView({super.key});

  @override
  ConsumerState<DailyView> createState() => _DailyViewState();
}

class _DailyViewState extends ConsumerState<DailyView> {
  // 1시간당 픽셀 높이 (24시간 * 60px = 1440px)
  static const double _hourHeight = 60.0;
  static const double _timeColumnWidth = 52.0;

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
    final scrollOffset = (now.hour * _hourHeight) - 100;
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

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedCalendarDateProvider);
    // F17: 앱 이벤트 + Google Calendar 이벤트가 병합된 Provider를 사용한다
    final events = ref.watch(mergedEventsForDayProvider);
    final routinesAsync = ref.watch(routinesForDayProvider);
    final routines = routinesAsync.valueOrNull ?? const [];

    final now = DateTime.now();
    final isToday = now.year == selectedDate.year &&
        now.month == selectedDate.month &&
        now.day == selectedDate.day;

    return SingleChildScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      child: SizedBox(
        height: AppLayout.hoursInDay * _hourHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 시간 레이블 열
            _buildTimeColumn(),

            // 이벤트/루틴 배치 영역
            Expanded(
              child: Stack(
                children: [
                  // 시간 구분선
                  _buildTimeLines(),

                  // 루틴 블록
                  ...routines.map((r) => _buildRoutineBlock(r)),

                  // 이벤트 블록
                  ...events
                      .where((e) => e.startHour != null)
                      .map((e) => _buildEventBlock(e)),

                  // 현재 시간 빨간 가로선 (오늘만 표시)
                  if (isToday) _buildCurrentTimeLine(now),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 시간 레이블 열 (00:00 ~ 23:00)
  Widget _buildTimeColumn() {
    return SizedBox(
      width: _timeColumnWidth,
      child: Stack(
        children: List.generate(AppLayout.hoursInDay, (hour) {
          return Positioned(
            top: hour * _hourHeight - 8,
            left: 0,
            right: 0,
            child: Text(
              '${hour.toString().padLeft(2, '0')}:00',
              style: AppTypography.captionMd.copyWith(
                color: context.themeColors.textPrimaryWithAlpha(0.45),
              ),
              textAlign: TextAlign.right,
            ),
          );
        }),
      ),
    );
  }

  /// 수평 시간 구분선 (각 시간대마다)
  Widget _buildTimeLines() {
    return Column(
      children: List.generate(AppLayout.hoursInDay, (i) {
        return Container(
          height: _hourHeight,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: context.themeColors.textPrimaryWithAlpha(0.10),
                width: 1,
              ),
            ),
          ),
        );
      }),
    );
  }

  /// 현재 시간 빨간 가로선 (AC-CL-03)
  Widget _buildCurrentTimeLine(DateTime now) {
    final topOffset =
        now.hour * _hourHeight + now.minute * (_hourHeight / 60);
    return Positioned(
      top: topOffset,
      left: 0,
      right: 0,
      child: Row(
        children: [
          // 빨간 원형 점
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: ColorTokens.error,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Container(
              height: 1.5,
              color: ColorTokens.error,
            ),
          ),
        ],
      ),
    );
  }

  /// 이벤트 블록 (시간 위치에 배치)
  Widget _buildEventBlock(CalendarEvent event) {
    final startMin = (event.startHour ?? 0) * 60 + (event.startMinute ?? 0);
    final endMin = event.endHour != null
        ? event.endHour! * 60 + (event.endMinute ?? 0)
        : startMin + 60;
    final duration = endMin - startMin;

    final top = startMin * (_hourHeight / 60);
    final height = (duration * _hourHeight / 60).clamp(30.0, double.infinity);
    final eventColor = ColorTokens.eventColor(event.colorIndex);

    return Positioned(
      top: top,
      left: AppSpacing.xs,
      right: AppSpacing.xs,
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: eventColor.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: eventColor.withValues(alpha: 0.50),
            width: 1,
          ),
        ),
        child: Text(
          event.title,
          style: AppTypography.captionLg.copyWith(color: context.themeColors.textPrimary),
          maxLines: height > 40 ? 2 : 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  /// 루틴 블록 (이벤트와 동일한 타임라인에 표시)
  Widget _buildRoutineBlock(RoutineEntry routine) {
    final startMin = routine.startHour * 60 + routine.startMinute;
    final endMin = routine.endHour * 60 + routine.endMinute;
    final duration = endMin - startMin;

    final top = startMin * (_hourHeight / 60);
    final height = (duration * _hourHeight / 60).clamp(30.0, double.infinity);
    final routineColor = ColorTokens.eventColor(routine.colorIndex);

    return Positioned(
      top: top,
      right: AppSpacing.xs,
      width: 80,
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: routineColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: routineColor.withValues(alpha: 0.30),
            width: 1,
          ),
        ),
        child: Text(
          routine.name,
          style: AppTypography.captionMd.copyWith(
            color: routineColor.withValues(alpha: 0.80),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
