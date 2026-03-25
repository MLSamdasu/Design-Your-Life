// F4 서브위젯: FrequencyToggle - 빈도 토글 버튼
// HabitPresetFrequencyStep에서 사용하는 매일/특정 요일 토글 버튼
import 'package:flutter/material.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';

/// 빈도 토글 버튼 (매일 / 특정 요일)
class FrequencyToggle extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const FrequencyToggle({
    required this.label,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppAnimation.fast,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.mdLg),
        decoration: BoxDecoration(
          color: isSelected
              ? context.themeColors.accentWithAlpha(0.85)
              : context.themeColors.textPrimaryWithAlpha(0.08),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: isSelected
                ? context.themeColors.accent
                : context.themeColors.textPrimaryWithAlpha(0.18),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTypography.bodyMd.copyWith(
              color: context.themeColors.textPrimary,
              fontWeight: isSelected
                  ? AppTypography.weightBold
                  : AppTypography.weightRegular,
            ),
          ),
        ),
      ),
    );
  }
}
