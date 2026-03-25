// F-Memo: 메모 아이템 컨텍스트 메뉴
// 롱프레스 시 표시되는 바텀 시트 (고정/해제, 삭제)와 삭제 확인 다이얼로그를 제공한다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../models/memo.dart';
import '../../providers/memo_provider.dart';

/// 메모 삭제 확인 다이얼로그를 표시하고 결과를 반환한다
Future<bool> showMemoDeleteConfirmDialog(BuildContext context) async {
  return await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('메모 삭제'),
          content: const Text('이 메모를 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                '삭제',
                style: TextStyle(color: ColorTokens.error),
              ),
            ),
          ],
        ),
      ) ??
      false;
}

/// 메모 롱프레스 컨텍스트 메뉴 (고정/해제, 삭제)를 바텀 시트로 표시한다
void showMemoContextMenu({
  required BuildContext context,
  required WidgetRef ref,
  required Memo memo,
}) {
  final tc = context.themeColors;
  showModalBottomSheet(
    context: context,
    backgroundColor: tc.dialogSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppRadius.bottomSheet),
      ),
    ),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 고정/해제 타일
          ListTile(
            leading: Icon(
              memo.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
              color: tc.textPrimary,
            ),
            title: Text(
              memo.isPinned ? '고정 해제' : '상단 고정',
              style: AppTypography.bodyLg.copyWith(
                color: tc.textPrimary,
              ),
            ),
            onTap: () {
              Navigator.pop(ctx);
              final updated = memo.copyWith(
                isPinned: !memo.isPinned,
                updatedAt: DateTime.now(),
              );
              ref.read(updateMemoProvider)(memo.id, updated);
            },
          ),
          // 삭제 타일
          ListTile(
            leading: Icon(Icons.delete_outline, color: ColorTokens.error),
            title: Text(
              '삭제',
              style: AppTypography.bodyLg.copyWith(
                color: ColorTokens.error,
              ),
            ),
            onTap: () async {
              Navigator.pop(ctx);
              final confirmed =
                  await showMemoDeleteConfirmDialog(context);
              if (confirmed) {
                ref.read(deleteMemoProvider)(memo.id);
              }
            },
          ),
        ],
      ),
    ),
  );
}
