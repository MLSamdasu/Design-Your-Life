// F4 위젯: showRoutineDeleteConfirmDialog - 루틴 삭제 확인 다이얼로그
// 루틴 삭제 전 사용자에게 확인을 요청하는 다이얼로그를 표시한다 (P1-17).
import 'package:flutter/material.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';

/// 루틴 삭제 확인 다이얼로그를 표시한다 (P1-17)
/// 사용자가 '삭제'를 선택하면 true를 반환하여 Dismissible 삭제를 허용한다
Future<bool> showRoutineDeleteConfirmDialog(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: context.themeColors.dialogSurface,
      title: Text(
        '루틴 삭제',
        style: AppTypography.titleMd.copyWith(
          color: context.themeColors.textPrimary,
        ),
      ),
      content: Text(
        '이 루틴을 삭제하시겠습니까?',
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
