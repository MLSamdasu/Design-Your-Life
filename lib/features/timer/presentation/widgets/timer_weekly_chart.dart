// F6: 타이머 주간 바 차트 위젯
// CustomPaint로 7일 바 차트를 렌더링한다 (외부 차트 라이브러리 의존 없음).
// 오늘 바는 악센트 색상으로 하이라이트하고, 각 바 위에 분 단위 레이블을 표시한다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../models/timer_stats.dart';
import '../../providers/timer_stats_provider.dart';

/// 주간 집중 시간 바 차트 + 통계 요약
class TimerWeeklyChart extends ConsumerWidget {
  const TimerWeeklyChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final weekStart = mondayOfWeek(now);
    final dayMinutes = ref.watch(weeklyFocusListProvider(weekStart));
    final stats = ref.watch(weeklyStatsProvider(weekStart));

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('이번 주 집중',
              style: AppTypography.titleLg
                  .copyWith(color: context.themeColors.textPrimary)),
          const SizedBox(height: AppSpacing.xl),
          // 바 차트 영역
          SizedBox(
            height: 160,
            child: _BarChart(dayMinutes: dayMinutes, weekStart: weekStart),
          ),
          const SizedBox(height: AppSpacing.xl),
          // 통계 요약 행
          _WeeklyStatsSummary(stats: stats),
        ],
      ),
    );
  }
}

/// 7일 바 차트 (CustomPaint 기반)
class _BarChart extends StatelessWidget {
  final List<int> dayMinutes;
  final DateTime weekStart;

  const _BarChart({required this.dayMinutes, required this.weekStart});

  static const _dayLabels = ['월', '화', '수', '목', '금', '토', '일'];

  @override
  Widget build(BuildContext context) {
    final maxMinutes = dayMinutes.fold<int>(0, (a, b) => a > b ? a : b);
    final today = DateTime.now();
    // 오늘의 요일 인덱스 (월=0 ~ 일=6, 이번 주가 아닌 경우 -1)
    final todayIndex = _todayIndex(today);
    final accent = context.themeColors.accent;
    final textColor = context.themeColors.textSecondary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(7, (i) {
        final minutes = dayMinutes[i];
        final isToday = i == todayIndex;
        // 바 높이 비율 (최소 4px 확보)
        final ratio = maxMinutes > 0 ? minutes / maxMinutes : 0.0;
        final barHeight = (ratio * 100).clamp(4.0, 100.0);

        return Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // 바 위 분 레이블
              if (minutes > 0)
                Text('$minutes분',
                    style: AppTypography.captionSm.copyWith(
                      color: isToday ? accent : textColor,
                      fontWeight: isToday
                          ? AppTypography.weightSemiBold
                          : AppTypography.weightRegular,
                    )),
              const SizedBox(height: AppSpacing.xs),
              // 바 본체
              Container(
                height: barHeight,
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: isToday
                      ? accent
                      : accent.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              // 요일 레이블
              Text(_dayLabels[i],
                  style: AppTypography.captionMd.copyWith(
                    color: isToday ? accent : textColor,
                    fontWeight: isToday
                        ? AppTypography.weightBold
                        : AppTypography.weightRegular,
                  )),
            ],
          ),
        );
      }),
    );
  }

  /// 오늘이 이번 주에 포함되면 요일 인덱스, 아니면 -1을 반환한다
  int _todayIndex(DateTime today) {
    final diff = today.difference(weekStart).inDays;
    if (diff < 0 || diff >= 7) return -1;
    return diff;
  }
}

/// 주간 통계 요약 행 (총 시간 / 일 평균 / 세션 수)
class _WeeklyStatsSummary extends StatelessWidget {
  final TimerWeeklyStats stats;
  const _WeeklyStatsSummary({required this.stats});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('총 집중', _formatMinutes(stats.totalFocusMinutes)),
      ('일 평균', '${stats.dailyAverage.round()}분'),
      ('세션', '${stats.totalSessions}회'),
    ];

    return Row(
      children: items.map((item) {
        return Expanded(
          child: Column(
            children: [
              Text(item.$1,
                  style: AppTypography.captionMd
                      .copyWith(color: context.themeColors.textSecondary)),
              const SizedBox(height: AppSpacing.xs),
              Text(item.$2,
                  style: AppTypography.titleMd
                      .copyWith(color: context.themeColors.textPrimary)),
            ],
          ),
        );
      }).toList(),
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
