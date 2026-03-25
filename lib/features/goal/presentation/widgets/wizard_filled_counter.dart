// F5 위젯: WizardFilledCounter - 입력 진행 카운터
// N/M 입력됨 텍스트와 애니메이션 진행 바를 표시한다.
// SRP 분리: 위저드 입력 진행 상태 표시 UI만 담당한다.
import 'package:flutter/material.dart';
import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';

/// 입력 진행 카운터 (N/M 입력됨 + 진행 바)
class WizardFilledCounter extends StatelessWidget {
  final int filled;
  final int total;
  final bool isComplete;

  const WizardFilledCounter({
    required this.filled,
    required this.total,
    required this.isComplete,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? filled / total : 0.0;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isComplete)
              Icon(
                Icons.check_circle_rounded,
                size: AppLayout.iconSm,
                color: context.themeColors.accent,
              )
            else
              Icon(
                Icons.edit_note_rounded,
                size: AppLayout.iconSm,
                color: context.themeColors.textPrimaryWithAlpha(0.5),
              ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              isComplete
                  ? '전부 입력 완료!'
                  : '$filled / $total 입력됨',
              style: AppTypography.captionLg.copyWith(
                color: isComplete
                    ? context.themeColors.accent
                    : context.themeColors.textPrimaryWithAlpha(0.6),
                fontWeight: isComplete
                    ? AppTypography.weightSemiBold
                    : AppTypography.weightMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        // 진행 바
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xs),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: AppAnimation.normal,
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return LinearProgressIndicator(
                value: value,
                minHeight: GoalLayout.stepIndicatorHeight,
                backgroundColor:
                    context.themeColors.textPrimaryWithAlpha(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isComplete
                      ? context.themeColors.accent
                      : context.themeColors.accentWithAlpha(0.6),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
