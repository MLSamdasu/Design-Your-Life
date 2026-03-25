// F3 위젯: RedPencilStrikethroughPainter - 빨간 연필 취소선
// 좌측에서 우측으로 progress에 비례해 선을 그린다.
// 손으로 그린 듯한 미세한 흔들림(waviness)을 적용한다.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';

/// 취소선 색상: 회색 톤으로 완료된 투두를 부드럽게 표시한다
const kStrikethroughColor = ColorTokens.gray500;

/// 빨간 연필 스타일 취소선을 그리는 CustomPainter
/// 좌측에서 우측으로 progress에 비례해 선을 그린다.
/// 손으로 그린 듯한 미세한 흔들림(waviness)을 적용한다.
class RedPencilStrikethroughPainter extends CustomPainter {
  final double progress;

  RedPencilStrikethroughPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final paint = Paint()
      ..color = kStrikethroughColor.withValues(alpha: EffectLayout.pencilStrokeAlpha)
      ..strokeWidth = EffectLayout.pencilStrokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // 텍스트 수직 중앙 기준선 (첫 번째 줄 기준)
    final centerY = size.height * EffectLayout.pencilStrokeCenterY;
    final endX = size.width * progress;

    // 손으로 그린 듯한 미세한 흔들림 경로를 생성한다
    final path = Path();
    path.moveTo(0, centerY);

    // 세그먼트 간격으로 미세한 y축 흔들림을 주어 연필 느낌을 낸다
    const segmentWidth = EffectLayout.pencilSegmentWidth;
    final segmentCount = (endX / segmentWidth).ceil();
    final random = math.Random(42); // 고정 시드로 프레임 간 일관성 유지

    for (int i = 1; i <= segmentCount; i++) {
      final x = (i * segmentWidth).clamp(0.0, endX);
      // 미세한 y축 흔들림 범위
      final yOffset = (random.nextDouble() - 0.5) * EffectLayout.pencilWavinessRange;
      path.lineTo(x, centerY + yOffset);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(RedPencilStrikethroughPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
