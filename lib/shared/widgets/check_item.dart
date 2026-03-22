// 공용 위젯: CheckItem (체크박스 리스트 아이템)
// 투두 체크리스트 아이템 - 완료 시 빨간펜 취소선 애니메이션 + 부드러운 opacity 전환
// AN-05: 빨간펜 취소선 draw 애니메이션 — AnimatedStrikethrough 공용 위젯으로 위임
// AN-04: 체크박스 토글 시 TweenSequence 스케일 바운스 (0.95/1.02 패턴)
import 'package:flutter/material.dart';
import '../../core/theme/animation_tokens.dart';
import '../../core/theme/color_tokens.dart';
import '../../core/theme/layout_tokens.dart';
import '../../core/theme/radius_tokens.dart';
import '../../core/theme/spacing_tokens.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/theme/typography_tokens.dart';
import 'animated_strikethrough.dart';

/// 체크박스 리스트 아이템 공용 위젯
/// 홈 대시보드 투두 프리뷰, 투두 탭 리스트에서 사용한다
/// 체크박스 토글 시 스케일 바운스 + 빨간펜 취소선이 부드럽게 그어지고 텍스트가 서서히 흐려진다
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
  late final AnimationController _bounceController;
  late final Animation<double> _bounceAnimation;

  /// 토글 디바운스 플래그: 연속 탭으로 인한 중복 호출을 방지한다
  bool _isDebouncePending = false;

  @override
  void initState() {
    super.initState();
    // 스케일 바운스: 통일된 TweenSequence 패턴 (500ms, 0.95/1.02)
    _bounceController = AnimationController(
      duration: AppAnimation.slow,
      vsync: this,
    );
    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.95), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.02), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.02, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  /// 체크박스 토글 핸들러: 바운스 애니메이션 후 콜백 실행
  void _handleToggle() {
    if (widget.onToggle == null) return;

    // 연속 탭 방지: 500ms 디바운스로 중복 토글을 차단한다
    if (_isDebouncePending) return;
    _isDebouncePending = true;
    Future.delayed(const Duration(milliseconds: 500), () {
      _isDebouncePending = false;
    });

    // Reduced Motion 확인: 접근성 설정 시 바운스 생략
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (!reduceMotion) {
      _bounceController.forward(from: 0.0);
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
        child: ScaleTransition(
          scale: _bounceAnimation,
          child: Row(
            children: [
              // 체크박스 (시각: 20x20, 터치 타겟: 44x44)
              // WCAG 2.1 기준 최소 터치 타겟 44x44px 적용
              Semantics(
                label: widget.isCompleted
                    ? '${widget.title} 완료됨'
                    : '${widget.title} 미완료',
                toggled: widget.isCompleted,
                child: GestureDetector(
                  onTap: _handleToggle,
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    width: AppLayout.minTouchTarget,
                    height: AppLayout.minTouchTarget,
                    child: Center(
                      // 체크박스 색상 전환: 500ms easeInOut로 부드럽게
                      child: AnimatedContainer(
                        duration: AppAnimation.slow,
                        curve: Curves.easeInOut,
                        width: AppLayout.checkboxMd,
                        height: AppLayout.checkboxMd,
                        decoration: BoxDecoration(
                          // 완료: 빨간색 배경 / 미완료: 투명
                          color: widget.isCompleted
                              ? ColorTokens.error.withValues(alpha: 0.15)
                              : ColorTokens.transparent,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: widget.isCompleted
                                ? ColorTokens.error
                                : context.themeColors.textPrimaryWithAlpha(0.40),
                            width: AppLayout.borderThick,
                          ),
                        ),
                        // 체크 아이콘도 부드럽게 나타남 (AnimatedOpacity로 전환)
                        child: AnimatedOpacity(
                          opacity: widget.isCompleted ? 1.0 : 0.0,
                          duration: AppAnimation.slow,
                          curve: Curves.easeInOut,
                          child: Icon(
                            Icons.check,
                            color: ColorTokens.error,
                            size: AppSpacing.lg,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: AppSpacing.lg), // space-3

              // 텍스트: 빨간펜 취소선 + 부드러운 opacity 전환
              // AnimatedStrikethrough가 자체 컨트롤러로 취소선을 관리한다
              Expanded(
                child: AnimatedOpacity(
                  opacity: widget.isCompleted ? 0.50 : 1.0,
                  duration: AppAnimation.textFade,
                  curve: Curves.easeInOut,
                  child: AnimatedStrikethrough(
                    text: widget.title,
                    style: AppTypography.bodyLg.copyWith(
                      color: context.themeColors.textPrimary,
                    ),
                    isActive: widget.isCompleted,
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
      ),
    );
  }
}
