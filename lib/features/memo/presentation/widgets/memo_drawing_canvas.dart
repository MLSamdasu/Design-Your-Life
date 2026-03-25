// F7-W2: 자유 드로잉 캔버스 위젯
// Listener로 PointerEvent를 수신하여 필압 데이터를 포함한 스트로크를 기록한다.
// 완성된 스트로크는 onStrokesChanged 콜백으로 부모에게 전달한다.
// 입력: 초기 스트로크 목록, 현재 펜 색상/두께, 지우개 모드
// 출력: onStrokesChanged 콜백 (자동 저장 트리거)
import 'package:flutter/material.dart';

import '../../models/stroke_data.dart';
import 'memo_stroke_painter.dart';

/// 자유 드로잉 캔버스
/// Apple Pencil / S Pen 필압을 지원하며 smooth 곡선을 실시간 렌더링한다
class MemoDrawingCanvas extends StatefulWidget {
  /// 저장된 스트로크 목록 (초기값)
  final List<StrokeData> initialStrokes;

  /// 현재 선택된 펜 색상
  final Color penColor;

  /// 현재 선택된 펜 두께
  final double penWidth;

  /// 지우개 모드 활성화 여부
  final bool isErasing;

  /// 스트로크 목록이 변경될 때 호출되는 콜백 (자동 저장용)
  final ValueChanged<List<StrokeData>> onStrokesChanged;

  const MemoDrawingCanvas({
    super.key,
    required this.initialStrokes,
    required this.penColor,
    required this.penWidth,
    required this.isErasing,
    required this.onStrokesChanged,
  });

  @override
  State<MemoDrawingCanvas> createState() => MemoDrawingCanvasState();
}

class MemoDrawingCanvasState extends State<MemoDrawingCanvas> {
  /// 완성된 스트로크 목록
  late List<StrokeData> _strokes;

  /// 현재 그리는 중인 포인트 목록
  List<PointData> _currentPoints = [];

  @override
  void initState() {
    super.initState();
    _strokes = List.of(widget.initialStrokes);
  }

  /// 마지막 스트로크를 제거한다 (Undo 기능)
  void undoLastStroke() {
    if (_strokes.isEmpty) return;
    setState(() => _strokes = _strokes.sublist(0, _strokes.length - 1));
    widget.onStrokesChanged(_strokes);
  }

  /// 모든 스트로크를 제거한다 (Clear 기능)
  void clearAllStrokes() {
    if (_strokes.isEmpty) return;
    setState(() => _strokes = []);
    widget.onStrokesChanged(_strokes);
  }

  /// 터치/펜 시작 시 호출된다
  void _onPointerDown(PointerDownEvent event) {
    if (widget.isErasing) {
      _eraseAtPosition(event.localPosition);
      return;
    }
    // 새 스트로크 시작: 첫 포인트를 기록한다
    setState(() {
      _currentPoints = [
        PointData(
          x: event.localPosition.dx,
          y: event.localPosition.dy,
          pressure: event.pressure > 0 ? event.pressure : 0.5,
        ),
      ];
    });
  }

  /// 터치/펜 이동 시 호출된다
  void _onPointerMove(PointerMoveEvent event) {
    if (widget.isErasing) {
      _eraseAtPosition(event.localPosition);
      return;
    }
    if (_currentPoints.isEmpty) return;
    // 현재 스트로크에 포인트를 추가한다
    setState(() {
      _currentPoints = [
        ..._currentPoints,
        PointData(
          x: event.localPosition.dx,
          y: event.localPosition.dy,
          pressure: event.pressure > 0 ? event.pressure : 0.5,
        ),
      ];
    });
  }

  /// 터치/펜 끝 시 호출된다
  void _onPointerUp(PointerUpEvent event) {
    if (widget.isErasing || _currentPoints.isEmpty) return;

    // 현재 스트로크를 완성하여 목록에 추가한다
    final completedStroke = StrokeData(
      points: _currentPoints,
      colorValue: widget.penColor.toARGB32(),
      width: widget.penWidth,
    );

    setState(() {
      _strokes = [..._strokes, completedStroke];
      _currentPoints = [];
    });

    // 부모에게 변경을 알린다 (자동 저장 트리거)
    widget.onStrokesChanged(_strokes);
  }

  /// 지우개: 터치 위치 근처의 스트로크를 제거한다
  void _eraseAtPosition(Offset position) {
    const eraseRadius = 20.0;
    final eraseRadiusSq = eraseRadius * eraseRadius;

    final filtered = _strokes.where((stroke) {
      // 스트로크의 어떤 포인트라도 지우개 반경 안에 있으면 삭제한다
      return !stroke.points.any((p) {
        final dx = p.x - position.dx;
        final dy = p.y - position.dy;
        return (dx * dx + dy * dy) < eraseRadiusSq;
      });
    }).toList();

    if (filtered.length != _strokes.length) {
      setState(() => _strokes = filtered);
      widget.onStrokesChanged(_strokes);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 현재 그리는 중인 스트로크 데이터 (실시간 렌더링용)
    final activeStroke = _currentPoints.isNotEmpty
        ? StrokeData(
            points: _currentPoints,
            colorValue: widget.penColor.toARGB32(),
            width: widget.penWidth,
          )
        : null;

    return Listener(
      // Listener로 PointerEvent를 수신하여 필압을 포함한다
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      child: RepaintBoundary(
        child: CustomPaint(
          painter: MemoStrokePainter(
            strokes: _strokes,
            activeStroke: activeStroke,
          ),
          // 캔버스 전체 영역을 터치 가능하게 한다
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}
