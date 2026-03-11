// 공용 위젯: CheckItem (체크박스 리스트 아이템)
// 투두 체크리스트 아이템 - 완료 시 취소선 + opacity 0.5 적용
// AN-04: Scale bounce + 체크마크 draw 애니메이션 (300ms, easeOutBack)
// design-system.md 14.1절 투두 체크박스 스펙 참조
import 'package:flutter/material.dart';
import '../../core/theme/animation_tokens.dart';
import '../../core/theme/color_tokens.dart';
import '../../core/theme/layout_tokens.dart';
import '../../core/theme/radius_tokens.dart';
import '../../core/theme/spacing_tokens.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/theme/typography_tokens.dart';

/// 체크박스 리스트 아이템 공용 위젯
/// 홈 대시보드 투두 프리뷰, 투두 탭 리스트에서 사용한다
class CheckItem extends StatefulWidget {
  /// 아이템 텍스트
  final String title;

  /// 완료 상태
  final bool isCompleted;

  /// 완료 상태 변경 콜백
  final ValueChanged<bool>? onToggle;

  /// 텍스트 클릭 콜백 (선택)
  final VoidCallback? onTap;

  /// 오른쪽 부가 위젯 (선택: 시간, 태그 등)
  final Widget? trailing;

  const CheckItem({
    super.key,
    required this.title,
    required this.isCompleted,
    this.onToggle,
    this.onTap,
    this.trailing,
  });

  @override
  State<CheckItem> createState() => _CheckItemState();
}

class _CheckItemState extends State<CheckItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // AN-04: Scale bounce 애니메이션 (300ms, easeOutBack)
    _controller = AnimationController(
      duration: AppAnimation.medium,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleToggle() async {
    if (widget.onToggle == null) return;

    // Reduced Motion 확인
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    if (!reduceMotion) {
      // Scale bounce: 1.0 -> 0.85 -> 1.15 -> 1.0
      _scaleAnimation = TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.85),
          weight: 25,
        ),
        TweenSequenceItem(
          tween: Tween(begin: 0.85, end: 1.15),
          weight: 35,
        ),
        TweenSequenceItem(
          tween: Tween(begin: 1.15, end: 1.0),
          weight: 40,
        ),
      ]).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
      );
      await _controller.forward(from: 0);
    }

    widget.onToggle!(!widget.isCompleted);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Padding(
        // check item 간격: 8px (space-2)
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            // 체크박스 (시각: 20x20, 터치 타겟: 44x44)
            // WCAG 2.1 기준 최소 터치 타겟 44x44px 적용
            Semantics(
              label: widget.isCompleted
                  ? '${widget.title} 완료됨'
                  : '${widget.title} 미완료',
              toggled: widget.isCompleted,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: GestureDetector(
                  onTap: _handleToggle,
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    width: AppLayout.minTouchTarget,
                    height: AppLayout.minTouchTarget,
                    child: Center(
                      child: AnimatedContainer(
                        duration: AppAnimation.normal,
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          // 완료: 테마 텍스트 색상 30% / 미완료: 투명
                          color: widget.isCompleted
                              ? context.themeColors.textPrimaryWithAlpha(0.30)
                              : ColorTokens.transparent,
                          borderRadius: BorderRadius.circular(AppRadius.md), // radius-md (6px)
                          border: Border.all(
                            color: widget.isCompleted
                                ? context.themeColors.textPrimaryWithAlpha(0.60)
                                : context.themeColors.textPrimaryWithAlpha(0.40),
                            width: 2,
                          ),
                        ),
                        child: widget.isCompleted
                            ? Icon(
                                Icons.check,
                                color: context.themeColors.textPrimary,
                                size: AppSpacing.lg,
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: AppSpacing.lg), // space-3

            // 텍스트 (완료 시 취소선 + opacity 0.5)
            Expanded(
              child: AnimatedOpacity(
                opacity: widget.isCompleted ? 0.50 : 1.0,
                duration: AppAnimation.normal,
                child: Text(
                  widget.title,
                  style: AppTypography.bodyLg.copyWith(
                    color: context.themeColors.textPrimary,
                    decoration: widget.isCompleted
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    decorationColor: context.themeColors.textPrimaryWithAlpha(0.50),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            // 오른쪽 부가 위젯 (선택)
            if (widget.trailing != null) ...[
              const SizedBox(width: AppSpacing.md),
              widget.trailing!,
            ],
          ],
        ),
      ),
    );
  }
}
