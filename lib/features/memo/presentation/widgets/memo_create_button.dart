// F-Memo: 새 메모 생성 버튼 위젯
// 메모 리스트 상단에 표시되며, 탭 시 새 메모를 생성한다.
import 'package:flutter/material.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';

/// 새 메모 생성 버튼
class MemoCreateButton extends StatelessWidget {
  /// 버튼 탭 시 호출되는 콜백
  final VoidCallback onTap;

  const MemoCreateButton({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tc = context.themeColors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Material(
        color: ColorTokens.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.mdLg,
            ),
            decoration: BoxDecoration(
              color: tc.accentWithAlpha(0.10),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add,
                  size: AppLayout.iconMd,
                  color: tc.accent,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '+ 새 메모',
                  style: AppTypography.bodyMd.copyWith(
                    color: tc.accent,
                    fontWeight: AppTypography.weightSemiBold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
