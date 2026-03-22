// F3 위젯: TodoItemTile - 투두 아이템 타일
// 체크박스 + 투두 제목 + 시간(선택) + 색상 인디케이터를 표시한다.
// 체크박스 탭 시 300ms debounce로 isCompleted를 토글한다.
// 완료 시 빨간 연필 스타일 취소선이 좌→우로 애니메이션 된다.
// 타이머 아이콘 버튼 탭 시 해당 투두가 연결된 상태로 타이머 화면으로 이동한다.
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_paths.dart';
import '../../../timer/providers/timer_provider.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../shared/models/todo.dart';
import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';

/// 취소선 색상: 회색 톤으로 완료된 투두를 부드럽게 표시한다
const _kStrikethroughColor = ColorTokens.gray500;

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
  late Animation<double> _strikethroughAnimation;
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

  /// 투두 삭제 확인 다이얼로그를 표시한다 (P1-15)
  /// 사용자가 '삭제'를 선택하면 true를 반환하여 Dismissible 삭제를 허용한다
  Future<bool> _showDeleteConfirm(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.themeColors.dialogSurface,
        title: Text(
          '할 일 삭제',
          style: AppTypography.titleMd.copyWith(
            color: context.themeColors.textPrimary,
          ),
        ),
        content: Text(
          '이 할 일을 삭제하시겠습니까?',
          style: AppTypography.bodyMd.copyWith(
            color: context.themeColors.textPrimaryWithAlpha(0.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              '취소',
              style: AppTypography.bodyMd.copyWith(
                color: context.themeColors.textPrimaryWithAlpha(0.7),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              '삭제',
              style: AppTypography.bodyMd.copyWith(
                color: ColorTokens.error,
              ),
            ),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  @override
  Widget build(BuildContext context) {
    final color = ColorTokens.eventColor(widget.todo.colorIndex);
    return Dismissible(
      key: Key(widget.todo.id),
      direction: DismissDirection.endToStart,
      // 스와이프 삭제 시 확인 다이얼로그를 표시한다 (P1-15)
      confirmDismiss: (_) => _showDeleteConfirm(context),
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
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
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
              // WCAG 2.1 기준 최소 터치 타겟 44x44px 적용
              GestureDetector(
                onTap: _handleToggle,
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: AppLayout.minTouchTarget,
                  height: AppLayout.minTouchTarget,
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _checkController,
                      builder: (context, _) {
                        // 체크박스 탭 시 미세한 스케일 bounce 효과
                        final scale = 1.0 +
                            (_checkController.value > 0.5
                                ? (1 - _checkController.value) * AppLayout.checkboxBounceScale
                                : -_checkController.value * AppLayout.checkboxShrinkScale);
                        return Transform.scale(
                          scale: scale,
                          child: _CheckboxWidget(
                            isChecked: widget.todo.isCompleted,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              // 제목 + 시간 (빨간 연필 취소선 애니메이션 포함)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 텍스트 위에 빨간 연필 취소선을 그리기 위해 Stack 사용
                    AnimatedBuilder(
                      animation: _strikethroughAnimation,
                      builder: (context, _) {
                        return Stack(
                          children: [
                            // 텍스트 본문 (기본 lineThrough 대신 커스텀 취소선 사용)
                            AnimatedDefaultTextStyle(
                              duration: AppAnimation.slow,
                              curve: Curves.easeInOut,
                              style: AppTypography.bodyLg.copyWith(
                                // 취소선 애니메이션 완료 후 투명도를 낮춘다
                                color: Color.lerp(
                                  context.themeColors.textPrimary,
                                  context.themeColors.textPrimaryWithAlpha(0.5),
                                  _strikethroughAnimation.value,
                                ),
                              ),
                              child: Text(
                                widget.todo.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // 빨간 연필 취소선 (좌→우 애니메이션)
                            if (_strikethroughAnimation.value > 0)
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: _RedPencilStrikethroughPainter(
                                    progress: _strikethroughAnimation.value,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    if (widget.todo.time != null) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        '${widget.todo.time!.hour.toString().padLeft(2, '0')}:${widget.todo.time!.minute.toString().padLeft(2, '0')}',
                        // WCAG: 시간 텍스트 알파 0.55 이상으로 가독성 보장
                        style: AppTypography.captionMd.copyWith(
                          color: context.themeColors.textPrimaryWithAlpha(0.55),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // 포모도로 타이머 연결 버튼
              // 해당 투두를 연결한 상태로 타이머 탭으로 전환한다
              // 원형 테두리 + 아이콘으로 직관적인 타이머 시작 버튼을 제공한다
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  // 타이머에 투두를 연결한 뒤 타이머 탭으로 전환한다
                  final container = ProviderScope.containerOf(context);
                  container.read(timerStateProvider.notifier).linkTodo(
                        todoId: widget.todo.id,
                        todoTitle: widget.todo.title,
                      );
                  context.go(RoutePaths.timer);
                },
                child: SizedBox(
                  width: AppLayout.minTouchTarget,
                  height: AppLayout.minTouchTarget,
                  child: Center(
                    child: Container(
                      width: AppLayout.containerMd,
                      height: AppLayout.containerMd,
                      decoration: BoxDecoration(
                        // 포모도로 아이콘 배경: 악센트 색상 힌트로 직관성 향상
                        color: context.themeColors.accentWithAlpha(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: context.themeColors.accentWithAlpha(0.35),
                        ),
                      ),
                      child: Icon(
                        Icons.timer_rounded,
                        // WCAG 대비: accent 배경 위에서 테마 색상으로 고대비 확보
                        color: context.themeColors.textPrimaryWithAlpha(0.8),
                        size: AppLayout.iconSm,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 빨간 연필 스타일 취소선을 그리는 CustomPainter
/// 좌측에서 우측으로 progress에 비례해 선을 그린다.
/// 손으로 그린 듯한 미세한 흔들림(waviness)을 적용한다.
class _RedPencilStrikethroughPainter extends CustomPainter {
  final double progress;

  _RedPencilStrikethroughPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final paint = Paint()
      ..color = _kStrikethroughColor.withValues(alpha: AppLayout.pencilStrokeAlpha)
      ..strokeWidth = AppLayout.pencilStrokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // 텍스트 수직 중앙 기준선 (첫 번째 줄 기준)
    final centerY = size.height * AppLayout.pencilStrokeCenterY;
    final endX = size.width * progress;

    // 손으로 그린 듯한 미세한 흔들림 경로를 생성한다
    final path = Path();
    path.moveTo(0, centerY);

    // 세그먼트 간격으로 미세한 y축 흔들림을 주어 연필 느낌을 낸다
    const segmentWidth = AppLayout.pencilSegmentWidth;
    final segmentCount = (endX / segmentWidth).ceil();
    final random = math.Random(42); // 고정 시드로 프레임 간 일관성 유지

    for (int i = 1; i <= segmentCount; i++) {
      final x = (i * segmentWidth).clamp(0.0, endX);
      // 미세한 y축 흔들림 범위
      final yOffset = (random.nextDouble() - 0.5) * AppLayout.pencilWavinessRange;
      path.lineTo(x, centerY + yOffset);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_RedPencilStrikethroughPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// 투두 체크박스 위젯 (사각형, 6px radius)
/// AnimatedContainer slow(500ms) + AnimatedOpacity로 부드러운 전환
class _CheckboxWidget extends StatelessWidget {
  final bool isChecked;

  const _CheckboxWidget({required this.isChecked});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppAnimation.slow,
      curve: Curves.easeInOut,
      width: AppLayout.checkboxMd,
      height: AppLayout.checkboxMd,
      decoration: BoxDecoration(
        // 완료: 빨간색 배경 / 미완료: 투명
        color: isChecked
            ? ColorTokens.error.withValues(alpha: 0.20)
            : ColorTokens.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isChecked
              ? ColorTokens.error
              : context.themeColors.textPrimaryWithAlpha(0.50),
          width: AppLayout.borderThick,
        ),
      ),
      // 체크 아이콘: AnimatedOpacity로 부드러운 fade 전환 (조건부 null 대신)
      child: AnimatedOpacity(
        opacity: isChecked ? 1.0 : 0.0,
        duration: AppAnimation.slow,
        child: Icon(
          Icons.check_rounded,
          size: AppLayout.iconXxxs,
          color: ColorTokens.error,
        ),
      ),
    );
  }
}
