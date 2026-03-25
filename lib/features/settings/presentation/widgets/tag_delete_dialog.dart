// 태그 삭제 확인 다이얼로그
// 삭제 전 사용자에게 확인을 요청하고, 확인 시 태그를 삭제한다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../shared/models/tag.dart';
import '../../../../shared/providers/tag_provider.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../../core/theme/radius_tokens.dart';

/// 태그 삭제 확인 다이얼로그를 표시하고, 확인 시 삭제를 수행한다
Future<void> showTagDeleteDialog(
  BuildContext context,
  WidgetRef ref,
  Tag tag,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    barrierColor: ColorTokens.barrierBase.withValues(alpha: 0.5),
    // 테마 인식 다이얼로그 배경: 모든 테마에서 텍스트 가독성 보장
    builder: (ctx) => AlertDialog(
      backgroundColor: context.themeColors.dialogSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.huge),
      ),
      title: Text(
        '태그 삭제',
        style: AppTypography.titleLg.copyWith(
          color: context.themeColors.textPrimary,
        ),
      ),
      content: Text(
        '"${tag.name}" 태그를 삭제합니다.\n이미 태그가 부착된 아이템에서는 해당 태그가 표시되지 않게 됩니다.',
        style: AppTypography.bodyLg.copyWith(
          color: context.themeColors.textPrimaryWithAlpha(0.7),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(null),
          child: Text(
            '취소',
            style: AppTypography.titleMd.copyWith(
              color: context.themeColors.textPrimaryWithAlpha(0.7),
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(
            '삭제',
            style: AppTypography.titleMd.copyWith(
              color: ColorTokens.errorLight,
            ),
          ),
        ),
      ],
    ),
  );

  if (confirmed != true) return;

  final deleteTag = ref.read(deleteTagProvider);
  try {
    await deleteTag(tag.id);
    // 태그 삭제 시 deleteTagProvider가 버전 카운터를 증가시켜 모든 파생 Provider가 자동 갱신된다
  } catch (e) {
    if (!context.mounted) return;
    AppSnackBar.showError(context, '태그 삭제에 실패했습니다');
  }
}
