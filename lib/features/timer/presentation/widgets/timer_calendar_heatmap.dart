// F6: 타이머 월간 캘린더 히트맵 위젯
// 월별 일일 집중 시간을 색상 강도로 표시하는 읽기 전용 캘린더 그리드이다.
// 각 날짜 셀을 탭하면 해당 일의 집중 시간 + 세션 수 툴팁을 보여준다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/timer_stats_provider.dart';

/// 히트맵 강도 레벨 (집중 시간 범위별)
enum _HeatLevel { none, light, medium, strong }

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
          _MonthNavigator(selectedMonth: selectedMonth),
          const SizedBox(height: AppSpacing.lg),
          _WeekdayHeaders(),
          const SizedBox(height: AppSpacing.xs),
          _CalendarGrid(
            month: selectedMonth,
            focusMap: focusMap,
            sessionMap: sessionMap,
          ),
          const SizedBox(height: AppSpacing.lg),
          _HeatLegend(),
        ],
      ),
    );
  }
}

/// 월 탐색 헤더 (< 2026년 3월 >)
class _MonthNavigator extends ConsumerWidget {
  final DateTime selectedMonth;
  const _MonthNavigator({required this.selectedMonth});

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
          splashRadius: AppLayout.iconButtonSplashRadius,
        ),
        Text(label,
            style: AppTypography.titleLg
                .copyWith(color: context.themeColors.textPrimary)),
        IconButton(
          icon: Icon(Icons.chevron_right_rounded,
              color: context.themeColors.textPrimary),
          onPressed: () => _changeMonth(ref, 1),
          splashRadius: AppLayout.iconButtonSplashRadius,
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

/// 요일 헤더 행 (일 ~ 토)
class _WeekdayHeaders extends StatelessWidget {
  static const _labels = ['일', '월', '화', '수', '목', '금', '토'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _labels
          .map((l) => Expanded(
                child: Center(
                  child: Text(l,
                      style: AppTypography.captionMd.copyWith(
                          color: context.themeColors.textSecondary)),
                ),
              ))
          .toList(),
    );
  }
}

/// 날짜 셀 그리드 (6주 × 7일)
class _CalendarGrid extends StatelessWidget {
  final DateTime month;
  final Map<int, int> focusMap;
  final Map<int, int> sessionMap;

  const _CalendarGrid({
    required this.month,
    required this.focusMap,
    required this.sessionMap,
  });

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(month.year, month.month, 1);
    // 일요일 시작: weekday 7(일) → offset 0, 1(월) → offset 1, ...
    final startOffset = firstDay.weekday % 7;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final today = DateTime.now();

    // 전체 셀 수 (6주 최대)
    final totalCells = ((startOffset + daysInMonth + 6) ~/ 7) * 7;

    return Column(
      children: List.generate(totalCells ~/ 7, (week) {
        return Row(
          children: List.generate(7, (dayOfWeek) {
            final cellIndex = week * 7 + dayOfWeek;
            final day = cellIndex - startOffset + 1;

            // 이번 달이 아닌 빈 셀
            if (day < 1 || day > daysInMonth) {
              // 빈 셀도 히트맵 셀과 동일한 높이 유지
              return const Expanded(child: SizedBox(height: AppLayout.colorBarHeight));
            }

            final minutes = focusMap[day] ?? 0;
            final sessions = sessionMap[day] ?? 0;
            final isToday = today.year == month.year &&
                today.month == month.month &&
                today.day == day;

            return Expanded(
              child: _DayCell(
                day: day,
                minutes: minutes,
                sessions: sessions,
                isToday: isToday,
              ),
            );
          }),
        );
      }),
    );
  }
}

/// 개별 날짜 셀 (탭하면 툴팁 표시)
class _DayCell extends StatelessWidget {
  final int day;
  final int minutes;
  final int sessions;
  final bool isToday;

  const _DayCell({
    required this.day,
    required this.minutes,
    required this.sessions,
    required this.isToday,
  });

  _HeatLevel get _level {
    if (minutes <= 0) return _HeatLevel.none;
    if (minutes <= 30) return _HeatLevel.light;
    if (minutes <= 60) return _HeatLevel.medium;
    return _HeatLevel.strong;
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.themeColors.accent;
    final bg = _resolveBackground(accent);
    final tooltipMsg = minutes > 0
        ? '$minutes분 / $sessions세션'
        : '기록 없음';

    return Tooltip(
      message: tooltipMsg,
      preferBelow: false,
      child: Container(
        height: AppLayout.colorBarHeight,
        margin: const EdgeInsets.all(AppLayout.borderMedium),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: isToday
              ? Border.all(color: accent, width: AppLayout.borderThick)
              : null,
        ),
        child: Center(
          child: Text(
            '$day',
            style: AppTypography.captionLg.copyWith(
              color: _level == _HeatLevel.strong
                  ? ColorTokens.white
                  : context.themeColors.textPrimary,
              fontWeight: isToday
                  ? AppTypography.weightBold
                  : AppTypography.weightRegular,
            ),
          ),
        ),
      ),
    );
  }

  /// 히트 레벨에 따른 배경색을 반환한다
  Color _resolveBackground(Color accent) {
    switch (_level) {
      case _HeatLevel.none:
        return accent.withValues(alpha: 0.05);
      case _HeatLevel.light:
        return accent.withValues(alpha: 0.20);
      case _HeatLevel.medium:
        return accent.withValues(alpha: 0.45);
      case _HeatLevel.strong:
        return accent.withValues(alpha: 0.75);
    }
  }
}

/// 히트맵 범례 (색상 강도 설명)
class _HeatLegend extends StatelessWidget {
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
