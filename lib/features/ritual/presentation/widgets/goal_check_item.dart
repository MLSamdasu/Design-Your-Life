// 데일리 리추얼: Top 5 선택 리스트 아이템
// 체크박스 + 목표 텍스트로 구성된 개별 목표 선택 아이템이다.
// 선택 안 된 항목은 취소선 + "Avoid List" 레이블을 표시한다.

import 'package:flutter/material.dart';

import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';

/// Top 5 선택 리스트의 개별 목표 아이템
/// [index]: 목표 인덱스 (0-based)
/// [text]: 목표 텍스트
/// [isSelected]: 선택 여부
/// [canSelect]: 추가 선택 가능 여부 (5개 미만이거나 이미 선택됨)
/// [onToggle]: 선택/해제 콜백
class GoalCheckItem extends StatelessWidget {
  final int index;
  final String text;
  final bool isSelected;
  final bool canSelect;
  final VoidCallback onToggle;

  const GoalCheckItem({
    super.key,
    required this.index,
    required this.text,
    required this.isSelected,
    required this.canSelect,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final tc = context.themeColors;

    return GestureDetector(
      onTap: canSelect ? onToggle : null,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lgXl,
        ),
        margin: const EdgeInsets.only(bottom: AppSpacing.xs),
        decoration: BoxDecoration(
          color: isSelected
              ? tc.accent.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            _buildCheckIcon(tc),
            const SizedBox(width: AppSpacing.lg),
            Expanded(child: _buildGoalText(tc)),
          ],
        ),
      ),
    );
  }

  /// 체크 아이콘 (선택됨/미선택/비활성)
  Widget _buildCheckIcon(ResolvedThemeColors tc) {
    if (isSelected) {
      return Icon(
        Icons.check_circle_rounded,
        // 어두운 배경에서도 보이도록 테마 인식 악센트 사용
        color: tc.accent,
        size: 22,
      );
    }
    return Icon(
      Icons.circle_outlined,
      color: canSelect
          ? tc.textPrimaryWithAlpha(0.35)
          : tc.textPrimaryWithAlpha(0.15),
      size: 22,
    );
  }

  /// 목표 텍스트 (미선택 시 취소선 + Avoid List 레이블)
  Widget _buildGoalText(ResolvedThemeColors tc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${index + 1}. $text',
          style: AppTypography.bodyLg.copyWith(
            color: isSelected
                ? tc.textPrimary
                : tc.textPrimaryWithAlpha(0.45),
            decoration: isSelected
                ? TextDecoration.none
                : TextDecoration.lineThrough,
            decorationColor: tc.textPrimaryWithAlpha(0.30),
          ),
        ),
        if (!isSelected)
          Text(
            'Avoid List',
            style: AppTypography.captionSm.copyWith(
              // alpha 0.50은 너무 연하므로 0.75로 올려 가독성 확보
              color: tc.isOnDarkBackground
                  ? const Color(0xFFF87171).withValues(alpha: 0.80)
                  : const Color(0xFFEF4444).withValues(alpha: 0.75),
            ),
          ),
      ],
    );
  }
}
