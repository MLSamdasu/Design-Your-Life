// F3 위젯: TodoTimePickerButton - 시간 선택 버튼
// todo_time_picker.dart에서 SRP 분리한다.
import 'package:flutter/material.dart';

import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';

/// 시간 선택 버튼 위젯
class TodoTimePickerButton extends StatelessWidget {
  final TimeOfDay selectedTime;
  final VoidCallback onTap;

  const TodoTimePickerButton({
    super.key,
    required this.selectedTime,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hourStr = selectedTime.hour.toString().padLeft(2, '0');
    final minStr = selectedTime.minute.toString().padLeft(2, '0');
    return GestureDetector(
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
              Icons.access_time_rounded,
              color: context.themeColors.textPrimaryWithAlpha(0.7),
              size: AppLayout.iconMd,
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              '$hourStr:$minStr',
              style: AppTypography.bodyLg.copyWith(
                color: context.themeColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
