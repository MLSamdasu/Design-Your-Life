// F2 위젯: CalendarHeader — 캘린더 상단 헤더 (월/연도 네비게이션 + 뷰 전환 탭)
// SRP 분리: 헤더 레이아웃 구성만 담당한다
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/calendar_provider.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../shared/widgets/global_action_bar.dart';
import 'calendar_header_actions.dart';
import 'calendar_month_navigation.dart';
import 'calendar_view_switcher.dart';

/// 캘린더 화면 상단 헤더 (월/연도 네비게이션 + 뷰 전환 탭)
class CalendarHeader extends ConsumerWidget {
  const CalendarHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentView = ref.watch(calendarViewTypeProvider);
    final focusedMonth = ref.watch(focusedCalendarMonthProvider);
    final selectedDate = ref.watch(selectedCalendarDateProvider);

    return Container(
      // 다른 화면 헤더(투두, 습관)와 동일한 상단 패딩(16px)을 적용한다
      padding: const EdgeInsets.fromLTRB(AppSpacing.pageHorizontal, AppSpacing.pageVertical, AppSpacing.pageHorizontal, 0),
      child: Column(
        children: [
          // 월/연도 네비게이션 행 — 후행 버튼 간 간격을 줄여 오버플로를 방지한다
          Row(
            children: [
              Expanded(
                child: MonthNavigation(
                  currentView: currentView,
                  focusedMonth: focusedMonth,
                  selectedDate: selectedDate,
                ),
              ),
              // F17: Google Calendar 연동 활성화 시 수동 동기화 버튼 표시
              const GoogleSyncButton(),
              // 오늘 버튼
              const TodayButton(),
              // 업적 + 설정 아이콘 버튼
              const GlobalActionBar(),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const CalendarViewSwitcher(),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
