// 인증 Feature: 로그인 화면 하위 위젯 모음
// SRP 분리: login_screen.dart에서 AppIcon, LoginCard, GoogleSignInButton을 추출한다.
// IN: isLoading, errorMessage, onGoogleSignIn 콜백
// OUT: 로그인 UI 위젯
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../core/theme/typography_tokens.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/theme/animation_tokens.dart';
import '../../../core/theme/radius_tokens.dart';
import '../../../core/theme/spacing_tokens.dart';
import '../../../core/theme/layout_tokens.dart';

// ─── 앱 아이콘 위젯 ─────────────────────────────────────────────────────────

/// 앱 아이콘 (Glass 스타일, 80x80px)
class AppIcon extends StatelessWidget {
  const AppIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.massive),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: AppLayout.blurSigmaStandard, sigmaY: AppLayout.blurSigmaStandard),
        child: Container(
          width: AppLayout.appIconSize,
          height: AppLayout.appIconSize,
          decoration: BoxDecoration(
            color: context.themeColors.textPrimaryWithAlpha(0.18),
            borderRadius: BorderRadius.circular(AppRadius.massive),
            border: Border.all(
              color: context.themeColors.textPrimaryWithAlpha(0.30),
              width: AppLayout.borderMedium,
            ),
            boxShadow: [
              BoxShadow(
                color: ColorTokens.gray900.withValues(alpha: 0.18),
                blurRadius: AppLayout.shadowBlurXl,
                offset: const Offset(0, AppLayout.shadowOffsetMd),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '✦',
              style: AppTypography.emojiLg.copyWith(
                fontSize: AppLayout.emojiAppIcon,
                color: context.themeColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── 로그인 카드 ─────────────────────────────────────────────────────────────

/// 로그인 카드 (Glass 모달 스타일)
/// Google Sign-In 버튼 + 에러 메시지를 포함한다
class LoginCard extends StatelessWidget {
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onGoogleSignIn;
  /// 테스트 로그인 콜백 (kDebugMode에서만 non-null)
  final VoidCallback? onTestSignIn;

  const LoginCard({
    super.key,
    required this.isLoading,
    required this.errorMessage,
    required this.onGoogleSignIn,
    this.onTestSignIn,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.massive),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: AppLayout.blurSigmaStandard, sigmaY: AppLayout.blurSigmaStandard),
        child: Container(
          padding: const EdgeInsets.all(AppLayout.loginCardPadding),
          decoration: BoxDecoration(
            color: context.themeColors.textPrimaryWithAlpha(0.15),
            borderRadius: BorderRadius.circular(AppRadius.massive),
            border: Border.all(
              color: context.themeColors.textPrimaryWithAlpha(0.25),
              width: AppLayout.borderThin,
            ),
            boxShadow: [
              BoxShadow(
                color: ColorTokens.gray900.withValues(alpha: 0.12),
                blurRadius: AppLayout.shadowBlurXxl,
                offset: const Offset(0, AppLayout.shadowOffsetLg),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 카드 제목
              Text(
                '시작하기',
                style: AppTypography.headingSm.copyWith(
                    color: context.themeColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Google 계정으로 간편하게 로그인하세요',
                style: AppTypography.captionMd.copyWith(
                  color: context.themeColors.textPrimaryWithAlpha(0.60),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxxl),

              // Google 로그인 버튼 (접근성: Semantics 래핑)
              Semantics(
                label: 'Google 계정으로 로그인',
                button: true,
                child: GoogleSignInButton(
                  isLoading: isLoading,
                  onTap: onGoogleSignIn,
                ),
              ),

              // 테스트 로그인 버튼 (kDebugMode 전용)
              if (onTestSignIn != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Semantics(
                  label: '테스트 계정으로 로그인',
                  button: true,
                  child: GestureDetector(
                    onTap: isLoading ? null : onTestSignIn,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xxl,
                        vertical: AppSpacing.lgXl,
                      ),
                      decoration: BoxDecoration(
                        color: context.themeColors.textPrimaryWithAlpha(0.08),
                        borderRadius: BorderRadius.circular(AppRadius.xlLg),
                        border: Border.all(
                          color: context.themeColors.textPrimaryWithAlpha(0.20),
                          width: AppLayout.borderThin,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.bug_report_outlined,
                            size: AppLayout.iconLg,
                            color: context.themeColors.textPrimaryWithAlpha(0.60),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Text(
                            '테스트 계정으로 로그인 (DEV)',
                            style: AppTypography.captionLg.copyWith(
                              color: context.themeColors.textPrimaryWithAlpha(0.60),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],

              // 에러 메시지 (로그인 실패 시)
              if (errorMessage != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  errorMessage!,
                  style: AppTypography.captionMd.copyWith(
                    color: ColorTokens.errorLight,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

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
              blurRadius: AppLayout.shadowBlurMd,
              offset: const Offset(0, AppLayout.shadowOffsetSm),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 로딩 중이면 인디케이터, 아니면 Google 'G' 로고
            if (widget.isLoading)
              SizedBox(
                width: AppLayout.googleLogoSize,
                height: AppLayout.googleLogoSize,
                child: CircularProgressIndicator(
                  strokeWidth: AppLayout.spinnerStrokeWidth,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    context.themeColors.textPrimaryWithAlpha(0.80),
                  ),
                ),
              )
            else
              Container(
                width: AppLayout.googleLogoSize,
                height: AppLayout.googleLogoSize,
                decoration: BoxDecoration(
                  color: context.themeColors.textPrimary,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Center(
                  child: Text(
                    'G',
                    style: AppTypography.captionLg.copyWith(
                      color: ColorTokens.main,
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
