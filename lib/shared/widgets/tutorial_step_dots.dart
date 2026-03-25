// 튜토리얼 단계 인디케이터 도트 위젯
// 현재 단계를 시각적으로 표시하는 가로 도트 행을 렌더링한다.
// SRP 분리: 단계 인디케이터 도트 UI만 담당한다.
import 'package:flutter/material.dart';

import '../../core/theme/animation_tokens.dart';
import '../../core/theme/color_tokens.dart';
import '../../core/theme/layout_tokens.dart';
import '../../core/theme/radius_tokens.dart';
import '../../core/theme/spacing_tokens.dart';

/// 단계 인디케이터 도트
class TutorialStepDots extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const TutorialStepDots({
    required this.currentStep,
    required this.totalSteps,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSteps, (i) {
        final isActive = i == currentStep;
        final isPast = i < currentStep;
        return AnimatedContainer(
          duration: AppAnimation.standard,
          curve: Curves.easeInOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          width: isActive
              ? MiscLayout.stepIndicatorActiveWidth
              : MiscLayout.stepIndicatorInactiveWidth,
          height: MiscLayout.stepIndicatorHeightLg,
          decoration: BoxDecoration(
            color: isActive
                ? ColorTokens.mainLight
                : isPast
                    ? ColorTokens.mainLight.withValues(alpha: 0.5)
                    : ColorTokens.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        );
      }),
    );
  }
}
