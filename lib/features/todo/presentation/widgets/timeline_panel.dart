// 시간별 타임라인 패널 위젯
// Stack+Positioned 레이아웃으로 겹침을 시각화한다
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../shared/models/todo.dart';
import 'event_overlap_layout.dart';
import 'timeline_constants.dart';
import 'timeline_grid_widgets.dart';
import 'timeline_event_block.dart';
import 'timeline_overflow_badge.dart';

/// 시간별 타임라인 패널
/// Stack+Positioned 레이아웃으로 겹침을 시각화한다
class TimelinePanel extends StatelessWidget {
  final List<Todo> timedTodos;
  final ScrollController scrollController;

  const TimelinePanel({
    super.key,
    required this.timedTodos,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final layouts = calculateOverlapLayout(
      timedTodos,
      hourHeight: timelineHourHeight,
      minBlockHeight: timelineMinBlockHeight,
    );
    final densityRanges = calculateDensityRanges(layouts);
    final totalHeight = AppLayout.hoursInDay * timelineHourHeight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '타임라인',
          style: AppTypography.captionLg.copyWith(
            color: context.themeColors.textPrimaryWithAlpha(0.6),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Expanded(
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.only(
              bottom: TimelineLayout.timelineBottomPadding,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final availableWidth = constraints.maxWidth -
                    timelineTimeColumnWidth -
                    TimelineLayout.timelineGutter;
                return SizedBox(
                  height: totalHeight,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // 1. 시간 격자선
                      ...List.generate(
                        AppLayout.hoursInDay,
                        (hour) => HourGridLine(
                          hour: hour,
                          isCurrentHour: hour == now.hour,
                        ),
                      ),
                      // 2. 현재 시간 표시선
                      CurrentTimeIndicator(now: now),
                      // 3. 겹침 밀도 배경 스트립
                      ..._buildDensityBackgrounds(
                        densityRanges,
                        availableWidth,
                      ),
                      // 4. 겹침 그룹의 "+N" 뱃지
                      ..._buildOverflowBadges(layouts, availableWidth),
                      // 5. 이벤트 블록들
                      ...layouts
                          .where((l) =>
                              l.overlapIndex <
                              TimelineLayout.timelineMaxVisibleOverlaps)
                          .map((layout) => _buildEventBlock(
                                layout,
                                availableWidth,
                              )),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  /// 겹침 밀도 배경 스트립을 생성한다
  List<Widget> _buildDensityBackgrounds(
    List<({int startMinutes, int endMinutes, int count})> densityRanges,
    double availableWidth,
  ) {
    return densityRanges.map((range) {
      final top = range.startMinutes * (timelineHourHeight / 60.0);
      final height = (range.endMinutes - range.startMinutes) *
          (timelineHourHeight / 60.0);

      double alpha;
      if (range.count <= 1) {
        alpha = EffectLayout.densityAlphaLow;
      } else if (range.count == 2) {
        alpha = EffectLayout.densityAlphaMedium;
      } else {
        alpha = EffectLayout.densityAlphaHigh;
      }

      return Positioned(
        top: top,
        left: timelineTimeColumnWidth + TimelineLayout.timelineGutter,
        width: availableWidth,
        height: height,
        child: Container(
          decoration: BoxDecoration(
            color: ColorTokens.main.withValues(alpha: alpha),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      );
    }).toList();
  }

  /// 4개 이상 겹치는 그룹에 "+N" 뱃지를 생성한다
  List<Widget> _buildOverflowBadges(
    List<OverlapLayoutResult> layouts,
    double availableWidth,
  ) {
    final overflowGroups = <OverlapLayoutResult>[];
    for (final layout in layouts) {
      if (layout.totalOverlaps > TimelineLayout.timelineMaxVisibleOverlaps &&
          layout.overlapIndex == 0) {
        overflowGroups.add(layout);
      }
    }

    return overflowGroups.map((layout) {
      final extraCount =
          layout.totalOverlaps - TimelineLayout.timelineMaxVisibleOverlaps;
      return Positioned(
        top: layout.top + AppSpacing.xxs,
        right: AppSpacing.xs,
        child: OverflowBadge(
          count: extraCount,
          allTodos: layouts
              .where((l) =>
                  l.totalOverlaps == layout.totalOverlaps &&
                  l.top == layout.top)
              .map((l) => l.todo)
              .toList(),
        ),
      );
    }).toList();
  }

  /// 이벤트 블록 Positioned 위젯을 생성한다
  Widget _buildEventBlock(
    OverlapLayoutResult layout,
    double availableWidth,
  ) {
    final blockWidth = availableWidth * layout.widthFraction;
    final leftOffset = timelineTimeColumnWidth +
        TimelineLayout.timelineGutter +
        (availableWidth * layout.leftFraction);

    return Positioned(
      top: layout.top,
      left: leftOffset,
      width: blockWidth,
      height: max(layout.height, timelineMinBlockHeight),
      child: OverlapAwareBlock(
        todo: layout.todo,
        overlapIndex: layout.overlapIndex,
        totalOverlaps: layout.totalOverlaps,
        blockHeight: layout.height,
      ),
    );
  }
}
