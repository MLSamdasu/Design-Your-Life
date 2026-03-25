// 공용 위젯: DateItem (날짜 슬라이더 개별 아이템)
// DateSlider 내부에서 사용하는 개별 날짜 아이템 위젯 (SRP 분리)
import 'package:flutter/material.dart';
import '../../core/theme/animation_tokens.dart';
import '../../core/theme/color_tokens.dart';
import '../../core/theme/layout_tokens.dart';
import '../../core/theme/radius_tokens.dart';
import '../../core/theme/spacing_tokens.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/theme/typography_tokens.dart';

/// 날짜 슬라이더 개별 날짜 아이템
class DateItem extends StatelessWidget {
  final DateTime date;
  final bool isSelected;
  final bool isToday;
  final VoidCallback onTap;

  const DateItem({
    required this.date,
    required this.isSelected,
    required this.isToday,
    required this.onTap,
    super.key,
  });

  static const List<String> _weekdayLabels = [
    '월', '화', '수', '목', '금', '토', '일'
  ];

  @override
  Widget build(BuildContext context) {
    // Dart weekday: 1=월 ~ 7=일
    final weekdayLabel = _weekdayLabels[date.weekday - 1];
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppAnimation.normal,
        curve: Curves.easeInOutCubic,
        width: AppLayout.containerLg,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        // 선택된 날짜 캡슐: 배경 테마에 맞는 악센트 색상을 사용한다.
        // Glassmorphism/Neon에서는 밝은 보라(mainLight)로 표시해 가독성을 확보한다.
        decoration: isSelected
            ? BoxDecoration(
                color: context.themeColors.accent,
                borderRadius: BorderRadius.circular(AppRadius.xxl + AppSpacing.xxs),
                boxShadow: [
                  BoxShadow(
                    color: context.themeColors.accentWithAlpha(0.4),
                    blurRadius: EffectLayout.shadowBlurMd,
                    offset: const Offset(0, EffectLayout.shadowOffsetSm),
                  ),
                ],
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 요일 텍스트
            Text(
              weekdayLabel,
              style: AppTypography.captionMd.copyWith(
                // 선택된 상태는 MAIN 컬러 배경 위이므로 흰색 유지
                color: isSelected
                    ? ColorTokens.white
                    : context.themeColors.textPrimaryWithAlpha(0.6),
                fontWeight:
                    isSelected ? AppTypography.weightSemiBold : AppTypography.weightRegular,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            // 날짜 숫자
            Text(
              '${date.day}',
              style: AppTypography.bodyMd.copyWith(
                // 선택된 상태는 MAIN 컬러 배경 위이므로 흰색 유지
                color: isSelected
                    ? ColorTokens.white
                    : isToday
                        ? context.themeColors.textPrimary
                        : context.themeColors.textPrimaryWithAlpha(0.7),
                fontWeight: isSelected || isToday
                    ? AppTypography.weightBold
                    : AppTypography.weightRegular,
              ),
            ),
            // 오늘 표시 점: 배경 테마에 맞는 악센트 색상을 사용한다.
            if (isToday && !isSelected)
              Container(
                margin: const EdgeInsets.only(top: AppSpacing.xxs),
                width: AppSpacing.xs,
                height: AppSpacing.xs,
                decoration: BoxDecoration(
                  color: context.themeColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
