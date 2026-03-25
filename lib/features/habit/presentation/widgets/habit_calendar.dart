// F4 위젯: HabitCalendar - 습관 월간 달력
// 각 날짜에 미니 DonutChart와 % 숫자를 표시한다.
// 날짜 탭 시 해당일 습관 상세를 표시한다. 과거 날짜는 읽기 전용이다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../shared/widgets/donut_chart.dart';
import '../../providers/habit_provider.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';

/// 습관 캘린더 위젯
/// table_calendar 패키지를 사용하여 월간 달력을 표시한다
class HabitCalendar extends ConsumerWidget {
  const HabitCalendar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusedMonth = ref.watch(habitFocusedMonthProvider);
    final selectedDate = ref.watch(habitSelectedDateProvider);
    final calendarData = ref.watch(habitCalendarDataProvider);

    return TableCalendar(
      locale: 'ko_KR',
      focusedDay: focusedMonth,
      firstDay: DateTime(TimelineLayout.calendarStartYear),
      lastDay: DateTime(TimelineLayout.calendarEndYear),
      selectedDayPredicate: (day) => isSameDay(day, selectedDate),
      calendarFormat: CalendarFormat.month,
      startingDayOfWeek: StartingDayOfWeek.monday,
      // 날짜 탭: 선택일 변경
      onDaySelected: (selectedDay, focusedDay) {
        ref.read(habitSelectedDateProvider.notifier).state = selectedDay;
        ref.read(habitFocusedMonthProvider.notifier).state = focusedDay;
      },
      // 월 변경
      onPageChanged: (focusedDay) {
        ref.read(habitFocusedMonthProvider.notifier).state = focusedDay;
      },
      // 스타일 설정
      calendarStyle: CalendarStyle(
        outsideDaysVisible: false,
        todayDecoration: BoxDecoration(
          color: context.themeColors.textPrimaryWithAlpha(0.2),
          shape: BoxShape.circle,
        ),
        // 선택된 날짜 원: 배경 테마에 맞는 악센트 색상으로 표시해 가독성을 확보한다
        selectedDecoration: BoxDecoration(
          color: context.themeColors.accent,
          shape: BoxShape.circle,
        ),
        defaultTextStyle: AppTypography.captionLg.copyWith(
          color: context.themeColors.textPrimaryWithAlpha(0.8),
        ),
        weekendTextStyle: AppTypography.captionLg.copyWith(
          color: context.themeColors.textPrimaryWithAlpha(0.6),
        ),
        // WCAG 최소 대비: 외부 날짜(다른 달) 텍스트 0.55 이상 보장
        outsideTextStyle: AppTypography.captionLg.copyWith(
          color: context.themeColors.textPrimaryWithAlpha(0.55),
        ),
        todayTextStyle: AppTypography.captionLg.copyWith(
                    color: context.themeColors.textPrimary,
          fontWeight: AppTypography.weightBold,
        ),
        selectedTextStyle: AppTypography.captionLg.copyWith(
                    color: context.themeColors.textPrimary,
          fontWeight: AppTypography.weightBold,
        ),
        cellMargin: const EdgeInsets.all(AppSpacing.xxs),
        cellPadding: EdgeInsets.zero,
      ),
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextStyle: AppTypography.bodyMd.copyWith(
                    color: context.themeColors.textPrimary,
          fontWeight: AppTypography.weightSemiBold,
        ),
        leftChevronIcon: Icon(
          Icons.chevron_left_rounded,
          color: context.themeColors.textPrimaryWithAlpha(0.7),
        ),
        rightChevronIcon: Icon(
          Icons.chevron_right_rounded,
          color: context.themeColors.textPrimaryWithAlpha(0.7),
        ),
        headerPadding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      ),
      // WCAG 최소 대비: 요일 헤더 텍스트 0.55 이상 보장
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: AppTypography.captionMd.copyWith(
          color: context.themeColors.textPrimaryWithAlpha(0.55),
        ),
        weekendStyle: AppTypography.captionMd.copyWith(
          color: context.themeColors.textPrimaryWithAlpha(0.55),
        ),
      ),
      // 날짜 셀 빌더: 미니 도넛 차트 표시
      calendarBuilders: CalendarBuilders(
        defaultBuilder: (context, day, focusedDay) {
          return _buildDayCell(context, day, calendarData, false, false);
        },
        todayBuilder: (context, day, focusedDay) {
          return _buildDayCell(context, day, calendarData, true, false);
        },
        selectedBuilder: (context, day, focusedDay) {
          return _buildDayCell(context, day, calendarData, false, true);
        },
      ),
    );
  }

  /// 날짜 셀 위젯 생성
  Widget _buildDayCell(
    BuildContext context,
    DateTime day,
    Map<DateTime, double> calendarData,
    bool isToday,
    bool isSelected,
  ) {
    final dayKey = DateTime(day.year, day.month, day.day);
    final rate = calendarData[dayKey];
    final hasData = rate != null && rate > 0;

    // 셀 영역에 맞춰 날짜+도넛차트가 오버플로우하지 않도록 FittedBox로 감싼다
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 날짜 숫자
          Container(
            width: AppLayout.iconNav,
            height: AppLayout.iconNav,
            // 날짜 선택 원: 배경 테마에 맞는 악센트 색상을 사용한다
            decoration: isSelected
                ? BoxDecoration(
                    color: context.themeColors.accent,
                    shape: BoxShape.circle,
                  )
                : isToday
                    ? BoxDecoration(
                        color: context.themeColors.textPrimaryWithAlpha(0.2),
                        shape: BoxShape.circle,
                      )
                    : null,
            child: Center(
              child: Text(
                '${day.day}',
                // captionMd 토큰(11px)으로 fontSize 하드코딩 제거
                // 선택 날짜 텍스트: 악센트 배경 위이므로 테마 인식 색상 사용
                style: AppTypography.captionMd.copyWith(
                  color: isSelected
                      ? context.themeColors.textPrimary
                      : isToday
                          ? context.themeColors.textPrimary
                          : context.themeColors.textPrimaryWithAlpha(0.8),
                  fontWeight: isSelected || isToday
                      ? AppTypography.weightBold
                      : AppTypography.weightRegular,
                ),
              ),
            ),
          ),
          // 미니 도넛 차트
          if (hasData)
            Padding(
              padding: const EdgeInsets.only(top: AppLayout.borderThin),
              child: DonutChart(
                percentage: rate,
                size: DonutChartSize.mini,
                type: DonutChartType.habit,
              ),
            )
          else
            SizedBox(height: AppLayout.donutMini + AppLayout.borderThin), // 도넛차트 공간과 동일한 높이 맞춤 (28+1)
        ],
      ),
    );
  }
}
