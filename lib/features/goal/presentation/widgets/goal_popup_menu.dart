// F5 위젯: GoalPopupMenu - 목표 카드 팝업 메뉴
// 수정/삭제 메뉴를 제공한다.
// goal_card.dart에서 분리된 하위 위젯이다.
import 'package:flutter/material.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';

/// 목표 카드 팝업 메뉴 (수정/삭제)
class GoalPopupMenu extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const GoalPopupMenu({
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppLayout.iconHuge,
      height: AppLayout.iconHuge,
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        iconSize: AppLayout.iconMd,
        icon: Icon(
          Icons.more_vert_rounded,
          color: context.themeColors.textPrimaryWithAlpha(0.5),
          size: AppLayout.iconMd,
        ),
        color: context.themeColors.dialogSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        onSelected: (value) {
          if (value == 'edit') onEdit();
          if (value == 'delete') onDelete();
        },
        itemBuilder: (context) => [
          PopupMenuItem<String>(
            value: 'edit',
            child: Row(
              children: [
                Icon(
                  Icons.edit_rounded,
                  size: AppLayout.iconSm,
                  color: context.themeColors.textPrimary,
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  '수정',
                  style: AppTypography.bodyMd.copyWith(
                    color: context.themeColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'delete',
            child: Row(
              children: [
                Icon(
                  Icons.delete_outline_rounded,
                  size: AppLayout.iconSm,
                  color: ColorTokens.error,
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  '삭제',
                  style: AppTypography.bodyMd.copyWith(
                    color: ColorTokens.error,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
