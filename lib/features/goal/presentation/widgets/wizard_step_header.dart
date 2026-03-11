// F5 위젯: WizardStepHeader - 만다라트 위저드 헤더 영역
// 단계 진행 표시기 + 단계 제목 + 취소 버튼을 포함한다.
// SRP: 위저드 헤더 표시만 담당한다.
import 'package:flutter/material.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';

/// 위저드 헤더 (단계 표시 + 취소 버튼)
class WizardStepHeader extends StatelessWidget {
  final int step;
  final VoidCallback? onCancel;

  const WizardStepHeader({required this.step, required this.onCancel, super.key});

  static const _titles = ['핵심 목표 설정', '세부 목표 입력', '실천 과제 입력'];
  static const _subtitles = [
    '이루고 싶은 가장 중요한 목표를 입력해주세요',
    '핵심 목표를 달성하기 위한 8가지 세부 목표를 입력해주세요',
    '각 세부 목표를 위한 실천 과제를 입력해주세요',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '만다라트 만들기',
                  style: AppTypography.titleMd.copyWith(color: context.themeColors.textPrimary),
                ),
              ),
              // 취소 버튼 (접근성: Semantics 적용)
              Semantics(
                label: '위저드 닫기',
                button: true,
                child: GestureDetector(
                  onTap: onCancel,
                  child: Icon(
                    Icons.close_rounded,
                    color: context.themeColors.textPrimaryWithAlpha(0.6),
                    size: AppLayout.iconXl,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // 단계 진행 표시기
          WizardStepIndicator(currentStep: step),
          const SizedBox(height: AppSpacing.lg),
          // 단계 제목
          Text(
            _titles[step - 1],
            style: AppTypography.headingSm.copyWith(color: context.themeColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _subtitles[step - 1],
            style: AppTypography.captionMd.copyWith(
              color: context.themeColors.textPrimaryWithAlpha(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

/// 단계 진행 표시기 (1/3, 2/3, 3/3)
class WizardStepIndicator extends StatelessWidget {
  final int currentStep;

  const WizardStepIndicator({required this.currentStep, super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (i) {
        final isActive = i < currentStep;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < 2 ? 4 : 0),
            child: AnimatedContainer(
              duration: AppAnimation.medium,
              height: 4,
              decoration: BoxDecoration(
                // 어두운 배경(Glassmorphism/Neon)에서 진한 보라 대신 밝은 보라를 사용해 가독성을 확보한다
        color: isActive
                    ? context.themeColors.accent
                    : context.themeColors.textPrimaryWithAlpha(0.15),
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
            ),
          ),
        );
      }),
    );
  }
}
