// F7-W1: 스트로크 렌더링 CustomPainter
// perfect_freehand의 getStroke()를 사용하여 부드러운 곡선을 그린다.
// 각 StrokeData를 Path.addPolygon()으로 변환하여 캔버스에 렌더링한다.
// 입력: List<StrokeData> (완성된 스트로크) + StrokeData? (현재 그리는 중인 스트로크)
// 출력: Canvas에 렌더링된 스트로크 폴리곤
import 'package:flutter/material.dart';
import 'package:perfect_freehand/perfect_freehand.dart';

import '../../models/stroke_data.dart';

/// 스트로크 렌더링 전용 CustomPainter
/// 완성된 스트로크 목록과 현재 그리는 중인 스트로크를 분리하여 처리한다
class MemoStrokePainter extends CustomPainter {
  /// 이미 완성된 스트로크 목록
  final List<StrokeData> strokes;

  /// 현재 그리는 중인 스트로크 (null이면 비활성)
  final StrokeData? activeStroke;

  const MemoStrokePainter({
    required this.strokes,
    this.activeStroke,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 완성된 스트로크를 순서대로 렌더링한다
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke, isComplete: true);
    }
    // 현재 그리는 중인 스트로크를 실시간 렌더링한다
    if (activeStroke != null) {
      _drawStroke(canvas, activeStroke!, isComplete: false);
    }
  }

  /// 단일 스트로크를 캔버스에 그린다
  void _drawStroke(Canvas canvas, StrokeData stroke,
      {required bool isComplete}) {
    if (stroke.points.isEmpty) return;

    // PointData → PointVector 변환 (perfect_freehand 입력 형식)
    final points = stroke.points
        .map((p) => PointVector(p.x, p.y, p.pressure))
        .toList();

    // getStroke()로 부드러운 외곽선 좌표를 생성한다
    final outlinePoints = getStroke(
      points,
      options: StrokeOptions(
        size: stroke.width,
        thinning: 0.4,
        smoothing: 0.5,
        streamline: 0.5,
        simulatePressure: false,
        isComplete: isComplete,
      ),
    );

    if (outlinePoints.isEmpty) return;

    // 외곽선 좌표를 Path로 변환한다
    final path = Path();
    if (outlinePoints.length < 2) {
      // 포인트가 1개인 경우 원으로 표현한다
      final p = outlinePoints.first;
      path.addOval(Rect.fromCircle(
        center: p,
        radius: stroke.width / 2,
      ));
    } else {
      path.addPolygon(outlinePoints, true);
    }

    // 페인트 설정 (안티앨리어싱 + 색상)
    final paint = Paint()
      ..color = Color(stroke.colorValue)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(MemoStrokePainter oldDelegate) {
    // 스트로크 목록이나 현재 그리는 중인 스트로크가 변경되면 다시 그린다
    return strokes != oldDelegate.strokes ||
        activeStroke != oldDelegate.activeStroke;
  }
}
