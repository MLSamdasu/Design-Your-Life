// F5 유틸: showGoalDeleteDialog - 목표 삭제 확인 다이얼로그
// 삭제 전 사용자에게 확인을 받는 AlertDialog를 표시한다.
// goal_card.dart에서 분리된 헬퍼 함수이다.
import 'package:flutter/material.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';

/// 목표 삭제 확인 다이얼로그를 표시한다
/// 사용자가 '삭제'를 누르면 true, '취소'를 누르면 false/null을 반환한다
Future<bool?> showGoalDeleteDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: context.themeColors.dialogSurface,
      title: Text(
        '목표 삭제',
        style: AppTypography.titleMd.copyWith(
          color: context.themeColors.textPrimary,
        ),
      ),
      content: Text(
        '이 목표와 관련된 하위 목표, 실천 과제가 모두 삭제됩니다.\n정말 삭제하시겠습니까?',
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
}
