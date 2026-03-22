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
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../shared/widgets/animated_strikethrough.dart';

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
          // isDimmed일 때만 기존 alpha에 dimmedAlpha를 곱해 흐리게 한다
          // 기존 alpha를 덮어쓰면 textPrimaryWithAlpha(0.04) 등의 설정이 무시된다
          color: isDimmed
              ? bgColor.withValues(alpha: bgColor.a * AppAnimation.dimmedAlpha)
              : bgColor,
          border: Border.all(
            color: context.themeColors.textPrimaryWithAlpha(0.08),
            width: AppLayout.borderHairline,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxs),
            child: _buildCellContent(context, textColor),
          ),
        ),
      ),
    );
  }

  Widget _buildCellContent(BuildContext context, Color textColor) {
    // 빈 셀: "+" 아이콘 표시
    if (cell.type == MandalartCellType.empty) {
      // WCAG 최소 대비: 빈 셀 "+" 아이콘 0.50 이상 보장
      return Icon(
        Icons.add_rounded,
        size: AppLayout.iconMd,
        color: context.themeColors.textPrimaryWithAlpha(0.50),
      );
    }

    // FittedBox로 셀 크기에 맞게 텍스트를 자동 축소한다
    // 긴 텍스트가 어색하게 줄바꿈되는 것을 방지한다
    final style = _textStyle(textColor);

    // 실천과제(task)는 빨간펜 취소선 애니메이션으로 완료 상태를 표시한다
    if (cell.type == MandalartCellType.task) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        child: AnimatedStrikethrough(
          text: cell.text,
          style: style,
          isActive: cell.isCompleted,
          maxLines: 2,
        ),
      );
    }

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        cell.text,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: style,
      ),
    );
  }

  TextStyle _textStyle(Color textColor) {
    switch (cell.type) {
      case MandalartCellType.core:
        return AppTypography.captionLg.copyWith(
          color: textColor,
          fontWeight: AppTypography.weightExtraBold,
        );
      case MandalartCellType.subGoal:
        return AppTypography.captionMd.copyWith(
          color: textColor,
          fontWeight: AppTypography.weightSemiBold,
        );
      case MandalartCellType.task:
        // 취소선은 AnimatedStrikethrough 위젯에서 처리한다
        return AppTypography.captionSm.copyWith(
          color: textColor.withValues(
            alpha: cell.isCompleted ? AppAnimation.completedTextAlpha : AppAnimation.activeTextAlpha,
          ),
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
      // WCAG 최소 대비: 빈 셀 텍스트 0.50 이상 보장
      case MandalartCellType.empty:
        return context.themeColors.textPrimaryWithAlpha(0.50);
    }
  }
}
