// F1: 홈 대시보드 주간 요약 섹션 위젯
// 이번 주 투두 완료율 + 습관 달성률을 2열 그리드 stat 카드로 표시한다
// WeekStatCard 2개를 Row로 배치 (각 50% 너비)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../shared/widgets/section_title.dart';
import '../../../../shared/widgets/week_stat_card.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../providers/home_provider.dart';
import '../../providers/home_dday_provider.dart';
import '../../../../core/theme/spacing_tokens.dart';

/// 주간 요약 섹션 위젯
class WeekSummarySection extends ConsumerWidget {
  const WeekSummarySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekAsync = ref.watch(weekSummaryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 섹션 제목 (현재 오늘의 데이터를 표시한다)
        const SectionTitle(title: '오늘의 요약'),

        // 2열 그리드 stat 카드
        weekAsync.when(
          loading: () => _buildSkeleton(),
          error: (_, __) => _buildSkeleton(),
          data: (summary) => _buildContent(context, summary),
        ),
      ],
    );
  }

  /// 로딩 스켈레톤 (2열)
  Widget _buildSkeleton() {
    return Row(
      children: [
        Expanded(
          child: LoadingSkeleton(height: 80, borderRadius: 14),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: LoadingSkeleton(height: 80, borderRadius: 14),
        ),
      ],
    );
  }

  /// 실제 콘텐츠
  Widget _buildContent(BuildContext context, WeeklySummary summary) {
    return Row(
      children: [
        // 투두 완료율 카드
        Expanded(
          child: WeekStatCard(
            value: '${summary.todoWeekRate.round()}%',
            label: '투두 완료율',
            progress: summary.todoWeekRate / 100,
            progressColor: context.themeColors.textPrimaryWithAlpha(0.80),
            icon: Icons.check_circle_outline_rounded,
          ),
        ),
        const SizedBox(width: AppSpacing.lg), // 카드 간격: 12px

        // 습관 달성률 카드
        Expanded(
          child: WeekStatCard(
            value: '${summary.habitWeekRate.round()}%',
            label: '습관 달성률',
            progress: summary.habitWeekRate / 100,
            // 습관: habitProgress 토큰 (민트 그린)
            progressColor: ColorTokens.habitProgress,
            icon: Icons.loop_rounded,
          ),
        ),
      ],
    );
  }
}
