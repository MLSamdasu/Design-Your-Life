// F6: 히트맵 캘린더 보조 위젯 — 월 탐색 헤더 + 범례
// MonthNavigator · HeatLegend 를 포함한다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../providers/timer_stats_provider.dart';

/// 월 탐색 헤더 (< 2026년 3월 >)
class HeatmapMonthNavigator extends ConsumerWidget {
  final DateTime selectedMonth;
  const HeatmapMonthNavigator({super.key, required this.selectedMonth});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label = '${selectedMonth.year}년 ${selectedMonth.month}월';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: Icon(Icons.chevron_left_rounded,
              color: context.themeColors.textPrimary),
          onPressed: () => _changeMonth(ref, -1),
          splashRadius: MiscLayout.iconButtonSplashRadius,
        ),
        Text(label,
            style: AppTypography.titleLg
                .copyWith(color: context.themeColors.textPrimary)),
        IconButton(
          icon: Icon(Icons.chevron_right_rounded,
              color: context.themeColors.textPrimary),
          onPressed: () => _changeMonth(ref, 1),
          splashRadius: MiscLayout.iconButtonSplashRadius,
        ),
      ],
    );
  }

  /// 월을 delta만큼 이동한다 (음수: 이전, 양수: 다음)
  void _changeMonth(WidgetRef ref, int delta) {
    final current = ref.read(statsSelectedMonthProvider);
    final newMonth = DateTime(current.year, current.month + delta);
    ref.read(statsSelectedMonthProvider.notifier).state = newMonth;
  }
}

/// 히트맵 범례 (색상 강도 설명)
class HeatmapLegend extends StatelessWidget {
  const HeatmapLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final accent = context.themeColors.accent;
    final items = [
      ('없음', accent.withValues(alpha: 0.05)),
      ('~30분', accent.withValues(alpha: 0.20)),
      ('~60분', accent.withValues(alpha: 0.45)),
      ('60분+', accent.withValues(alpha: 0.75)),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: item.$2,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(item.$1,
                  style: AppTypography.captionSm
                      .copyWith(color: context.themeColors.textSecondary)),
            ],
          ),
        );
      }).toList(),
    );
  }
}
