// F4 위젯: TimetableDayHeader — 요일 헤더 행 (오늘 강조)
import 'package:flutter/material.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';

/// 요일 헤더 행 (오늘 강조)
class TimetableDayHeader extends StatelessWidget {
  final double labelWidth;
  final double colWidth;

  const TimetableDayHeader({
    required this.labelWidth,
    required this.colWidth,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    const days = ['월', '화', '수', '목', '금', '토', '일'];
    final todayIdx = DateTime.now().weekday - 1;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(width: labelWidth),
        ...List.generate(7, (i) {
          final isToday = i == todayIdx;
          return SizedBox(
            width: colWidth,
            child: Center(
              child: Container(
                width: 28,
                height: 28,
                // 오늘 날짜 표시 원
                decoration: isToday
                    ? BoxDecoration(
                        color: context.themeColors.accentWithAlpha(0.7),
                        shape: BoxShape.circle,
                      )
                    : null,
                child: Center(
                  child: Text(
                    days[i],
                    style: AppTypography.bodyMd.copyWith(
                      color: isToday
                          ? context.themeColors.textPrimary
                          : i >= 5
                              ? context.themeColors.textPrimaryWithAlpha(0.5)
                              : context.themeColors.textPrimaryWithAlpha(0.7),
                      fontWeight: isToday
                          ? AppTypography.weightBold
                          : AppTypography.weightMedium,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
