// F5 위젯: YearMonthSelector + GoalDropdownField - 연도/월 선택 위젯
// SRP 분리: goal_create_form_fields.dart에서 연도/월 선택 관련 위젯을 추출
import 'package:flutter/material.dart';

import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../shared/enums/goal_period.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';

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
            items: List.generate(GoalLayout.goalYearRange, (i) => DateTime.now().year - GoalLayout.goalYearPastOffset + i),
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
