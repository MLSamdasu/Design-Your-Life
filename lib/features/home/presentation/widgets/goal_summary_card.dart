// F1 위젯: GoalSummaryCard — 홈 대시보드 목표 요약 카드
// 현재 연도의 목표 달성률을 도넛 차트로, 평균 진행률을 프로그레스 바로 표시한다.
// TodoSummaryCard와 동일한 GlassCard + DonutChart 레이아웃 패턴을 따른다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/donut_chart.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../providers/home_provider.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';

/// 홈 대시보드 목표 요약 카드
/// 현재 연도의 목표 달성률을 도넛 차트로 표시하고
/// 평균 진행률을 프로그레스 바로 표시한다
class GoalSummaryCard extends ConsumerWidget {
  const GoalSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(todayGoalStatsProvider);

    return GlassCard(
      variant: GlassCardVariant.defaultCard,
      child: summary.totalCount == 0
          ? _buildEmpty(context)
          : _buildContent(context, summary),
    );
  }

  /// 목표가 없을 때 빈 상태 표시
  Widget _buildEmpty(BuildContext context) {
    return EmptyState(
      icon: Icons.flag_outlined,
      mainText: '목표를 추가해보세요',
      ctaLabel: '목표 만들러 가기',
      onCtaTap: () => context.go(RoutePaths.goal),
      minHeight: 100,
    );
  }

  /// 도넛 차트 + 통계 + 프로그레스 바 콘텐츠
  Widget _buildContent(BuildContext context, GoalSummary summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 카드 헤더: 도넛 차트 + 통계 텍스트
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 도넛 차트 (AN-03: 0->목표% sweep)
            DonutChart(
              percentage: summary.achievementRate * 100,
              size: DonutChartSize.medium,
              type: DonutChartType.todo,
              centerLabel: '달성률',
            ),

            const SizedBox(width: AppSpacing.xl),

            // 통계 텍스트
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '올해의 목표',
                    style: AppTypography.titleLg.copyWith(
                        color: context.themeColors.textPrimary),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${summary.completedCount}/${summary.totalCount} 달성',
                    style: AppTypography.bodyMd.copyWith(
                      color:
                          context.themeColors.textPrimaryWithAlpha(0.70),
                    ),
                  ),
                  // "목표 탭으로 이동" 링크
                  const SizedBox(height: AppSpacing.lg),
                  GestureDetector(
                    onTap: () => context.go(RoutePaths.goal),
                    child: Text(
                      '전체 보기 →',
                      style: AppTypography.captionLg.copyWith(
                        color: context.themeColors
                            .textPrimaryWithAlpha(0.60),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // 평균 진행률 프로그레스 바
        const SizedBox(height: AppSpacing.xl),
        Divider(color: context.themeColors.dividerColor, height: 1),
        const SizedBox(height: AppSpacing.lg),

        // 평균 진행률 텍스트 + 바
        Text(
          '평균 진행률 ${(summary.avgProgress * 100).round()}%',
          style: AppTypography.captionLg.copyWith(
            color: context.themeColors.textPrimaryWithAlpha(0.60),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xs),
          child: LinearProgressIndicator(
            value: summary.avgProgress,
            backgroundColor:
                context.themeColors.textPrimaryWithAlpha(0.08),
            valueColor: AlwaysStoppedAnimation<Color>(
              context.themeColors.accent,
            ),
            minHeight: AppLayout.borderThick,
          ),
        ),
      ],
    );
  }
}
