// F1: 리추얼 요약 카드 헤더
// 아이콘 + 제목 + 날짜 + 완료/미완료 배지를 표시한다.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';

/// 리추얼 요약 카드 헤더 (아이콘 + 제목 + 날짜 + 배지)
class RitualCardHeader extends StatelessWidget {
  /// 리추얼 완료 여부
  final bool completed;

  const RitualCardHeader({super.key, required this.completed});

  @override
  Widget build(BuildContext context) {
    final tc = context.themeColors;
    final dateStr = DateFormat('M월 d일').format(DateTime.now());

    return Row(
      children: [
        Icon(
          completed ? Icons.auto_awesome_rounded : Icons.wb_sunny_outlined,
          color: tc.accent,
          size: 22,
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Text(
            '데일리 리추얼',
            style: AppTypography.titleLg.copyWith(color: tc.textPrimary),
          ),
        ),
        // 날짜 표시
        Text(
          dateStr,
          style: AppTypography.captionLg.copyWith(
            color: tc.textPrimaryWithAlpha(0.45),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        // 완료 상태 배지
        _buildBadge(tc),
      ],
    );
  }

  /// 완료 상태 배지
  Widget _buildBadge(ResolvedThemeColors tc) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: completed
            ? (tc.isOnDarkBackground
                ? const Color(0xFF4ADE80).withValues(alpha: 0.15)
                : const Color(0xFF22C55E).withValues(alpha: 0.12))
            : tc.overlayLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        completed ? '완료' : '미완료',
        style: AppTypography.captionLg.copyWith(
          color: completed
              ? (tc.isOnDarkBackground
                  ? const Color(0xFF4ADE80)
                  : const Color(0xFF22C55E))
              : tc.textPrimaryWithAlpha(0.50),
        ),
      ),
    );
  }
}
