// F-Memo: 메모 리스트 아이템 위젯
// 제목, 내용 미리보기, 날짜, 타입 아이콘을 표시한다.
// 선택 상태 하이라이트, 롱프레스 컨텍스트 메뉴, 스와이프 삭제를 지원한다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../models/memo.dart';
import '../../providers/memo_provider.dart';
import 'memo_item_context_menu.dart';

// 하위 호환을 위한 배럴 re-export
export 'memo_item_context_menu.dart';

/// 메모 리스트의 개별 아이템 위젯
class MemoListItem extends ConsumerWidget {
  final Memo memo;
  final bool isSelected;
  final VoidCallback onTap;

  const MemoListItem({
    super.key,
    required this.memo,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tc = context.themeColors;
    // 날짜 포맷: M월 d일
    final dateText = DateFormat('M월 d일').format(memo.updatedAt);
    // 타입별 아이콘 결정
    final typeIcon =
        memo.type == 'drawing' ? Icons.draw_outlined : Icons.edit_note;

    return Dismissible(
      key: ValueKey(memo.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => showMemoDeleteConfirmDialog(context),
      onDismissed: (_) => ref.read(deleteMemoProvider)(memo.id),
      background: _buildDeleteBackground(tc),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: () => showMemoContextMenu(
          context: context,
          ref: ref,
          memo: memo,
        ),
        child: AnimatedContainer(
          duration: AppAnimation.fast,
          margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xxs,
          ),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: isSelected
                ? tc.accentWithAlpha(0.15)
                : tc.overlayLight,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: isSelected
                ? Border.all(
                    color: tc.accent,
                    width: AppLayout.borderMedium,
                  )
                : null,
          ),
          child: Row(
            children: [
              // 타입 아이콘
              Icon(
                typeIcon,
                size: AppLayout.iconXl,
                color: tc.textPrimaryWithAlpha(0.60),
              ),
              const SizedBox(width: AppSpacing.lg),
              // 제목 + 내용 미리보기 + 날짜
              Expanded(child: _buildTextColumn(tc, dateText)),
              // 고정 표시 아이콘
              if (memo.isPinned)
                Icon(
                  Icons.push_pin,
                  size: AppLayout.iconSm,
                  color: tc.accent,
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 텍스트 컬럼: 제목 + 내용 미리보기 + 날짜
  Widget _buildTextColumn(ResolvedThemeColors tc, String dateText) {
    // 내용 미리보기 (첫 줄만 표시)
    final preview = memo.content.isEmpty
        ? '내용 없음'
        : memo.content.split('\n').first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          memo.title,
          style: AppTypography.titleMd.copyWith(color: tc.textPrimary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          preview,
          style: AppTypography.bodySm.copyWith(
            color: tc.textPrimaryWithAlpha(0.55),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          dateText,
          style: AppTypography.captionMd.copyWith(
            color: tc.textPrimaryWithAlpha(0.45),
          ),
        ),
      ],
    );
  }

  /// 스와이프 삭제 배경
  Widget _buildDeleteBackground(ResolvedThemeColors tc) {
    return Container(
      alignment: Alignment.centerRight,
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xxs,
      ),
      padding: const EdgeInsets.only(right: AppSpacing.xxl),
      decoration: BoxDecoration(
        color: ColorTokens.error.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Icon(
        Icons.delete_outline,
        color: ColorTokens.error,
        size: AppLayout.iconXl,
      ),
    );
  }
}
