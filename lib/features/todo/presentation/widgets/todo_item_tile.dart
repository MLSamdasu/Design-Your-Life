// F3 위젯: TodoItemTile - 투두 아이템 타일
// 체크박스 + 투두 제목 + 시간(선택) + 색상 인디케이터를 표시한다.
// 체크박스 탭 시 300ms debounce로 isCompleted를 토글한다.
// 완료 시 빨간 연필 스타일 취소선이 좌→우로 애니메이션 된다.
// 타이머 아이콘 버튼 탭 시 해당 투두가 연결된 상태로 타이머 화면으로 이동한다.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../shared/models/todo.dart';
import 'todo_animated_checkbox.dart';
import 'todo_delete_confirm_dialog.dart';
import 'todo_timer_button.dart';
import 'todo_title_section.dart';

/// 투두 아이템 타일 위젯
/// AN-04: 체크박스 완료 시 scale bounce + 빨간 연필 취소선 애니메이션
/// 타일 탭 시 수정 다이얼로그를 열 수 있다
class TodoItemTile extends StatefulWidget {
  final Todo todo;
  final ValueChanged<bool> onToggle;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const TodoItemTile({
    required this.todo,
    required this.onToggle,
    this.onDelete,
    this.onEdit,
    super.key,
  });

  @override
  State<TodoItemTile> createState() => _TodoItemTileState();
}

class _TodoItemTileState extends State<TodoItemTile>
    with TickerProviderStateMixin {
  late AnimationController _checkController;
  late AnimationController _strikethroughController;
  // CurvedAnimation 타입으로 선언해야 dispose()를 호출할 수 있다
  late CurvedAnimation _strikethroughAnimation;
  bool _isDebouncePending = false;

  @override
  void initState() {
    super.initState();
    // AN-04: 체크박스 bounce 애니메이션 — 외부 컨테이너와 동일한 slow(500ms) 사용
    _checkController = AnimationController(
      duration: AppAnimation.slow,
      vsync: this,
    );
    // 빨간 연필 취소선 애니메이션: 800ms easeOutCubic (공용 AnimatedStrikethrough와 동일한 effect 토큰)
    _strikethroughController = AnimationController(
      duration: AppAnimation.effect,
      vsync: this,
    );
    _strikethroughAnimation = CurvedAnimation(
      parent: _strikethroughController,
      curve: Curves.easeOutCubic,
    );
    // 이미 완료된 투두는 애니메이션 없이 바로 완료 상태를 보여준다
    if (widget.todo.isCompleted) {
      _checkController.value = 1.0;
      _strikethroughController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(TodoItemTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.todo.isCompleted != widget.todo.isCompleted) {
      if (widget.todo.isCompleted) {
        _checkController.forward();
        _strikethroughController.forward();
      } else {
        _checkController.reverse();
        _strikethroughController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _checkController.dispose();
    // CurvedAnimation은 별도로 dispose해야 리스너 누수를 방지한다
    _strikethroughAnimation.dispose();
    _strikethroughController.dispose();
    super.dispose();
  }

  /// 300ms debounce로 체크 토글 (spec 11.6)
  void _handleToggle() {
    if (_isDebouncePending) return;
    _isDebouncePending = true;
    // 햅틱 피드백 (Android)
    HapticFeedback.lightImpact();
    widget.onToggle(!widget.todo.isCompleted);
    Future.delayed(AppAnimation.slow, () {
      // 위젯이 소멸된 후에는 상태를 변경하지 않는다
      if (!mounted) return;
      _isDebouncePending = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = ColorTokens.eventColor(widget.todo.colorIndex);
    return Dismissible(
      key: Key(widget.todo.id),
      direction: DismissDirection.endToStart,
      // 스와이프 삭제 시 확인 다이얼로그를 표시한다 (P1-15)
      confirmDismiss: (_) => showTodoDeleteConfirm(context),
      onDismissed: (_) => widget.onDelete?.call(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.xxl),
        decoration: BoxDecoration(
          color: ColorTokens.error.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Icon(
          Icons.delete_outline_rounded,
          color: context.themeColors.textPrimary,
          size: AppLayout.iconXl,
        ),
      ),
      child: GestureDetector(
        // 타일 탭 시 수정 다이얼로그를 연다
        onTap: widget.onEdit,
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            color: context.themeColors.textPrimaryWithAlpha(0.12),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: context.themeColors.textPrimaryWithAlpha(0.18),
            ),
          ),
          child: Row(
            children: [
              // 색상 인디케이터
              Container(
                width: AppLayout.colorBarWidth,
                height: AppLayout.colorBarHeight,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              // 체크박스 (시각: 20x20, 터치 타겟: 44x44)
              TodoAnimatedCheckbox(
                isChecked: widget.todo.isCompleted,
                checkController: _checkController,
                onTap: _handleToggle,
              ),
              const SizedBox(width: AppSpacing.lg),
              // 제목 + 시간 (빨간 연필 취소선 애니메이션 포함)
              Expanded(
                child: TodoTitleSection(
                  title: widget.todo.title,
                  time: widget.todo.time,
                  strikethroughAnimation: _strikethroughAnimation,
                ),
              ),
              // 포모도로 타이머 연결 버튼
              TodoTimerButton(
                todoId: widget.todo.id,
                todoTitle: widget.todo.title,
              ),
            ],
          ),
        ),
      ),
    );
  }

}
