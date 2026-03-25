// F6-GH: GitHub 복원 확인 다이얼로그
// 복원 전 사용자가 로컬 데이터 덮어쓰기를 인지하도록 경고한다
import 'package:flutter/material.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';

/// GitHub 복원 전 사용자 확인 다이얼로그를 표시한다
/// true를 반환하면 복원을 진행하고, null이면 취소한다
Future<bool?> showGitHubRestoreDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierColor: ColorTokens.barrierBase.withValues(alpha: 0.5),
    builder: (ctx) => AlertDialog(
      backgroundColor: ctx.themeColors.dialogSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.huge),
      ),
      title: Text(
        'GitHub에서 복원',
        style: AppTypography.titleLg
            .copyWith(color: ctx.themeColors.textPrimary),
      ),
      content: Text(
        'GitHub 백업 데이터로 복원하면 현재 로컬 데이터를 덮어씁니다.\n'
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
