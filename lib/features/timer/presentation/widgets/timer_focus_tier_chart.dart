// F6: 타이머 집중 시간 구간별 분포 차트 위젯
// 일별 집중 시간을 5개 구간으로 분류하여 수평 바 차트로 표시한다.
import 'package:flutter/material.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../models/timer_stats.dart';

/// 구간별 집중 시간 분포 위젯
/// 5개 구간 각각의 일수를 수평 바 차트 형태로 표시한다
class TimerFocusTierChart extends StatelessWidget {
  final TimerFocusTiers tiers;
  const TimerFocusTierChart({super.key, required this.tiers});

  @override
  Widget build(BuildContext context) {
    final totalActive = tiers.totalActiveDays;

    // 구간 정의: 레이블, 일수, 색상
    final tierItems = [
      _TierData('1시간 이하', tiers.under1h, ColorTokens.info),
      _TierData('3시간 이하', tiers.under3h, ColorTokens.success),
      _TierData('6시간 이하', tiers.under6h, ColorTokens.warning),
      _TierData('10시간 이하', tiers.under10h, ColorTokens.main),
      _TierData('10시간 이상', tiers.over10h, ColorTokens.error),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '일별 집중 시간 분포',
          style: AppTypography.bodyMd.copyWith(
            color: context.themeColors.textSecondary,
            fontWeight: AppTypography.weightMedium,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        ...tierItems.map((tier) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _TierRow(
                tier: tier,
                maxDays: totalActive,
              ),
            )),
      ],
    );
  }
}

/// 구간 데이터
class _TierData {
  final String label;
  final int days;
  final Color color;
  const _TierData(this.label, this.days, this.color);
}

/// 개별 구간 행 (레이블 + 바 + 일수)
class _TierRow extends StatelessWidget {
  final _TierData tier;
  final int maxDays;

  const _TierRow({required this.tier, required this.maxDays});

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
    // 비율 계산 (최소 0.03으로 빈 바도 약간 보이게 한다)
    final ratio = maxDays > 0
        ? (tier.days / maxDays).clamp(0.0, 1.0)
        : 0.0;
    final barRatio = tier.days > 0 ? ratio.clamp(0.03, 1.0) : 0.0;

    return Row(
      children: [
        // 구간 레이블 (고정 폭)
        SizedBox(
          width: 80,
          child: Text(
            tier.label,
            style: AppTypography.captionMd.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        // 수평 바
        Expanded(
          child: Container(
            height: 16,
            decoration: BoxDecoration(
              color: colors.overlayLight,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: barRatio,
              child: Container(
                decoration: BoxDecoration(
                  color: tier.color.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        // 일수 표시
        SizedBox(
          width: 32,
          child: Text(
            '${tier.days}일',
            textAlign: TextAlign.end,
            style: AppTypography.captionMd.copyWith(
              color: colors.textPrimary,
              fontWeight: AppTypography.weightSemiBold,
            ),
          ),
        ),
      ],
    );
  }
}
