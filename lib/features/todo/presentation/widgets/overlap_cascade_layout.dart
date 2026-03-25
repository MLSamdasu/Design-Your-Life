// 캐스케이드 레이아웃 계산 로직
// 겹침 그룹 내에서 Greedy 컬럼 할당으로 각 아이템의 위치를 결정한다.

import 'dart:math';

import '../../../../shared/models/todo.dart';
import '../../../../core/theme/layout_tokens.dart';
import 'overlap_layout_result.dart';

/// 투두의 시작/종료 시간을 분 단위로 변환하는 헬퍼
class TimeRange {
  final Todo todo;

  /// 시작 시간 (분 단위, 0~1439)
  final int startMinutes;

  /// 종료 시간 (분 단위, 0~1439)
  final int endMinutes;

  TimeRange({
    required this.todo,
    required this.startMinutes,
    required this.endMinutes,
  });
}

/// 겹침 그룹: 시간이 겹치는 투두들의 모음
class CollisionGroup {
  final List<TimeRange> items;

  /// 그룹의 최대 종료 시간 (분 단위)
  int maxEndMinutes;

  CollisionGroup(this.items, this.maxEndMinutes);
}

/// 캐스케이드 레이아웃 파라미터
class CascadeParams {
  /// 각 아이템의 너비 비율
  final double widthPerItem;

  /// 컬럼 간 좌측 오프셋 스텝
  final double offsetStep;

  const CascadeParams({
    required this.widthPerItem,
    required this.offsetStep,
  });
}

/// 겹침 수에 따른 캐스케이드 레이아웃 파라미터를 계산한다
///
/// | 겹침 수 | 너비 | 오프셋 스텝 |
/// |---------|------|------------|
/// | 1       | 100% | 0          |
/// | 2       | 75%  | 25%        |
/// | 3       | 65%  | 17.5%      |
/// | 4+      | 65%  | 첫 3개까지 |
CascadeParams calculateCascadeParams(int overlapCount) {
  switch (overlapCount) {
    case 0:
    case 1:
      return const CascadeParams(widthPerItem: 1.0, offsetStep: 0.0);
    case 2:
      return const CascadeParams(
        widthPerItem: EffectLayout.cascadeWidth2,
        offsetStep: EffectLayout.cascadeOffset2,
      );
    case 3:
      return const CascadeParams(
        widthPerItem: EffectLayout.cascadeWidth3Plus,
        offsetStep: EffectLayout.cascadeOffset3Plus,
      );
    default:
      // 4개 이상: 첫 3개는 캐스케이드, 나머지는 "+N" 뱃지로 처리
      return const CascadeParams(
        widthPerItem: EffectLayout.cascadeWidth3Plus,
        offsetStep: EffectLayout.cascadeOffset3Plus,
      );
  }
}

/// 겹침 그룹 내에서 캐스케이드 레이아웃 위치를 계산한다
/// Greedy 컬럼 할당 알고리즘을 사용한다
List<OverlapLayoutResult> layoutGroup(
  CollisionGroup group,
  double hourHeight,
  int startHour,
  double minBlockHeight,
) {
  final items = group.items;

  // Greedy 컬럼 할당: 각 아이템에 가능한 가장 왼쪽 컬럼을 할당한다
  // columnEndTimes[col]: 해당 컬럼에서 마지막 이벤트의 종료 시간(분)
  final columnEndTimes = <int>[];
  final columnAssignments = <int>[];

  for (final item in items) {
    var assignedCol = -1;
    for (var col = 0; col < columnEndTimes.length; col++) {
      if (columnEndTimes[col] <= item.startMinutes) {
        assignedCol = col;
        columnEndTimes[col] = item.endMinutes;
        break;
      }
    }
    if (assignedCol == -1) {
      assignedCol = columnEndTimes.length;
      columnEndTimes.add(item.endMinutes);
    }
    columnAssignments.add(assignedCol);
  }

  // 실제 동시 사용 컬럼 수
  final maxColumns = columnEndTimes.length;
  final effectiveParams = calculateCascadeParams(maxColumns);

  final results = <OverlapLayoutResult>[];
  for (var i = 0; i < items.length; i++) {
    final item = items[i];
    final col = columnAssignments[i];

    // Y 위치: (시작 분 - 타임라인 시작) * 분당 픽셀
    final minuteHeight = hourHeight / 60;
    final topOffset = (item.startMinutes - startHour * 60) * minuteHeight;

    // 높이: 지속 시간 * 분당 픽셀, 최소 minBlockHeight
    final durationMinutes = item.endMinutes - item.startMinutes;
    final blockHeight = max(durationMinutes * minuteHeight, minBlockHeight);

    // 캐스케이드 위치: 컬럼 인덱스에 따른 좌측 오프셋
    final leftFraction = col * effectiveParams.offsetStep;
    final widthFraction = effectiveParams.widthPerItem;

    results.add(OverlapLayoutResult(
      todo: item.todo,
      top: topOffset,
      height: blockHeight,
      leftFraction: leftFraction.clamp(0.0, 1.0 - widthFraction),
      widthFraction: widthFraction,
      overlapIndex: col,
      totalOverlaps: maxColumns,
    ));
  }

  return results;
}
