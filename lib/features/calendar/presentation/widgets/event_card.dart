// F2 위젯: EventCard - 캘린더 이벤트 표시 카드
// 색상 코딩 + 제목 + 시간을 표시하는 작은 카드 위젯
// Glass Subtle 스타일 (radius-lg: 12px)
// AN: 체크박스 bounce + 빨간 취소선 draw/erase 애니메이션 포함
// 낙관적 로컬 상태로 즉시 애니메이션 시작 후 Provider 업데이트
import 'package:flutter/material.dart';

import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../providers/event_provider.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import 'event_card_color_bar.dart';
import 'event_card_badge_row.dart';
import 'event_card_title_time.dart';
import 'event_card_todo_checkbox.dart';

/// 이벤트 카드 위젯
/// 투두 이벤트 체크박스 토글 시 bounce + 취소선 draw 애니메이션을 지원한다
/// 낙관적 로컬 상태로 애니메이션을 즉시 시작하고, Provider 업데이트는 비동기로 처리한다
class EventCard extends StatefulWidget {
  final CalendarEvent event;
  final VoidCallback? onTap;

  /// 투두 이벤트 완료 토글 콜백 (투두 이벤트에서만 사용)
  final ValueChanged<bool>? onToggleTodo;

  const EventCard({super.key, required this.event, this.onTap, this.onToggleTodo});

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard>
    with SingleTickerProviderStateMixin {
  /// 체크박스 bounce 애니메이션 컨트롤러
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  /// 낙관적 로컬 완료 상태 (Provider 업데이트 전에 즉시 UI에 반영)
  late bool _localCompleted;

  @override
  void initState() {
    super.initState();
    _localCompleted = widget.event.isTodoCompleted;

    // AN-04: 체크박스 Scale bounce 애니메이션 (500ms, easeInOut)
    _bounceController = AnimationController(
      duration: AppAnimation.slow,
      vsync: this,
    );
    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant EventCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Provider 재빌드 시 외부 상태와 동기화 (이미 로컬에서 반영됐으면 변화 없음)
    if (widget.event.isTodoCompleted != oldWidget.event.isTodoCompleted) {
      _localCompleted = widget.event.isTodoCompleted;
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  /// 시간 포맷 (예: "14:30")
  String? _formatTime(int? hour, int? minute) {
    if (hour == null) return null;
    final h = hour.toString().padLeft(2, '0');
    final m = (minute ?? 0).toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// 체크박스 토글 핸들러
  /// 1) 로컬 상태 즉시 변경 → 취소선 애니메이션 시작
  /// 2) bounce 애니메이션 동시 재생
  /// 3) Provider 업데이트 비동기 실행 (await 없이)
  void _handleToggle() {
    if (widget.onToggleTodo == null) return;

    final newCompleted = !_localCompleted;

    // 1) 로컬 상태 즉시 반영 → AnimatedStrikethrough가 didUpdateWidget으로 애니메이션 시작
    setState(() {
      _localCompleted = newCompleted;
    });

    // 2) 체크박스 bounce 동시 재생
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (!reduceMotion) {
      _bounceAnimation = TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.95), weight: 30),
        TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.02), weight: 40),
        TweenSequenceItem(tween: Tween(begin: 1.02, end: 1.0), weight: 30),
      ]).animate(
        CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
      );
      _bounceController.forward(from: 0);
    }

    // 3) Provider 업데이트 (비동기 — 애니메이션과 동시 진행)
    widget.onToggleTodo!(newCompleted);
  }

  @override
  Widget build(BuildContext context) {
    // 투두 이벤트는 보라색 배경과 구분되는 틸/스카이블루 사용
    final cardColor = widget.event.isTodoEvent
        ? ColorTokens.todoCard
        : ColorTokens.eventColor(widget.event.colorIndex);
    final startTime = _formatTime(widget.event.startHour, widget.event.startMinute);
    final endTime = _formatTime(widget.event.endHour, widget.event.endMinute);
    // 로컬 상태 사용 — Provider 재빌드 전에도 즉시 반영
    final isCompleted = _localCompleted;

    return GestureDetector(
      onTap: widget.onTap,
      // AnimatedContainer: 카드 배경색/보더가 완료 상태 전환 시 부드럽게 변함 (400ms)
      child: AnimatedContainer(
        duration: AppAnimation.slower,
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.mdLg,
        ),
        decoration: BoxDecoration(
          color: cardColor.withValues(alpha: isCompleted ? 0.22 : 0.38),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: cardColor.withValues(alpha: isCompleted ? 0.40 : 0.65),
            width: AppLayout.borderThin,
          ),
        ),
        child: Row(
          children: [
            // 좌측 색상 인디케이터 바
            EventCardColorBar(color: cardColor, isCompleted: isCompleted),
            const SizedBox(width: AppSpacing.mdLg),

            // 이벤트 제목 + 시간
            Expanded(
              child: EventCardTitleTime(
                title: widget.event.title,
                startTime: startTime,
                endTime: endTime,
                isCompleted: isCompleted,
              ),
            ),

            // 중간 뱃지 영역 (범위 태그, Google 뱃지)
            if (widget.event.rangeTag != null || widget.event.isGoogleEvent)
              EventCardBadgeRow(
                rangeTag: widget.event.rangeTag,
                isGoogleEvent: widget.event.isGoogleEvent,
                cardColor: cardColor,
              ),

            // 투두 체크박스: 항상 오른쪽 끝에 배치
            if (widget.event.isTodoEvent)
              EventCardTodoCheckbox(
                isCompleted: isCompleted,
                bounceAnimation: _bounceAnimation,
                onTap: _handleToggle,
              ),
          ],
        ),
      ),
    );
  }
}
