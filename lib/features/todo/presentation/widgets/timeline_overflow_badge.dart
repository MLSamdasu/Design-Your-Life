// "+N" 오버플로우 뱃지 위젯
// 4개 이상 겹치는 이벤트에서 3개를 넘는 수를 표시한다
import 'package:flutter/material.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../shared/models/todo.dart';

/// "+N" 오버플로우 뱃지 위젯
/// 4개 이상 겹치는 이벤트에서 3개를 넘는 수를 표시한다
class OverflowBadge extends StatelessWidget {
  /// 숨겨진 이벤트 수
  final int count;

  /// 해당 그룹의 전체 투두 목록 (바텀시트에서 사용)
  final List<Todo> allTodos;

  const OverflowBadge({
    super.key,
    required this.count,
    required this.allTodos,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showOverflowSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: ColorTokens.main,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: [
            BoxShadow(
              color: ColorTokens.main.withValues(alpha: EffectLayout.badgeShadowAlpha),
              blurRadius: EffectLayout.overlapShadowBlur,
              offset: const Offset(0, AppSpacing.xxs),
            ),
          ],
        ),
        child: Text(
          '+$count',
          style: AppTypography.captionLg.copyWith(
            // MAIN 컬러 배경(#7C3AED) 위이므로 항상 흰색이 적절하다
            color: ColorTokens.white,
            fontWeight: AppTypography.weightSemiBold,
          ),
        ),
      ),
    );
  }

  /// 겹친 이벤트 전체 목록을 바텀시트로 표시한다
  void _showOverflowSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: ColorTokens.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        decoration: BoxDecoration(
          color: context.themeColors.dialogSurface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.huge),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '겹치는 일정 (${allTodos.length}개)',
              style: AppTypography.titleMd.copyWith(
                color: context.themeColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ...allTodos.map((todo) => _buildOverflowItem(context, todo)),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  /// 겹친 일정 목록의 개별 항목을 빌드한다
  Widget _buildOverflowItem(BuildContext context, Todo todo) {
    final color = ColorTokens.eventColor(todo.colorIndex);
    final startStr = todo.startTime != null
        ? '${todo.startTime!.hour.toString().padLeft(2, '0')}:${todo.startTime!.minute.toString().padLeft(2, '0')}'
        : '';
    final endStr = todo.endTime != null
        ? ' - ${todo.endTime!.hour.toString().padLeft(2, '0')}:${todo.endTime!.minute.toString().padLeft(2, '0')}'
        : '';
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.mdLg,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.lgXl),
        border: Border(
          left: BorderSide(color: color, width: AppSpacing.xxs),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              todo.title,
              style: AppTypography.bodyMd.copyWith(
                color: context.themeColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (startStr.isNotEmpty)
            Text(
              '$startStr$endStr',
              style: AppTypography.captionMd.copyWith(
                color: context.themeColors.textPrimaryWithAlpha(0.5),
              ),
            ),
        ],
      ),
    );
  }
}
