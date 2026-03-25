// F2 위젯: MonthlyCalendarGrid - TableCalendar 그리드 래퍼
// 월간 캘린더의 날짜 셀, 요일 헤더, 이벤트 dot 스타일을 설정한다
// 날짜 탭/페이지 변경 콜백을 외부에서 주입받는다
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';

/// 월간 캘린더 그리드 위젯
/// TableCalendar의 스타일 설정과 이벤트 dot 표시를 담당한다
class MonthlyCalendarGrid extends StatelessWidget {
  /// 현재 선택된 날짜
  final DateTime selectedDate;

  /// 포커스된 월 (페이지 이동용)
  final DateTime focusedMonth;

  /// 날짜별 이벤트 존재 여부 맵
  final Map<String, bool> eventsByDate;

  /// 날짜 선택 콜백
  final void Function(DateTime selected, DateTime focused) onDaySelected;

  /// 월 페이지 변경 콜백
  final void Function(DateTime focused) onPageChanged;

  const MonthlyCalendarGrid({
    super.key,
    required this.selectedDate,
    required this.focusedMonth,
    required this.eventsByDate,
    required this.onDaySelected,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TableCalendar(
      // 한국어 로케일로 요일/월 이름을 표시한다
      locale: 'ko_KR',
      firstDay: DateTime(2020, 1, 1),
      lastDay: DateTime(2035, 12, 31),
      focusedDay: focusedMonth,
      selectedDayPredicate: (day) => isSameDay(day, selectedDate),
      onDaySelected: onDaySelected,
      onPageChanged: onPageChanged,
      // 헤더 스타일: 글래스 텍스트
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextStyle: AppTypography.titleLg
            .copyWith(color: context.themeColors.textPrimary),
        leftChevronIcon: Icon(
          Icons.chevron_left_rounded,
          color: context.themeColors.textPrimaryWithAlpha(0.70),
        ),
        rightChevronIcon: Icon(
          Icons.chevron_right_rounded,
          color: context.themeColors.textPrimaryWithAlpha(0.70),
        ),
      ),
      // 요일 헤더 스타일
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: AppTypography.captionLg.copyWith(
          color: context.themeColors.textPrimaryWithAlpha(0.60),
        ),
        // WCAG 최소 대비: 주말 요일 텍스트 0.55 이상 보장
        weekendStyle: AppTypography.captionLg.copyWith(
          color: context.themeColors.textPrimaryWithAlpha(0.55),
        ),
      ),
      // 날짜 셀 스타일
      calendarStyle: CalendarStyle(
        defaultTextStyle: AppTypography.bodyMd
            .copyWith(color: context.themeColors.textPrimary),
        weekendTextStyle: AppTypography.bodyMd.copyWith(
          color: context.themeColors.textPrimaryWithAlpha(0.80),
        ),
        selectedDecoration: BoxDecoration(
          color: context.themeColors.accent,
          shape: BoxShape.circle,
        ),
        selectedTextStyle: AppTypography.bodyMd.copyWith(
          color: context.themeColors.textPrimary,
          fontWeight: AppTypography.weightBold,
        ),
        todayDecoration: BoxDecoration(
          color: context.themeColors.textPrimaryWithAlpha(0.25),
          shape: BoxShape.circle,
        ),
        todayTextStyle: AppTypography.bodyMd.copyWith(
          color: context.themeColors.textPrimary,
          fontWeight: AppTypography.weightBold,
        ),
        outsideTextStyle: AppTypography.bodyMd.copyWith(
          color: context.themeColors.textPrimaryWithAlpha(0.55),
        ),
        markersMaxCount: 3,
        markerDecoration: BoxDecoration(
          color: context.themeColors.textPrimaryWithAlpha(0.70),
          shape: BoxShape.circle,
        ),
        markerSize: TimelineLayout.calendarMarkerSize,
        markerMargin: const EdgeInsets.only(top: AppSpacing.xxs),
      ),
      // 이벤트 dot: 해당 날짜에 이벤트가 있으면 dot 표시
      eventLoader: (day) {
        final key = AppDateUtils.toDateString(day);
        return eventsByDate.containsKey(key) ? [Object()] : [];
      },
    );
  }
}
