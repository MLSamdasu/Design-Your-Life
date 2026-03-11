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
import '../../../../shared/widgets/loading_indicator.dart' show GlassLoadingSpinner;
import '../../../todo/providers/todo_provider.dart';
import '../../models/timer_state.dart';
import '../../providers/timer_provider.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';

/// 타이머에 연결할 투두 선택 바텀시트
/// showModalBottomSheet로 표시하며, 선택 시 timerStateProvider에 연결한다
class TimerTodoSelector extends ConsumerWidget {
  const TimerTodoSelector({super.key});

  /// 바텀시트를 표시하는 정적 팩토리 메서드
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      // 배경 투명 처리로 GlassCard 스타일 유지
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const TimerTodoSelector(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todosAsync = ref.watch(todosForDateProvider);
    final timerState = ref.watch(timerStateProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return GlassCard(
          variant: GlassCardVariant.elevated,
          borderRadius: 28,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              // 드래그 핸들
              _buildHandle(context),

              // 헤더 영역
              _buildHeader(context, ref, timerState),

              // 투두 목록 영역
              Expanded(
                child: todosAsync.when(
                  loading: () => _buildLoading(),
                  error: (_, __) => _buildError(),
                  data: (todos) => _buildTodoList(
                    context,
                    ref,
                    todos,
                    timerState,
                    scrollController,
                  ),
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
        width: 40,
        height: 4,
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

  /// 로딩 상태 UI
  Widget _buildLoading() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.huge),
        child: GlassLoadingSpinner(size: 32),
      ),
    );
  }

  /// 오류 상태 UI
  Widget _buildError() {
    return const EmptyState(
      icon: Icons.sync_problem_rounded,
      mainText: '투두를 불러오지 못했어요',
      subText: '잠시 후 다시 시도해주세요',
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

        return _TodoSelectorItem(
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

/// 투두 선택 아이템 위젯
class _TodoSelectorItem extends StatelessWidget {
  final Todo todo;
  final bool isLinked;
  final VoidCallback onTap;

  const _TodoSelectorItem({
    required this.todo,
    required this.isLinked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = ColorTokens.eventColor(todo.colorIndex);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
        // 연결된 투두는 배경 테마에 맞는 악센트 색상으로 강조한다
        decoration: BoxDecoration(
          color: isLinked
              ? context.themeColors.accentWithAlpha(0.20)
              : context.themeColors.textPrimaryWithAlpha(0.08),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: isLinked
                ? context.themeColors.accentWithAlpha(0.50)
                : context.themeColors.textPrimaryWithAlpha(0.12),
          ),
        ),
        child: Row(
          children: [
            // 색상 인디케이터
            Container(
              width: 4,
              height: 32,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),

            // 투두 제목
            Expanded(
              child: Text(
                todo.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyLg.copyWith(
                    color: context.themeColors.textPrimary,
                  decoration: todo.isCompleted
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                ),
              ),
            ),

            const SizedBox(width: AppSpacing.lg),

            // 연결 상태 아이콘
            Icon(
              isLinked ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              // 연결 아이콘: 배경 테마에 맞는 악센트 색상으로 표시한다
              color: isLinked
                  ? context.themeColors.accent
                  : context.themeColors.textPrimaryWithAlpha(0.30),
              size: AppLayout.iconXl,
            ),
          ],
        ),
      ),
    );
  }
}
