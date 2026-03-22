// F1: 홈 대시보드 오늘의 습관 요약 카드 위젯
// 도넛 차트(달성률) + 습관 필 목록(최대 3개) + "습관 탭으로 이동" 링크
// GlassCard(defaultCard), AN-02 staggered 등장 (index 1, 100ms 딜레이)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/donut_chart.dart';
import '../../../../shared/widgets/habit_pill.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../habit/providers/habit_provider.dart';
import '../../providers/home_provider.dart';
import '../../../../core/theme/spacing_tokens.dart';

/// 오늘의 습관 요약 카드
class HabitSummaryCard extends ConsumerWidget {
  const HabitSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 동기 Provider: 직접 값을 사용한다
    final summary = ref.watch(todayHabitsProvider);

    return GlassCard(
      variant: GlassCardVariant.defaultCard,
      child: _buildContent(context, ref, summary),
    );
  }

  /// 실제 콘텐츠
  Widget _buildContent(BuildContext context, WidgetRef ref, HabitSummary summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 카드 헤더: 도넛 차트 + 달성률 텍스트
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 도넛 차트 (AN-03: 습관은 초록색, 200ms 딜레이)
            DonutChart(
              percentage: summary.achievementRate,
              size: DonutChartSize.medium,
              // 습관 달성률: 밝은 초록 (#A0F0C0)
              type: DonutChartType.habit,
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
                    '오늘의 습관',
                    style: AppTypography.titleLg.copyWith(color: context.themeColors.textPrimary),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${summary.completedCount}/${summary.totalCount} 달성',
                    style: AppTypography.bodyMd.copyWith(
                      color: context.themeColors.textPrimaryWithAlpha(0.70),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  GestureDetector(
                    onTap: () => context.go(RoutePaths.habit),
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

        // 습관 필 목록 (최대 3개) or 빈 상태
        if (summary.previewItems.isEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          EmptyState(
            icon: Icons.loop_rounded,
            mainText: '등록된 습관이 없어요',
            ctaLabel: '습관 등록하러 가기',
            onCtaTap: () => context.go(RoutePaths.habit),
            minHeight: 100,
          ),
        ] else ...[
          const SizedBox(height: AppSpacing.xl),
          Divider(color: context.themeColors.dividerColor, height: 1),
          const SizedBox(height: AppSpacing.lg),
          // 습관 필 목록
          ...summary.previewItems.asMap().entries.map((entry) {
            final item = entry.value;
            return Padding(
              // 습관 필 간격: 10px (space-3)
              padding: const EdgeInsets.only(bottom: AppSpacing.mdLg),
              child: HabitPill(
                icon: item.icon,
                name: item.name,
                isCompleted: item.isCompleted,
                streak: item.streak,
                // 홈 미리보기에서도 습관 토글을 지원한다
                onToggle: () => ref.read(toggleHabitProvider)(
                  item.id,
                  DateTime.now(),
                  !item.isCompleted,
                ),
              ),
            );
          }),
        ],
      ],
    );
  }
}
