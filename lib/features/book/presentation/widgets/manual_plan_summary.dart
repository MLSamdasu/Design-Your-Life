// F-Book: 수동 분배 요약 위젯 — 상단 요약 정보 + 에러 요약을 표시한다
import 'package:flutter/material.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';

/// 상단 요약 정보 (총 일수, 활성 일수, 총 페이지/챕터)
class ManualPlanSummaryHeader extends StatelessWidget {
  final int totalDays;
  final int activeDays;
  final int totalAmount;
  final bool isPageMode;

  const ManualPlanSummaryHeader({
    super.key,
    required this.totalDays,
    required this.activeDays,
    required this.totalAmount,
    required this.isPageMode,
  });

  @override
  Widget build(BuildContext context) {
    final unit = isPageMode ? '페이지' : '챕터';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: ColorTokens.main.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '총 $totalDays일 (읽기 $activeDays일) · '
        '$totalAmount$unit',
        style: AppTypography.captionLg.copyWith(
            color: context.themeColors.textPrimary),
      ),
    );
  }
}

/// 유효성 검사 요약 에러 표시
class ManualPlanErrorSummary extends StatelessWidget {
  final List<String> errors;
  const ManualPlanErrorSummary({super.key, required this.errors});

  @override
  Widget build(BuildContext context) {
    if (errors.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: ColorTokens.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: ColorTokens.error.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: errors
              .map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text('- $e',
                        style: AppTypography.captionMd
                            .copyWith(color: ColorTokens.error)),
                  ))
              .toList(),
        ),
      ),
    );
  }
}
