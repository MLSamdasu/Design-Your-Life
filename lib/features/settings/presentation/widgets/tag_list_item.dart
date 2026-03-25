// 태그 목록 아이템 위젯
// 색상 도트 + 태그 이름 + 편집/삭제 버튼으로 구성된 단일 태그 행을 렌더링한다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/global_providers.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../shared/models/tag.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';

/// 단일 태그 아이템 위젯 (색상 도트 + 이름 + 편집/삭제)
class TagListItem extends ConsumerWidget {
  final Tag tag;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TagListItem({
    super.key,
    required this.tag,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkModeProvider);
    final tagColor = ColorTokens.eventColor(tag.colorIndex, isDark: isDark);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      child: Row(
        children: [
          // 색상 도트
          Container(
            width: AppLayout.iconSm,
            height: AppLayout.iconSm,
            decoration: BoxDecoration(
              color: tagColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.lgXl),
          // 태그 이름
          Expanded(
            child: Text(
              tag.name,
              style: AppTypography.bodyLg.copyWith(
                color: context.themeColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // 편집 버튼
          GestureDetector(
            onTap: onEdit,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: AppLayout.containerLg,
              height: AppLayout.containerLg,
              child: Center(
                child: Icon(
                  // WCAG: 편집 아이콘 알파 0.50 이상으로 가독성 보장
                  Icons.edit_outlined,
                  color: context.themeColors.textPrimaryWithAlpha(0.50),
                  size: AppLayout.iconLg,
                ),
              ),
            ),
          ),
          // 삭제 버튼
          GestureDetector(
            onTap: onDelete,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: AppLayout.containerLg,
              height: AppLayout.containerLg,
              child: Center(
                child: Icon(
                  Icons.delete_outline_rounded,
                  color: ColorTokens.errorLight.withValues(alpha: 0.7),
                  size: AppLayout.iconLg,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
