// F8: 홈 대시보드 업적 요약 카드
// 달성 업적 수와 최근 달성 업적(최대 3개)을 표시한다.
// 탭 시 업적 화면으로 이동한다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../achievement/models/achievement.dart';
import '../../../achievement/models/achievement_definition.dart';
import '../../../achievement/providers/achievement_provider.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';

/// 홈 대시보드 업적 요약 카드
/// 달성 업적 수와 최근 달성 배지를 한눈에 표시한다
class AchievementSummaryCard extends ConsumerWidget {
  const AchievementSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // userAchievementsProvider는 동기 Provider이므로 직접 사용한다
    final achievements = ref.watch(userAchievementsProvider);
    final unlockedIds = ref.watch(unlockedAchievementIdsProvider);

    return GestureDetector(
      // 카드 탭 시 업적 화면으로 이동한다
      onTap: () => context.push(RoutePaths.achievements),
      child: GlassCard(
        variant: GlassCardVariant.defaultCard,
        // 동기 Provider이므로 직접 렌더링한다
        child: _buildContent(
          context,
          unlockedCount: unlockedIds.length,
          totalCount: AchievementDef.all.length,
          recentAchievements: achievements
              .take(3) // 최근 달성 업적 최대 3개
              .toList(),
        ),
      ),
    );
  }

  /// 실제 콘텐츠
  /// unlockedCount: 달성 업적 수, totalCount: 전체 업적 수,
  /// recentAchievements: 최근 달성 업적 목록 (최대 3개)
  Widget _buildContent(
    BuildContext context, {
    required int unlockedCount,
    required int totalCount,
    required List<Achievement> recentAchievements,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 헤더: 업적 아이콘 + 달성 수 정보
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 업적 아이콘 원형 배경
            Container(
              width: AppLayout.containerAchievement,
              height: AppLayout.containerAchievement,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // 배경 테마에 맞는 악센트 색상으로 표시한다
                color: context.themeColors.accentWithAlpha(0.20),
                border: Border.all(
                  color: context.themeColors.accentWithAlpha(0.40),
                  width: AppLayout.borderMedium,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.emoji_events_rounded,
                  size: AppLayout.iconXl,
                  // WCAG 대비: accent 배경 위에서 테마 색상으로 고대비 확보
                  color: context.themeColors.textPrimaryWithAlpha(0.8),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),

            // 업적 달성 수 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '업적 & 배지',
                    style: AppTypography.titleMd.copyWith(
                      color: context.themeColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  // 달성 수 / 전체 수 텍스트
                  Text(
                    '$unlockedCount / $totalCount 달성',
                    style: AppTypography.captionLg.copyWith(
                      color: context.themeColors.textPrimaryWithAlpha(0.60),
                    ),
                  ),
                ],
              ),
            ),

            // 업적 화면 이동 화살표
            Icon(
              Icons.chevron_right_rounded,
              color: context.themeColors.textPrimaryWithAlpha(0.50),
              size: AppLayout.iconXl,
            ),
          ],
        ),

        // 최근 달성 업적 (최대 3개)
        if (recentAchievements.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lgXl),
          Divider(color: context.themeColors.dividerColor, height: 1),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Text(
                '최근 달성',
                style: AppTypography.captionLg.copyWith(
                  color: context.themeColors.textPrimaryWithAlpha(0.60),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // 최근 달성 이모지 뱃지 목록
              ...recentAchievements.map(
                (achievement) => Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: Container(
                    width: AppLayout.iconHuge,
                    height: AppLayout.iconHuge,
                    // 업적 이모지 배경: 배경 테마에 맞는 악센트 색상으로 표시한다
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.themeColors.accentWithAlpha(0.20),
                      border: Border.all(
                        color: context.themeColors.accentWithAlpha(0.40),
                        width: AppLayout.borderThin,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        achievement.iconName,
                        // 업적 이모지 배지 텍스트 (bodyLg 기반 14px)
                        style: AppTypography.emojiSm,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ] else ...[
          // 달성 업적이 없는 경우 안내 텍스트
          const SizedBox(height: AppSpacing.mdLg),
          Text(
            '첫 번째 업적을 달성해보세요!',
            style: AppTypography.captionMd.copyWith(
              color: context.themeColors.textPrimaryWithAlpha(0.45),
            ),
          ),
        ],
      ],
    );
  }
}
