// 공용 위젯: LoadingIndicator
// 데이터 로딩 중 표시하는 스켈레톤/스피너 컴포넌트.
import 'package:flutter/material.dart';
import '../../core/theme/animation_tokens.dart';
import '../../core/theme/layout_tokens.dart';
import '../../core/theme/radius_tokens.dart';
import '../../core/theme/theme_colors.dart';

/// 글래스모피즘 스타일 로딩 스켈레톤 위젯
/// AN-14: Gradient sweep 1500ms 반복 시머 애니메이션
class LoadingSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const LoadingSkeleton({
    this.width = double.infinity,
    this.height = 80,
    this.borderRadius = AppRadius.card,
    super.key,
  });

  @override
  State<LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<LoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // AN-14: 1500ms 반복 시머 (linear 예외 허용)
    _controller = AnimationController(
      duration: AppAnimation.shimmer,
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + _controller.value * 3, 0),
              end: Alignment(-1.0 + _controller.value * 3 + 1, 0),
              colors: [
                context.themeColors.textPrimaryWithAlpha(0.06),
                context.themeColors.textPrimaryWithAlpha(0.15),
                context.themeColors.textPrimaryWithAlpha(0.06),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 원형 로딩 스피너 (글래스모피즘 스타일)
class GlassLoadingSpinner extends StatelessWidget {
  final double size;

  const GlassLoadingSpinner({this.size = AppLayout.iconXxl, super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        valueColor: AlwaysStoppedAnimation<Color>(
          context.themeColors.textPrimaryWithAlpha(0.7),
        ),
      ),
    );
  }
}
