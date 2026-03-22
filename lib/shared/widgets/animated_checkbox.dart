// 공용 위젯: AnimatedCheckbox (스케일 바운스 체크박스)
// 모든 탭에서 동일한 체크박스 경험을 제공한다
// CheckItem 위젯의 TweenSequence 바운스 패턴을 재사용하여 일관성을 유지한다
import 'package:flutter/material.dart';

import '../../core/theme/animation_tokens.dart';
import '../../core/theme/color_tokens.dart';
import '../../core/theme/layout_tokens.dart';
import '../../core/theme/radius_tokens.dart';
import '../../core/theme/theme_colors.dart';

/// 스케일 바운스가 포함된 애니메이션 체크박스
/// 탭 시 1.0→0.95→1.02→1.0 스케일 시퀀스로 물리적 피드백을 제공한다
class AnimatedCheckbox extends StatefulWidget {
  /// 완료 상태
  final bool isCompleted;

  /// 탭 콜백 (null이면 비활성)
  final VoidCallback? onTap;

  /// 체크박스 크기 (기본값: AppLayout.checkboxMd = 20px)
  final double size;

  const AnimatedCheckbox({
    super.key,
    required this.isCompleted,
    this.onTap,
    this.size = AppLayout.checkboxMd,
  });

  @override
  State<AnimatedCheckbox> createState() => _AnimatedCheckboxState();
}

class _AnimatedCheckboxState extends State<AnimatedCheckbox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceController;
  late final Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    // 바운스 컨트롤러: 500ms slow 토큰과 동일
    _bounceController = AnimationController(
      duration: AppAnimation.slow,
      vsync: this,
    );
    // TweenSequence: 자연스러운 3단계 스케일 바운스
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Reduced Motion 확인: 접근성 설정 시 바운스 생략
        final reduceMotion = MediaQuery.disableAnimationsOf(context);
        if (!reduceMotion) {
          _bounceController.forward(from: 0.0);
        }
        widget.onTap?.call();
      },
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _bounceAnimation,
        child: AnimatedContainer(
          duration: AppAnimation.slow,
          curve: Curves.easeInOut,
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
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
          child: AnimatedOpacity(
            opacity: widget.isCompleted ? 1.0 : 0.0,
            duration: AppAnimation.slow,
            curve: Curves.easeInOut,
            child: Icon(
              Icons.check,
              color: ColorTokens.error,
              size: widget.size * 0.65,
            ),
          ),
        ),
      ),
    );
  }
}
