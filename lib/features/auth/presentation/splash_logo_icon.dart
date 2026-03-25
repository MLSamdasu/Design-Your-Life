// 스플래시 화면용 글래스 스타일 로고 아이콘 위젯
// ClipRRect + BackdropFilter로 유리 효과를 적용한다
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../core/theme/typography_tokens.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/theme/radius_tokens.dart';
import '../../../core/theme/spacing_tokens.dart';
import '../../../core/theme/layout_tokens.dart';

/// 글래스 스타일 로고 아이콘 위젯
/// ClipRRect + BackdropFilter로 유리 효과를 적용한다
class SplashLogoIcon extends StatelessWidget {
  const SplashLogoIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: EffectLayout.blurSigmaStandard,
          sigmaY: EffectLayout.blurSigmaStandard,
        ),
        child: Container(
          width: MiscLayout.splashLogoSize,
          height: MiscLayout.splashLogoSize,
          decoration: BoxDecoration(
            // Glass 효과: 흰색 반투명 배경
            color: context.themeColors.textPrimaryWithAlpha(0.20),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: context.themeColors.textPrimaryWithAlpha(0.35),
              width: AppLayout.borderMedium,
            ),
            boxShadow: [
              BoxShadow(
                // gray900 토큰 사용 (Tinted Grey 그림자)
                color: ColorTokens.gray900.withValues(alpha: 0.20),
                blurRadius: EffectLayout.modalBlurSigma,
                offset: const Offset(0, AppSpacing.md),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '✦',
              // emojiLg 토큰 사용 (22px)
              style: AppTypography.emojiLg.copyWith(
                fontSize: MiscLayout.emojiSplash,
                color: context.themeColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
