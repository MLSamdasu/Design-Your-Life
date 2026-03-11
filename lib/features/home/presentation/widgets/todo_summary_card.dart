// F1: 홈 대시보드 오늘의 투두 요약 카드 위젯
// 도넛 차트(완료율) + 체크리스트 미리보기(최대 5개) + "더보기" 링크로 구성
// GlassCard(elevated variant)를 사용하며, AN-02 staggered 등장 애니메이션 적용
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/donut_chart.dart';
import '../../../../shared/widgets/check_item.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../todo/providers/todo_provider.dart';
import '../../providers/home_provider.dart';
import '../../../../core/theme/spacing_tokens.dart';

/// 오늘의 투두 요약 카드
class TodoSummaryCard extends ConsumerWidget {
  const TodoSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todosAsync = ref.watch(todayTodosProvider);
    final toggleTodo = ref.watch(toggleTodoProvider);

    return GlassCard(
      variant: GlassCardVariant.defaultCard,
      child: todosAsync.when(
        loading: () => _buildSkeleton(),
        error: (_, __) => _buildError(),
        data: (summary) => _buildContent(context, summary, toggleTodo),
      ),
    );
  }

  /// 로딩 스켈레톤 UI (AN-14)
  Widget _buildSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const LoadingSkeleton(width: 90, height: 90, borderRadius: 45),
            const SizedBox(width: AppSpacing.xl),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LoadingSkeleton(width: 120, height: 16, borderRadius: 8),
                  const SizedBox(height: AppSpacing.md),
                  LoadingSkeleton(width: 80, height: 12, borderRadius: 6),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        ...List.generate(3, (i) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: LoadingSkeleton(height: 20, borderRadius: 6),
        )),
      ],
    );
  }

  /// 에러 상태 UI
  Widget _buildError() {
    return EmptyState(
      icon: Icons.sync_problem_rounded,
      mainText: '데이터를 불러오지 못했어요',
      subText: '잠시 후 다시 시도해주세요',
      minHeight: 120,
    );
  }

  /// 실제 콘텐츠
  /// toggleTodo: 투두 완료 상태 토글 콜백 (todoId, isCompleted)
  Widget _buildContent(
    BuildContext context,
    TodoSummary summary,
    Future<void> Function(String, bool) toggleTodo,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 카드 헤더: 도넛 차트 + 완료율 텍스트
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 도넛 차트 (AN-03: 0->목표% sweep)
            DonutChart(
              percentage: summary.completionRate,
              size: DonutChartSize.medium,
              type: DonutChartType.todo,
              centerLabel: '완료율',
            ),

            const SizedBox(width: AppSpacing.xl),

            // 통계 텍스트
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '오늘의 할 일',
                    style: AppTypography.titleLg.copyWith(color: context.themeColors.textPrimary),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${summary.completedCount}/${summary.totalCount} 완료',
                    style: AppTypography.bodyMd.copyWith(
                      color: context.themeColors.textPrimaryWithAlpha(0.70),
                    ),
                  ),
                  // "투두 탭으로 이동" 링크
                  const SizedBox(height: AppSpacing.lg),
                  GestureDetector(
                    onTap: () => context.go(RoutePaths.todo),
                    child: Text(
                      '전체 보기 →',
                      style: AppTypography.captionLg.copyWith(
                        color: context.themeColors.textPrimaryWithAlpha(0.60),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // 체크리스트 미리보기 (최대 5개) or 빈 상태
        if (summary.previewItems.isEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          EmptyState(
            icon: Icons.checklist_rounded,
            mainText: '오늘 할 일이 없어요',
            ctaLabel: '할 일 추가하러 가기',
            onCtaTap: () => context.go(RoutePaths.todo),
            minHeight: 100,
          ),
        ] else ...[
          const SizedBox(height: AppSpacing.xl),
          // 구분선
          Divider(color: context.themeColors.dividerColor, height: 1),
          const SizedBox(height: AppSpacing.lg),
          // 체크 아이템 목록 (AnimatedSwitcher로 빈->콘텐츠 전환, AN-13)
          ...summary.previewItems.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: CheckItem(
              title: item.title,
              isCompleted: item.isCompleted,
              // 홈 미리보기에서도 체크박스 토글을 지원한다
              onToggle: (isCompleted) =>
                  toggleTodo(item.id, isCompleted),
            ),
          )),

          // 더보기 (5개 초과 시)
          if (summary.totalCount > 5) ...[
            const SizedBox(height: AppSpacing.md),
            GestureDetector(
              onTap: () => context.go(RoutePaths.todo),
              child: Text(
                '+ ${summary.totalCount - 5}개 더보기',
                style: AppTypography.captionLg.copyWith(
                  color: context.themeColors.textPrimaryWithAlpha(0.50),
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }
}
