// F4 위젯: RoutineCardDaysBadge - 루틴 반복 요일 배지
// 루틴의 반복 요일을 컴팩트한 배지 형태로 표시한다.
import 'package:flutter/material.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/theme_colors.dart';

/// 루틴 반복 요일 배지 위젯
class RoutineCardDaysBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool isActive;

  const RoutineCardDaysBadge({
    required this.label,
    required this.color,
    required this.isActive,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: isActive
            ? color.withValues(alpha: 0.2)
            : context.themeColors.textPrimaryWithAlpha(0.08),
        borderRadius: BorderRadius.circular(AppRadius.huge),
        border: Border.all(
          color: isActive
              ? color.withValues(alpha: 0.4)
              : context.themeColors.textPrimaryWithAlpha(0.12),
        ),
      ),
      child: Text(
        label.isEmpty ? '없음' : label,
        style: AppTypography.captionMd.copyWith(
          // WCAG: 활성 배지도 textPrimary 사용하여 모든 테마에서 가독성 보장
          // 배지 배경이 이미 이벤트 색상(color)으로 색상 연관성을 표현하므로 텍스트는 기본 색상 사용
          color: isActive
              ? context.themeColors.textPrimary
              : context.themeColors.textPrimaryWithAlpha(0.50),
          fontWeight: AppTypography.weightSemiBold,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
