// F6: 타이머 월간 통계 카드 위젯
// 선택된 월의 총 집중 시간, 세션 수, 활동 일수, 일 평균, 최장 연속을
// 2열 그리드 형태의 GlassCard로 표시한다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../models/timer_stats.dart' as models;
import '../../providers/timer_stats_provider.dart';

/// 월간 통계 요약 카드
/// statsSelectedMonthProvider의 월을 기준으로 통계를 표시한다
class TimerMonthlyStatsCard extends ConsumerWidget {
  const TimerMonthlyStatsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(statsSelectedMonthProvider);
    final stats = ref.watch(monthlyStatsProvider(selectedMonth));
    final label = '${selectedMonth.year}년 ${selectedMonth.month}월 통계';

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTypography.titleLg
                  .copyWith(color: context.themeColors.textPrimary)),
          const SizedBox(height: AppSpacing.xl),
          _StatsGrid(stats: stats),
        ],
      ),
    );
  }
}

/// 2열 통계 그리드
class _StatsGrid extends StatelessWidget {
  final models.TimerMonthlyStats stats;
  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final items = [
      _StatItem(
        icon: Icons.timer_rounded,
        label: '총 집중 시간',
        value: _formatMinutes(stats.totalFocusMinutes),
      ),
      _StatItem(
        icon: Icons.play_circle_outline_rounded,
        label: '총 세션 수',
        value: '${stats.totalSessions}회',
      ),
      _StatItem(
        icon: Icons.calendar_today_rounded,
        label: '활동 일수',
        value: '${stats.activeDays}일',
      ),
      _StatItem(
        icon: Icons.trending_up_rounded,
        label: '일 평균',
        value: '${stats.dailyAverage.round()}분',
      ),
      _StatItem(
        icon: Icons.local_fire_department_rounded,
        label: '최장 연속',
        value: '${stats.longestStreak}일',
      ),
    ];

    return Wrap(
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.lg,
      children: items.map((item) => _StatCell(item: item)).toList(),
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

/// 개별 통계 셀 데이터
class _StatItem {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });
}

/// 개별 통계 셀 위젯
class _StatCell extends StatelessWidget {
  final _StatItem item;
  const _StatCell({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
    return Container(
      width: 140,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.overlayLight,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: colors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(item.icon, size: 18, color: colors.accent),
          const SizedBox(height: AppSpacing.md),
          Text(item.value,
              style: AppTypography.titleLg
                  .copyWith(color: colors.textPrimary)),
          const SizedBox(height: AppSpacing.xxs),
          Text(item.label,
              style: AppTypography.captionMd
                  .copyWith(color: colors.textSecondary)),
        ],
      ),
    );
  }
}
