// F5 위젯: StaggeredCard - 카드 등장 애니메이션 위젯 (SRP 분리)
// goal_list_helpers.dart에서 추출한다.
// 카드 인덱스 기반 딜레이로 순차적 등장 효과를 구현한다 (AN-02).
import 'package:flutter/material.dart';
import '../../../../core/theme/animation_tokens.dart';

/// Staggered 카드 등장 애니메이션 위젯
/// 카드 인덱스 기반 딜레이로 순차적 등장 효과를 구현한다 (AN-02)
class StaggeredCard extends StatefulWidget {
  final int index;
  final Widget child;

  const StaggeredCard({
    super.key,
    required this.index,
    required this.child,
  });

  @override
  State<StaggeredCard> createState() => _StaggeredCardState();
}

class _StaggeredCardState extends State<StaggeredCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimation.slow,
    );

    // 카드 인덱스 기반 딜레이 (최대 8개 * 50ms = 400ms)
    final delay = (widget.index * 50).clamp(0, 350);
    Future.delayed(Duration(milliseconds: delay), () {
      if (mounted) _controller.forward();
    });

    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}
