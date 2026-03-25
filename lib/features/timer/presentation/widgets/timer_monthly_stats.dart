// F6: 타이머 월간 통계 카드 위젯
// 선택된 월의 요약 통계(총 집중 시간, 세션 수)를 헤더로 표시하고,
// 그 아래에 일별 집중 시간을 5개 구간으로 분류한 티어 분포를 보여준다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../models/timer_stats.dart';
import '../../providers/timer_stats_provider.dart';
import 'timer_focus_tier_chart.dart';

// 하위 호환용 재수출
export 'timer_focus_tier_chart.dart';

/// 월간 통계 요약 + 티어 분포 카드
/// statsSelectedMonthProvider의 월을 기준으로 통계를 표시한다
class TimerMonthlyStatsCard extends ConsumerWidget {
  const TimerMonthlyStatsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(statsSelectedMonthProvider);
    final stats = ref.watch(monthlyStatsProvider(selectedMonth));
    final tiers = ref.watch(monthlyFocusTiersProvider(selectedMonth));
    final label = '${selectedMonth.year}년 ${selectedMonth.month}월 통계';

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTypography.titleLg
                  .copyWith(color: context.themeColors.textPrimary)),
          const SizedBox(height: AppSpacing.xl),
          // 요약 헤더 (총 집중 시간 + 총 세션 수)
          _SummaryHeader(stats: stats),
          const SizedBox(height: AppSpacing.xl),
          // 구간별 분포
          TimerFocusTierChart(tiers: tiers),
        ],
      ),
    );
  }
}

/// 요약 헤더: 총 집중 시간과 총 세션 수를 간결하게 표시한다
class _SummaryHeader extends StatelessWidget {
  final TimerMonthlyStats stats;
  const _SummaryHeader({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 총 집중 시간
        Expanded(
          child: _SummaryCell(
            icon: Icons.timer_rounded,
            label: '총 집중',
            value: _formatMinutes(stats.totalFocusMinutes),
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        // 총 세션 수
        Expanded(
          child: _SummaryCell(
            icon: Icons.play_circle_outline_rounded,
            label: '세션',
            value: '${stats.totalSessions}회',
          ),
        ),
      ],
    );
  }

  /// 분을 '시간 분' 형태로 포맷한다
  String _formatMinutes(int minutes) {
    if (minutes < 60) return '$minutes분';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m > 0 ? '$h시간 $m분' : '$h시간';
  }
}

/// 요약 셀 위젯
class _SummaryCell extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryCell({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.overlayLight,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: colors.borderLight),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.accent),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: AppTypography.titleMd
                        .copyWith(color: colors.textPrimary)),
                Text(label,
                    style: AppTypography.captionMd
                        .copyWith(color: colors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
