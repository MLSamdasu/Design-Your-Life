// F3 위젯: TodoDatePickerRow - 날짜 선택 행
// 캘린더 아이콘 + 날짜 표시 + 탭하면 DatePicker 다이얼로그를 연다.
// todo_create_dialog.dart에서 분리된 하위 위젯이다.
import 'package:flutter/material.dart';

import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';

/// 날짜 선택 행 위젯 (P1-16)
/// 캘린더 아이콘 + 날짜 표시 + 탭하면 DatePicker 다이얼로그를 연다
class TodoDatePickerRow extends StatelessWidget {
  final DateTime selectedDate;
  final VoidCallback onTap;

  const TodoDatePickerRow({
    required this.selectedDate,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final formatted =
        '${selectedDate.year}.${selectedDate.month.toString().padLeft(2, '0')}.${selectedDate.day.toString().padLeft(2, '0')}';
    // 요일 레이블
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[(selectedDate.weekday - 1).clamp(0, 6)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '날짜',
          style: AppTypography.bodyMd.copyWith(
            color: context.themeColors.textPrimaryWithAlpha(0.8),
          ),
        ),
        const SizedBox(height: AppSpacing.mdLg),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.lg,
            ),
            decoration: BoxDecoration(
              color: context.themeColors.textPrimaryWithAlpha(0.10),
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(
                color: context.themeColors.textPrimaryWithAlpha(0.20),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  color: context.themeColors.textPrimaryWithAlpha(0.7),
                  size: AppLayout.iconMd,
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  '$formatted ($weekday)',
                  style: AppTypography.bodyLg.copyWith(
                    color: context.themeColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
