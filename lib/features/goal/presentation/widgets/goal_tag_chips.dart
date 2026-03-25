// F5 위젯: GoalTagChips - 목표 태그 칩 목록
// 목표에 할당된 태그를 칩 형태로 렌더링한다.
// goal_card_header.dart에서 분리된 하위 위젯이다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../shared/providers/tag_provider.dart';

/// 목표 태그 칩 목록 위젯
/// tagIds로부터 태그 데이터를 조회하여 색상 칩으로 렌더링한다
class GoalTagChips extends ConsumerWidget {
  /// 표시할 태그 ID 목록
  final List<String> tagIds;

  /// 다크 모드 여부 (이벤트 색상 계산에 사용)
  final bool isDark;

  const GoalTagChips({
    required this.tagIds,
    required this.isDark,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: tagIds.map((tagId) {
        final tag = ref.watch(tagByIdProvider(tagId));
        if (tag == null) return const SizedBox.shrink();
        final tagColor = ColorTokens.eventColor(
          tag.colorIndex,
          isDark: isDark,
        );
        // WCAG 대비: 태그 배경(tagColor alpha 0.2) 위에서
        // 기본 텍스트 색상을 사용하여 충분한 명도 대비를 확보한다
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xxs,
          ),
          decoration: BoxDecoration(
            color: tagColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(AppRadius.huge),
            border: Border.all(
              color: tagColor.withValues(alpha: 0.4),
              width: AppLayout.borderThin,
            ),
          ),
          child: Text(
            tag.name,
            style: AppTypography.captionSm.copyWith(
              color: context.themeColors.textPrimaryWithAlpha(0.85),
              fontWeight: AppTypography.weightMedium,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
    );
  }
}
