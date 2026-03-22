// F3 위젯: TodoListView - 할 일 목록 (체크리스트)
// 시간 미지정 투두를 체크리스트 형태로 표시한다.
// 상단에 오늘의 이벤트/루틴/타이머 세션 수를 요약 표시한다.
// 빈 상태: "오늘 일정이 없습니다. 새로운 일정을 추가해보세요!"
import 'package:flutter/material.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/todo.dart';
import '../../../../shared/models/habit.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/providers/tag_provider.dart';
import '../../providers/todo_provider.dart';
import '../../../habit/providers/habit_provider.dart';
import 'todo_create_dialog.dart';
import 'todo_item_tile.dart';
import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../shared/widgets/animated_strikethrough.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../shared/widgets/bottom_scroll_spacer.dart';
import '../../../../shared/widgets/app_snack_bar.dart';

/// 수정 다이얼로그를 열고 결과를 updateTodo로 저장한다
Future<void> _openEditDialog(
  BuildContext context,
  WidgetRef ref,
  Todo todo,
  DateTime selectedDate,
  Future<void> Function(String, Todo) updateTodo,
) async {
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

  try {
    // 기존 투두를 수정된 필드로 업데이트한다
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
        // 색상 인덱스를 문자열로 저장한다
        color: result.colorIndex.toString(),
        memo: result.memo,
        clearMemo: result.memo == null,
        // 태그 정보를 Map 목록으로 전달한다
        tags: tagMaps,
      ),
    );
  } catch (e) {
    // 수정 실패 시 사용자에게 오류를 알린다
    if (context.mounted) {
      AppSnackBar.showError(context, '할 일 수정에 실패했습니다');
    }
  }
}

/// 할 일 목록 뷰 (서브탭 2)
/// AnimatedList로 추가/제거 애니메이션을 처리한다
class TodoListView extends ConsumerWidget {
  const TodoListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // P0: 액션 Provider는 ref.read()로 충분하다 (watch하면 불필요한 rebuild 발생)
    final toggleTodo = ref.read(toggleTodoProvider);
    final deleteTodo = ref.read(deleteTodoProvider);
    final updateTodo = ref.read(updateTodoProvider);
    final selectedDate = ref.watch(selectedDateProvider);

    // 오늘의 캘린더 이벤트/루틴/타이머 세션 수를 요약 표시용으로 watch한다
    final calendarEvents = ref.watch(calendarEventsForTimelineProvider);
    final routineEntries = ref.watch(routinesForTimelineProvider);
    final timerEntries = ref.watch(timerLogsForTimelineProvider);
    // 오늘의 습관 체크리스트를 watch한다
    final habitsForDay = ref.watch(habitsForTodoDateProvider);

    // 태그 필터가 적용된 정렬 목록을 사용한다
    final filtered = ref.watch(filteredTodosProvider);

    if (filtered.isEmpty && habitsForDay.isEmpty) {
      return EmptyState(
        key: const ValueKey('todo-empty'),
        icon: Icons.task_alt_rounded,
        mainText: '오늘 할 일이 없습니다',
        subText: '새로운 할 일을 추가해보세요!',
        ctaLabel: '할 일 추가',
        onCtaTap: null, // FAB에서 처리
      );
    }

    // 이벤트/루틴/타이머 중 하나라도 있으면 요약 바를 표시한다
    final hasScheduleInfo = calendarEvents.isNotEmpty ||
        routineEntries.isNotEmpty ||
        timerEntries.isNotEmpty;

    // 습관 섹션이 있는지 확인한다
    final hasHabits = habitsForDay.isNotEmpty;

    // 헤더 수: 요약 바 + 습관 섹션 (각각 존재할 때만)
    final headerCount = (hasScheduleInfo ? 1 : 0) + (hasHabits ? 1 : 0);

    // 외부 SingleChildScrollView가 제거되었으므로 ListView 자체가 스크롤을 담당한다
    return ListView.builder(
      key: const ValueKey('todo-list'),
      // 하단 여백: 마지막 콘텐츠를 화면 중앙까지 스크롤 가능하도록 화면 절반 높이
      padding: EdgeInsets.fromLTRB(AppSpacing.xxl, 0, AppSpacing.xxl, BottomScrollSpacer.height(context)),
      // 요약 바 + 습관 섹션 + 투두 목록
      itemCount: filtered.length + headerCount,
      itemBuilder: (context, index) {
        int currentOffset = 0;

        // 요약 정보 바 (첫 번째 헤더)
        if (hasScheduleInfo) {
          if (index == currentOffset) {
            return _ScheduleSummaryBar(
              eventCount: calendarEvents.length,
              routineCount: routineEntries.length,
              timerCount: timerEntries.length,
            );
          }
          currentOffset++;
        }

        // 습관 체크리스트 섹션 (두 번째 헤더)
        if (hasHabits) {
          if (index == currentOffset) {
            return _HabitChecklistSection(
              habits: habitsForDay,
              selectedDate: selectedDate,
            );
          }
          currentOffset++;
        }

        final todoIndex = index - currentOffset;
        final todo = filtered[todoIndex];
        return RepaintBoundary(
          child: TodoItemTile(
            key: Key(todo.id),
            todo: todo,
            onToggle: (isCompleted) =>
                toggleTodo(todo.id, isCompleted),
            onDelete: () => deleteTodo(todo.id),
            onEdit: () => _openEditDialog(
              context,
              ref,
              todo,
              selectedDate,
              updateTodo,
            ),
          ),
        );
      },
    );
  }
}

/// 오늘의 일정/루틴/타이머 세션 수를 요약하는 작은 정보 바
/// 투두 목록 상단에 표시하여 캘린더/루틴/타이머 데이터와의 연결감을 제공한다
/// 루틴 칩 탭 시 주간 루틴 서브탭으로 전환한다
class _ScheduleSummaryBar extends ConsumerWidget {
  final int eventCount;
  final int routineCount;
  final int timerCount;

  const _ScheduleSummaryBar({
    required this.eventCount,
    required this.routineCount,
    required this.timerCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: context.themeColors.textPrimaryWithAlpha(0.06),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // 이벤트 수
            if (eventCount > 0) ...[
              _buildInfoChip(
                context,
                icon: Icons.event_rounded,
                label: '일정 $eventCount',
              ),
              if (routineCount > 0 || timerCount > 0)
                _buildDot(context),
            ],
            // 루틴 수 — 탭 시 주간 루틴 서브탭으로 전환
            if (routineCount > 0) ...[
              GestureDetector(
                onTap: () => ref.read(todoSubTabProvider.notifier).state =
                    TodoSubTab.weeklyRoutine,
                child: _buildInfoChip(
                  context,
                  icon: Icons.repeat_rounded,
                  label: '루틴 $routineCount',
                ),
              ),
              if (timerCount > 0)
                _buildDot(context),
            ],
            // 타이머 세션 수
            if (timerCount > 0)
              _buildInfoChip(
                context,
                icon: Icons.timer_rounded,
                label: '타이머 $timerCount',
              ),
          ],
        ),
      ),
    );
  }

  /// 아이콘 + 레이블 조합 칩
  Widget _buildInfoChip(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: AppLayout.iconSm,
          color: context.themeColors.textPrimaryWithAlpha(0.50),
        ),
        const SizedBox(width: AppSpacing.xxs),
        Text(
          label,
          style: AppTypography.captionMd.copyWith(
            color: context.themeColors.textPrimaryWithAlpha(0.55),
          ),
        ),
      ],
    );
  }

  /// 구분 점
  Widget _buildDot(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Container(
        width: 3,
        height: 3,
        decoration: BoxDecoration(
          color: context.themeColors.textPrimaryWithAlpha(0.30),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// 습관 체크리스트 섹션
/// 투두 목록 상단에 오늘의 습관을 체크리스트 형태로 표시한다
class _HabitChecklistSection extends ConsumerWidget {
  final List<({Habit habit, bool isCompleted})> habits;
  final DateTime selectedDate;

  const _HabitChecklistSection({
    required this.habits,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completedCount = habits.where((e) => e.isCompleted).length;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: context.themeColors.textPrimaryWithAlpha(0.06),
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더: 제목 + 완료 카운트
            Row(
              children: [
                Icon(
                  Icons.self_improvement_rounded,
                  size: AppLayout.iconMd,
                  color: context.themeColors.textPrimaryWithAlpha(0.55),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '오늘의 습관',
                  style: AppTypography.captionLg.copyWith(
                    color: context.themeColors.textPrimaryWithAlpha(0.65),
                    fontWeight: AppTypography.weightSemiBold,
                  ),
                ),
                const Spacer(),
                Text(
                  '$completedCount/${habits.length}',
                  style: AppTypography.captionMd.copyWith(
                    color: context.themeColors.accent,
                    fontWeight: AppTypography.weightSemiBold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // 습관 아이템 목록
            ...habits.map((entry) => _buildHabitItem(
              context, ref, entry.habit, entry.isCompleted,
            )),
          ],
        ),
      ),
    );
  }

  /// 개별 습관 체크 아이템
  Widget _buildHabitItem(
    BuildContext context,
    WidgetRef ref,
    Habit habit,
    bool isCompleted,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        children: [
          // 체크박스
          GestureDetector(
            onTap: () {
              ref.read(toggleHabitProvider)(
                habit.id, selectedDate, !isCompleted,
              );
            },
            child: AnimatedContainer(
              duration: AppAnimation.slow,
              curve: Curves.easeInOut,
              width: AppLayout.iconMd,
              height: AppLayout.iconMd,
              decoration: BoxDecoration(
                color: isCompleted
                    ? context.themeColors.accent
                    : ColorTokens.transparent,
                borderRadius: BorderRadius.circular(AppRadius.xs),
                border: Border.all(
                  color: isCompleted
                      ? context.themeColors.accent
                      : context.themeColors.textPrimaryWithAlpha(0.3),
                  width: AppLayout.borderMedium,
                ),
              ),
              child: isCompleted
                  ? Icon(
                      Icons.check,
                      size: AppLayout.iconSm,
                      color: context.themeColors.dialogSurface,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // 습관 아이콘
          if (habit.icon != null)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: Text(habit.icon!, style: AppTypography.bodyMd),
            ),
          // 습관 이름 (완료 시 빨간펜 취소선 애니메이션 적용)
          Expanded(
            child: AnimatedStrikethrough(
              text: habit.name,
              style: AppTypography.bodySm.copyWith(
                color: context.themeColors.textPrimary,
              ),
              isActive: isCompleted,
            ),
          ),
        ],
      ),
    );
  }
}
