// F2 위젯: WeeklyDayColumn - 주간 뷰 단일 날짜 열 (SRP 분리)
// weekly_view.dart에서 추출한다.
// 시간 구분선 그리드 + 루틴 블록 + 이벤트 블록 + 현재 시간선을 Stack으로 배치한다
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../providers/event_provider.dart';
import '../../../habit/providers/routine_log_provider.dart';
import '../../../todo/providers/todo_provider.dart';
import 'weekly_view_widgets.dart';

/// 단일 날짜 열 (시간 구분선 + 루틴 블록 + 이벤트 블록 + 현재 시간선)
/// ConsumerWidget으로 투두/루틴 완료 토글 Provider에 접근한다
class WeeklyDayColumn extends ConsumerWidget {
  final DateTime day;
  final List<CalendarEvent> events;
  final List<RoutineEntry> routines;
  final bool isToday;
  final bool isSelected;
  final DateTime now;
  final void Function(CalendarEvent)? onEventTap;

  const WeeklyDayColumn({
    super.key,
    required this.day,
    required this.events,
    required this.routines,
    required this.isToday,
    required this.isSelected,
    required this.now,
    this.onEventTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        // 시간 구분선 그리드
        Column(
          children: List.generate(AppLayout.hoursInDay, (i) {
            return Container(
              height: kWeeklyHourHeight,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: context.themeColors.textPrimaryWithAlpha(0.22),
                    width: AppLayout.borderThin,
                  ),
                  left: BorderSide(
                    color: context.themeColors.textPrimaryWithAlpha(0.18),
                    width: AppLayout.borderThin,
                  ),
                ),
                // 선택된 날짜 열 배경 미세 하이라이트
                color: isSelected
                    ? context.themeColors.textPrimaryWithAlpha(0.03)
                    : ColorTokens.transparent,
              ),
            );
          }),
        ),

        // 루틴 블록 (이벤트 아래 레이어에 반투명 배경으로 표시)
        ...routines.map((r) {
          // 해당 날짜의 루틴 완료 상태를 Provider에서 감시한다
          final isCompleted = ref.watch(routineCompletionProvider(
            (routineId: r.id, date: day),
          ));
          return WeeklyRoutineBlock(
            routine: r,
            isCompleted: isCompleted,
            onToggle: () {
              ref.read(toggleRoutineLogProvider)(r.id, day, !isCompleted);
            },
          );
        }),

        // 이벤트 블록 (공용 위젯 사용, 루틴 위에 표시)
        ...events
            .where((e) => e.startHour != null)
            .map((e) => WeeklyEventBlock(
              event: e,
              onTap: onEventTap != null ? () => onEventTap!(e) : null,
              // 투두 이벤트: 완료 토글 콜백 전달
              onToggleTodo: e.isTodoEvent
                  ? () {
                      final todoId = e.id.replaceFirst('todo_', '');
                      ref.read(toggleTodoProvider)(
                        todoId,
                        !e.isTodoCompleted,
                      );
                    }
                  : null,
            )),

        // 현재 시간 빨간 가로선 - 오늘 열에만 표시 (공용 위젯 사용)
        if (isToday) WeeklyCurrentTimeLine(now: now),
      ],
    );
  }
}
