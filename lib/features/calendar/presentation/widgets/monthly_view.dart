// F2 위젯: MonthlyView - 월간 캘린더 그리드
// table_calendar 패키지 기반. 일정 있는 날짜에 컬러 dot을 표시한다.
// 날짜 탭 시 selectedCalendarDateProvider 업데이트
// F17: Google Calendar 이벤트도 dot 표시에 포함한다
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/calendar_sync/calendar_sync_provider.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../providers/calendar_provider.dart';
import 'event_card.dart';
import '../../../../core/theme/spacing_tokens.dart';

/// 월간 캘린더 뷰
class MonthlyView extends ConsumerWidget {
  const MonthlyView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedCalendarDateProvider);
    final focusedMonth = ref.watch(focusedCalendarMonthProvider);
    // F17: 앱 이벤트 + Google Calendar 이벤트를 병합한 날짜 맵 사용
    final eventsByDate = ref.watch(mergedEventsByDateMapProvider);
    // F17: 선택된 날짜의 이벤트도 병합된 Provider 사용
    final selectedDayEvents = ref.watch(mergedEventsForDayProvider);

    return Column(
      children: [
        // table_calendar 그리드
        TableCalendar(
          firstDay: DateTime(2020, 1, 1),
          lastDay: DateTime(2035, 12, 31),
          focusedDay: focusedMonth,
          selectedDayPredicate: (day) => isSameDay(day, selectedDate),
          // 날짜 탭 시 선택 날짜 + 포커스 월 업데이트
          onDaySelected: (selected, focused) {
            ref.read(selectedCalendarDateProvider.notifier).state =
                DateTime(selected.year, selected.month, selected.day);
            ref.read(focusedCalendarMonthProvider.notifier).state = focused;
          },
          onPageChanged: (focused) {
            ref.read(focusedCalendarMonthProvider.notifier).state = focused;
          },
          // 헤더 스타일: 글래스 텍스트
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: AppTypography.titleLg.copyWith(color: context.themeColors.textPrimary),
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
            weekendStyle: AppTypography.captionLg.copyWith(
              color: context.themeColors.textPrimaryWithAlpha(0.50),
            ),
          ),
          // 날짜 셀 스타일
          calendarStyle: CalendarStyle(
            // 기본 날짜
            defaultTextStyle: AppTypography.bodyMd.copyWith(color: context.themeColors.textPrimary),
            weekendTextStyle: AppTypography.bodyMd.copyWith(
              color: context.themeColors.textPrimaryWithAlpha(0.80),
            ),
            // 선택된 날짜: 배경 테마에 맞는 악센트 색상 원으로 표시한다
            selectedDecoration: BoxDecoration(
              color: context.themeColors.accent,
              shape: BoxShape.circle,
            ),
            selectedTextStyle: AppTypography.bodyMd.copyWith(
                    color: context.themeColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
            // 오늘 날짜: 반투명 white pill
            todayDecoration: BoxDecoration(
              color: context.themeColors.textPrimaryWithAlpha(0.25),
              shape: BoxShape.circle,
            ),
            todayTextStyle: AppTypography.bodyMd.copyWith(
                    color: context.themeColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
            // 외부 날짜 (다른 달)
            outsideTextStyle: AppTypography.bodyMd.copyWith(
              color: context.themeColors.textPrimaryWithAlpha(0.25),
            ),
            // 이벤트 dot 빌더는 eventLoader로 제공
            markersMaxCount: 3,
            markerDecoration: BoxDecoration(
              color: context.themeColors.textPrimaryWithAlpha(0.70),
              shape: BoxShape.circle,
            ),
            markerSize: 5,
            markerMargin: const EdgeInsets.only(top: AppSpacing.xxs),
          ),
          // 이벤트 dot: 해당 날짜에 이벤트가 있으면 dot 표시
          eventLoader: (day) {
            final key = '${day.year}-${day.month}-${day.day}';
            return eventsByDate.containsKey(key) ? [Object()] : [];
          },
        ),

        // 선택된 날짜의 이벤트 목록
        if (selectedDayEvents.isNotEmpty) ...[
          Divider(color: context.themeColors.dividerColor, height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg, horizontal: AppSpacing.xxl),
              itemCount: selectedDayEvents.length,
              itemBuilder: (context, index) {
                final event = selectedDayEvents[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: EventCard(event: event),
                );
              },
            ),
          ),
        ] else ...[
          Expanded(
            child: Center(
              child: Text(
                '일정이 없습니다',
                style: AppTypography.bodyMd.copyWith(
                  color: context.themeColors.textPrimaryWithAlpha(0.50),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
