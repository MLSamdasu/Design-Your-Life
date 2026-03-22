// 공용 위젯: AnimatedStrikethrough (빨간펜 취소선 애니메이션)
// 텍스트 위에 빨간 선이 좌에서 우로 800ms 동안 그어지는 효과를 제공한다.
// AN-05: 글자의 실제 렌더링 너비만큼만 선이 그어진다.
// isActive 상태 변경 시 forward/reverse 로 자연스러운 전환을 수행한다.
import 'package:flutter/material.dart';

import '../../core/theme/animation_tokens.dart';
import '../../core/theme/color_tokens.dart';

/// 빨간펜 취소선 애니메이션 위젯
/// 텍스트 위에 빨간 선이 좌→우로 800ms 동안 그어지는 효과를 제공한다.
/// 글자의 실제 렌더링 너비만큼만 선이 그어진다.
class AnimatedStrikethrough extends StatefulWidget {
  /// 표시할 텍스트
  final String text;

  /// 텍스트 스타일 (너비 측정 + 렌더링 공유)
  final TextStyle style;

  /// true면 선 그어짐, false면 선 없음
  final bool isActive;

  /// 최대 줄 수 (기본: 1)
  final int maxLines;

  /// 텍스트 오버플로우 처리 (기본: ellipsis)
  final TextOverflow overflow;

  const AnimatedStrikethrough({
    super.key,
    required this.text,
    required this.style,
    required this.isActive,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
  });

  @override
  State<AnimatedStrikethrough> createState() => _AnimatedStrikethroughState();
}

class _AnimatedStrikethroughState extends State<AnimatedStrikethrough>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  // easeOut 커브로 처음 빠르게 → 끝에서 감속하여 자연스러운 필기 느낌
  late final CurvedAnimation _curvedAnimation;

  @override
  void initState() {
    super.initState();
    // AN-05: 빨간펜 취소선 800ms — 천천히 펜으로 긋는 속도
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimation.effect,
    );
    _curvedAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
    // 이미 완료된 상태로 위젯이 생성된 경우 → 애니메이션 없이 바로 표시
    if (widget.isActive) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedStrikethrough oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 외부에서 isActive가 변경된 경우 (토글, 데이터 동기화 등)
    if (oldWidget.isActive != widget.isActive) {
      if (widget.isActive) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _curvedAnimation.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curvedAnimation,
      builder: (context, child) {
        return CustomPaint(
          foregroundPainter: _StrikethroughPainter(
            progress: _curvedAnimation.value,
            color: ColorTokens.error.withValues(alpha: 0.70),
            title: widget.text,
            textStyle: widget.style,
            maxLines: widget.maxLines,
          ),
          child: child,
        );
      },
      child: Text(
        widget.text,
        style: widget.style,
        maxLines: widget.maxLines,
        overflow: widget.overflow,
      ),
    );
  }
}

/// 빨간펜 취소선을 그리는 CustomPainter
/// 텍스트 실제 렌더링 너비를 TextPainter로 측정하여 글자 끝까지만 선을 긋는다.
/// [progress] 0.0~1.0: 선이 좌측에서 우측으로 그어지는 비율
/// [color]: 취소선 색상 (ColorTokens.error 기반)
class _StrikethroughPainter extends CustomPainter {
  final double progress;
  final Color color;
  final String title;
  final TextStyle textStyle;
  final int maxLines;

  /// 취소선 두께 (플래너 빨간연필 느낌: 4px — 굵직한 연필 스트로크)
  static const double _strokeWidth = 4.0;

  _StrikethroughPainter({
    required this.progress,
    required this.color,
    required this.title,
    required this.textStyle,
    required this.maxLines,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // progress가 0이면 아무것도 그리지 않는다
    if (progress <= 0.0) return;

    // TextPainter로 텍스트 실제 렌더링 크기를 측정한다
    final textPainter = TextPainter(
      text: TextSpan(text: title, style: textStyle),
      maxLines: maxLines,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width);

    // 실제 텍스트 너비 (ellipsis 처리된 경우 size.width보다 작을 수 있음)
    final textWidth = textPainter.width.clamp(0.0, size.width);

    // 텍스트 실제 높이 기준으로 Y 위치 계산 (컨테이너가 더 클 수 있음)
    // 텍스트가 컨테이너 상단 정렬이므로 텍스트 높이의 중앙이 실제 글자 중앙
    final textHeight = textPainter.height;
    final y = textHeight / 2;

    final paint = Paint()
      ..color = color
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;

    final endX = textWidth * progress;

    canvas.drawLine(
      Offset(0, y),
      Offset(endX, y),
      paint,
    );
  }

  @override
  bool shouldRepaint(_StrikethroughPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.title != title;
  }
}
