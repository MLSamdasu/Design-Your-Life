// F1: 홈 대시보드 오늘의 요약 섹션 위젯
// 오늘 투두 완료율 + 습관 달성률을 2열 그리드 stat 카드로 표시한다
// TodayStatCard 2개를 Row로 배치 (각 50% 너비)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../shared/widgets/section_title.dart';
import '../../../../shared/widgets/today_stat_card.dart';
import '../../../timer/providers/timer_provider.dart';
import '../../providers/home_provider.dart';
import '../../providers/home_dday_provider.dart';
import '../../../../core/theme/spacing_tokens.dart';

/// 오늘의 요약 섹션 위젯
class TodaySummarySection extends ConsumerWidget {
  const TodaySummarySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 동기 Provider: 직접 값을 사용한다
    final summary = ref.watch(todaySummaryProvider);
    // 목표 진행률과 오늘 집중 시간을 추가로 읽는다
    final goalStats = ref.watch(todayGoalStatsProvider);
    // 홈 대시보드 전용: 항상 오늘 날짜 기준으로 집중 시간을 표시한다
    final focusMinutes = ref.watch(todayOnlyFocusMinutesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 섹션 제목 (오늘의 데이터를 표시한다)
        const SectionTitle(title: '오늘의 요약'),

        // 동기 Provider이므로 직접 값을 사용한다
        _buildContent(
          context,
          summary,
          goalStats: goalStats,
          focusMinutes: focusMinutes,
        ),
      ],
    );
  }

  /// 실제 콘텐츠 (2x2 그리드)
  Widget _buildContent(
    BuildContext context,
    TodaySummary summary, {
    required GoalSummary goalStats,
    required int focusMinutes,
  }) {
    // 집중 시간을 "시간:분" 형식으로 표시한다
    final focusLabel = focusMinutes >= 60
        ? '${focusMinutes ~/ 60}h ${focusMinutes % 60}m'
        : '${focusMinutes}m';

    return Column(
      children: [
        // 첫 번째 행: 투두 완료율 + 습관 달성률
        Row(
          children: [
            // 투두 완료율 카드
            Expanded(
              child: TodayStatCard(
                value: '${summary.todoTodayRate.round()}%',
                label: '투두 완료율',
                progress: summary.todoTodayRate / 100,
                progressColor: context.themeColors.textPrimaryWithAlpha(0.80),
                icon: Icons.check_circle_outline_rounded,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),

            // 습관 달성률 카드
            Expanded(
              child: TodayStatCard(
                value: '${summary.habitTodayRate.round()}%',
                label: '습관 달성률',
                progress: summary.habitTodayRate / 100,
                // 습관: habitProgress 토큰 (민트 그린)
                progressColor: ColorTokens.habitProgress,
                icon: Icons.loop_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // 두 번째 행: 목표 진행률 + 오늘 집중 시간
        Row(
          children: [
            // 목표 진행률 카드
            Expanded(
              child: TodayStatCard(
                value: '${(goalStats.avgProgress * 100).round()}%',
                label: '목표 진행률',
                progress: goalStats.avgProgress,
                progressColor: ColorTokens.eventColor(5),
                icon: Icons.flag_rounded,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),

            // 오늘 집중 시간 카드
            Expanded(
              child: TodayStatCard(
                value: focusLabel,
                label: '오늘 집중',
                icon: Icons.timer_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
