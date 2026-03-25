// F-Memo: 에디터 빈 상태 위젯
// 데스크탑 분할 뷰에서 메모가 선택되지 않았을 때 표시되는 안내 위젯이다.
import 'package:flutter/material.dart';

import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';

/// 에디터 빈 상태 위젯 (메모 미선택 시 표시)
class MemoEditorEmptyState extends StatelessWidget {
  const MemoEditorEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final tc = context.themeColors;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.note_alt_outlined,
            size: AppLayout.iconEmptyLg,
            color: tc.textPrimaryWithAlpha(0.25),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            '메모를 선택하세요',
            style: AppTypography.bodyLg.copyWith(
              color: tc.textPrimaryWithAlpha(0.40),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '좌측 목록에서 메모를 선택하거나 새 메모를 만드세요',
            style: AppTypography.captionMd.copyWith(
              color: tc.textPrimaryWithAlpha(0.30),
            ),
          ),
        ],
      ),
    );
  }
}
