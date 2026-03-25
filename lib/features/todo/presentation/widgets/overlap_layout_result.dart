// 타임라인 겹침 레이아웃 계산 결과 모델
// 각 투두의 화면 상 위치와 크기를 표현한다.

import '../../../../shared/models/todo.dart';

/// 타임라인 겹침 레이아웃 계산 결과
/// 각 투두의 화면 상 위치와 크기를 나타낸다
class OverlapLayoutResult {
  /// 대상 투두 아이템
  final Todo todo;

  /// 타임라인 상 Y 위치 (픽셀)
  final double top;

  /// 블록 높이 (픽셀, 시간 비례)
  final double height;

  /// 좌측 오프셋 비율 (0.0~1.0)
  final double leftFraction;

  /// 너비 비율 (0.0~1.0)
  final double widthFraction;

  /// 겹침 그룹 내 순서 (0부터)
  final int overlapIndex;

  /// 해당 그룹의 총 겹침 수
  final int totalOverlaps;

  const OverlapLayoutResult({
    required this.todo,
    required this.top,
    required this.height,
    required this.leftFraction,
    required this.widthFraction,
    required this.overlapIndex,
    required this.totalOverlaps,
  });
}
