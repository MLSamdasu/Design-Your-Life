// F2 위젯: DailyAllDaySection - 일간 뷰 상단 종일 이벤트 섹션
// 종일 이벤트가 있을 때만 표시되며, AnimatedSwitcher로 전환된다
import 'package:flutter/material.dart';

import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../providers/event_models.dart';
import 'event_card.dart';

/// 종일 이벤트 섹션 (일간 뷰 상단에 표시)
/// 종일 이벤트 목록과 탭/토글 콜백을 외부에서 주입받는다
class DailyAllDaySection extends StatelessWidget {
  /// 종일 이벤트 목록
  final List<CalendarEvent> allDayEvents;

  /// 이벤트 카드 탭 콜백 (편집 다이얼로그 등)
  final void Function(CalendarEvent event) onEventTap;

  /// 투두 이벤트 완료 토글 콜백
  final void Function(String todoId, bool isCompleted) onToggleTodo;

  const DailyAllDaySection({
    super.key,
    required this.allDayEvents,
    required this.onEventTap,
    required this.onToggleTodo,
  });

  @override
  Widget build(BuildContext context) {
    if (allDayEvents.isEmpty) return const SizedBox.shrink();

    return AnimatedSwitcher(
      duration: AppAnimation.normal,
      child: Container(
        key: ValueKey('allday_${allDayEvents.length}'),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl,
          vertical: AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: allDayEvents.map((e) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: EventCard(
                event: e,
                onTap: () => onEventTap(e),
                onToggleTodo: e.isTodoEvent
                    ? (isCompleted) {
                        // 'todo_' 접두사를 제거하여 원본 투두 ID를 추출한다
                        final todoId = e.id.replaceFirst('todo_', '');
                        onToggleTodo(todoId, isCompleted);
                      }
                    : null,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
