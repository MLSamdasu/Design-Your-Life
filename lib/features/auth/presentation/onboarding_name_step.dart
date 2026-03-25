// 온보딩 2단계: 이름 입력 위젯 (SRP 분리)
// NameInputStep을 담는다.
// onboarding_widgets.dart에서 추출한다.
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/theme/typography_tokens.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../shared/widgets/glass_input_field.dart';
import 'onboarding_shared_widgets.dart';
import '../../../core/theme/radius_tokens.dart';
import '../../../core/theme/spacing_tokens.dart';
import '../../../core/theme/layout_tokens.dart';

/// 이름 입력 단계 위젯
/// 이름 텍스트 필드 + "시작하기" 버튼으로 구성된다
class NameInputStep extends StatelessWidget {
  final TextEditingController controller;
  final String? errorText;
  final bool isSaving;
  final VoidCallback onComplete;

  const NameInputStep({
    super.key,
    required this.controller,
    required this.errorText,
    required this.isSaving,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 단계 인디케이터 (2/2)
        const StepIndicator(currentStep: 2, totalSteps: 2),
        const SizedBox(height: AppSpacing.huge),

        // Glass 카드 (이름 입력 필드)
        ClipRRect(
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
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 카드 제목
                  Text(
                    '어떻게 불러드릴까요?',
                    style: AppTypography.headingSm.copyWith(
                    color: context.themeColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '홈 화면 인사말에 사용될 이름을 입력해주세요',
                    style: AppTypography.bodySm.copyWith(
                      color: context.themeColors.textPrimaryWithAlpha(0.65),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxxl),

                  // 이름 입력 필드 (GlassInputField 공용 위젯 사용)
                  GlassInputField(
                    controller: controller,
                    label: '이름',
                    hint: '이름을 입력해주세요 (최대 20자)',
                    maxLength: 20,
                    errorText: errorText,
                    autofocus: true,
                    prefixIcon: Icons.person_outline_rounded,
                    onSubmitted: onComplete,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),

        // 시작하기 버튼
        NextButton(
          label: '시작하기',
          isEnabled: !isSaving,
          isLoading: isSaving,
          onTap: onComplete,
        ),
      ],
    );
  }
}
