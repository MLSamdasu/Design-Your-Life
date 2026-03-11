// F5 위젯: MandalartCell - 만다라트 개별 셀
// 텍스트, 배경 색상(진행률 기반), 탭 핸들러를 포함한다.
// 빈 셀은 "+" 아이콘으로 표시한다.
import 'package:flutter/material.dart';

import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../shared/models/mandalart_grid.dart';
import '../../../../shared/enums/mandalart_cell_type.dart';
import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';

/// 만다라트 개별 셀 위젯
/// 셀 유형에 따라 배경색과 표시 내용이 달라진다
class MandalartCellWidget extends StatelessWidget {
  final MandalartCell cell;

  /// 탭 핸들러 (편집 또는 추가 작업)
  final VoidCallback? onTap;

  /// 완료 진행률 (0.0 ~ 1.0): 색상 채도 결정에 사용
  final double progress;

  /// 현재 확대 뷰의 대상 서브그리드 인덱스 (null이면 전체 뷰)
  final bool isDimmed;

  const MandalartCellWidget({
    required this.cell,
    this.onTap,
    this.progress = 0.0,
    this.isDimmed = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = _cellBackgroundColor(context);
    final textColor = _cellTextColor(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppAnimation.normal,
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: bgColor.withValues(alpha: isDimmed ? 0.3 : 1.0),
          border: Border.all(
            color: context.themeColors.textPrimaryWithAlpha(0.08),
            width: 0.5,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: _buildCellContent(context, textColor),
          ),
        ),
      ),
    );
  }

  Widget _buildCellContent(BuildContext context, Color textColor) {
    // 빈 셀: "+" 아이콘 표시
    if (cell.type == MandalartCellType.empty) {
      return Icon(
        Icons.add_rounded,
        size: AppLayout.iconMd,
        color: context.themeColors.textPrimaryWithAlpha(0.25),
      );
    }

    return Text(
      cell.text,
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: _textStyle(textColor),
    );
  }

  TextStyle _textStyle(Color textColor) {
    switch (cell.type) {
      case MandalartCellType.core:
        return AppTypography.captionLg.copyWith(
          color: textColor,
          fontWeight: FontWeight.w800,
        );
      case MandalartCellType.subGoal:
        return AppTypography.captionMd.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        );
      case MandalartCellType.task:
        return AppTypography.captionSm.copyWith(
          color: textColor.withValues(
            alpha: cell.isCompleted ? 0.5 : 0.85,
          ),
          decoration: cell.isCompleted ? TextDecoration.lineThrough : null,
        );
      case MandalartCellType.empty:
        return AppTypography.captionSm.copyWith(color: textColor);
    }
  }

  /// 셀 유형 및 진행률에 따라 배경색을 결정한다
  Color _cellBackgroundColor(BuildContext context) {
    switch (cell.type) {
      case MandalartCellType.core:
        // 핵심 목표: 배경 테마에 맞는 악센트 색상으로 표시한다
        return context.themeColors.accent;
      case MandalartCellType.subGoal:
        // 세부목표: 진행률이 높을수록 더 진한 악센트 색상으로 진행 상황을 표시한다
        return Color.lerp(
          context.themeColors.textPrimaryWithAlpha(0.12),
          context.themeColors.accentWithAlpha(0.75),
          progress,
        )!;
      case MandalartCellType.task:
        // 실천과제: 완료 시 약간 밝게
        return cell.isCompleted
            ? context.themeColors.textPrimaryWithAlpha(0.18)
            : context.themeColors.textPrimaryWithAlpha(0.08);
      case MandalartCellType.empty:
        return context.themeColors.textPrimaryWithAlpha(0.04);
    }
  }

  Color _cellTextColor(BuildContext context) {
    switch (cell.type) {
      case MandalartCellType.core:
        return context.themeColors.textPrimary;
      case MandalartCellType.subGoal:
        return context.themeColors.textPrimary;
      case MandalartCellType.task:
        return context.themeColors.textPrimary;
      case MandalartCellType.empty:
        return context.themeColors.textPrimaryWithAlpha(0.3);
    }
  }
}
