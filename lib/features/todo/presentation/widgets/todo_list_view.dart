// F3 위젯: TodoListView - 할 일 목록 (체크리스트)
// 시간 미지정 투두를 체크리스트 형태로 표시한다.
// 빈 상태: "오늘 일정이 없습니다. 새로운 일정을 추가해보세요!"
import 'package:flutter/material.dart';
import '../../../../core/theme/theme_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../providers/todo_provider.dart';
import 'todo_item_tile.dart';
import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';

/// 할 일 목록 뷰 (서브탭 2)
/// AnimatedList로 추가/제거 애니메이션을 처리한다
class TodoListView extends ConsumerWidget {
  const TodoListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todosAsync = ref.watch(todosForDateProvider);
    final toggleTodo = ref.watch(toggleTodoProvider);
    final deleteTodo = ref.watch(deleteTodoProvider);

    return todosAsync.when(
      data: (todos) {
        if (todos.isEmpty) {
          // AN-13: 빈 상태 -> 콘텐츠 전환 AnimatedSwitcher
          return AnimatedSwitcher(
            duration: AppAnimation.medium,
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: EmptyState(
              key: const ValueKey('todo-empty'),
              icon: Icons.task_alt_rounded,
              mainText: '오늘 일정이 없습니다',
              subText: '새로운 일정을 추가해보세요!',
              ctaLabel: '할 일 추가',
              onCtaTap: null, // FAB에서 처리
            ),
          );
        }

        // 정렬: 미완료 먼저, 완료된 항목은 하단
        final sorted = ref.watch(sortedTodosProvider);

        // 외부 SingleChildScrollView가 제거되었으므로 ListView 자체가 스크롤을 담당한다
        return ListView.builder(
          key: const ValueKey('todo-list'),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          itemCount: sorted.length,
          itemBuilder: (context, index) {
            final todo = sorted[index];
            return TodoItemTile(
              key: Key(todo.id),
              todo: todo,
              onToggle: (isCompleted) =>
                  toggleTodo(todo.id, isCompleted),
              onDelete: () => deleteTodo(todo.id),
            );
          },
        );
      },
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        child: Column(
          children: List.generate(
            3,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: LoadingSkeleton(height: 60, borderRadius: 12),
            ),
          ),
        ),
      ),
      error: (error, _) => Center(
        child: Text(
          '투두를 불러오지 못했어요',
          style: TextStyle(color: context.themeColors.textPrimaryWithAlpha(0.6)),
        ),
      ),
    );
  }
}
