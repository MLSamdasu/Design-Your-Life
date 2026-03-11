// F3 위젯: DailyScheduleView - 하루 일정표
// 좌: 완료율 DonutChart + 오늘 일정 수 + 유형별 카운트 (고정, 스크롤 안 됨)
// 우: 시간별 타임라인 (시간 지정 투두를 Stack+Positioned으로 배치, 겹침 레이아웃 적용)
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../shared/models/todo.dart';
import '../../../../shared/widgets/glassmorphic_card.dart';
import '../../providers/todo_provider.dart';
import 'event_overlap_layout.dart';
import 'todo_stats_card.dart';
import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';

/// 타임라인 상수: 1시간당 픽셀 높이
const double _hourHeight = 60.0;

/// 시간 라벨 컬럼 너비
const double _timeColumnWidth = 44.0;

/// 최소 블록 높이 (15분 미만 이벤트)
const double _minBlockHeight = 24.0;

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
    // 현재 시간의 Y 위치에서 약간 위로 여유를 두고 스크롤한다
    final scrollOffset = (now.hour * _hourHeight) - 80;
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
    final todos = ref.watch(sortedTodosProvider);
    final timedTodos = todos.where((t) => t.time != null).toList();

    // LayoutBuilder로 화면 너비에 따라 반응형으로 처리한다
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 좌측 통계 패널 너비: 전체의 30%, 최소 120px, 최대 160px
          final leftWidth =
              (constraints.maxWidth * 0.30).clamp(120.0, 160.0);
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 좌측: 통계 패널 (고정, 스크롤에서 제외)
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
              // 우측: 타임라인 패널 (내부에서 독립적으로 수직 스크롤)
              Expanded(
                child: GlassmorphicCard(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: _TimelinePanel(
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

/// 시간별 타임라인 패널
/// Stack+Positioned 레이아웃으로 겹침을 시각화한다
class _TimelinePanel extends StatelessWidget {
  final List<Todo> timedTodos;
  final ScrollController scrollController;

  const _TimelinePanel({
    required this.timedTodos,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    // 겹침 레이아웃을 계산한다
    final layouts = calculateOverlapLayout(
      timedTodos,
      hourHeight: _hourHeight,
      minBlockHeight: _minBlockHeight,
    );

    // 밀도 범위를 계산한다 (배경 스트립용)
    final densityRanges = calculateDensityRanges(layouts);

    // 전체 타임라인 높이: 24시간
    final totalHeight = AppLayout.hoursInDay * _hourHeight;

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
        // Expanded로 남은 공간을 채우고, 내부에서 독립적으로 스크롤한다
        Expanded(
          child: SingleChildScrollView(
            controller: scrollController,
            child: LayoutBuilder(
              builder: (context, constraints) {
                // 이벤트 배치에 사용할 가용 너비 (시간 라벨 제외)
                final availableWidth =
                    constraints.maxWidth - _timeColumnWidth - 8;

                return SizedBox(
                  height: totalHeight,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // 1. 시간 격자선 (배경)
                      ...List.generate(AppLayout.hoursInDay,
                        (hour) => _HourGridLine(
                          hour: hour,
                          isCurrentHour: hour == now.hour,
                        ),
                      ),
                      // 2. 현재 시간 표시선
                      _CurrentTimeIndicator(now: now),
                      // 3. 겹침 밀도 배경 스트립
                      ..._buildDensityBackgrounds(
                        densityRanges,
                        availableWidth,
                      ),
                      // 4. 겹침 그룹의 "+N" 뱃지
                      ..._buildOverflowBadges(
                        layouts,
                        availableWidth,
                      ),
                      // 5. 이벤트 블록들 (최대 3개까지 표시)
                      ...layouts
                          .where((l) => l.overlapIndex < 3)
                          .map((layout) => _buildEventBlock(
                                layout,
                                availableWidth,
                                context,
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
  /// 겹침 수에 따라 메인 컬러의 낮은 불투명도로 배경을 채운다
  List<Widget> _buildDensityBackgrounds(
    List<({int startMinutes, int endMinutes, int count})> densityRanges,
    double availableWidth,
  ) {
    return densityRanges.map((range) {
      final top = range.startMinutes * (_hourHeight / 60.0);
      final height =
          (range.endMinutes - range.startMinutes) * (_hourHeight / 60.0);

      // 겹침 수에 따른 배경 불투명도
      double alpha;
      if (range.count <= 1) {
        alpha = 0.03;
      } else if (range.count == 2) {
        alpha = 0.06;
      } else {
        alpha = 0.10;
      }

      return Positioned(
        top: top,
        left: _timeColumnWidth + 8,
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
    // 겹침 수가 4 이상인 그룹을 찾는다
    // totalOverlaps > 3이고 overlapIndex == 0인 아이템을 기준으로 뱃지를 배치한다
    final overflowGroups = <OverlapLayoutResult>[];
    for (final layout in layouts) {
      if (layout.totalOverlaps > 3 && layout.overlapIndex == 0) {
        overflowGroups.add(layout);
      }
    }

    return overflowGroups.map((layout) {
      final extraCount = layout.totalOverlaps - 3;
      return Positioned(
        top: layout.top + 2,
        right: AppSpacing.xs,
        child: _OverflowBadge(
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
    BuildContext context,
  ) {
    final blockWidth = availableWidth * layout.widthFraction;
    final leftOffset =
        _timeColumnWidth + 8 + (availableWidth * layout.leftFraction);

    return Positioned(
      top: layout.top,
      left: leftOffset,
      width: blockWidth,
      height: max(layout.height, _minBlockHeight),
      child: _OverlapAwareBlock(
        todo: layout.todo,
        overlapIndex: layout.overlapIndex,
        totalOverlaps: layout.totalOverlaps,
        blockHeight: layout.height,
      ),
    );
  }
}

/// 시간 격자선 (배경)
class _HourGridLine extends StatelessWidget {
  final int hour;
  final bool isCurrentHour;

  const _HourGridLine({
    required this.hour,
    required this.isCurrentHour,
  });

  @override
  Widget build(BuildContext context) {
    final top = hour * _hourHeight;
    return Positioned(
      top: top,
      left: 0,
      right: 0,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 시간 라벨
          SizedBox(
            width: _timeColumnWidth,
            child: Text(
              '${hour.toString().padLeft(2, '0')}:00',
              style: AppTypography.captionMd.copyWith(
                color: isCurrentHour
                    ? context.themeColors.textPrimary
                    : context.themeColors.textPrimaryWithAlpha(0.4),
                fontWeight: isCurrentHour ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          // 구분선
          Expanded(
            child: Container(
              height: 1,
              margin: const EdgeInsets.only(top: AppSpacing.sm),
              color: context.themeColors.textPrimaryWithAlpha(0.08),
            ),
          ),
        ],
      ),
    );
  }
}

/// 현재 시간 표시선 (빨간 점 + 수평선)
class _CurrentTimeIndicator extends StatelessWidget {
  final DateTime now;

  const _CurrentTimeIndicator({required this.now});

  @override
  Widget build(BuildContext context) {
    final minuteOffset = now.hour * 60 + now.minute;
    final top = minuteOffset * (_hourHeight / 60.0);

    return Positioned(
      top: top - 3,
      left: _timeColumnWidth,
      right: 0,
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: ColorTokens.error,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Container(
              height: 1.5,
              color: ColorTokens.error.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

/// 겹침 인식 이벤트 블록 위젯
/// 블록 높이와 겹침 상태에 따라 텍스트/스타일을 적응적으로 변경한다
class _OverlapAwareBlock extends StatelessWidget {
  final Todo todo;

  /// 겹침 그룹 내 순서 (0부터)
  final int overlapIndex;

  /// 해당 그룹의 총 겹침 수
  final int totalOverlaps;

  /// 블록의 실제 높이 (px)
  final double blockHeight;

  const _OverlapAwareBlock({
    required this.todo,
    required this.overlapIndex,
    required this.totalOverlaps,
    required this.blockHeight,
  });

  @override
  Widget build(BuildContext context) {
    final color = ColorTokens.eventColor(todo.colorIndex);
    final effectiveHeight = max(blockHeight, _minBlockHeight);
    final isOverlapping = totalOverlaps > 1;

    // 겹침 위치에 따른 배경 불투명도 (뒤쪽이 낮고 앞쪽이 높다)
    final double bgAlpha;
    if (!isOverlapping) {
      bgAlpha = 0.25;
    } else {
      bgAlpha = 0.20 + (overlapIndex * 0.05);
    }

    // 겹침 위치에 따른 좌측 컬러 바 너비 (겹칠수록 두꺼워진다)
    final leftBarWidth = isOverlapping ? 2.0 + (overlapIndex * 0.5) : 3.0;

    // 2번째 이상 겹침 카드에 깊이감 그림자 추가
    final shadows = overlapIndex > 0
        ? [
            BoxShadow(
              color: ColorTokens.shadowBase.withValues(alpha: 0.12),
              blurRadius: 4,
              offset: const Offset(-2, 1),
            ),
          ]
        : <BoxShadow>[];

    return GestureDetector(
      onTap: () {
        // 투두 상세 보기 또는 편집으로 연결할 수 있다
      },
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: bgAlpha),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border(
            left: BorderSide(color: color, width: leftBarWidth),
          ),
          boxShadow: shadows,
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        child: _buildAdaptiveContent(context, effectiveHeight, color),
      ),
    );
  }

  /// 블록 높이와 겹침 상태에 따라 적응적 콘텐츠를 생성한다
  ///
  /// | 높이       | 제목      | 시간 표시           |
  /// |------------|-----------|---------------------|
  /// | >= 60px    | 2줄       | "HH:MM - HH:MM"    |
  /// | 40~59px    | 1줄       | "HH:MM" 인라인      |
  /// | 30~39px    | 1줄       | 숨김 (툴팁)         |
  /// | < 30px     | 6자 + ... | 숨김                |
  Widget _buildAdaptiveContent(
    BuildContext context,
    double height,
    Color eventColor,
  ) {
    final isOverlapping = totalOverlaps > 1;
    // 겹침 시 폰트를 한 단계 작게 한다
    final titleStyle = isOverlapping
        ? AppTypography.captionMd
        : AppTypography.captionLg;
    final timeStyle = AppTypography.captionSm;

    final textColor = todo.isCompleted
        ? context.themeColors.textPrimaryWithAlpha(0.5)
        : context.themeColors.textPrimary;
    final decoration =
        todo.isCompleted ? TextDecoration.lineThrough : null;

    // 시간 문자열 생성
    final startStr = _formatTime(todo.startTime);
    final endStr = _formatTime(todo.endTime);
    final timeRangeStr = endStr != null ? '$startStr - $endStr' : startStr;

    if (height >= 60) {
      // 큰 블록: 제목 2줄 + 시간 범위 표시
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            todo.title,
            style: titleStyle.copyWith(
              color: textColor,
              decoration: decoration,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (timeRangeStr != null) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              timeRangeStr,
              style: timeStyle.copyWith(
                color: context.themeColors.textPrimaryWithAlpha(0.5),
              ),
              maxLines: 1,
            ),
          ],
        ],
      );
    } else if (height >= 40) {
      // 중간 블록: 제목 1줄 + 시간 인라인
      // 겹침 시에는 시간을 숨긴다 (공간 부족)
      return Row(
        children: [
          Expanded(
            child: Text(
              todo.title,
              style: titleStyle.copyWith(
                color: textColor,
                decoration: decoration,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (!isOverlapping && startStr != null) ...[
            const SizedBox(width: AppSpacing.xs),
            Text(
              startStr,
              style: timeStyle.copyWith(
                color: context.themeColors.textPrimaryWithAlpha(0.4),
              ),
            ),
          ],
        ],
      );
    } else if (height >= 30) {
      // 작은 블록: 제목 1줄만
      return Tooltip(
        message: '${todo.title} ($timeRangeStr)',
        child: Text(
          todo.title,
          style: titleStyle.copyWith(
            color: textColor,
            decoration: decoration,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    } else {
      // 매우 작은 블록: 6자 축약
      final shortTitle = todo.title.length > 6
          ? '${todo.title.substring(0, 6)}...'
          : todo.title;
      return Tooltip(
        message: '${todo.title} ($timeRangeStr)',
        child: Text(
          shortTitle,
          style: AppTypography.captionSm.copyWith(
            color: textColor,
            decoration: decoration,
          ),
          maxLines: 1,
          overflow: TextOverflow.clip,
        ),
      );
    }
  }

  /// TimeOfDay를 "HH:MM" 형식으로 변환한다
  String? _formatTime(TimeOfDay? time) {
    if (time == null) return null;
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

/// "+N" 오버플로우 뱃지 위젯
/// 4개 이상 겹치는 이벤트에서 3개를 넘는 수를 표시한다
class _OverflowBadge extends StatelessWidget {
  /// 숨겨진 이벤트 수
  final int count;

  /// 해당 그룹의 전체 투두 목록 (바텀시트에서 사용)
  final List<Todo> allTodos;

  const _OverflowBadge({
    required this.count,
    required this.allTodos,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showOverflowSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: ColorTokens.main,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: [
            BoxShadow(
              color: ColorTokens.main.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          '+$count',
          style: AppTypography.captionLg.copyWith(
            // MAIN 컬러 배경(#7C3AED) 위이므로 항상 흰색이 적절하다
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// 겹친 이벤트 전체 목록을 바텀시트로 표시한다
  void _showOverflowSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        decoration: BoxDecoration(
          color: context.themeColors.textPrimaryWithAlpha(0.95).withValues(
                alpha: 1.0,
              ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '겹치는 일정 (${allTodos.length}개)',
              style: AppTypography.titleMd.copyWith(
                color: context.themeColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ...allTodos.map((todo) {
              final color = ColorTokens.eventColor(todo.colorIndex);
              final startStr = todo.startTime != null
                  ? '${todo.startTime!.hour.toString().padLeft(2, '0')}:${todo.startTime!.minute.toString().padLeft(2, '0')}'
                  : '';
              final endStr = todo.endTime != null
                  ? ' - ${todo.endTime!.hour.toString().padLeft(2, '0')}:${todo.endTime!.minute.toString().padLeft(2, '0')}'
                  : '';
              return Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.mdLg),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.lgXl),
                  border: Border(
                    left: BorderSide(color: color, width: 3),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        todo.title,
                        style: AppTypography.bodyMd.copyWith(
                          color: context.themeColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (startStr.isNotEmpty)
                      Text(
                        '$startStr$endStr',
                        style: AppTypography.captionMd.copyWith(
                          color:
                              context.themeColors.textPrimaryWithAlpha(0.5),
                        ),
                      ),
                  ],
                ),
              );
            }),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}
