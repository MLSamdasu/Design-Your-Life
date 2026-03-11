// F3 위젯: TodoStatsCard - 투두 통계 카드
// 완료율(%), 할일/일정/범위/반복 유형별 카운트를 표시한다.
import 'package:flutter/material.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../shared/widgets/donut_chart.dart';
import '../../../todo/services/todo_filter.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';

/// 하루 일정표 좌측 통계 패널
/// DonutChart(완료율) + 유형별 카운트를 포함한다
class TodoStatsCard extends StatelessWidget {
  final TodoStats stats;
  final int totalScheduleCount;

  const TodoStatsCard({
    required this.stats,
    required this.totalScheduleCount,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 도넛 차트 (AN-03 애니메이션 포함)
        Center(
          child: DonutChart(
            percentage: stats.completionRate,
            size: DonutChartSize.large,
            type: DonutChartType.todo,
            centerLabel: '완료',
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        // 전체 일정 수
        _StatRow(
          icon: Icons.event_note_rounded,
          label: '오늘 일정',
          value: '$totalScheduleCount개',
        ),
        const SizedBox(height: AppSpacing.md),
        // 시간 지정 투두
        _StatRow(
          icon: Icons.access_time_rounded,
          label: '시간 지정',
          value: '${stats.withTimeCount}개',
        ),
        const SizedBox(height: AppSpacing.md),
        // 미완료 투두
        _StatRow(
          icon: Icons.radio_button_unchecked_rounded,
          label: '남은 할 일',
          value:
              '${stats.totalCount - stats.completedCount}개',
        ),
        const SizedBox(height: AppSpacing.md),
        // 완료 투두 (habitProgress 토큰: 민트 그린)
        _StatRow(
          icon: Icons.check_circle_outline_rounded,
          label: '완료',
          value: '${stats.completedCount}개',
          valueColor: ColorTokens.habitProgress,
        ),
      ],
    );
  }
}

/// 통계 행 위젯
class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: AppLayout.iconSm,
          color: context.themeColors.textPrimaryWithAlpha(0.5),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: AppTypography.captionMd.copyWith(
              color: context.themeColors.textPrimaryWithAlpha(0.6),
            ),
          ),
        ),
        Text(
          value,
          style: AppTypography.captionLg.copyWith(
            color: valueColor ?? context.themeColors.textPrimaryWithAlpha(0.85),
          ),
        ),
      ],
    );
  }
}
