// 태그 목록 뷰 위젯
// 태그 리스트와 빈 상태를 표시한다.
// 태그 존재 시 GlassCard 내에 TagListItem 목록을 렌더링하고,
// 태그 미존재 시 빈 상태 안내를 렌더링한다.
import 'package:flutter/material.dart';

import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../shared/models/tag.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import 'tag_list_item.dart';

/// 태그 목록 + 빈 상태 위젯
class TagListView extends StatelessWidget {
  final List<Tag> tags;
  final ValueChanged<Tag> onEdit;
  final ValueChanged<Tag> onDelete;

  const TagListView({
    super.key,
    required this.tags,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) {
      return const _TagEmptyState();
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        0,
        AppSpacing.pageHorizontal,
        AppSpacing.bottomScrollPadding,
      ),
      children: [
        // 태그 수 표시 (한도 안내)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: Text(
            '${tags.length} / ${Tag.maxTagsPerUser}개',
            style: AppTypography.captionMd.copyWith(
              // WCAG: 태그 수 텍스트 알파 0.55 이상으로 가독성 보장
              color: context.themeColors.textPrimaryWithAlpha(0.55),
            ),
          ),
        ),
        GlassCard(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: tags.asMap().entries.map((entry) {
              final i = entry.key;
              final tag = entry.value;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TagListItem(
                    tag: tag,
                    onEdit: () => onEdit(tag),
                    onDelete: () => onDelete(tag),
                  ),
                  // 마지막 항목 아래는 디바이더 미표시
                  if (i < tags.length - 1)
                    Divider(
                      color: context.themeColors.textPrimaryWithAlpha(0.08),
                      height: 1,
                      indent: MiscLayout.tagDividerIndent,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ─── 빈 상태 위젯 ───────────────────────────────────────────────────────────

/// 태그가 없을 때 표시하는 빈 상태 위젯
class _TagEmptyState extends StatelessWidget {
  const _TagEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.label_outline_rounded,
            size: MiscLayout.iconEmptyXl,
            // WCAG: 빈 상태 아이콘 알파 0.50 이상으로 가독성 보장
            color: context.themeColors.textPrimaryWithAlpha(0.50),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            '아직 태그가 없습니다',
            // WCAG: 빈 상태 제목 알파 0.55 이상으로 가독성 보장
            style: AppTypography.titleMd.copyWith(
              color: context.themeColors.textPrimaryWithAlpha(0.55),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '+ 버튼을 눌러 첫 번째 태그를 만들어 보세요',
            // WCAG: 빈 상태 설명 알파 0.55 이상으로 가독성 보장
            style: AppTypography.bodySm.copyWith(
              color: context.themeColors.textPrimaryWithAlpha(0.55),
            ),
          ),
        ],
      ),
    );
  }
}
