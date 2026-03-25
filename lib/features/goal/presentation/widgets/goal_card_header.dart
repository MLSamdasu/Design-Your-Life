// F5 위젯: GoalCardHeader - 목표 카드 헤더
// 제목, 설명, 태그 칩, 체크박스, 진행률, 수정/삭제 메뉴를 표시한다.
// goal_card.dart에서 분리된 하위 위젯이다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/global_providers.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../shared/models/goal.dart';
import '../../../../shared/widgets/animated_strikethrough.dart';
import 'goal_popup_menu.dart';
import 'goal_progress_bar.dart';
import 'goal_tag_chips.dart';

/// 목표 카드 헤더 (제목, 설명, 태그 칩, 체크박스, 진행률, 수정/삭제 메뉴)
class GoalCardHeader extends ConsumerWidget {
  final Goal goal;
  final double progress;
  final bool isExpanded;
  final Animation<double> checkScale;
  final VoidCallback onExpandToggle;
  final VoidCallback onCompletionToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const GoalCardHeader({
    required this.goal,
    required this.progress,
    required this.isExpanded,
    required this.checkScale,
    required this.onExpandToggle,
    required this.onCompletionToggle,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkModeProvider);

    return InkWell(
      onTap: onExpandToggle,
      borderRadius: BorderRadius.circular(AppRadius.huge),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 완료 체크박스 (AN-04 bounce)
                _buildCheckbox(context),
                const SizedBox(width: AppSpacing.lg),
                // 제목 + 설명 + 태그
                Expanded(
                  child: _buildTitleSection(context, isDark),
                ),
                const SizedBox(width: AppSpacing.md),
                // 진행률 + 확장 아이콘 + 메뉴
                _buildTrailingSection(context),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            GoalProgressBar(progress: progress),
          ],
        ),
      ),
    );
  }

  /// 완료 체크박스 위젯 (AN-04 bounce 애니메이션 포함)
  Widget _buildCheckbox(BuildContext context) {
    return ScaleTransition(
      scale: checkScale,
      child: GestureDetector(
        onTap: onCompletionToggle,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: AppLayout.minTouchTarget,
          height: AppLayout.minTouchTarget,
          child: Center(
            child: AnimatedContainer(
              duration: AppAnimation.slow,
              curve: Curves.easeInOut,
              width: AppLayout.checkboxMd,
              height: AppLayout.checkboxMd,
              decoration: BoxDecoration(
                color: goal.isCompleted
                    ? context.themeColors.textPrimaryWithAlpha(0.3)
                    : ColorTokens.transparent,
                border: Border.all(
                  color: goal.isCompleted
                      ? context.themeColors.textPrimaryWithAlpha(0.6)
                      : context.themeColors.textPrimaryWithAlpha(0.4),
                  width: AppLayout.borderThick,
                ),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: AnimatedOpacity(
                opacity: goal.isCompleted ? 1.0 : 0.0,
                duration: AppAnimation.slow,
                curve: Curves.easeInOut,
                child: Icon(Icons.check_rounded,
                    size: AppLayout.iconXxxs,
                    color: context.themeColors.textPrimary),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 제목 + 설명 + 태그 칩 섹션
  Widget _buildTitleSection(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedStrikethrough(
          text: goal.title,
          style: AppTypography.titleLg.copyWith(
            color: goal.isCompleted
                ? context.themeColors.textPrimaryWithAlpha(0.5)
                : context.themeColors.textPrimary,
          ),
          isActive: goal.isCompleted,
          maxLines: 2,
        ),
        if (goal.description != null && goal.description!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            goal.description!,
            style: AppTypography.bodySm.copyWith(
              color: context.themeColors.textPrimaryWithAlpha(0.6),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        if (goal.tagIds.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          GoalTagChips(tagIds: goal.tagIds, isDark: isDark),
        ],
      ],
    );
  }

  /// 진행률 퍼센트 + 확장 아이콘 + 메뉴 버튼 섹션
  Widget _buildTrailingSection(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${(progress * 100).round()}%',
              style: AppTypography.captionLg.copyWith(
                color: context.themeColors.textPrimaryWithAlpha(0.8),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            AnimatedRotation(
              turns: isExpanded ? 0.5 : 0,
              duration: AppAnimation.normal,
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: AppLayout.iconXl,
                color: context.themeColors.textPrimaryWithAlpha(0.5),
              ),
            ),
          ],
        ),
        GoalPopupMenu(onEdit: onEdit, onDelete: onDelete),
      ],
    );
  }
}
