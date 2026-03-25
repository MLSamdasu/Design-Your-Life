// F5 위젯: GoalStatsHeader - 목표 통계 헤더
// 달성률(%), 평균 진행률(%), 총 목표 수를 가로 배치로 표시한다.
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/glassmorphism.dart';
import '../../../../features/goal/services/progress_calculator.dart';
import '../../../../shared/models/goal.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';

/// 목표 통계 헤더 위젯
/// 달성률/평균 진행률/총 목표 수 3개 스탯 카드를 가로로 표시한다
class GoalStatsHeader extends ConsumerWidget {
  final GoalStats stats;
  final List<Goal> goals;
  final bool isLoading;

  const GoalStatsHeader({
    required this.stats,
    this.goals = const [],
    this.isLoading = false,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        // 평균 진행률 카드 (체크포인트/할일 기반 실질 진행률)
        Expanded(
          child: _StatCard(
            label: '달성률',
            value: '${stats.avgProgressPercent}%',
            icon: Icons.flag_rounded,
            isLoading: isLoading,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        // 완료 목표 수 카드 (isCompleted=true인 목표 수)
        Expanded(
          child: _StatCard(
            label: '완료',
            value: '${goals.where((g) => g.isCompleted).length}',
            icon: Icons.check_circle_outline_rounded,
            isLoading: isLoading,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        // 총 목표 수 카드
        Expanded(
          child: _StatCard(
            label: '총 목표 수',
            value: '${stats.totalGoalCount}',
            icon: Icons.checklist_rounded,
            isLoading: isLoading,
          ),
        ),
      ],
    );
  }
}

/// 개별 통계 카드
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isLoading;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xxl),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: GlassDecoration.subtleBlurSigma,
          sigmaY: GlassDecoration.subtleBlurSigma,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg, horizontal: AppSpacing.lg),
          // 서브탭 카드와 동일한 xxl(16px) 반지름을 사용한다
          decoration: GlassDecoration.subtleCard(radius: AppRadius.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 아이콘
              Icon(
                icon,
                size: AppLayout.iconMd,
                color: context.themeColors.textPrimaryWithAlpha(0.7),
              ),
              const SizedBox(height: AppSpacing.sm),
              // 수치
              isLoading
                  ? Container(
                      height: GoalLayout.skeletonTextHeight,
                      width: GoalLayout.skeletonTextWidth,
                      decoration: BoxDecoration(
                        color: context.themeColors.textPrimaryWithAlpha(0.15),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                    )
                  : Text(
                      value,
                      style: AppTypography.headingMd.copyWith(
                    color: context.themeColors.textPrimary,
                      ),
                    ),
              const SizedBox(height: AppSpacing.xxs),
              // 레이블
              Text(
                label,
                style: AppTypography.captionMd.copyWith(
                  color: context.themeColors.textPrimaryWithAlpha(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
