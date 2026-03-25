// F3 위젯: TodoListView - 할 일 목록 (체크리스트)
// 시간 미지정 투두를 체크리스트 형태로 표시한다.
// 상단에 오늘의 이벤트/루틴/타이머 세션 수를 요약 표시한다.
// 빈 상태: "오늘 일정이 없습니다. 새로운 일정을 추가해보세요!"
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../providers/todo_provider.dart';
import 'todo_item_tile.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../shared/widgets/bottom_scroll_spacer.dart';
import 'todo_edit_helper.dart';
import 'schedule_summary_bar.dart';
import 'habit_checklist_section.dart';

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
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xxl, 0, AppSpacing.xxl, BottomScrollSpacer.height(context),
      ),
      // 요약 바 + 습관 섹션 + 투두 목록
      itemCount: filtered.length + headerCount,
      itemBuilder: (context, index) {
        int currentOffset = 0;

        // 요약 정보 바 (첫 번째 헤더)
        if (hasScheduleInfo) {
          if (index == currentOffset) {
            return ScheduleSummaryBar(
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
            return HabitChecklistSection(
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
            onEdit: () => openEditDialog(
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
