// F6: 히트맵 캘린더 그리드 — 날짜 셀 + 요일 헤더 + 그리드 배치
// CalendarGrid · DayCell · WeekdayHeaders 를 포함한다.
import 'package:flutter/material.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';

/// 히트맵 강도 레벨 (집중 시간 범위별)
enum HeatLevel { none, light, medium, strong }

/// 요일 헤더 행 (일 ~ 토)
class HeatmapWeekdayHeaders extends StatelessWidget {
  const HeatmapWeekdayHeaders({super.key});

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
class HeatmapCalendarGrid extends StatelessWidget {
  final DateTime month;
  final Map<int, int> focusMap;
  final Map<int, int> sessionMap;

  const HeatmapCalendarGrid({
    super.key,
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
              return const Expanded(
                  child: SizedBox(height: AppLayout.colorBarHeight));
            }

            final minutes = focusMap[day] ?? 0;
            final sessions = sessionMap[day] ?? 0;
            final isToday = today.year == month.year &&
                today.month == month.month &&
                today.day == day;

            return Expanded(
              child: HeatmapDayCell(
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
class HeatmapDayCell extends StatelessWidget {
  final int day;
  final int minutes;
  final int sessions;
  final bool isToday;

  const HeatmapDayCell({
    super.key,
    required this.day,
    required this.minutes,
    required this.sessions,
    required this.isToday,
  });

  HeatLevel get _level {
    if (minutes <= 0) return HeatLevel.none;
    if (minutes <= 30) return HeatLevel.light;
    if (minutes <= 60) return HeatLevel.medium;
    return HeatLevel.strong;
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.themeColors.accent;
    final bg = _resolveBackground(accent);
    final tooltipMsg =
        minutes > 0 ? '$minutes분 / $sessions세션' : '기록 없음';

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
              color: _level == HeatLevel.strong
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
      case HeatLevel.none:
        return accent.withValues(alpha: 0.05);
      case HeatLevel.light:
        return accent.withValues(alpha: 0.20);
      case HeatLevel.medium:
        return accent.withValues(alpha: 0.45);
      case HeatLevel.strong:
        return accent.withValues(alpha: 0.75);
    }
  }
}
