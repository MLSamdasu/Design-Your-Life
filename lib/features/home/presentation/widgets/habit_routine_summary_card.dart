// F1: 홈 대시보드 오늘의 습관과 루틴 통합 요약 카드
// 습관 도넛 차트 + 습관 필 목록 + 루틴 아이템 목록을 하나의 카드에 통합한다
// GlassCard(defaultCard variant) 사용
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
import 'habit_routine_sections.dart';

/// 오늘의 습관과 루틴 통합 요약 카드
/// 습관 달성률 + 습관 필 목록 + 루틴 아이템 목록을 하나로 합친다
class HabitRoutineSummaryCard extends ConsumerWidget {
  const HabitRoutineSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 동기 Provider: 직접 값을 사용한다
    final habitSummary = ref.watch(todayHabitsProvider);
    final routineSummary = ref.watch(todayRoutinesProvider);

    return GlassCard(
      variant: GlassCardVariant.defaultCard,
      child: _buildContent(context, ref, habitSummary, routineSummary),
    );
  }

  /// 실제 콘텐츠: 습관 섹션 + 루틴 섹션 통합
  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    HabitSummary habitSummary,
    RoutineSummary routineSummary,
  ) {
    final hasHabits = habitSummary.previewItems.isNotEmpty;
    final hasRoutines = routineSummary.routineItems.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── 습관 헤더: 도넛 차트 + 달성률 텍스트 ───────────────────────────
        _HabitHeader(
          habitSummary: habitSummary,
          routineSummary: routineSummary,
        ),

        // ── 습관/루틴이 모두 없을 때 빈 상태 ────────────────────────────
        if (!hasHabits && !hasRoutines) ...[
          const SizedBox(height: AppSpacing.xl),
          EmptyState(
            icon: Icons.loop_rounded,
            mainText: '등록된 습관과 루틴이 없어요',
            ctaLabel: '등록하러 가기',
            onCtaTap: () => context.go(RoutePaths.habit),
            minHeight: 100,
          ),
        ],

        // ── 습관 필 목록 ──────────────────────────────────────────────────
        if (hasHabits) ...[
          const SizedBox(height: AppSpacing.xl),
          Divider(color: context.themeColors.dividerColor, height: 1),
          const SizedBox(height: AppSpacing.lg),
          HabitPillListSection(habitSummary: habitSummary, ref: ref),
        ],

        // ── 루틴 아이템 목록 ──────────────────────────────────────────────
        if (hasRoutines) ...[
          const SizedBox(height: AppSpacing.md),
          Divider(color: context.themeColors.dividerColor, height: 1),
          const SizedBox(height: AppSpacing.lg),
          HomeRoutineListSection(routineSummary: routineSummary),
        ],
      ],
    );
  }
}

/// 습관 헤더: 도넛 차트 + 달성률/루틴 텍스트 + '전체 보기' 링크
class _HabitHeader extends StatelessWidget {
  final HabitSummary habitSummary;
  final RoutineSummary routineSummary;

  const _HabitHeader({
    required this.habitSummary,
    required this.routineSummary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 도넛 차트 (습관 달성률)
        DonutChart(
          percentage: habitSummary.achievementRate,
          size: DonutChartSize.medium,
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
                '오늘의 습관과 루틴',
                style: AppTypography.titleLg.copyWith(
                  color: context.themeColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '습관 ${habitSummary.completedCount}/${habitSummary.totalCount} · 루틴 ${routineSummary.total}개',
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
    );
  }
}
