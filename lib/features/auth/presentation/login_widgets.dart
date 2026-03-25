// 인증 Feature: 로그인 화면 하위 위젯 모음
// SRP 분리: login_screen.dart에서 AppIcon, LoginCard를 추출한다.
// GoogleSignInButton은 google_sign_in_button.dart로 별도 분리한다.
// 입력: isLoading, errorMessage, onGoogleSignIn 콜백
// 출력: 로그인 UI 위젯
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../core/theme/typography_tokens.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/theme/radius_tokens.dart';
import '../../../core/theme/spacing_tokens.dart';
import '../../../core/theme/layout_tokens.dart';
import 'google_sign_in_button.dart';

// ─── 앱 아이콘 위젯 ─────────────────────────────────────────────────────────

/// 앱 아이콘 (Glass 스타일, 80x80px)
class AppIcon extends StatelessWidget {
  const AppIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.massive),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: EffectLayout.blurSigmaStandard, sigmaY: EffectLayout.blurSigmaStandard),
        child: Container(
          width: MiscLayout.appIconSize,
          height: MiscLayout.appIconSize,
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
                blurRadius: EffectLayout.shadowBlurXl,
                offset: const Offset(0, EffectLayout.shadowOffsetMd),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '✦',
              style: AppTypography.emojiLg.copyWith(
                fontSize: MiscLayout.emojiAppIcon,
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
        filter: ImageFilter.blur(sigmaX: EffectLayout.blurSigmaStandard, sigmaY: EffectLayout.blurSigmaStandard),
        child: Container(
          padding: const EdgeInsets.all(MiscLayout.loginCardPadding),
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
                blurRadius: EffectLayout.shadowBlurXxl,
                offset: const Offset(0, EffectLayout.shadowOffsetLg),
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
