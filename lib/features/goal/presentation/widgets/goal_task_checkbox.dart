// F5 위젯: GoalTaskCheckbox - 실천 할일 체크박스
// AN-04 bounce 애니메이션이 적용된 체크박스 컴포넌트
import 'package:flutter/material.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';

/// AN-04 bounce 애니메이션이 적용된 체크박스 위젯
/// [isCompleted] 상태에 따라 시각적 피드백을 제공한다
class GoalTaskCheckbox extends StatelessWidget {
  final bool isCompleted;
  final Animation<double> bounceScale;

  const GoalTaskCheckbox({
    required this.isCompleted,
    required this.bounceScale,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: bounceScale,
      child: AnimatedContainer(
        duration: AppAnimation.slow,
        curve: Curves.easeInOut,
        width: AppLayout.iconLg,
        height: AppLayout.iconLg,
        decoration: BoxDecoration(
          color: isCompleted
              ? context.themeColors.textPrimaryWithAlpha(0.3)
              : ColorTokens.transparent,
          border: Border.all(
            color: isCompleted
                ? context.themeColors.textPrimaryWithAlpha(0.6)
                : context.themeColors.textPrimaryWithAlpha(0.3),
            width: AppLayout.borderMedium,
          ),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        // 체크 아이콘 페이드 인/아웃 (abrupt 전환 방지)
        child: AnimatedOpacity(
          opacity: isCompleted ? 1.0 : 0.0,
          duration: AppAnimation.slow,
          curve: Curves.easeInOut,
          child: Icon(
            Icons.check_rounded,
            size: AppLayout.iconXxs,
            color: context.themeColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
