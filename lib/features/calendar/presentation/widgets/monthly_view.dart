// F2 위젯: MonthlyView - 월간 캘린더 그리드
// table_calendar 패키지 기반. 일정 있는 날짜에 컬러 dot을 표시한다.
// 날짜 탭 시 selectedCalendarDateProvider 업데이트
// F17: Google Calendar 이벤트도 dot 표시에 포함한다
// Task 9: 드래그 핸들로 캘린더/리스트 비율 조절 지원
// Task 10: 루틴 카드 탭 시 편집 다이얼로그 열기
// Task 11: 루틴 카드에 완료 체크박스 추가
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/calendar_sync/calendar_sync_provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/global_providers.dart';
import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../shared/models/habit.dart';
import '../../../../shared/widgets/bottom_scroll_spacer.dart';
import '../../providers/calendar_provider.dart';
import '../../providers/event_provider.dart';
import '../../../habit/presentation/widgets/routine_edit_dialog.dart';
import '../../../habit/providers/habit_provider.dart';
import '../../../habit/providers/routine_log_provider.dart';
import '../../../habit/providers/routine_provider.dart';
import '../../../todo/providers/todo_provider.dart';
import 'event_card.dart';
import '../utils/event_dialog_utils.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../shared/widgets/animated_strikethrough.dart';

/// 월간 캘린더 뷰
class MonthlyView extends ConsumerStatefulWidget {
  const MonthlyView({super.key});

  @override
  ConsumerState<MonthlyView> createState() => _MonthlyViewState();
}

class _MonthlyViewState extends ConsumerState<MonthlyView> {
  /// 캘린더/리스트 비율 (0.3~0.7, 기본 0.5)
  double _calendarRatio = 0.5;

  /// 초기 비율 로드 완료 여부
  bool _ratioLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 최초 1회만 Hive에서 저장된 비율을 로드한다
    if (!_ratioLoaded) {
      final cache = ref.read(hiveCacheServiceProvider);
      _calendarRatio = cache.readSetting<double>(
            AppConstants.settingsKeyCalendarRatio,
          ) ??
          0.5;
      _ratioLoaded = true;
    }
  }

  /// 이벤트 편집 다이얼로그를 열고, 저장 후 목록을 갱신한다
  void _openEditDialog(BuildContext context, CalendarEvent calendarEvent) {
    // 투두/Google 이벤트는 편집 대상이 아니다
    if (calendarEvent.isTodoEvent || calendarEvent.isGoogleEvent) return;

    // 반복 이벤트 인스턴스 ID에서 원본 ID를 추출한다
    String baseEventId = calendarEvent.id;
    if (baseEventId.length > 36 && baseEventId.contains('_')) {
      final lastUnderscoreIdx = baseEventId.lastIndexOf('_');
      final candidate = baseEventId.substring(0, lastUnderscoreIdx);
      if (candidate.length == 36) {
        baseEventId = candidate;
      }
    }

    // Hive에서 원본 Event를 조회한다
    final repository = ref.read(eventRepositoryProvider);
    final event = repository.getEventById(baseEventId);
    if (event == null) return;

    showEventEditDialog(context: context, ref: ref, event: event);
  }

  /// 루틴 카드 탭 시 원본 Routine을 조회하여 편집 다이얼로그를 연다
  void _openRoutineEditDialog(RoutineEntry entry) {
    final routineRepo = ref.read(routineRepositoryProvider);
    final routines = routineRepo.getRoutines();
    final routine = routines.where((r) => r.id == entry.id).firstOrNull;
    if (routine == null) return;

    showRoutineEditDialog(context: context, ref: ref, routine: routine);
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedCalendarDateProvider);
    final focusedMonth = ref.watch(focusedCalendarMonthProvider);
    // F17: 앱 이벤트 + Google Calendar 이벤트를 병합한 날짜 맵 사용
    final eventsByDate = ref.watch(mergedEventsByDateMapProvider);
    // F17: 선택된 날짜의 이벤트도 병합된 Provider 사용
    final selectedDayEvents = ref.watch(mergedEventsForDayProvider);
    // 선택된 날짜의 루틴 목록 (활성 루틴 중 해당 요일) — 동기 Provider이므로 직접 사용한다
    final routines = ref.watch(routinesForDayProvider);
    // 선택된 날짜의 습관 체크리스트 데이터
    final habitsForDay = ref.watch(habitsForDayProvider);

    // 캘린더/리스트 flex 비율 계산
    final calendarFlex = (_calendarRatio * 100).round();
    final listFlex = ((1 - _calendarRatio) * 100).round();

    final hasContent = selectedDayEvents.isNotEmpty ||
        routines.isNotEmpty ||
        habitsForDay.isNotEmpty;

    return Column(
      children: [
        // table_calendar 그리드
        Flexible(
          flex: calendarFlex,
          child: TableCalendar(
            // 한국어 로케일로 요일/월 이름을 표시한다
            locale: 'ko_KR',
            firstDay: DateTime(2020, 1, 1),
            lastDay: DateTime(2035, 12, 31),
            focusedDay: focusedMonth,
            selectedDayPredicate: (day) => isSameDay(day, selectedDate),
            // 날짜 탭 시 선택 날짜 + 포커스 월 업데이트
            onDaySelected: (selected, focused) {
              ref.read(selectedCalendarDateProvider.notifier).state =
                  DateTime(selected.year, selected.month, selected.day);
              ref.read(focusedCalendarMonthProvider.notifier).state = focused;
            },
            onPageChanged: (focused) {
              ref.read(focusedCalendarMonthProvider.notifier).state = focused;
            },
            // 헤더 스타일: 글래스 텍스트
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: AppTypography.titleLg
                  .copyWith(color: context.themeColors.textPrimary),
              leftChevronIcon: Icon(
                Icons.chevron_left_rounded,
                color: context.themeColors.textPrimaryWithAlpha(0.70),
              ),
              rightChevronIcon: Icon(
                Icons.chevron_right_rounded,
                color: context.themeColors.textPrimaryWithAlpha(0.70),
              ),
            ),
            // 요일 헤더 스타일
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: AppTypography.captionLg.copyWith(
                color: context.themeColors.textPrimaryWithAlpha(0.60),
              ),
              // WCAG 최소 대비: 주말 요일 텍스트 0.55 이상 보장
              weekendStyle: AppTypography.captionLg.copyWith(
                color: context.themeColors.textPrimaryWithAlpha(0.55),
              ),
            ),
            // 날짜 셀 스타일
            calendarStyle: CalendarStyle(
              defaultTextStyle: AppTypography.bodyMd
                  .copyWith(color: context.themeColors.textPrimary),
              weekendTextStyle: AppTypography.bodyMd.copyWith(
                color: context.themeColors.textPrimaryWithAlpha(0.80),
              ),
              selectedDecoration: BoxDecoration(
                color: context.themeColors.accent,
                shape: BoxShape.circle,
              ),
              selectedTextStyle: AppTypography.bodyMd.copyWith(
                color: context.themeColors.textPrimary,
                fontWeight: AppTypography.weightBold,
              ),
              todayDecoration: BoxDecoration(
                color: context.themeColors.textPrimaryWithAlpha(0.25),
                shape: BoxShape.circle,
              ),
              todayTextStyle: AppTypography.bodyMd.copyWith(
                color: context.themeColors.textPrimary,
                fontWeight: AppTypography.weightBold,
              ),
              outsideTextStyle: AppTypography.bodyMd.copyWith(
                color: context.themeColors.textPrimaryWithAlpha(0.55),
              ),
              markersMaxCount: 3,
              markerDecoration: BoxDecoration(
                color: context.themeColors.textPrimaryWithAlpha(0.70),
                shape: BoxShape.circle,
              ),
              markerSize: AppLayout.calendarMarkerSize,
              markerMargin: const EdgeInsets.only(top: AppSpacing.xxs),
            ),
            // 이벤트 dot: 해당 날짜에 이벤트가 있으면 dot 표시
            eventLoader: (day) {
              final key = AppDateUtils.toDateString(day);
              return eventsByDate.containsKey(key) ? [Object()] : [];
            },
          ),
        ),

        // 드래그 핸들: 캘린더와 이벤트 목록 사이의 리사이즈 핸들
        GestureDetector(
          onVerticalDragUpdate: (details) {
            final screenHeight = MediaQuery.of(context).size.height;
            final delta = details.primaryDelta! / screenHeight;
            setState(() {
              _calendarRatio = (_calendarRatio + delta).clamp(0.3, 0.7);
            });
          },
          onVerticalDragEnd: (_) {
            // 변경된 비율을 Hive에 저장한다
            ref.read(hiveCacheServiceProvider).saveSetting(
                  AppConstants.settingsKeyCalendarRatio,
                  _calendarRatio,
                );
          },
          child: Container(
            height: 24,
            alignment: Alignment.center,
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.themeColors.textPrimaryWithAlpha(0.25),
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
            ),
          ),
        ),

        // 선택된 날짜의 이벤트 + 루틴 + 습관 목록
        if (hasContent)
          Flexible(
            flex: listFlex,
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xxl,
                AppSpacing.lg,
                AppSpacing.xxl,
                BottomScrollSpacer.height(context),
              ),
              children: [
                // 이벤트 카드 목록
                ...selectedDayEvents.map((event) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: EventCard(
                        event: event,
                        onTap: () => _openEditDialog(context, event),
                        onToggleTodo: event.isTodoEvent
                            ? (isCompleted) {
                                final todoId =
                                    event.id.replaceFirst('todo_', '');
                                ref.read(toggleTodoProvider)(
                                    todoId, isCompleted);
                              }
                            : null,
                      ),
                    )),

                // 루틴 카드 목록 (이벤트 아래에 표시)
                if (routines.isNotEmpty) ...[
                  if (selectedDayEvents.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(
                          top: AppSpacing.sm, bottom: AppSpacing.md),
                      child: Text(
                        '루틴',
                        style: AppTypography.captionLg.copyWith(
                          color:
                              context.themeColors.textPrimaryWithAlpha(0.60),
                        ),
                      ),
                    ),
                  ...routines.map((routine) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: GestureDetector(
                          onTap: () => _openRoutineEditDialog(routine),
                          child: _RoutineInfoCard(
                            routine: routine,
                            selectedDate: selectedDate,
                          ),
                        ),
                      )),
                ],

                // 습관 체크리스트 섹션 (루틴 아래에 표시)
                if (habitsForDay.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(
                        top: AppSpacing.sm, bottom: AppSpacing.md),
                    child: Text(
                      '오늘의 습관',
                      style: AppTypography.captionLg.copyWith(
                        color:
                            context.themeColors.textPrimaryWithAlpha(0.60),
                        fontWeight: AppTypography.weightSemiBold,
                      ),
                    ),
                  ),
                  ...habitsForDay.map((entry) => _HabitCheckItem(
                        habit: entry.habit,
                        isCompleted: entry.isCompleted,
                        onToggle: () {
                          ref.read(toggleHabitProvider)(
                            entry.habit.id,
                            selectedDate,
                            !entry.isCompleted,
                          );
                        },
                      )),
                ],
              ],
            ),
          )
        else
          Flexible(
            flex: listFlex,
            child: Center(
              child: Text(
                '일정이 없습니다',
                // WCAG 최소 대비: 빈 상태 텍스트도 0.55 이상 보장
                style: AppTypography.bodyMd.copyWith(
                  color: context.themeColors.textPrimaryWithAlpha(0.55),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// 루틴 정보 카드 (월간 뷰의 선택된 날짜 목록에서 사용)
/// 루틴 이름 + 시간 범위 + 완료 체크박스를 표시한다
/// CheckItem 위젯과 동일한 빨간색 취소선 + scale bounce 동작을 적용한다
class _RoutineInfoCard extends ConsumerStatefulWidget {
  final RoutineEntry routine;
  final DateTime selectedDate;

  const _RoutineInfoCard({
    required this.routine,
    required this.selectedDate,
  });

  @override
  ConsumerState<_RoutineInfoCard> createState() => _RoutineInfoCardState();
}

class _RoutineInfoCardState extends ConsumerState<_RoutineInfoCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceController;
  late final Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    // 스케일 바운스: CheckItem 패턴과 동일한 TweenSequence (500ms)
    _bounceController = AnimationController(
      duration: AppAnimation.slow,
      vsync: this,
    );
    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.95), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.02), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.02, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  /// 체크박스 토글: bounce 애니메이션 후 상태 변경
  void _handleToggle(bool isCompleted) {
    // Reduced Motion 확인: 접근성 설정 시 바운스 생략
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (!reduceMotion) {
      _bounceController.forward(from: 0.0);
    }
    ref.read(toggleRoutineLogProvider)(
      widget.routine.id,
      widget.selectedDate,
      !isCompleted,
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = ColorTokens.eventColor(widget.routine.colorIndex);
    final startStr =
        '${widget.routine.startHour.toString().padLeft(2, '0')}:${widget.routine.startMinute.toString().padLeft(2, '0')}';
    final endStr =
        '${widget.routine.endHour.toString().padLeft(2, '0')}:${widget.routine.endMinute.toString().padLeft(2, '0')}';

    // 루틴 완료 상태를 Provider에서 읽는다
    final isCompleted = ref.watch(
      routineCompletionProvider(
          (routineId: widget.routine.id, date: widget.selectedDate)),
    );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border(
          left: BorderSide(color: color, width: AppSpacing.xxs),
        ),
      ),
      child: ScaleTransition(
        scale: _bounceAnimation,
        child: Row(
        children: [
          // 완료 체크박스 (빨간색 스타일 + scale bounce)
          GestureDetector(
            onTap: () => _handleToggle(isCompleted),
            child: AnimatedContainer(
              duration: AppAnimation.slow,
              curve: Curves.easeInOut,
              width: AppLayout.iconMd,
              height: AppLayout.iconMd,
              decoration: BoxDecoration(
                color: isCompleted
                    ? ColorTokens.error.withValues(alpha: 0.20)
                    : ColorTokens.transparent,
                borderRadius: BorderRadius.circular(AppRadius.xs),
                border: Border.all(
                  color: isCompleted
                      ? ColorTokens.error
                      : context.themeColors.textPrimaryWithAlpha(0.3),
                  width: AppLayout.borderMedium,
                ),
              ),
              // 체크 아이콘: 조건부 렌더링 대신 AnimatedOpacity로 부드럽게 전환
              child: AnimatedOpacity(
                opacity: isCompleted ? 1.0 : 0.0,
                duration: AppAnimation.slow,
                curve: Curves.easeInOut,
                child: Icon(Icons.check,
                    size: AppLayout.iconSm,
                    color: ColorTokens.error),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Icon(
            Icons.repeat_rounded,
            color: context.themeColors.textPrimaryWithAlpha(0.60),
            size: AppLayout.iconMd,
          ),
          const SizedBox(width: AppSpacing.md),
          // 루틴 이름 (완료 시 opacity 0.50 + 빨간펜 취소선 애니메이션)
          Expanded(
            child: AnimatedOpacity(
              opacity: isCompleted ? 0.50 : 1.0,
              duration: AppAnimation.textFade,
              curve: Curves.easeInOut,
              child: AnimatedStrikethrough(
                text: widget.routine.name,
                style: AppTypography.bodyMd.copyWith(
                  color: context.themeColors.textPrimary,
                ),
                isActive: isCompleted,
              ),
            ),
          ),
          Text(
            '$startStr - $endStr',
            style: AppTypography.captionMd.copyWith(
              color: context.themeColors.textPrimaryWithAlpha(0.55),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

/// 습관 체크 아이템 위젯 (월간 뷰의 선택된 날짜 목록에서 사용)
/// 스케일 바운스 애니메이션으로 탭 피드백을 제공한다
class _HabitCheckItem extends StatefulWidget {
  final Habit habit;
  final bool isCompleted;
  final VoidCallback onToggle;

  const _HabitCheckItem({
    required this.habit,
    required this.isCompleted,
    required this.onToggle,
  });

  @override
  State<_HabitCheckItem> createState() => _HabitCheckItemState();
}

class _HabitCheckItemState extends State<_HabitCheckItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceController;
  late final Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    // 스케일 바운스: CheckItem 패턴과 동일한 TweenSequence (500ms)
    _bounceController = AnimationController(
      duration: AppAnimation.slow,
      vsync: this,
    );
    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.95), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.02), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.02, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Reduced Motion 확인: 접근성 설정 시 바운스 생략
        final reduceMotion = MediaQuery.disableAnimationsOf(context);
        if (!reduceMotion) {
          _bounceController.forward(from: 0.0);
        }
        widget.onToggle();
      },
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _bounceAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
          child: Row(
            children: [
              // 체크박스 (CheckItem과 동일한 애니메이션 파라미터)
              AnimatedContainer(
                duration: AppAnimation.slow,
                curve: Curves.easeInOut,
                width: AppLayout.iconMd,
                height: AppLayout.iconMd,
                decoration: BoxDecoration(
                  color: widget.isCompleted
                      ? context.themeColors.accent
                      : ColorTokens.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                  border: Border.all(
                    color: widget.isCompleted
                        ? context.themeColors.accent
                        : context.themeColors.textPrimaryWithAlpha(0.3),
                    width: AppLayout.borderMedium,
                  ),
                ),
                // 체크 아이콘: 조건부 렌더링 대신 AnimatedOpacity로 부드럽게 전환
                child: AnimatedOpacity(
                  opacity: widget.isCompleted ? 1.0 : 0.0,
                  duration: AppAnimation.slow,
                  curve: Curves.easeInOut,
                  child: Icon(
                    Icons.check,
                    size: AppLayout.iconSm,
                    color: context.themeColors.dialogSurface,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // 습관 아이콘
              if (widget.habit.icon != null)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: Text(widget.habit.icon!, style: AppTypography.bodyMd),
                ),
              // 습관 이름 (완료 시 빨간펜 취소선 애니메이션 + 행 전체 투명도 적용)
              Expanded(
                child: AnimatedOpacity(
                  opacity: widget.isCompleted ? 0.50 : 1.0,
                  duration: AppAnimation.textFade,
                  curve: Curves.easeInOut,
                  child: AnimatedStrikethrough(
                    text: widget.habit.name,
                    style: AppTypography.bodySm.copyWith(
                      color: context.themeColors.textPrimary,
                    ),
                    isActive: widget.isCompleted,
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
