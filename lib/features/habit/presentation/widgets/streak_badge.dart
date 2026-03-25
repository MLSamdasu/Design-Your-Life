// F4 위젯: StreakBadge - 스트릭 뱃지
// 연속 달성 일수를 "7일 연속" 형태로 표시한다.
// StreakCalculator(F4.3) 결과를 기반으로 렌더링한다.
import 'package:flutter/material.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';

/// 스트릭 뱃지 위젯
/// AN-12: TweenAnimationBuilder로 숫자 카운팅 애니메이션 적용
class StreakBadge extends StatelessWidget {
  final int streak;

  const StreakBadge({required this.streak, super.key});

  @override
  Widget build(BuildContext context) {
    if (streak <= 0) return const SizedBox.shrink();

    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: streak),
      duration: AppAnimation.dramatic,
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xxs),
          decoration: BoxDecoration(
            // 스트릭이 높을수록 더 강조된 색상
            color: streak >= MiscLayout.streakHighlightThreshold
                ? ColorTokens.eventSocial.withValues(alpha: 0.35)
                : context.themeColors.textPrimaryWithAlpha(0.15),
            borderRadius: BorderRadius.circular(AppRadius.huge),
            border: Border.all(
              color: streak >= MiscLayout.streakHighlightThreshold
                  ? ColorTokens.eventSocial.withValues(alpha: 0.6)
                  : context.themeColors.textPrimaryWithAlpha(0.25),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 불꽃 이모지 (7일 이상이면 표시)
              if (streak >= MiscLayout.streakHighlightThreshold)
                Text('🔥', style: AppTypography.captionSm),
              if (streak >= MiscLayout.streakHighlightThreshold) const SizedBox(width: AppSpacing.xxs),
              Text(
                '$value일 연속',
                style: AppTypography.captionLg.copyWith(
                  color: streak >= MiscLayout.streakHighlightThreshold
                      ? ColorTokens.warningLight
                      : context.themeColors.textPrimaryWithAlpha(0.8),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
