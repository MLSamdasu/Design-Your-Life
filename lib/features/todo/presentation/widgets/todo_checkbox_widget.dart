// F3 위젯: TodoCheckboxWidget - 투두 체크박스
// 사각형 6px radius, 완료 시 빨간색 배경 + 체크 아이콘
// AnimatedContainer slow(500ms) + AnimatedOpacity로 부드러운 전환
import 'package:flutter/material.dart';

import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/theme_colors.dart';

/// 투두 체크박스 위젯 (사각형, 6px radius)
/// AnimatedContainer slow(500ms) + AnimatedOpacity로 부드러운 전환
class TodoCheckboxWidget extends StatelessWidget {
  final bool isChecked;

  const TodoCheckboxWidget({
    required this.isChecked,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppAnimation.slow,
      curve: Curves.easeInOut,
      width: AppLayout.checkboxMd,
      height: AppLayout.checkboxMd,
      decoration: BoxDecoration(
        // 완료: 빨간색 배경 / 미완료: 투명
        color: isChecked
            ? ColorTokens.error.withValues(alpha: 0.20)
            : ColorTokens.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isChecked
              ? ColorTokens.error
              : context.themeColors.textPrimaryWithAlpha(0.50),
          width: AppLayout.borderThick,
        ),
      ),
      // 체크 아이콘: AnimatedOpacity로 부드러운 fade 전환 (조건부 null 대신)
      child: AnimatedOpacity(
        opacity: isChecked ? 1.0 : 0.0,
        duration: AppAnimation.slow,
        child: Icon(
          Icons.check_rounded,
          size: AppLayout.iconXxxs,
          color: ColorTokens.error,
        ),
      ),
    );
  }
}
