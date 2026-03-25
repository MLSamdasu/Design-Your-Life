// F2 위젯: MonthlyDayContentList - 선택된 날짜의 이벤트/루틴/습관 목록
// 이벤트 카드, 루틴 카드, 습관 체크 아이템을 세로로 나열한다
// 각 아이템의 탭 동작은 콜백으로 외부에서 주입받는다
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../shared/models/habit.dart';
import '../../../../shared/widgets/bottom_scroll_spacer.dart';
import '../../providers/event_provider.dart';
import '../../../habit/providers/habit_provider.dart';
import '../../../todo/providers/todo_provider.dart';
import 'event_card.dart';
import '../../../../core/theme/spacing_tokens.dart';
import 'routine_info_card.dart';
import 'habit_check_item.dart';

/// 선택된 날짜의 이벤트 + 루틴 + 습관 목록 위젯
/// MonthlyView 하단 영역에서 사용한다
class MonthlyDayContentList extends ConsumerWidget {
  /// 현재 선택된 날짜
  final DateTime selectedDate;

  /// 선택된 날짜의 이벤트 목록
  final List<CalendarEvent> selectedDayEvents;

  /// 선택된 날짜의 루틴 목록
  final List<RoutineEntry> routines;

  /// 선택된 날짜의 습관 체크리스트 데이터
  final List<({Habit habit, bool isCompleted})> habitsForDay;

  /// 이벤트 카드 탭 콜백
  final void Function(CalendarEvent event) onEventTap;

  /// 루틴 카드 탭 콜백
  final void Function(RoutineEntry routine) onRoutineTap;

  const MonthlyDayContentList({
    super.key,
    required this.selectedDate,
    required this.selectedDayEvents,
    required this.routines,
    required this.habitsForDay,
    required this.onEventTap,
    required this.onRoutineTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.lg,
        AppSpacing.xxl,
        BottomScrollSpacer.height(context),
      ),
      children: [
        // 이벤트 카드 목록
        ...selectedDayEvents.map((event) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: EventCard(
                event: event,
                onTap: () => onEventTap(event),
                onToggleTodo: event.isTodoEvent
                    ? (isCompleted) {
                        final todoId = event.id.replaceFirst('todo_', '');
                        ref.read(toggleTodoProvider)(todoId, isCompleted);
                      }
                    : null,
              ),
            )),

        // 루틴 카드 목록 (이벤트 아래에 표시)
        if (routines.isNotEmpty) ...[
          if (selectedDayEvents.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(
                  top: AppSpacing.sm, bottom: AppSpacing.md),
              child: Text(
                '루틴',
                style: AppTypography.captionLg.copyWith(
                  color: context.themeColors.textPrimaryWithAlpha(0.60),
                ),
              ),
            ),
          ...routines.map((routine) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: GestureDetector(
                  onTap: () => onRoutineTap(routine),
                  child: RoutineInfoCard(
                    routine: routine,
                    selectedDate: selectedDate,
                  ),
                ),
              )),
        ],

        // 습관 체크리스트 섹션 (루틴 아래에 표시)
        if (habitsForDay.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(
                top: AppSpacing.sm, bottom: AppSpacing.md),
            child: Text(
              '오늘의 습관',
              style: AppTypography.captionLg.copyWith(
                color: context.themeColors.textPrimaryWithAlpha(0.60),
                fontWeight: AppTypography.weightSemiBold,
              ),
            ),
          ),
          ...habitsForDay.map((entry) => HabitCheckItem(
                habit: entry.habit,
                isCompleted: entry.isCompleted,
                onToggle: () {
                  ref.read(toggleHabitProvider)(
                    entry.habit.id,
                    selectedDate,
                    !entry.isCompleted,
                  );
                },
              )),
        ],
      ],
    );
  }
}
