// F-Memo: 메모 삭제 확인 다이얼로그
// 모바일/데스크탑 에디터에서 공통으로 사용한다.
import 'package:flutter/material.dart';

import '../../../../core/theme/color_tokens.dart';

/// 메모 삭제 확인 다이얼로그를 표시한다
/// 사용자가 확인하면 true를 반환한다
Future<bool> showMemoDeleteDialog(BuildContext context) async {
  final confirmed = await showDialog<bool>(
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
  );
  return confirmed == true;
}
