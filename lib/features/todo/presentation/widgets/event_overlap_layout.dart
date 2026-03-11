// F3 위젯: 타임라인 겹침 레이아웃 계산 순수 함수
// 투두 아이템들의 시간 겹침을 감지하고 캐스케이드 레이아웃 위치를 계산한다.
// 순수 함수만 포함하며, UI 의존성이 없다.
import 'dart:math';

import '../../../../shared/models/todo.dart';
import '../../../../core/theme/layout_tokens.dart';

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

/// 투두의 시작/종료 시간을 분 단위로 변환하는 헬퍼
class _TimeRange {
  final Todo todo;

  /// 시작 시간 (분 단위, 0~1439)
  final int startMinutes;

  /// 종료 시간 (분 단위, 0~1439)
  final int endMinutes;

  _TimeRange({
    required this.todo,
    required this.startMinutes,
    required this.endMinutes,
  });
}

/// 겹침 그룹: 시간이 겹치는 투두들의 모음
class _CollisionGroup {
  final List<_TimeRange> items;

  /// 그룹의 최대 종료 시간 (분 단위)
  int maxEndMinutes;

  _CollisionGroup(this.items, this.maxEndMinutes);
}

/// 타임라인 겹침 레이아웃을 계산한다
/// 시간이 지정된 투두만 입력으로 받는다 (startTime != null)
///
/// [todos]: 시간이 지정된 투두 목록
/// [hourHeight]: 1시간당 픽셀 높이 (기본 60px)
/// [startHour]: 타임라인 시작 시간 (기본 0시)
/// [minBlockHeight]: 최소 블록 높이 (기본 24px)
List<OverlapLayoutResult> calculateOverlapLayout(
  List<Todo> todos, {
  double hourHeight = 60.0,
  int startHour = 0,
  double minBlockHeight = 24.0,
}) {
  // 시간이 없는 투두는 필터링한다
  final timedTodos = todos.where((t) => t.startTime != null).toList();
  if (timedTodos.isEmpty) return [];

  // 1. 시간 범위 객체로 변환한다
  final timeRanges = _convertToTimeRanges(timedTodos);

  // 2. 시작 시간 기준으로 정렬한다 (같으면 긴 이벤트 우선)
  timeRanges.sort((a, b) {
    final startDiff = a.startMinutes.compareTo(b.startMinutes);
    if (startDiff != 0) return startDiff;
    // 시작이 같으면 종료가 늦은(긴) 이벤트를 먼저 배치한다
    return b.endMinutes.compareTo(a.endMinutes);
  });

  // 3. 겹침 그룹으로 분류한다
  final groups = _buildCollisionGroups(timeRanges);

  // 4. 각 그룹 내에서 레이아웃 위치를 계산한다
  final results = <OverlapLayoutResult>[];
  for (final group in groups) {
    results.addAll(_layoutGroup(group, hourHeight, startHour, minBlockHeight));
  }

  return results;
}

/// 투두를 시간 범위 객체로 변환한다
/// endTime이 없으면 기본 30분 지속으로 처리한다
List<_TimeRange> _convertToTimeRanges(List<Todo> todos) {
  return todos.map((todo) {
    final start = todo.startTime!;
    final startMin = start.hour * 60 + start.minute;

    int endMin;
    if (todo.endTime != null) {
      endMin = todo.endTime!.hour * 60 + todo.endTime!.minute;
      // 종료가 시작보다 이르면 (예: 23:30~00:30) 다음날까지로 처리한다
      if (endMin <= startMin) {
        endMin = AppLayout.hoursInDay * 60; // 자정까지로 제한한다
      }
    } else {
      // endTime 미설정 시 기본 30분 지속
      endMin = min(startMin + 30, AppLayout.hoursInDay * 60);
    }

    return _TimeRange(
      todo: todo,
      startMinutes: startMin,
      endMinutes: endMin,
    );
  }).toList();
}

/// 시간이 겹치는 투두들을 그룹으로 묶는다
/// 이벤트 B의 시작이 이벤트 A의 종료 전이면 같은 그룹이다
List<_CollisionGroup> _buildCollisionGroups(List<_TimeRange> sorted) {
  final groups = <_CollisionGroup>[];
  if (sorted.isEmpty) return groups;

  var currentGroup = _CollisionGroup([sorted.first], sorted.first.endMinutes);

  for (var i = 1; i < sorted.length; i++) {
    final item = sorted[i];
    // 현재 아이템의 시작이 그룹의 최대 종료 전이면 겹침이다
    if (item.startMinutes < currentGroup.maxEndMinutes) {
      currentGroup.items.add(item);
      currentGroup.maxEndMinutes =
          max(currentGroup.maxEndMinutes, item.endMinutes);
    } else {
      // 새 그룹 시작
      groups.add(currentGroup);
      currentGroup = _CollisionGroup([item], item.endMinutes);
    }
  }
  groups.add(currentGroup);

  return groups;
}

/// 겹침 그룹 내에서 캐스케이드 레이아웃 위치를 계산한다
/// Greedy 컬럼 할당 알고리즘을 사용한다
List<OverlapLayoutResult> _layoutGroup(
  _CollisionGroup group,
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
  final effectiveParams = _calculateCascadeParams(maxColumns);

  final results = <OverlapLayoutResult>[];
  for (var i = 0; i < items.length; i++) {
    final item = items[i];
    final col = columnAssignments[i];

    // Y 위치: (시작 분 - 타임라인 시작) * 분당 픽셀
    final minuteHeight = hourHeight / 60.0;
    final topOffset =
        (item.startMinutes - startHour * 60) * minuteHeight;

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

/// 캐스케이드 레이아웃 파라미터
class _CascadeParams {
  /// 각 아이템의 너비 비율
  final double widthPerItem;

  /// 컬럼 간 좌측 오프셋 스텝
  final double offsetStep;

  const _CascadeParams({
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
_CascadeParams _calculateCascadeParams(int overlapCount) {
  switch (overlapCount) {
    case 0:
    case 1:
      return const _CascadeParams(widthPerItem: 1.0, offsetStep: 0.0);
    case 2:
      return const _CascadeParams(widthPerItem: 0.75, offsetStep: 0.25);
    case 3:
      return const _CascadeParams(widthPerItem: 0.65, offsetStep: 0.175);
    default:
      // 4개 이상: 첫 3개는 65% 캐스케이드, 나머지는 "+N" 뱃지로 처리
      return const _CascadeParams(widthPerItem: 0.65, offsetStep: 0.175);
  }
}

/// 겹침 밀도(같은 시간대 겹침 수)를 시간 범위별로 계산한다
/// 배경 밀도 스트립 렌더링에 사용한다
///
/// 반환값: [(startMinutes, endMinutes, overlapCount), ...]
List<({int startMinutes, int endMinutes, int count})> calculateDensityRanges(
  List<OverlapLayoutResult> layouts,
) {
  if (layouts.isEmpty) return [];

  // 이벤트 시작/종료 지점을 수집한다
  final events = <({int minute, bool isStart})>[];
  for (final layout in layouts) {
    final start = layout.todo.startTime!;
    final startMin = start.hour * 60 + start.minute;

    int endMin;
    if (layout.todo.endTime != null) {
      endMin = layout.todo.endTime!.hour * 60 + layout.todo.endTime!.minute;
      if (endMin <= startMin) endMin = AppLayout.hoursInDay * 60;
    } else {
      endMin = min(startMin + 30, AppLayout.hoursInDay * 60);
    }

    events.add((minute: startMin, isStart: true));
    events.add((minute: endMin, isStart: false));
  }

  // 시간순 정렬 (같은 시간이면 종료를 먼저)
  events.sort((a, b) {
    final diff = a.minute.compareTo(b.minute);
    if (diff != 0) return diff;
    // 종료를 먼저 처리하여 겹침 수가 과대 계산되지 않게 한다
    return a.isStart ? 1 : -1;
  });

  final ranges = <({int startMinutes, int endMinutes, int count})>[];
  var currentCount = 0;
  var prevMinute = 0;

  for (final event in events) {
    if (currentCount > 0 && event.minute > prevMinute) {
      ranges.add((
        startMinutes: prevMinute,
        endMinutes: event.minute,
        count: currentCount,
      ));
    }
    currentCount += event.isStart ? 1 : -1;
    prevMinute = event.minute;
  }

  // 겹침 수가 2 이상인 범위만 반환한다 (밀도 표시 대상)
  return ranges.where((r) => r.count >= 2).toList();
}
