// 개별 태그 칩 위젯
// 태그 하나를 색상 도트 + 이름으로 표시하며, 선택/미선택 상태를 시각적으로 구분한다.
// TagChipSelector의 칩 목록에서 각 태그를 렌더링할 때 사용한다.
import 'package:flutter/material.dart';

import '../../core/theme/animation_tokens.dart';
import '../../core/theme/color_tokens.dart';
import '../../core/theme/layout_tokens.dart';
import '../../core/theme/radius_tokens.dart';
import '../../core/theme/spacing_tokens.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/theme/typography_tokens.dart';

/// 개별 태그 칩 (선택/미선택 상태 표시)
class TagChip extends StatelessWidget {
  /// 태그 이름
  final String name;

  /// 태그 색상 (ColorTokens.eventColor로 계산된 값)
  final Color tagColor;

  /// 선택 여부
  final bool isSelected;

  /// 탭 콜백
  final VoidCallback onTap;

  const TagChip({
    super.key,
    required this.name,
    required this.tagColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AppAnimation.normal,
        curve: Curves.easeOutCubic,
        // WCAG 2.1 터치 타겟 44px 이상 확보
        constraints:
            const BoxConstraints(minHeight: AppLayout.minTouchTarget),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          // 선택 시 태그 색상 배경, 미선택 시 테마 인식 반투명 배경
          color: isSelected
              ? tagColor.withValues(alpha: 0.85)
              : context.themeColors.overlayLight,
          borderRadius: BorderRadius.circular(AppRadius.huge),
          border: Border.all(
            color: isSelected
                ? tagColor
                : context.themeColors.borderMedium,
            width: isSelected
                ? AppLayout.borderMedium
                : AppLayout.borderThin,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 태그 색상 도트 인디케이터
            Container(
              width: AppSpacing.md,
              height: AppSpacing.md,
              decoration: BoxDecoration(
                // 선택 시: 흰색(컬러 배경 위 대비), 미선택 시: 태그 색상
                color: isSelected ? ColorTokens.white : tagColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // 긴 태그명이 칩을 넘지 않도록 제한한다
            ConstrainedBox(
              constraints:
                  const BoxConstraints(maxWidth: AppLayout.donutLarge),
              child: Text(
                name,
                style: AppTypography.captionLg.copyWith(
                  // 선택 시: 흰색(컬러 배경 위 대비), 미선택 시: 테마 텍스트
                  color: isSelected
                      ? ColorTokens.white
                      : context.themeColors.textPrimaryWithAlpha(0.8),
                  fontWeight: isSelected
                      ? AppTypography.weightBold
                      : AppTypography.weightMedium,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
