// 튜토리얼 탭 아이콘 애니메이션 위젯
// 원형 배경 위에 탭 아이콘을 표시하며, 글로우 펄스 효과를 적용한다.
// SRP 분리: 튜토리얼 아이콘 애니메이션 표시만 담당한다.
import 'package:flutter/material.dart';

import '../../core/theme/animation_tokens.dart';
import '../../core/theme/color_tokens.dart';
import '../../core/theme/layout_tokens.dart';
import '../../core/theme/spacing_tokens.dart';

/// 탭 아이콘 애니메이션 위젯
/// 등장 시 스케일 + 글로우 효과를 적용한다
class TutorialAnimatedIcon extends StatefulWidget {
  final IconData icon;
  final int stepIndex;

  const TutorialAnimatedIcon({
    required this.icon,
    required this.stepIndex,
    super.key,
  });

  @override
  State<TutorialAnimatedIcon> createState() => _TutorialAnimatedIconState();
}

class _TutorialAnimatedIconState extends State<TutorialAnimatedIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: AppAnimation.snackBar,
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        // 부드러운 글로우 펄스: 0.3 ~ 0.6 불투명도 변화
        final glowAlpha = 0.3 + (_pulseController.value * 0.3);
        return Container(
          width: AppLayout.containerXl,
          height: AppLayout.containerXl,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ColorTokens.main.withValues(alpha: 0.3),
            boxShadow: [
              BoxShadow(
                color: ColorTokens.mainLight.withValues(alpha: glowAlpha),
                blurRadius: EffectLayout.blurRadiusXl,
                spreadRadius: AppSpacing.xs,
              ),
            ],
          ),
          child: Icon(
            widget.icon,
            size: AppLayout.iconHuge + AppSpacing.md,
            color: ColorTokens.white,
          ),
        );
      },
    );
  }
}
