// F6: 투두 선택 아이템 위젯
// 바텀시트 내에서 개별 투두를 표시하며, 연결 상태를 시각적으로 구분한다.
import 'package:flutter/material.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../shared/models/todo.dart';
import '../../../../shared/widgets/animated_strikethrough.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';

/// 투두 선택 아이템 위젯
/// 색상 인디케이터, 제목, 연결 상태 아이콘을 표시한다
class TodoSelectorItem extends StatelessWidget {
  final Todo todo;
  final bool isLinked;
  final VoidCallback onTap;

  const TodoSelectorItem({
    super.key,
    required this.todo,
    required this.isLinked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = ColorTokens.eventColor(todo.colorIndex);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
        // 연결된 투두는 배경 테마에 맞는 악센트 색상으로 강조한다
        decoration: BoxDecoration(
          color: isLinked
              ? context.themeColors.accentWithAlpha(0.20)
              : context.themeColors.textPrimaryWithAlpha(0.08),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: isLinked
                ? context.themeColors.accentWithAlpha(0.50)
                : context.themeColors.textPrimaryWithAlpha(0.12),
          ),
        ),
        child: Row(
          children: [
            // 색상 인디케이터
            Container(
              width: AppLayout.colorBarWidth,
              height: AppLayout.containerMd,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),

            // 투두 제목 (완료 시 빨간펜 취소선 애니메이션)
            Expanded(
              child: AnimatedStrikethrough(
                text: todo.title,
                style: AppTypography.bodyLg.copyWith(
                  color: context.themeColors.textPrimary,
                ),
                isActive: todo.isCompleted,
                maxLines: 2,
              ),
            ),

            const SizedBox(width: AppSpacing.lg),

            // 연결 상태 아이콘
            Icon(
              isLinked ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              // 연결 아이콘: 배경 테마에 맞는 악센트 색상으로 표시한다
              color: isLinked
                  ? context.themeColors.accent
                  : context.themeColors.textPrimaryWithAlpha(0.30),
              size: AppLayout.iconXl,
            ),
          ],
        ),
      ),
    );
  }
}
