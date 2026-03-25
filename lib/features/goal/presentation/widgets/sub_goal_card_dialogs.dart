// F5 다이얼로그: SubGoalCard에서 사용하는 다이얼로그 함수들
// 하위 목표 수정/삭제, 실천과제 추가 다이얼로그를 제공한다.
import 'package:flutter/material.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';

/// 하위 목표 제목 수정 다이얼로그를 표시한다
/// [currentTitle]에 기존 제목을 전달하면 편집 가능한 상태로 표시된다.
/// 저장 시 수정된 제목 문자열, 취소 시 null을 반환한다.
Future<String?> showEditSubGoalDialog(
  BuildContext context,
  String currentTitle,
) async {
  final controller = TextEditingController(text: currentTitle);
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: context.themeColors.dialogSurface,
      title: Text(
        '하위 목표 수정',
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
          hintText: '하위 목표 제목',
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
          onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
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
  );
  controller.dispose();
  return result;
}

/// 하위 목표 삭제 확인 다이얼로그를 표시한다
/// 삭제 확인 시 true, 취소 시 false를 반환한다.
Future<bool> showDeleteSubGoalDialog(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: context.themeColors.dialogSurface,
      title: Text(
        '하위 목표 삭제',
        style: AppTypography.titleMd.copyWith(
          color: context.themeColors.textPrimary,
        ),
      ),
      content: Text(
        '이 하위 목표와 관련된 실천 과제가 모두 삭제됩니다.\n정말 삭제하시겠습니까?',
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

/// 실천 과제 추가 다이얼로그를 표시한다
/// 추가 확인 시 입력된 제목 문자열, 취소 시 null을 반환한다.
Future<String?> showAddTaskDialog(BuildContext context) async {
  final controller = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: context.themeColors.dialogSurface,
      title: Text(
        '실천 과제 추가',
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
          hintText: '실천 과제 제목을 입력해주세요',
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
          onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
          child: Text(
            '추가',
            style: AppTypography.bodyMd.copyWith(
              // 테마 인식: 다크 모드 dialogSurface 위에서도 고대비를 보장한다
              color: context.themeColors.accent,
            ),
          ),
        ),
      ],
    ),
  );
  controller.dispose();
  return result;
}
