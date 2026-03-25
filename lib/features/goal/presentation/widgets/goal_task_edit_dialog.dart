// F5 다이얼로그: 실천 할일 제목 수정 다이얼로그
// GoalTaskItem에서 롱프레스 시 호출되며, 수정된 제목을 반환한다
import 'package:flutter/material.dart';

import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';

/// 실천 할일 제목 수정 다이얼로그를 표시한다
/// 수정된 제목 문자열을 반환하며, 취소 시 null을 반환한다
Future<String?> showGoalTaskEditDialog(
  BuildContext context, {
  required String currentTitle,
}) {
  final controller = TextEditingController(text: currentTitle);

  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: context.themeColors.dialogSurface,
      title: Text(
        '실천 과제 수정',
        style: AppTypography.titleMd.copyWith(
          color: context.themeColors.textPrimary,
        ),
      ),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLength: 200,
        style: AppTypography.bodyMd.copyWith(
          color: context.themeColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: '실천 과제 제목',
          hintStyle: AppTypography.bodyMd.copyWith(
            color: context.themeColors.textPrimaryWithAlpha(0.4),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(
            '취소',
            style: AppTypography.bodyMd.copyWith(
              color: context.themeColors.textPrimaryWithAlpha(0.7),
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            final text = controller.text.trim();
            Navigator.of(ctx).pop(text);
          },
          child: Text(
            '저장',
            style: AppTypography.bodyMd.copyWith(
              // 테마 인식: 다크 모드 dialogSurface 위에서도 고대비를 보장한다
              color: context.themeColors.accent,
            ),
          ),
        ),
      ],
    ),
  ).then((result) {
    // 다이얼로그 닫힌 후 컨트롤러를 해제한다
    controller.dispose();
    return result;
  });
}
