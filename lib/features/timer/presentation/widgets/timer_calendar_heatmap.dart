// F6: 타이머 월간 캘린더 히트맵 위젯
// 월별 일일 집중 시간을 색상 강도로 표시하는 읽기 전용 캘린더 그리드이다.
// 각 날짜 셀을 탭하면 해당 일의 집중 시간 + 세션 수 툴팁을 보여준다.
//
// 배럴 파일: 히트맵 관련 하위 모듈을 재수출한다.
export 'heatmap_controls.dart';
export 'heatmap_grid.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/spacing_tokens.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/timer_stats_provider.dart';
import 'heatmap_controls.dart';
import 'heatmap_grid.dart';

/// 월간 캘린더 히트맵 위젯
/// 월 탐색 화살표 + 요일 헤더 + 날짜 셀 그리드로 구성된다
class TimerCalendarHeatmap extends ConsumerWidget {
  const TimerCalendarHeatmap({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(statsSelectedMonthProvider);
    final focusMap = ref.watch(monthlyFocusMapProvider(selectedMonth));
    final sessionMap = ref.watch(monthlySessionMapProvider(selectedMonth));

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HeatmapMonthNavigator(selectedMonth: selectedMonth),
          const SizedBox(height: AppSpacing.lg),
          const HeatmapWeekdayHeaders(),
          const SizedBox(height: AppSpacing.xs),
          HeatmapCalendarGrid(
            month: selectedMonth,
            focusMap: focusMap,
            sessionMap: sessionMap,
          ),
          const SizedBox(height: AppSpacing.lg),
          const HeatmapLegend(),
        ],
      ),
    );
  }
}
