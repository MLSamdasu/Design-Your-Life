// F6: 복원 확인 다이얼로그
// 복원 전 사용자가 로컬 데이터 덮어쓰기를 인지하도록 경고한다
import 'package:flutter/material.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';

/// 복원 전 사용자 확인 다이얼로그를 표시한다
/// true를 반환하면 복원을 진행하고, null이면 취소한다
Future<bool?> showRestoreConfirmDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierColor: ColorTokens.barrierBase.withValues(alpha: 0.5),
    // 테마 인식 다이얼로그 배경: 모든 테마에서 텍스트 가독성 보장
    builder: (ctx) => AlertDialog(
      backgroundColor: ctx.themeColors.dialogSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.huge),
      ),
      title: Text(
        '데이터 복원',
        style: AppTypography.titleLg
            .copyWith(color: ctx.themeColors.textPrimary),
      ),
      content: Text(
        'Google Drive 데이터로 복원하면 현재 로컬 데이터를 덮어씁니다.\n'
        '이 작업은 되돌릴 수 없습니다.',
        style: AppTypography.bodyLg.copyWith(
          color: ctx.themeColors.textPrimaryWithAlpha(0.7),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(null),
          child: Text(
            '취소',
            style: AppTypography.titleMd.copyWith(
              color: ctx.themeColors.textPrimaryWithAlpha(0.7),
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(
            '복원',
            style: AppTypography.titleMd
                .copyWith(color: ctx.themeColors.accent),
          ),
        ),
      ],
    ),
  );
}
