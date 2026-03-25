// "+" 새 태그 추가 버튼 위젯
// TagChipSelector의 칩 목록 끝에 표시되어 인라인 태그 생성 폼을 열 수 있게 한다.
import 'package:flutter/material.dart';

import '../../core/theme/layout_tokens.dart';
import '../../core/theme/radius_tokens.dart';
import '../../core/theme/spacing_tokens.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/theme/typography_tokens.dart';

/// "+" 새 태그 추가 버튼
class TagAddButton extends StatelessWidget {
  /// 탭 콜백
  final VoidCallback onTap;

  const TagAddButton({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        // WCAG 2.1 터치 타겟 44px 이상 확보
        constraints:
            const BoxConstraints(minHeight: AppLayout.minTouchTarget),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        // 새 태그 버튼: 테마 인식 텍스트 색상으로 배경과 충분한 대비를 확보한다
        decoration: BoxDecoration(
          color: context.themeColors.overlayLight,
          borderRadius: BorderRadius.circular(AppRadius.huge),
          border: Border.all(
            color: context.themeColors.borderMedium,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_rounded,
              size: AppLayout.iconSm,
              color: context.themeColors.textPrimaryWithAlpha(0.8),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              '새 태그',
              style: AppTypography.captionLg.copyWith(
                color: context.themeColors.textPrimaryWithAlpha(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
