// F3 헬퍼: showTodoDeleteConfirm - 투두 삭제 확인 다이얼로그
// 사용자가 '삭제'를 선택하면 true를 반환한다 (Dismissible과 연동)
import 'package:flutter/material.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';

/// 투두 삭제 확인 다이얼로그를 표시한다 (P1-15)
/// 사용자가 '삭제'를 선택하면 true를 반환하여 Dismissible 삭제를 허용한다
Future<bool> showTodoDeleteConfirm(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: context.themeColors.dialogSurface,
      title: Text(
        '할 일 삭제',
        style: AppTypography.titleMd.copyWith(
          color: context.themeColors.textPrimary,
        ),
      ),
      content: Text(
        '이 할 일을 삭제하시겠습니까?',
        style: AppTypography.bodyMd.copyWith(
          color: context.themeColors.textPrimaryWithAlpha(0.7),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(
            '취소',
            style: AppTypography.bodyMd.copyWith(
              color: context.themeColors.textPrimaryWithAlpha(0.7),
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(
            '삭제',
            style: AppTypography.bodyMd.copyWith(
              color: ColorTokens.error,
            ),
          ),
        ),
      ],
    ),
  );
  return confirmed == true;
}
