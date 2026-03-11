// F3 위젯: TodoItemTile - 투두 아이템 타일
// 체크박스 + 투두 제목 + 시간(선택) + 색상 인디케이터를 표시한다.
// 체크박스 탭 시 300ms debounce로 isCompleted를 토글한다.
// 완료 시 빨간 연필 스타일 취소선이 좌→우로 애니메이션 된다.
// 타이머 아이콘 버튼 탭 시 해당 투두가 연결된 상태로 타이머 화면으로 이동한다.
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../shared/models/todo.dart';
import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';

/// 빨간 연필 취소선 색상 (ColorTokens.error 사용)
const _kStrikethroughColor = ColorTokens.error;

/// 투두 아이템 타일 위젯
/// AN-04: 체크박스 완료 시 scale bounce + 빨간 연필 취소선 애니메이션
class TodoItemTile extends StatefulWidget {
  final Todo todo;
  final ValueChanged<bool> onToggle;
  final VoidCallback? onDelete;

  const TodoItemTile({
    required this.todo,
    required this.onToggle,
    this.onDelete,
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
    // AN-04: 체크박스 bounce 애니메이션 300ms easeOutBack
    _checkController = AnimationController(
      duration: AppAnimation.medium,
      vsync: this,
    );
    // 빨간 연필 취소선 애니메이션: 400ms easeOutCubic
    _strikethroughController = AnimationController(
      duration: AppAnimation.slower,
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
    Future.delayed(AppAnimation.medium, () {
      _isDebouncePending = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = ColorTokens.eventColor(widget.todo.colorIndex);
    return Dismissible(
      key: Key(widget.todo.id),
      direction: DismissDirection.endToStart,
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
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
        decoration: BoxDecoration(
          color: context.themeColors.textPrimaryWithAlpha(0.08),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: context.themeColors.textPrimaryWithAlpha(0.12),
          ),
        ),
        child: Row(
          children: [
            // 색상 인디케이터
            Container(
              width: 4,
              height: 36,
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
                width: 44,
                height: 44,
                child: Center(
                  child: AnimatedBuilder(
                    animation: _checkController,
                    builder: (context, _) {
                      // 체크박스 탭 시 미세한 스케일 bounce 효과
                      final scale = 1.0 +
                          (_checkController.value > 0.5
                              ? (1 - _checkController.value) * 0.3
                              : -_checkController.value * 0.15);
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
                            duration: AppAnimation.normal,
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
                      style: AppTypography.captionMd.copyWith(
                        color: context.themeColors.textPrimaryWithAlpha(0.5),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // 포모도로 타이머 연결 버튼
            // 해당 투두를 연결한 상태로 타이머 화면으로 이동한다
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => context.push(
                RoutePaths.timer,
                extra: {
                  'todoId': widget.todo.id,
                  'todoTitle': widget.todo.title,
                },
              ),
              child: SizedBox(
                width: 36,
                height: 44,
                child: Center(
                  child: Icon(
                    Icons.timer_outlined,
                    color: context.themeColors.textPrimaryWithAlpha(0.40),
                    size: AppLayout.iconLg,
                  ),
                ),
              ),
            ),
          ],
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
      ..color = _kStrikethroughColor.withValues(alpha: 0.85)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // 텍스트 수직 중앙 기준선 (첫 번째 줄 기준)
    final centerY = size.height * 0.45;
    final endX = size.width * progress;

    // 손으로 그린 듯한 미세한 흔들림 경로를 생성한다
    final path = Path();
    path.moveTo(0, centerY);

    // 약 8px 간격으로 미세한 y축 흔들림을 주어 연필 느낌을 낸다
    const segmentWidth = 8.0;
    final segmentCount = (endX / segmentWidth).ceil();
    final random = math.Random(42); // 고정 시드로 프레임 간 일관성 유지

    for (int i = 1; i <= segmentCount; i++) {
      final x = (i * segmentWidth).clamp(0.0, endX);
      // -1.2 ~ 1.2px 범위의 미세한 y축 흔들림
      final yOffset = (random.nextDouble() - 0.5) * 2.4;
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
class _CheckboxWidget extends StatelessWidget {
  final bool isChecked;

  const _CheckboxWidget({required this.isChecked});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppAnimation.normal,
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: isChecked
            ? context.themeColors.textPrimaryWithAlpha(0.3)
            : ColorTokens.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isChecked
              ? context.themeColors.textPrimaryWithAlpha(0.6)
              : context.themeColors.textPrimaryWithAlpha(0.4),
          width: 2,
        ),
      ),
      child: isChecked
          ? Icon(
              Icons.check_rounded,
              size: 12,
              color: context.themeColors.textPrimary,
            )
          : null,
    );
  }
}
