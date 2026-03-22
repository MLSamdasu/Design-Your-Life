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
import '../../../../shared/providers/tag_provider.dart';
import '../../../calendar/providers/event_provider.dart';
import '../../../calendar/presentation/utils/event_dialog_utils.dart';
import '../../providers/todo_provider.dart';
import 'event_overlap_layout.dart';
import 'todo_create_dialog.dart';
import 'todo_stats_card.dart';
import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';

/// 타임라인 상수: 1시간당 픽셀 높이
const double _hourHeight = AppLayout.timelineHourHeight;

/// 시간 라벨 컬럼 너비
const double _timeColumnWidth = AppLayout.timelineTimeColumnMd;

/// 최소 블록 높이 (15분 미만 이벤트)
const double _minBlockHeight = AppLayout.timelineMinBlockHeight;

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
    final scrollOffset = (now.hour * _hourHeight) - AppLayout.scheduleAutoScrollOffset;
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
    // P1-2: 태그 필터가 적용된 목록을 사용한다
    final todos = ref.watch(filteredTodosProvider);
    // 캘린더 이벤트를 투두 형태로 변환한 목록을 가져온다
    final calendarEvents = ref.watch(calendarEventsForTimelineProvider);
    // 루틴을 투두 형태로 변환한 목록을 가져온다
    final routineEvents = ref.watch(routinesForTimelineProvider);
    // 타이머 세션을 투두 형태로 변환한 목록을 가져온다
    final timerEvents = ref.watch(timerLogsForTimelineProvider);
    // 투두 + 캘린더 이벤트 + 루틴 + 타이머를 병합하여 타임라인에 표시한다
    final timedTodos = [
      ...todos.where((t) => t.time != null),
      ...calendarEvents.where((t) => t.time != null),
      ...routineEvents.where((t) => t.time != null),
      ...timerEvents.where((t) => t.time != null),
    ];

    // LayoutBuilder로 화면 너비에 따라 반응형으로 처리한다
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 좌측 통계 패널 너비: 전체의 30%, 최소 120px, 최대 160px
          final leftWidth =
              (constraints.maxWidth * AppLayout.scheduleStatsPanelRatio).clamp(AppLayout.scheduleStatsPanelMinWidth, AppLayout.scheduleStatsPanelMaxWidth);
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
            // 하단 여백: 23시를 스크롤 중앙에 배치하기 위한 공간
            padding: const EdgeInsets.only(bottom: AppLayout.timelineBottomPadding),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // 이벤트 배치에 사용할 가용 너비 (시간 라벨 제외)
                final availableWidth =
                    constraints.maxWidth - _timeColumnWidth - AppLayout.timelineGutter;

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
                      // 5. 이벤트 블록들 (최대 표시 개수까지만)
                      ...layouts
                          .where((l) => l.overlapIndex < AppLayout.timelineMaxVisibleOverlaps)
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
        alpha = AppLayout.densityAlphaLow;
      } else if (range.count == 2) {
        alpha = AppLayout.densityAlphaMedium;
      } else {
        alpha = AppLayout.densityAlphaHigh;
      }

      return Positioned(
        top: top,
        left: _timeColumnWidth + AppLayout.timelineGutter,
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
      if (layout.totalOverlaps > AppLayout.timelineMaxVisibleOverlaps && layout.overlapIndex == 0) {
        overflowGroups.add(layout);
      }
    }

    return overflowGroups.map((layout) {
      final extraCount = layout.totalOverlaps - AppLayout.timelineMaxVisibleOverlaps;
      return Positioned(
        top: layout.top + AppSpacing.xxs,
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
        _timeColumnWidth + AppLayout.timelineGutter + (availableWidth * layout.leftFraction);

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
                fontWeight: isCurrentHour ? AppTypography.weightSemiBold : AppTypography.weightRegular,
              ),
            ),
          ),
          // 구분선
          Expanded(
            child: Container(
              height: AppLayout.dividerHeight,
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
      top: top - AppLayout.timelineCurrentTimeOffset,
      left: _timeColumnWidth,
      right: 0,
      child: Row(
        children: [
          Container(
            width: AppSpacing.sm,
            height: AppSpacing.sm,
            decoration: BoxDecoration(
              color: ColorTokens.error,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Container(
              height: AppLayout.lineHeightMedium,
              color: ColorTokens.error.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

/// 겹침 인식 이벤트 블록 위젯 (읽기 전용)
/// 블록 높이와 겹침 상태에 따라 텍스트/스타일을 적응적으로 변경한다
/// 체크박스/토글 없이 탭 시 상세 보기만 제공한다
class _OverlapAwareBlock extends ConsumerWidget {
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

  /// 캘린더 출처 항목인지 확인한다 (id 접두사 'cal_')
  bool get _isCalendarEvent => todo.id.startsWith('cal_');

  /// 루틴 출처 항목인지 확인한다 (id 접두사 'routine_')
  bool get _isRoutineEvent => todo.id.startsWith('routine_');

  /// 타이머 세션 항목인지 확인한다 (id 접두사 'timer_')
  bool get _isTimerEvent => todo.id.startsWith('timer_');

  /// 항목 유형에 따른 아이콘을 반환한다 (일반 투두는 null)
  IconData? get _typeIcon {
    if (_isCalendarEvent) return Icons.event_rounded;
    if (_isRoutineEvent) return Icons.repeat_rounded;
    if (_isTimerEvent) return Icons.timer_rounded;
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 완료 상태는 Todo 모델의 isCompleted를 직접 사용한다 (읽기 전용)
    final isCompleted = todo.isCompleted;
    final color = ColorTokens.eventColor(todo.colorIndex);
    final effectiveHeight = max(blockHeight, _minBlockHeight);
    final isOverlapping = totalOverlaps > 1;

    // 겹침 위치에 따른 배경 불투명도 (뒤쪽이 낮고 앞쪽이 높다)
    final double bgAlpha;
    if (!isOverlapping) {
      bgAlpha = 0.15;
    } else {
      bgAlpha = 0.12 + (overlapIndex * 0.04);
    }

    // 2번째 이상 겹침 카드에 깊이감 그림자 추가
    final shadows = overlapIndex > 0
        ? [
            BoxShadow(
              color: ColorTokens.shadowBase.withValues(alpha: AppLayout.overlapShadowAlpha),
              blurRadius: AppLayout.overlapShadowBlur,
              offset: const Offset(-AppSpacing.xxs, AppLayout.borderThin),
            ),
          ]
        : <BoxShadow>[];

    // 완료 상태에 따른 불투명도 (완료 시 50% 투명도로 시각적 구분)
    final blockOpacity = isCompleted ? 0.5 : 1.0;

    // 좌측 컬러 바 너비: 4px 고정 (모던 타임라인 UI 패턴)
    const colorBarWidth = 4.0;

    return GestureDetector(
      onTap: () => _handleTap(context, ref),
      child: AnimatedOpacity(
        opacity: blockOpacity,
        duration: AppAnimation.slow,
        curve: Curves.easeInOut,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: color.withValues(alpha: bgAlpha),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: shadows,
          ),
          child: Row(
            children: [
              // 좌측 컬러 바: 이벤트 색상 100% 불투명도
              Container(
                width: colorBarWidth,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppRadius.lg),
                    bottomLeft: Radius.circular(AppRadius.lg),
                  ),
                ),
              ),
              // 콘텐츠 영역: 패딩 포함
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  child: _buildAdaptiveContent(context, effectiveHeight, isCompleted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 탭 시 유형별 상세 모달을 표시한다 (모든 유형 공통 바텀시트)
  void _handleTap(BuildContext context, WidgetRef ref) {
    _showDetailsModal(context, ref);
  }

  /// 유형 라벨을 반환한다 (투두/캘린더/루틴/타이머)
  String get _typeLabel {
    if (_isCalendarEvent) return '캘린더';
    if (_isRoutineEvent) return '루틴';
    if (_isTimerEvent) return '타이머';
    return '투두';
  }

  /// 편집 가능 여부를 반환한다 (투두, 캘린더만 편집 가능)
  bool get _isEditable => !_isRoutineEvent && !_isTimerEvent;

  /// 자동 생성 항목의 안내 메시지를 반환한다
  String? get _autoGeneratedMessage {
    if (_isRoutineEvent) return '자동 생성된 루틴입니다';
    if (_isTimerEvent) return '포모도로 타이머 기록입니다';
    return null;
  }

  /// 모든 유형에 공통으로 사용되는 상세 모달 바텀시트를 표시한다
  void _showDetailsModal(BuildContext context, WidgetRef ref) {
    final color = ColorTokens.eventColor(todo.colorIndex);
    final startStr = _formatTime(todo.startTime);
    final endStr = _formatTime(todo.endTime);
    final timeRangeStr = endStr != null ? '$startStr ~ $endStr' : (startStr ?? '');
    final durationStr = _formatDuration(todo.startTime, todo.endTime);

    showModalBottomSheet(
      context: context,
      backgroundColor: ColorTokens.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        decoration: BoxDecoration(
          color: context.themeColors.dialogSurface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.huge),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 컬러 바 + 타이틀 + 유형 뱃지
            Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    todo.title,
                    style: AppTypography.titleMd.copyWith(
                      color: context.themeColors.textPrimary,
                    ),
                  ),
                ),
                // 유형 뱃지
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                  ),
                  child: Text(
                    _typeLabel,
                    style: AppTypography.captionMd.copyWith(
                      color: color,
                      fontWeight: AppTypography.weightSemiBold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            // 시간 범위 정보
            if (timeRangeStr.isNotEmpty) ...[
              Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 16,
                    color: context.themeColors.textPrimaryWithAlpha(0.6),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    timeRangeStr,
                    style: AppTypography.bodyMd.copyWith(
                      color: context.themeColors.textPrimaryWithAlpha(0.8),
                    ),
                  ),
                  if (durationStr != null) ...[
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      '($durationStr)',
                      style: AppTypography.captionMd.copyWith(
                        color: context.themeColors.textPrimaryWithAlpha(0.5),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            // 메모가 있는 경우 표시
            if (todo.memo != null && todo.memo!.isNotEmpty) ...[
              Text(
                todo.memo!,
                style: AppTypography.bodyMd.copyWith(
                  color: context.themeColors.textPrimaryWithAlpha(0.7),
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            // 자동 생성 항목 안내 메시지 (루틴/타이머)
            if (_autoGeneratedMessage != null) ...[
              Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: context.themeColors.textPrimaryWithAlpha(0.5),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    _autoGeneratedMessage!,
                    style: AppTypography.captionMd.copyWith(
                      color: context.themeColors.textPrimaryWithAlpha(0.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            // 편집 버튼 (투두, 캘린더만)
            if (_isEditable) ...[
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () {
                    // 바텀시트를 먼저 닫고 편집 다이얼로그를 연다
                    Navigator.of(ctx).pop();
                    _openEditDialog(context, ref);
                  },
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: const Text('편집'),
                  style: TextButton.styleFrom(
                    foregroundColor: color,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.mdLg,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  /// 유형에 따른 편집 다이얼로그를 연다
  void _openEditDialog(BuildContext context, WidgetRef ref) {
    if (_isCalendarEvent) {
      // 캘린더 이벤트: cal_ 접두사를 제거하고 원본 이벤트를 조회한다
      final rawId = todo.id.replaceFirst('cal_', '');
      // 반복 인스턴스 ID 처리: {uuid}_{yyyymmdd} → 원본 uuid 추출
      String baseEventId = rawId;
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
    } else {
      // 일반 투두: 수정 다이얼로그를 열고 결과를 저장한다
      _openTodoEditDialog(context, ref);
    }
  }

  /// 투두 수정 다이얼로그를 열고 결과를 반영한다
  Future<void> _openTodoEditDialog(BuildContext context, WidgetRef ref) async {
    final result = await TodoCreateDialog.showEdit(
      context,
      existingTodo: todo,
    );
    if (result == null) return;

    // 선택된 태그 ID를 Tag 객체 정보가 포함된 Map 목록으로 변환한다
    final List<Map<String, dynamic>> tagMaps = result.tagIds.map((tagId) {
      final tag = ref.read(tagByIdProvider(tagId));
      if (tag == null) return null;
      return <String, dynamic>{
        'id': tag.id,
        'name': tag.name,
        'color_index': tag.colorIndex,
      };
    }).whereType<Map<String, dynamic>>().toList();

    final updateTodo = ref.read(updateTodoProvider);
    await updateTodo(
      todo.id,
      todo.copyWith(
        title: result.title,
        // P1-16: 다이얼로그에서 변경된 날짜를 반영한다
        date: result.date,
        startTime: result.startTime,
        clearStartTime: result.startTime == null,
        endTime: result.endTime,
        clearEndTime: result.endTime == null,
        color: result.colorIndex.toString(),
        memo: result.memo,
        clearMemo: result.memo == null,
        tags: tagMaps,
      ),
    );
  }

  /// 블록 높이에 따라 적응적 콘텐츠를 생성한다
  ///
  /// | 높이       | 내용                                         |
  /// |------------|----------------------------------------------|
  /// | >= 60px    | 유형 아이콘 + 제목 1줄 + "09:00 ~ 10:30" + 소요시간 |
  /// | 40~59px    | 유형 아이콘 + 제목 1줄 (시간은 위치에서 확인)    |
  /// | 30~39px    | 제목 1줄 (툴팁으로 전체 정보)                  |
  /// | < 30px     | 축약 제목 (툴팁)                              |
  Widget _buildAdaptiveContent(
    BuildContext context,
    double height,
    bool isCompleted,
  ) {
    final isOverlapping = totalOverlaps > 1;
    final titleStyle = isOverlapping
        ? AppTypography.captionMd
        : AppTypography.bodyMd;

    final textColor = isCompleted
        ? context.themeColors.textPrimaryWithAlpha(0.5)
        : context.themeColors.textPrimary;
    // 취소선은 AnimatedStrikethrough 위젯이 외부에서 처리하므로 텍스트에 적용하지 않는다
    final typeIcon = _typeIcon;

    // 시간 문자열 생성 ("09:00 ~ 10:30" 형식)
    final startStr = _formatTime(todo.startTime);
    final endStr = _formatTime(todo.endTime);
    final timeRangeStr = endStr != null ? '$startStr ~ $endStr' : startStr;
    final durationStr = _formatDuration(todo.startTime, todo.endTime);

    if (height >= AppLayout.eventBlockLargeThreshold) {
      // 큰 블록 (1시간 이상): 제목 + 시간 범위 + 소요시간
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 유형 아이콘 + 제목
          Row(
            children: [
              if (typeIcon != null) ...[
                Icon(
                  typeIcon,
                  size: 12,
                  color: context.themeColors.textPrimaryWithAlpha(0.5),
                ),
                const SizedBox(width: AppSpacing.xxs),
              ],
              Expanded(
                child: Text(
                  todo.title,
                  style: titleStyle.copyWith(
                    color: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          // 시간 범위
          if (timeRangeStr != null) ...[
            const SizedBox(height: AppSpacing.xxs),
            Row(
              children: [
                Text(
                  timeRangeStr,
                  style: AppTypography.captionSm.copyWith(
                    color: context.themeColors.textPrimaryWithAlpha(0.6),
                  ),
                  maxLines: 1,
                ),
                // 소요시간 (공간이 있을 때만)
                if (durationStr != null && !isOverlapping) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    durationStr,
                    style: AppTypography.captionSm.copyWith(
                      color: context.themeColors.textPrimaryWithAlpha(0.4),
                    ),
                    maxLines: 1,
                  ),
                ],
              ],
            ),
          ],
        ],
      );
    } else if (height >= AppLayout.eventBlockMediumThreshold) {
      // 중간 블록 (40~59px): 유형 아이콘 + 제목만 (시간은 타임라인 위치로 확인)
      return Row(
        children: [
          if (typeIcon != null) ...[
            Icon(
              typeIcon,
              size: 12,
              color: context.themeColors.textPrimaryWithAlpha(0.5),
            ),
            const SizedBox(width: AppSpacing.xxs),
          ],
          Expanded(
            child: Text(
              todo.title,
              style: titleStyle.copyWith(
                color: textColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    } else if (height >= AppLayout.eventBlockSmallThreshold) {
      // 작은 블록 (30~39px): 제목만 + 툴팁
      return Tooltip(
        message: '${todo.title} ($timeRangeStr)',
        child: Text(
          todo.title,
          style: (isOverlapping ? AppTypography.captionSm : AppTypography.captionMd).copyWith(
            color: textColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    } else {
      // 매우 작은 블록: 축약 제목 + 툴팁
      final shortTitle = todo.title.length > AppLayout.eventBlockTruncateLength
          ? '${todo.title.substring(0, AppLayout.eventBlockTruncateLength)}...'
          : todo.title;
      return Tooltip(
        message: '${todo.title} ($timeRangeStr)',
        child: Text(
          shortTitle,
          style: AppTypography.captionSm.copyWith(
            color: textColor,
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

  /// 시작~종료 시간의 소요시간을 한글 문자열로 반환한다
  /// 예: "1시간 30분", "45분"
  String? _formatDuration(TimeOfDay? start, TimeOfDay? end) {
    if (start == null || end == null) return null;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    final diff = endMinutes - startMinutes;
    if (diff <= 0) return null;
    final hours = diff ~/ 60;
    final minutes = diff % 60;
    if (hours > 0 && minutes > 0) return '$hours시간 $minutes분';
    if (hours > 0) return '$hours시간';
    return '$minutes분';
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
              color: ColorTokens.main.withValues(alpha: AppLayout.badgeShadowAlpha),
              blurRadius: AppLayout.overlapShadowBlur,
              offset: const Offset(0, AppSpacing.xxs),
            ),
          ],
        ),
        child: Text(
          '+$count',
          style: AppTypography.captionLg.copyWith(
            // MAIN 컬러 배경(#7C3AED) 위이므로 항상 흰색이 적절하다
            color: ColorTokens.white,
            fontWeight: AppTypography.weightSemiBold,
          ),
        ),
      ),
    );
  }

  /// 겹친 이벤트 전체 목록을 바텀시트로 표시한다
  void _showOverflowSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: ColorTokens.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        decoration: BoxDecoration(
          // 다이얼로그 서피스 색상을 사용하여 텍스트 가시성을 보장한다
          color: context.themeColors.dialogSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.huge)),
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
                    left: BorderSide(color: color, width: AppSpacing.xxs),
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
