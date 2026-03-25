// F-Memo: 드로잉 캔버스 본체 빌더
// MemoDrawingCanvas를 메모 데이터와 연결하여 구성한다.
// 모바일/데스크탑 에디터에서 공통으로 사용한다.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/memo.dart';
import '../../models/stroke_data.dart';
import '../../models/stroke_serializer.dart';
import '../../providers/memo_provider.dart';
import 'memo_drawing_canvas.dart';
import 'memo_drawing_tools.dart';

/// 드로잉 스트로크 자동 저장 디바운스 (ms)
const kStrokeDebounceMs = 500;

/// 드로잉 캔버스 위젯을 메모 데이터로 초기화하여 반환한다
Widget buildMemoDrawingCanvas({
  required GlobalKey<MemoDrawingCanvasState> canvasKey,
  required Memo memo,
  required int colorIndex,
  required int thicknessIndex,
  required bool isEraser,
  required void Function(Memo, List<StrokeData>) onStrokesChanged,
}) {
  final initialStrokes = StrokeSerializer.decode(memo.strokesJson);
  final penColor = kPenColors[colorIndex];
  final penWidth = kPenThicknesses[thicknessIndex];

  return MemoDrawingCanvas(
    key: canvasKey,
    initialStrokes: initialStrokes,
    penColor: penColor,
    penWidth: penWidth,
    isErasing: isEraser,
    onStrokesChanged: (strokes) => onStrokesChanged(memo, strokes),
  );
}

/// 드로잉 스트로크 변경 → 디바운스 후 Hive 저장
/// 반환값: 새로운 디바운스 타이머 (호출 측에서 관리)
Timer scheduleStrokeSave({
  required Timer? currentTimer,
  required Memo memo,
  required List<StrokeData> strokes,
  required WidgetRef ref,
}) {
  currentTimer?.cancel();
  return Timer(
    const Duration(milliseconds: kStrokeDebounceMs),
    () {
      final json = StrokeSerializer.encode(strokes);
      final update = ref.read(updateMemoProvider);
      update(
        memo.id,
        memo.copyWith(strokesJson: json, updatedAt: DateTime.now()),
      );
    },
  );
}
