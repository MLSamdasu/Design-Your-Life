// 인증 Feature: Google 로그인 버튼 위젯
// SRP 분리: login_widgets.dart에서 GoogleSignInButton을 추출한다.
// 입력: isLoading, onTap 콜백
// 출력: Google 로그인 버튼 UI
import 'package:flutter/material.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../core/theme/typography_tokens.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/theme/animation_tokens.dart';
import '../../../core/theme/radius_tokens.dart';
import '../../../core/theme/spacing_tokens.dart';
import '../../../core/theme/layout_tokens.dart';

// ─── Google 로그인 버튼 ─────────────────────────────────────────────────────

/// Google 로그인 버튼 (Glass 스타일)
/// Pressed 시 opacity 증가, 로딩 중엔 인디케이터를 표시한다
class GoogleSignInButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onTap;

  const GoogleSignInButton({
    super.key,
    required this.isLoading,
    required this.onTap,
  });

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        if (!widget.isLoading) setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        if (!widget.isLoading) setState(() => _isPressed = false);
      },
      onTapCancel: () {
        if (!widget.isLoading) setState(() => _isPressed = false);
      },
      onTap: widget.isLoading ? null : widget.onTap,
      child: AnimatedContainer(
        duration: AppAnimation.fast,
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl, vertical: AppSpacing.lgXl),
        decoration: BoxDecoration(
          // Pressed 시 opacity 증가 (design-system.md 4.4절)
          color: _isPressed
              ? context.themeColors.textPrimaryWithAlpha(0.30)
              : context.themeColors.textPrimaryWithAlpha(0.18),
          borderRadius: BorderRadius.circular(AppRadius.xlLg),
          border: Border.all(
            color: context.themeColors.textPrimaryWithAlpha(0.35),
            width: AppLayout.borderThin,
          ),
          boxShadow: [
            BoxShadow(
              color: ColorTokens.main.withValues(alpha: 0.15),
              blurRadius: EffectLayout.shadowBlurMd,
              offset: const Offset(0, EffectLayout.shadowOffsetSm),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 로딩 중이면 인디케이터, 아니면 Google 'G' 로고
            if (widget.isLoading)
              SizedBox(
                width: MiscLayout.googleLogoSize,
                height: MiscLayout.googleLogoSize,
                child: CircularProgressIndicator(
                  strokeWidth: GoalLayout.spinnerStrokeWidth,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    context.themeColors.textPrimaryWithAlpha(0.80),
                  ),
                ),
              )
            else
              Container(
                width: MiscLayout.googleLogoSize,
                height: MiscLayout.googleLogoSize,
                decoration: BoxDecoration(
                  color: context.themeColors.textPrimary,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Center(
                  child: Text(
                    'G',
                    style: AppTypography.captionLg.copyWith(
                      // textPrimary 배경(다크→밝은색/라이트→어두운색) 위이므로
                      // 반전 색상을 사용하여 고대비를 유지한다
                      color: context.themeColors.isOnDarkBackground
                          ? ColorTokens.main
                          : ColorTokens.mainLight,
                      fontWeight: AppTypography.weightExtraBold,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
            const SizedBox(width: AppSpacing.lg),
            // 버튼 텍스트
            Text(
              widget.isLoading ? '로그인 중...' : 'Google로 시작하기',
              // titleMd 토큰 사용 (15px, SemiBold)
              style: AppTypography.titleMd.copyWith(
                    color: context.themeColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
