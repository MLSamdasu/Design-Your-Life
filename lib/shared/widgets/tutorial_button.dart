// 튜토리얼 네비게이션 버튼 위젯
// 이전/다음/시작하기 등 튜토리얼 단계 전환 버튼을 렌더링한다.
// SRP 분리: 튜토리얼 버튼 UI만 담당한다.
import 'package:flutter/material.dart';

import '../../core/theme/animation_tokens.dart';
import '../../core/theme/color_tokens.dart';
import '../../core/theme/layout_tokens.dart';
import '../../core/theme/radius_tokens.dart';
import '../../core/theme/spacing_tokens.dart';
import '../../core/theme/typography_tokens.dart';

/// 튜토리얼 버튼 (이전/다음/시작하기)
class TutorialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool iconLeft;
  final bool isOutlined;
  final VoidCallback onTap;

  const TutorialButton({
    required this.label,
    required this.icon,
    required this.iconLeft,
    required this.isOutlined,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.lgXl,
          horizontal: AppSpacing.xl,
        ),
        decoration: BoxDecoration(
          color: isOutlined ? ColorTokens.transparent : ColorTokens.main,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: isOutlined
              ? Border.all(
                  color: ColorTokens.white.withValues(alpha: 0.3),
                  width: AppLayout.borderThin,
                )
              : null,
          boxShadow: isOutlined
              ? null
              : [
                  BoxShadow(
                    color: ColorTokens.main
                        .withValues(alpha: AppAnimation.buttonShadowAlpha),
                    blurRadius: EffectLayout.ctaShadowBlur,
                    offset: const Offset(0, EffectLayout.ctaShadowOffsetY),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (iconLeft) ...[
              Icon(
                icon,
                size: AppLayout.iconMd,
                color: isOutlined
                    ? ColorTokens.white.withValues(alpha: 0.7)
                    : ColorTokens.white,
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            Text(
              label,
              style: AppTypography.titleMd.copyWith(
                color: isOutlined
                    ? ColorTokens.white.withValues(alpha: 0.7)
                    : ColorTokens.white,
              ),
            ),
            if (!iconLeft) ...[
              const SizedBox(width: AppSpacing.sm),
              Icon(
                icon,
                size: AppLayout.iconMd,
                color: ColorTokens.white,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
