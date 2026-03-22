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
import '../../../../shared/models/habit.dart';
import '../../providers/event_provider.dart';
import '../../providers/calendar_provider.dart';
import '../../../habit/providers/habit_provider.dart';
import '../../../habit/providers/routine_log_provider.dart';
import '../../../todo/providers/todo_provider.dart';
import 'event_card.dart';
import '../utils/event_dialog_utils.dart';
import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../shared/widgets/animated_checkbox.dart';
import '../../../../shared/widgets/animated_strikethrough.dart';

/// 일간 타임라인 뷰
class DailyView extends ConsumerStatefulWidget {
  const DailyView({super.key});

  @override
  ConsumerState<DailyView> createState() => _DailyViewState();
}

class _DailyViewState extends ConsumerState<DailyView>
    with TickerProviderStateMixin {
  // 1시간당 픽셀 높이 (24시간 * 60px = 1440px)
  static const double _hourHeight = AppLayout.timelineHourHeight;
  static const double _timeColumnWidth = AppLayout.timelineTimeColumnLg;

  late final ScrollController _scrollController;

  /// 현재 시간 빨간 점 펄스 애니메이션 컨트롤러
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
    _pulseAnimation = Tween<double>(begin: 1.0, end: AppAnimation.bounceScale).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // 현재 시간으로 자동 스크롤
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentTime();
    });
  }

  void _scrollToCurrentTime() {
    final now = DateTime.now();
    final scrollOffset = (now.hour * _hourHeight) - AppLayout.dailyScrollOffset;
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
    _pulseController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedCalendarDateProvider);
    // F17: 앱 이벤트 + Google Calendar 이벤트 + 타이머 세션이 병합된 Provider를 사용한다
    final events = ref.watch(mergedEventsForDayProvider);
    // routinesForDayProvider는 동기 Provider이므로 직접 사용한다
    final routines = ref.watch(routinesForDayProvider);
    // 오늘의 습관 체크리스트 데이터
    final habitsForDay = ref.watch(habitsForDayProvider);

    final now = DateTime.now();
    final isToday = now.year == selectedDate.year &&
        now.month == selectedDate.month &&
        now.day == selectedDate.day;

    // 종일 이벤트와 시간 이벤트를 분리한다
    final allDayEvents = events.where((e) => e.isAllDay).toList();
    final timedEvents = events.where((e) => !e.isAllDay).toList();

    return Column(
      children: [
        // 종일 이벤트 섹션 (상단에 표시, 스태거드 페이드 인)
        if (allDayEvents.isNotEmpty)
          AnimatedSwitcher(
            duration: AppAnimation.normal,
            child: Container(
              key: ValueKey('allday_${allDayEvents.length}'),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xxl,
                vertical: AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: allDayEvents.map((e) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: EventCard(
                      event: e,
                      onTap: () => _openEditDialog(e),
                      onToggleTodo: e.isTodoEvent
                          ? (isCompleted) {
                              // 'todo_' 접두사를 제거하여 원본 투두 ID를 추출한다
                              final todoId = e.id.replaceFirst('todo_', '');
                              ref.read(toggleTodoProvider)(todoId, isCompleted);
                            }
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        // 습관 체크리스트 섹션 (종일 이벤트와 타임라인 사이에 표시)
        if (habitsForDay.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xxl,
              vertical: AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '오늘의 습관',
                  style: AppTypography.captionLg.copyWith(
                    color: context.themeColors.textPrimaryWithAlpha(0.6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                ...habitsForDay.map((entry) => _buildHabitCheckItem(
                  context, entry.habit, entry.isCompleted,
                )),
                Divider(
                  color: context.themeColors.textPrimaryWithAlpha(0.12),
                  height: 1,
                ),
              ],
            ),
          ),

        // 타임라인 영역
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            // 하단 여백: 23시를 스크롤 중앙에 배치 + 네비게이션 바 영역 포함
            padding: const EdgeInsets.only(bottom: AppLayout.timelineBottomPadding),
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

                        // 이벤트 블록 (시간이 있는 이벤트만)
                        ...timedEvents
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
          ),
        ),
      ],
    );
  }

  /// 습관 체크 아이템 위젯 (일간 뷰 종일 영역)
  /// AnimatedCheckbox를 사용하여 스케일 바운스를 적용한다
  Widget _buildHabitCheckItem(
    BuildContext context,
    Habit habit,
    bool isCompleted,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        children: [
          // 체크박스 (AnimatedCheckbox: 스케일 바운스 + 색상 전환 포함)
          AnimatedCheckbox(
            isCompleted: isCompleted,
            size: AppLayout.iconMd,
            onTap: () {
              final selectedDate = ref.read(selectedCalendarDateProvider);
              ref.read(toggleHabitProvider)(
                  habit.id, selectedDate, !isCompleted);
            },
          ),
          const SizedBox(width: AppSpacing.sm),
          // 습관 아이콘
          if (habit.icon != null)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: Text(habit.icon!, style: AppTypography.bodyMd),
            ),
          // 습관 이름 (완료 시 빨간펜 취소선 애니메이션 + 행 전체 투명도 적용)
          Expanded(
            child: AnimatedOpacity(
              opacity: isCompleted ? 0.50 : 1.0,
              duration: AppAnimation.textFade,
              curve: Curves.easeInOut,
              child: AnimatedStrikethrough(
                text: habit.name,
                style: AppTypography.bodySm.copyWith(
                  color: context.themeColors.textPrimary,
                ),
                isActive: isCompleted,
              ),
            ),
          ),
        ],
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
            top: hour * _hourHeight - AppLayout.dailyTimeLabelOffset,
            left: 0,
            right: 0,
            child: Text(
              '${hour.toString().padLeft(2, '0')}:00',
              style: AppTypography.captionMd.copyWith(
                // WCAG: 시간 레이블 텍스트 알파 0.55 이상으로 가독성 보장
                color: context.themeColors.textPrimaryWithAlpha(0.55),
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
                color: context.themeColors.textPrimaryWithAlpha(0.16),
                width: AppLayout.borderThin,
              ),
            ),
          ),
        );
      }),
    );
  }

  /// 현재 시간 빨간 가로선 (AC-CL-03)
  /// 빨간 원형 점에 펄스 스케일 애니메이션을 적용한다
  Widget _buildCurrentTimeLine(DateTime now) {
    final topOffset =
        now.hour * _hourHeight + now.minute * (_hourHeight / 60);
    // 접근성: 모션 축소 설정 시 펄스 정지
    final disableMotion = MediaQuery.disableAnimationsOf(context);
    return Positioned(
      top: topOffset,
      left: 0,
      right: 0,
      child: Row(
        children: [
          // 빨간 원형 점 — 펄스 스케일 애니메이션
          disableMotion
              ? Container(
                  width: AppSpacing.md,
                  height: AppSpacing.md,
                  decoration: const BoxDecoration(
                    color: ColorTokens.error,
                    shape: BoxShape.circle,
                  ),
                )
              : ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    width: AppSpacing.md,
                    height: AppSpacing.md,
                    decoration: const BoxDecoration(
                      color: ColorTokens.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
          Expanded(
            child: Container(
              height: AppLayout.lineHeightMedium,
              color: ColorTokens.error,
            ),
          ),
        ],
      ),
    );
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

  /// 투두 이벤트 전용 색상 (보라 배경에서 잘 보이는 밝은 틸 계열)
  static const Color _todoCardColor = ColorTokens.todoCard;
  /// 타이머 세션 블록 전용 색상 (에메랄드 그린)
  static const Color _timerSessionColor = ColorTokens.timerSession;

  /// 이벤트 블록 (시간 위치에 배치)
  /// AnimatedContainer로 완료 상태 변경 시 색상 부드럽게 전환
  /// _AnimatedStrikethrough로 취소선 좌→우 / 우→좌 애니메이션 적용
  Widget _buildEventBlock(CalendarEvent event) {
    final startMin = (event.startHour ?? 0) * 60 + (event.startMinute ?? 0);
    final endMin = event.endHour != null
        ? event.endHour! * 60 + (event.endMinute ?? 0)
        : startMin + 60;
    final duration = endMin - startMin;

    final top = startMin * (_hourHeight / 60);
    final height = (duration * _hourHeight / 60).clamp(AppLayout.dailyEventMinHeight, double.infinity);
    // 타이머 세션은 에메랄드 그린, 투두는 스카이블루, 일반은 기존 색상
    final isTimerEvent = event.source == 'timer';
    final blockColor = isTimerEvent
        ? _timerSessionColor
        : event.isTodoEvent
            ? _todoCardColor
            : ColorTokens.eventColor(event.colorIndex);
    final isCompleted = event.isTodoCompleted;

    return Positioned(
      top: top,
      left: AppSpacing.xs,
      right: AppSpacing.xs,
      child: GestureDetector(
        onTap: () {
          // 투두 이벤트: 블록 탭으로 완료 토글
          if (event.isTodoEvent) {
            final todoId = event.id.replaceFirst('todo_', '');
            ref.read(toggleTodoProvider)(todoId, !isCompleted);
            return;
          }
          _openEditDialog(event);
        },
        // AnimatedContainer: 완료 토글 시 배경/테두리 색상 부드럽게 전환 (400ms)
        child: AnimatedContainer(
          duration: AppAnimation.slower,
          curve: Curves.easeInOut,
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            color: blockColor.withValues(alpha: 0.38),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: blockColor.withValues(alpha: 0.65),
              width: AppLayout.borderThin,
            ),
          ),
          // 투두 이벤트: 체크박스 + 취소선 표시
          child: Row(
            children: [
              if (event.isTodoEvent)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: _buildMiniCheckbox(isCompleted),
                ),
              Expanded(
                // 공용 AnimatedStrikethrough로 취소선 애니메이션 적용
                child: AnimatedStrikethrough(
                  text: event.title,
                  style: AppTypography.bodyMd.copyWith(
                    color: context.themeColors.textPrimary,
                  ),
                  isActive: isCompleted,
                  maxLines: height > AppLayout.dailyEventMultiLineThreshold ? 2 : 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 타임라인 블록 내부 미니 체크박스 (16x16, CheckItem 스타일)
  /// AnimatedCheckbox를 사용하여 스케일 바운스를 적용한다
  /// 탭 이벤트는 부모 GestureDetector에서 처리하므로 onTap은 null이다
  Widget _buildMiniCheckbox(bool isCompleted) {
    return AnimatedCheckbox(
      isCompleted: isCompleted,
      size: AppLayout.iconMd,
    );
  }

  /// 루틴 블록 (이벤트와 동일한 타임라인에 표시)
  /// 루틴 완료 상태에 따라 체크박스 + 취소선 + 반투명 효과를 적용한다
  Widget _buildRoutineBlock(RoutineEntry routine) {
    final selectedDate = ref.watch(selectedCalendarDateProvider);
    // 루틴 완료 상태를 Provider에서 감시한다
    final isCompleted = ref.watch(routineCompletionProvider(
      (routineId: routine.id, date: selectedDate),
    ));

    final startMin = routine.startHour * 60 + routine.startMinute;
    final endMin = routine.endHour * 60 + routine.endMinute;
    // 자정을 넘는 루틴(예: 22:00~01:00)은 자정까지만 표시한다
    final effectiveEndMin = endMin <= startMin ? 24 * 60 : endMin;
    final duration = effectiveEndMin - startMin;

    final top = startMin * (_hourHeight / 60);
    final height = (duration * _hourHeight / 60).clamp(AppLayout.dailyEventMinHeight, double.infinity);
    final routineColor = ColorTokens.eventColor(routine.colorIndex);

    return Positioned(
      top: top,
      right: AppSpacing.xs,
      width: AppLayout.dailyRoutineColumnWidth,
      child: GestureDetector(
        onTap: () {
          // 루틴 완료 토글
          ref.read(toggleRoutineLogProvider)(
            routine.id,
            selectedDate,
            !isCompleted,
          );
        },
        // 완료 시 배경/테두리 색상 부드럽게 전환
        child: AnimatedContainer(
          duration: AppAnimation.slower,
          curve: Curves.easeInOut,
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            color: routineColor.withValues(alpha: isCompleted ? 0.12 : 0.25),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: routineColor.withValues(alpha: isCompleted ? 0.25 : 0.45),
              width: AppLayout.borderThin,
            ),
          ),
          child: Row(
            children: [
              // 루틴 미니 체크박스
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.xxs),
                child: _buildMiniCheckbox(isCompleted),
              ),
              Expanded(
                child: AnimatedOpacity(
                  opacity: isCompleted ? 0.50 : 1.0,
                  duration: AppAnimation.textFade,
                  curve: Curves.easeInOut,
                  child: AnimatedStrikethrough(
                    text: routine.name,
                    style: AppTypography.captionMd.copyWith(
                      color: routineColor.withValues(alpha: 0.80),
                    ),
                    isActive: isCompleted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

