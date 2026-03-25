// F5 위젯: SubGoalMiniProgressBar - 하위 목표 미니 진행률 바
// SubGoalCard 헤더 내부에서 사용하는 소형 진행률 표시 바이다.
import 'package:flutter/material.dart';

import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';

/// 미니 진행률 바 (SubGoalCard 내부용)
/// [progress]는 0.0~1.0 범위의 진행률 값이다.
class SubGoalMiniProgressBar extends StatelessWidget {
  final double progress;

  const SubGoalMiniProgressBar({
    required this.progress,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: AppLayout.progressBarHeightSm,
          width: double.infinity,
          decoration: BoxDecoration(
            color: context.themeColors.textPrimaryWithAlpha(0.1),
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: AppAnimation.emphasis,
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return Container(
                  width: constraints.maxWidth * value,
                  // 진행률 바: 배경 테마에 맞는 악센트 색상으로 표시한다
                  decoration: BoxDecoration(
                    color: context.themeColors.accent,
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
