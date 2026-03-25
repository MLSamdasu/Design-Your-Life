// F6: 투두 선택 바텀시트 위젯
// 오늘의 투두 목록을 표시하고 타이머에 연결할 투두를 선택한다.
// todosForDateProvider를 활용하여 오늘 날짜의 투두를 실시간으로 로드한다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../shared/models/todo.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../todo/providers/todo_provider.dart';
import '../../models/timer_state.dart';
import '../../providers/timer_provider.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import 'todo_selector_item.dart';

/// 타이머에 연결할 투두 선택 바텀시트
/// showModalBottomSheet로 표시하며, 선택 시 timerStateProvider에 연결한다
class TimerTodoSelector extends ConsumerWidget {
  const TimerTodoSelector({super.key});

  /// 바텀시트를 표시하는 정적 팩토리 메서드
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      // 배경 투명 처리로 GlassCard 스타일 유지
      backgroundColor: ColorTokens.transparent,
      isScrollControlled: true,
      builder: (_) => const TimerTodoSelector(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // P1-2: todosForDateProvider가 동기 Provider로 변경되어 async 처리 불필요
    final todos = ref.watch(todosForDateProvider);
    final timerState = ref.watch(timerStateProvider);

    return DraggableScrollableSheet(
      initialChildSize: MiscLayout.sheetInitialSize,
      minChildSize: MiscLayout.sheetMinSize,
      maxChildSize: MiscLayout.sheetMaxSize,
      builder: (context, scrollController) {
        return GlassCard(
          variant: GlassCardVariant.elevated,
          borderRadius: AppRadius.pill,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              // 드래그 핸들
              _buildHandle(context),

              // 헤더 영역
              _buildHeader(context, ref, timerState),

              // 투두 목록 영역
              Expanded(
                child: _buildTodoList(
                  context,
                  ref,
                  todos,
                  timerState,
                  scrollController,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 드래그 핸들 위젯
  Widget _buildHandle(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.xs),
      child: Container(
        width: AppSpacing.massive,
        height: AppSpacing.xs,
        decoration: BoxDecoration(
          color: context.themeColors.textPrimaryWithAlpha(0.30),
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
      ),
    );
  }

  /// 헤더: 제목 + 연결 해제 버튼
  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    TimerState timerState,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl, vertical: AppSpacing.lg),
      child: Row(
        children: [
          Text(
            '투두 연결하기',
            style: AppTypography.headingSm.copyWith(color: context.themeColors.textPrimary),
          ),
          const Spacer(),
          // 연결된 투두가 있을 때만 해제 버튼 표시
          if (timerState.linkedTodoId != null) ...[
            GestureDetector(
              onTap: () {
                ref.read(timerStateProvider.notifier).unlinkTodo();
                Navigator.of(context).pop();
              },
              child: Text(
                '연결 해제',
                style: AppTypography.bodyMd.copyWith(
                  color: ColorTokens.errorLight,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 투두 목록 UI
  Widget _buildTodoList(
    BuildContext context,
    WidgetRef ref,
    List<Todo> todos,
    TimerState timerState,
    ScrollController scrollController,
  ) {
    if (todos.isEmpty) {
      return const EmptyState(
        icon: Icons.checklist_rounded,
        mainText: '오늘 등록된 투두가 없어요',
        subText: '투두를 먼저 추가해주세요',
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
      itemCount: todos.length,
      itemBuilder: (context, index) {
        final todo = todos[index];
        final isLinked = timerState.linkedTodoId == todo.id;

        return TodoSelectorItem(
          todo: todo,
          isLinked: isLinked,
          onTap: () {
            ref.read(timerStateProvider.notifier).linkTodo(
                  todoId: todo.id,
                  todoTitle: todo.title,
                );
            Navigator.of(context).pop();
          },
        );
      },
    );
  }
}
