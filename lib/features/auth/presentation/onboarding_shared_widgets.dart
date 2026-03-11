// 온보딩 공용 하위 위젯 모음 (SRP 분리)
// StepIndicator, NextButton, GlassCheckbox를 담는다.
// onboarding_widgets.dart에서 추출하여 각 단계 위젯이 공유한다.
import 'package:flutter/material.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../core/theme/typography_tokens.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/theme/animation_tokens.dart';
import '../../../core/theme/radius_tokens.dart';
import '../../../core/theme/spacing_tokens.dart';
import '../../../core/theme/layout_tokens.dart';

/// 단계 인디케이터 (현재/전체 진행률 표시)
class StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const StepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSteps, (index) {
        final isActive = index + 1 == currentStep;
        return AnimatedContainer(
          duration: AppAnimation.medium,
          curve: Curves.easeInOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? context.themeColors.textPrimary
                : context.themeColors.textPrimaryWithAlpha(0.35),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        );
      }),
    );
  }
}

/// Glass 스타일 커스텀 체크박스
class GlassCheckbox extends StatelessWidget {
  final bool isChecked;

  const GlassCheckbox({super.key, required this.isChecked});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppAnimation.normal,
      curve: Curves.easeOutCubic,
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: isChecked
            ? context.themeColors.accentWithAlpha(0.85)
            : context.themeColors.textPrimaryWithAlpha(0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isChecked
              ? context.themeColors.accent
              : context.themeColors.textPrimaryWithAlpha(0.30),
          width: 1.5,
        ),
      ),
      child: isChecked
          ? Icon(Icons.check_rounded, size: AppLayout.iconSm, color: context.themeColors.textPrimary)
          : null,
    );
  }
}

/// 다음/완료 버튼 (MAIN 컬러 CTA 스타일)
class NextButton extends StatefulWidget {
  final String label;
  final bool isEnabled;
  final bool isLoading;
  final VoidCallback onTap;

  const NextButton({
    super.key,
    required this.label,
    required this.isEnabled,
    required this.isLoading,
    required this.onTap,
  });

  @override
  State<NextButton> createState() => _NextButtonState();
}

class _NextButtonState extends State<NextButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDisabled = !widget.isEnabled || widget.isLoading;

    return Semantics(
      label: widget.label,
      button: true,
      enabled: !isDisabled,
      child: GestureDetector(
        onTapDown: (_) {
          if (!isDisabled) setState(() => _isPressed = true);
        },
        onTapUp: (_) {
          if (!isDisabled) setState(() => _isPressed = false);
        },
        onTapCancel: () {
          if (!isDisabled) setState(() => _isPressed = false);
        },
        onTap: isDisabled ? null : widget.onTap,
        child: AnimatedContainer(
          duration: AppAnimation.fast,
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
          decoration: BoxDecoration(
            // 배경 테마에 맞는 악센트 컬러 CTA 버튼
            color: isDisabled
                ? context.themeColors.accentWithAlpha(0.40)
                : _isPressed
                    ? ColorTokens.mainPressed
                    : context.themeColors.accent,
            borderRadius: BorderRadius.circular(AppRadius.xlLg),
            boxShadow: isDisabled
                ? null
                : [
                    BoxShadow(
                      color: context.themeColors.accentWithAlpha(0.30),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: context.themeColors.textPrimary,
                    ),
                  )
                : Text(
                    widget.label,
                    style: AppTypography.titleMd.copyWith(
                      color: isDisabled
                          ? context.themeColors.textPrimaryWithAlpha(0.60)
                          : context.themeColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
