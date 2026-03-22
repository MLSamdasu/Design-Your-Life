// F2 위젯: DatePickerButton / TimePickerButton
// 날짜/시간 선택 버튼 - 탭하면 DatePicker/TimePicker 다이얼로그를 표시한다
// SRP: 날짜/시간 값 표시 + 탭 콜백 위임만 담당
import 'package:flutter/material.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';

/// 날짜 선택 버튼 (YYYY.MM.DD 형식으로 표시)
class DatePickerButton extends StatelessWidget {
  final DateTime date;
  final VoidCallback onTap;

  const DatePickerButton({super.key, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final formatted =
        '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.mdLg),
        decoration: BoxDecoration(
          color: context.themeColors.textPrimaryWithAlpha(0.12),
          borderRadius: BorderRadius.circular(AppRadius.lgXl),
          border: Border.all(
            color: context.themeColors.textPrimaryWithAlpha(0.20),
            width: AppLayout.borderThin,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              color: context.themeColors.textPrimaryWithAlpha(0.60),
              size: AppLayout.iconSm,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                formatted,
                style: AppTypography.bodyMd.copyWith(color: context.themeColors.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 시간 선택 버튼 (HH:MM 형식으로 표시)
class TimePickerButton extends StatelessWidget {
  final TimeOfDay? time;
  final String hint;
  final VoidCallback onTap;

  const TimePickerButton({
    super.key,
    required this.time,
    required this.hint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = time != null
        ? '${time!.hour.toString().padLeft(2, '0')}:${time!.minute.toString().padLeft(2, '0')}'
        : hint;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.mdLg),
        decoration: BoxDecoration(
          color: context.themeColors.textPrimaryWithAlpha(0.12),
          borderRadius: BorderRadius.circular(AppRadius.lgXl),
          border: Border.all(
            color: context.themeColors.textPrimaryWithAlpha(0.20),
            width: AppLayout.borderThin,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.access_time_rounded,
              color: context.themeColors.textPrimaryWithAlpha(0.60),
              size: AppLayout.iconSm,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: AppTypography.bodyMd.copyWith(
                color: time != null
                    ? context.themeColors.textPrimary
                    // WCAG 최소 대비: 힌트 텍스트도 0.55 이상 보장
                    : context.themeColors.textPrimaryWithAlpha(0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 날짜/시간 선택 다이얼로그 헬퍼 함수들 (테마 인식 배경색 적용)
Future<DateTime?> showGlassDatePicker(
    BuildContext context, DateTime initial) {
  final dialogBg = context.themeColors.dialogSurface;
  final isOnDark = context.themeColors.isOnDarkBackground;
  return showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: DateTime(2020),
    lastDate: DateTime(2035),
    // 테마 인식 Picker: 모든 테마에서 가독성 보장
    builder: (context, child) => Theme(
      data: (isOnDark ? ThemeData.dark() : ThemeData.light()).copyWith(
        colorScheme: (isOnDark
                ? const ColorScheme.dark(primary: ColorTokens.main)
                : const ColorScheme.light(primary: ColorTokens.main))
            .copyWith(surface: dialogBg),
      ),
      child: child!,
    ),
  );
}

Future<TimeOfDay?> showGlassTimePicker(
    BuildContext context, TimeOfDay initial) {
  final dialogBg = context.themeColors.dialogSurface;
  final isOnDark = context.themeColors.isOnDarkBackground;
  return showTimePicker(
    context: context,
    initialTime: initial,
    // 테마 인식 Picker: 모든 테마에서 가독성 보장
    builder: (context, child) => Theme(
      data: (isOnDark ? ThemeData.dark() : ThemeData.light()).copyWith(
        colorScheme: (isOnDark
                ? const ColorScheme.dark(primary: ColorTokens.main)
                : const ColorScheme.light(primary: ColorTokens.main))
            .copyWith(surface: dialogBg),
      ),
      child: child!,
    ),
  );
}
