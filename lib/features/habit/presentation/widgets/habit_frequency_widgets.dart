// 습관 빈도 선택 위젯: 빈도 칩(매일/특정요일) + 요일 선택 행
import 'package:flutter/material.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';

/// 다이얼로그용 빈도 선택 칩
class FrequencyChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const FrequencyChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.mdLg),
        decoration: BoxDecoration(
          color: isSelected
              ? context.themeColors.accentWithAlpha(0.85)
              : context.themeColors.textPrimaryWithAlpha(0.08),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: isSelected
                ? context.themeColors.accent
                : context.themeColors.textPrimaryWithAlpha(0.18),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTypography.captionLg.copyWith(
              color: context.themeColors.textPrimary,
              fontWeight: isSelected
                  ? AppTypography.weightBold
                  : AppTypography.weightRegular,
            ),
          ),
        ),
      ),
    );
  }
}

/// 다이얼로그용 요일 선택 행 (월~일)
class DaySelectorRow extends StatelessWidget {
  final Set<int> selectedDays;
  final ValueChanged<int> onToggle;
  const DaySelectorRow({
    super.key,
    required this.selectedDays,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    const labels = ['월', '화', '수', '목', '금', '토', '일'];
    // 7개 원이 다이얼로그 내에서 오버플로하지 않도록
    // spaceEvenly + Flexible 조합으로 균등 배치한다
    // 터치 영역 36px, 시각적 원 28px로 축소하여 소형 기기 대응
    const touchSize = 36.0;
    const circleSize = 28.0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(AppLayout.daysInWeek, (i) {
        final day = i + 1;
        final sel = selectedDays.contains(day);
        return Flexible(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onToggle(day),
            child: SizedBox(
              width: touchSize,
              height: touchSize,
              child: Center(
                child: Container(
                  width: circleSize,
                  height: circleSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: sel
                        ? context.themeColors.accentWithAlpha(0.85)
                        : context.themeColors.textPrimaryWithAlpha(0.08),
                    border: Border.all(
                      color: sel
                          ? context.themeColors.accent
                          : context.themeColors.textPrimaryWithAlpha(0.18),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      labels[i],
                      style: AppTypography.captionSm.copyWith(
                        color: sel
                            ? context.themeColors.textPrimary
                            : context.themeColors.textPrimaryWithAlpha(0.6),
                        fontWeight: sel
                            ? AppTypography.weightBold
                            : AppTypography.weightRegular,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
