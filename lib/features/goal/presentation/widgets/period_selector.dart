// F5 위젯: PeriodSelector + PillTab - 기간 선택 위젯 (년간/월간 Pill 탭)
// SRP 분리: goal_create_form_fields.dart에서 기간 선택 관련 위젯을 추출
import 'package:flutter/material.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../shared/enums/goal_period.dart';
import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';

// ─── 기간 선택 위젯 ───────────────────────────────────────────────────────

/// 기간 선택 위젯 (년간/월간 Pill 탭)
class PeriodSelector extends StatelessWidget {
  final GoalPeriod selected;
  final ValueChanged<GoalPeriod> onChanged;

  const PeriodSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.themeColors.textPrimaryWithAlpha(0.1),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: Row(
        children: [
          PillTab(
            label: '년간',
            isSelected: selected == GoalPeriod.yearly,
            onTap: () => onChanged(GoalPeriod.yearly),
          ),
          PillTab(
            label: '월간',
            isSelected: selected == GoalPeriod.monthly,
            onTap: () => onChanged(GoalPeriod.monthly),
          ),
        ],
      ),
    );
  }
}

/// Pill 탭 아이템 (기간 선택 탭용)
class PillTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const PillTab({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppAnimation.normal,
          curve: Curves.easeInOutCubic,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: isSelected
                ? context.themeColors.textPrimaryWithAlpha(0.25)
                : ColorTokens.transparent,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTypography.captionLg.copyWith(
              // WCAG 최소 대비: 비선택 탭 텍스트 0.55 이상 보장
              color: isSelected
                  ? context.themeColors.textPrimary
                  : context.themeColors.textPrimaryWithAlpha(0.55),
              fontWeight: isSelected ? AppTypography.weightBold : AppTypography.weightRegular,
            ),
          ),
        ),
      ),
    );
  }
}
