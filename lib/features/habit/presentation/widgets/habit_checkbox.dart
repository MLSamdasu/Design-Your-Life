// F4 위젯: HabitCheckbox - 습관 원형 체크박스
// 완료 상태에 따라 색상/보더/아이콘이 전환되며, 부드러운 애니메이션을 적용한다.
import 'package:flutter/material.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';

/// 습관 원형 체크박스
/// slow + easeInOut 전환으로 체크 상태를 시각적으로 피드백한다.
class HabitCheckbox extends StatelessWidget {
  final bool isChecked;
  final bool isEditable;

  const HabitCheckbox({
    required this.isChecked,
    required this.isEditable,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      // slow + easeInOut로 부드러운 색상/보더 전환
      duration: AppAnimation.slow,
      curve: Curves.easeInOut,
      width: AppLayout.checkboxLg,
      height: AppLayout.checkboxLg,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // 완료 상태: habitCheck 토큰 (초록 계열) 기반 색상
        color: isChecked
            ? ColorTokens.habitCheck.withValues(alpha: 0.4)
            : ColorTokens.transparent,
        border: Border.all(
          color: isChecked
              ? ColorTokens.habitCheck.withValues(alpha: 0.6)
              : isEditable
                  ? context.themeColors.textPrimaryWithAlpha(0.3)
                  : context.themeColors.textPrimaryWithAlpha(0.15),
          width: AppLayout.borderThick,
        ),
      ),
      // 체크 아이콘 페이드 인/아웃 (abrupt 전환 방지)
      child: AnimatedOpacity(
        opacity: isChecked ? 1.0 : 0.0,
        duration: AppAnimation.slow,
        curve: Curves.easeInOut,
        child: Icon(
          Icons.check_rounded,
          size: AppLayout.iconSm,
          color: context.themeColors.textPrimary,
        ),
      ),
    );
  }
}
