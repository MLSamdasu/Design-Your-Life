// 온보딩 1단계: 개인정보 처리 동의 위젯 (SRP 분리)
// ConsentStep과 ConsentContent를 담는다.
// onboarding_widgets.dart에서 추출한다.
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/theme/typography_tokens.dart';
import '../../../core/theme/theme_colors.dart';
import 'onboarding_shared_widgets.dart';
import '../../../core/theme/radius_tokens.dart';
import '../../../core/theme/spacing_tokens.dart';

/// 개인정보 처리 동의 단계 위젯
/// 필수 동의 체크박스 + 개인정보 처리방침 링크 + 다음 버튼
class ConsentStep extends StatelessWidget {
  final bool isChecked;
  final ValueChanged<bool> onChecked;
  final VoidCallback onNext;

  const ConsentStep({
    super.key,
    required this.isChecked,
    required this.onChecked,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 단계 인디케이터 (1/2)
        const StepIndicator(currentStep: 1, totalSteps: 2),
        const SizedBox(height: AppSpacing.huge),

        // Glass 카드 (동의 내용 + 체크박스)
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.massive),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: context.themeColors.textPrimaryWithAlpha(0.15),
                borderRadius: BorderRadius.circular(AppRadius.massive),
                border: Border.all(
                  color: context.themeColors.textPrimaryWithAlpha(0.25),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 카드 제목
                  Text(
                    '개인정보 처리 동의',
                    style: AppTypography.headingSm.copyWith(
                    color: context.themeColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Design Your Life 서비스 이용을 위해\n아래 내용을 확인하고 동의해주세요',
                    style: AppTypography.bodySm.copyWith(
                      color: context.themeColors.textPrimaryWithAlpha(0.65),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  // 개인정보 처리방침 요약 내용
                  const ConsentContent(),
                  const SizedBox(height: AppSpacing.xxl),
                  // 필수 동의 체크박스 (접근성: Semantics 래핑)
                  Semantics(
                    label: '개인정보 수집 및 이용 동의 (필수)',
                    checked: isChecked,
                    child: GestureDetector(
                      onTap: () => onChecked(!isChecked),
                      child: Row(
                        children: [
                          GlassCheckbox(isChecked: isChecked),
                          const SizedBox(width: AppSpacing.mdLg),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: AppTypography.bodyMd.copyWith(
                                  color: context.themeColors.textPrimaryWithAlpha(0.85),
                                ),
                                children: [
                                  TextSpan(
                                    text: '[필수] ',
                                    style: TextStyle(
                                      color: context.themeColors.accent,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '개인정보 수집 및 이용에 동의합니다',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),

        // 다음 버튼
        NextButton(
          label: '동의하고 계속하기',
          isEnabled: isChecked,
          isLoading: false,
          onTap: onNext,
        ),
      ],
    );
  }
}

/// 개인정보 처리방침 요약 박스
class ConsentContent extends StatelessWidget {
  const ConsentContent({super.key});

  @override
  Widget build(BuildContext context) {
    const items = [
      ('수집 항목', 'Google 계정 이름, 이메일, 프로필 사진'),
      ('수집 목적', '서비스 인증 및 개인 데이터 관리'),
      ('보유 기간', '회원 탈퇴 시까지'),
      ('제3자 제공', '제공하지 않음'),
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lgXl),
      decoration: BoxDecoration(
        color: context.themeColors.textPrimaryWithAlpha(0.08),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: context.themeColors.textPrimaryWithAlpha(0.15),
        ),
      ),
      child: Column(
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 70,
                  child: Text(
                    item.$1,
                    style: AppTypography.captionLg.copyWith(
                      color: context.themeColors.textPrimaryWithAlpha(0.55),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    item.$2,
                    style: AppTypography.captionLg.copyWith(
                      color: context.themeColors.textPrimaryWithAlpha(0.85),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
