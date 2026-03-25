// F4 위젯: HabitTrackerView - 습관 트래커 메인 뷰
// 섹션1: 오늘의 습관 (달성률 DonutChart + 습관 카드 리스트)
// 섹션2: 습관 캘린더 (HabitCalendarSection으로 분리)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../providers/habit_provider.dart';
import '../../../../shared/widgets/bottom_scroll_spacer.dart';
import 'habit_calendar_section.dart';
import 'today_habits_section.dart';

/// 습관 트래커 뷰 (서브탭 1)
class HabitTrackerView extends ConsumerWidget {
  const HabitTrackerView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TodayHabitsSection(
            habits: ref.watch(activeHabitsProvider),
            scheduledHabits: ref.watch(todayScheduledHabitsProvider),
            logs: ref.watch(habitLogsForDateProvider),
            completionRate: ref.watch(todayHabitCompletionRateProvider),
            today: DateTime(now.year, now.month, now.day),
          ),
          const SizedBox(height: AppSpacing.xxl),
          const HabitCalendarSection(),
          // 하단 여백: 마지막 콘텐츠를 화면 중앙까지 스크롤 가능하도록 화면 절반 높이
          const BottomScrollSpacer(),
        ],
      ),
    );
  }
}
