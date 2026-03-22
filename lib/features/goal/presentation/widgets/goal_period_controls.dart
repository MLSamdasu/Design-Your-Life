// F5 위젯: GoalPeriodControls - 년간/월간 탭 + 연도 선택 위젯 (SRP 분리)
// goal_list_helpers.dart에서 추출한다.
// 포함: PeriodTabRow, PeriodTabItem, YearSelector
import 'package:flutter/material.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../shared/enums/goal_period.dart';
import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';

/// 년간/월간 탭 위젯 (Glass Pill 스타일)
class PeriodTabRow extends StatelessWidget {
  final GoalPeriod selected;
  final ValueChanged<GoalPeriod> onChanged;

  const PeriodTabRow({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.themeColors.textPrimaryWithAlpha(0.1),
        borderRadius: BorderRadius.circular(AppRadius.huge),
      ),
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PeriodTabItem(
            label: '년간',
            isSelected: selected == GoalPeriod.yearly,
            onTap: () => onChanged(GoalPeriod.yearly),
          ),
          PeriodTabItem(
            label: '월간',
            isSelected: selected == GoalPeriod.monthly,
            onTap: () => onChanged(GoalPeriod.monthly),
          ),
        ],
      ),
    );
  }
}

/// 개별 기간 탭 아이템
class PeriodTabItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const PeriodTabItem({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppAnimation.normal,
        curve: Curves.easeInOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lgXl, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isSelected
              ? context.themeColors.textPrimaryWithAlpha(0.25)
              : ColorTokens.transparent,
          borderRadius: BorderRadius.circular(AppRadius.xxl),
        ),
        child: Text(
          label,
          style: AppTypography.captionLg.copyWith(
            // WCAG 최소 대비: 비선택 탭 텍스트 0.55 이상 보장
            color: isSelected
                ? context.themeColors.textPrimary
                : context.themeColors.textPrimaryWithAlpha(0.55),
            fontWeight: isSelected ? AppTypography.weightBold : AppTypography.weightRegular,
          ),
        ),
      ),
    );
  }
}

/// 연도 선택 버튼 (이전/다음 화살표)
class YearSelector extends StatelessWidget {
  final int year;
  final ValueChanged<int> onChanged;

  const YearSelector({
    super.key,
    required this.year,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () => onChanged(year - 1),
          icon: Icon(
            Icons.chevron_left_rounded,
            color: context.themeColors.textPrimaryWithAlpha(0.7),
            size: AppLayout.iconXl,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: AppLayout.minButtonSize, minHeight: AppLayout.minButtonSize),
        ),
        Text(
          '$year',
          style: AppTypography.bodyMd.copyWith(color: context.themeColors.textPrimary),
        ),
        IconButton(
          onPressed: () => onChanged(year + 1),
          icon: Icon(
            Icons.chevron_right_rounded,
            color: context.themeColors.textPrimaryWithAlpha(0.7),
            size: AppLayout.iconXl,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: AppLayout.minButtonSize, minHeight: AppLayout.minButtonSize),
        ),
      ],
    );
  }
}
