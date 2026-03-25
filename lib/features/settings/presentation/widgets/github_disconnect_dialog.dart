// F6-GH: GitHub 연결 해제 확인 다이얼로그
// 사용자가 GitHub 연결을 해제하기 전에 확인을 요청한다
import 'package:flutter/material.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';

/// GitHub 연결 해제 전 사용자 확인 다이얼로그를 표시한다
/// true를 반환하면 연결 해제를 진행하고, null이면 취소한다
Future<bool?> showGitHubDisconnectDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierColor: ColorTokens.barrierBase.withValues(alpha: 0.5),
    builder: (ctx) => AlertDialog(
      backgroundColor: ctx.themeColors.dialogSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.huge),
      ),
      title: Text(
        'GitHub 연결 해제',
        style: AppTypography.titleLg
            .copyWith(color: ctx.themeColors.textPrimary),
      ),
      content: Text(
        'GitHub 연결을 해제하면 자동 백업이 중지됩니다.\n'
        '기존 백업 데이터는 GitHub에 보존됩니다.',
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
            '연결 해제',
            style: AppTypography.titleMd
                .copyWith(color: ColorTokens.error),
          ),
        ),
      ],
    ),
  );
}
