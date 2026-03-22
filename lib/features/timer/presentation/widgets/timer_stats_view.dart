// F6: 타이머 통계 메인 뷰
// 월간 캘린더 히트맵, 주간 바 차트, 월간 통계 카드를
// 스크롤 가능한 세로 레이아웃으로 조합한다.
// timer_screen.dart의 '통계' 서브탭에서 표시된다.
import 'package:flutter/material.dart';

import '../../../../core/theme/spacing_tokens.dart';
import '../../../../shared/widgets/bottom_scroll_spacer.dart';
import 'timer_calendar_heatmap.dart';
import 'timer_monthly_stats.dart';
import 'timer_weekly_chart.dart';

/// 타이머 통계 메인 뷰
/// 3개 섹션을 수직으로 나열한다:
/// 1. 월간 캘린더 히트맵 (월 탐색 가능)
/// 2. 주간 바 차트 + 요약
/// 3. 월간 통계 카드 그리드
class TimerStatsView extends StatelessWidget {
  const TimerStatsView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        children: const [
          SizedBox(height: AppSpacing.xl),
          // 1. 월간 캘린더 히트맵
          TimerCalendarHeatmap(),
          SizedBox(height: AppSpacing.xl),
          // 2. 주간 바 차트
          TimerWeeklyChart(),
          SizedBox(height: AppSpacing.xl),
          // 3. 월간 통계 카드
          TimerMonthlyStatsCard(),
          // 하단 여백
          BottomScrollSpacer(),
        ],
      ),
    );
  }
}
