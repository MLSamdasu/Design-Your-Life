// F5 위젯: GoalCreateFormFields - 목표 생성 다이얼로그 폼 필드 위젯 모음
// SRP 분리: goal_create_dialog.dart에서 폼 필드 위젯들을 추출한다.
// 포함: PeriodSelector, PillTab, YearMonthSelector, DropdownField, GlassTextFormField
import 'package:flutter/material.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../shared/enums/goal_period.dart';
import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
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

// ─── 연도/월 선택 위젯 ────────────────────────────────────────────────────

/// 연도/월 선택 위젯
/// 기간이 monthly일 때만 월 선택 드롭다운을 추가로 표시한다
class YearMonthSelector extends StatelessWidget {
  final GoalPeriod period;
  final int year;
  final int month;
  final ValueChanged<int> onYearChanged;
  final ValueChanged<int> onMonthChanged;

  const YearMonthSelector({
    super.key,
    required this.period,
    required this.year,
    required this.month,
    required this.onYearChanged,
    required this.onMonthChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 연도 선택
        Expanded(
          child: GoalDropdownField<int>(
            label: '연도',
            value: year,
            items: List.generate(AppLayout.goalYearRange, (i) => DateTime.now().year - AppLayout.goalYearPastOffset + i),
            itemLabel: (y) => '$y년',
            onChanged: onYearChanged,
          ),
        ),
        // 월간 목표일 때만 월 선택 표시
        if (period == GoalPeriod.monthly) ...[
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: GoalDropdownField<int>(
              label: '월',
              value: month,
              items: List.generate(AppLayout.monthsInYear, (i) => i + 1),
              itemLabel: (m) => '$m월',
              onChanged: onMonthChanged,
            ),
          ),
        ],
      ],
    );
  }
}

// ─── 드롭다운 필드 ────────────────────────────────────────────────────────

/// Glass 스타일 드롭다운 필드
/// 연도/월 선택에 사용하는 Glass 스타일 드롭다운
class GoalDropdownField<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T> onChanged;

  const GoalDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.captionMd.copyWith(
            color: context.themeColors.textPrimaryWithAlpha(0.6),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            color: context.themeColors.textPrimaryWithAlpha(0.1),
            border: Border.all(
              color: context.themeColors.textPrimaryWithAlpha(0.2),
            ),
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              // 테마 인식 드롭다운 배경: 모든 테마에서 가독성 보장
              dropdownColor: context.themeColors.dialogSurface,
              style: AppTypography.bodyLg.copyWith(color: context.themeColors.textPrimary),
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: context.themeColors.textPrimaryWithAlpha(0.7),
              ),
              items: items
                  .map((item) => DropdownMenuItem<T>(
                        value: item,
                        child: Text(itemLabel(item)),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Glass 텍스트 폼 필드 ─────────────────────────────────────────────────

/// Glass 스타일 텍스트 입력 필드 (Form 유효성 검사 지원)
/// GoalCreateDialog의 제목/설명 입력에 사용한다
class GlassTextFormField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final int maxLength;
  final int maxLines;
  final String? Function(String?)? validator;

  const GlassTextFormField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.maxLength,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLength: maxLength,
      maxLines: maxLines,
      validator: validator,
      style: AppTypography.bodyLg.copyWith(color: context.themeColors.textPrimary),
      decoration: InputDecoration(
        hintText: hintText,
        // WCAG 최소 대비: 힌트 텍스트 0.55 이상 보장
        hintStyle: AppTypography.bodyLg.copyWith(
          color: context.themeColors.textPrimaryWithAlpha(0.55),
        ),
        // WCAG 최소 대비: 글자 수 카운터 텍스트 0.55 이상 보장
        counterStyle: AppTypography.captionSm.copyWith(
          color: context.themeColors.textPrimaryWithAlpha(0.55),
        ),
        filled: true,
        fillColor: context.themeColors.textPrimaryWithAlpha(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          borderSide: BorderSide(
            color: context.themeColors.textPrimaryWithAlpha(0.2),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          borderSide: BorderSide(
            color: context.themeColors.textPrimaryWithAlpha(0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          borderSide: BorderSide(
            color: context.themeColors.textPrimaryWithAlpha(0.5),
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          borderSide: BorderSide(
            color: ColorTokens.error.withValues(alpha: AppAnimation.errorBorderAlpha),
          ),
        ),
        errorStyle: AppTypography.captionMd.copyWith(
          color: ColorTokens.errorLight,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lgXl,
        ),
      ),
    );
  }
}
