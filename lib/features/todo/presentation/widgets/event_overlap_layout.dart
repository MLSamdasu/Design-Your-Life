// F3 위젯: 타임라인 겹침 레이아웃 계산 순수 함수
// 투두 아이템들의 시간 겹침을 감지하고 캐스케이드 레이아웃 위치를 계산한다.
// 순수 함수만 포함하며, UI 의존성이 없다.
import 'dart:math';

import '../../../../shared/models/todo.dart';
import '../../../../core/theme/layout_tokens.dart';
import 'overlap_layout_result.dart';
import 'overlap_cascade_layout.dart';

// 분리된 모듈을 재공개(re-export)하여 기존 import를 유지한다
export 'overlap_layout_result.dart';
export 'overlap_cascade_layout.dart';
export 'overlap_density.dart';

/// 타임라인 겹침 레이아웃을 계산한다
/// 시간이 지정된 투두만 입력으로 받는다 (startTime != null)
///
/// [todos]: 시간이 지정된 투두 목록
/// [hourHeight]: 1시간당 픽셀 높이 (기본 60px)
/// [startHour]: 타임라인 시작 시간 (기본 0시)
/// [minBlockHeight]: 최소 블록 높이 (기본 24px)
List<OverlapLayoutResult> calculateOverlapLayout(
  List<Todo> todos, {
  double hourHeight = TimelineLayout.timelineHourHeight,
  int startHour = 0,
  double minBlockHeight = TimelineLayout.timelineMinBlockHeight,
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
    results.addAll(layoutGroup(group, hourHeight, startHour, minBlockHeight));
  }

  return results;
}

/// 투두를 시간 범위 객체로 변환한다
/// endTime이 없으면 기본 30분 지속으로 처리한다
/// startTime이 null인 투두는 필터링하여 제외한다
List<TimeRange> _convertToTimeRanges(List<Todo> todos) {
  return todos.where((todo) => todo.startTime != null).map((todo) {
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
      // endTime 미설정 시 기본 지속 시간 적용
      endMin = min(
        startMin + TimelineLayout.defaultDurationMinutes,
        AppLayout.hoursInDay * 60,
      );
    }

    return TimeRange(
      todo: todo,
      startMinutes: startMin,
      endMinutes: endMin,
    );
  }).toList();
}

/// 시간이 겹치는 투두들을 그룹으로 묶는다
/// 이벤트 B의 시작이 이벤트 A의 종료 전이면 같은 그룹이다
List<CollisionGroup> _buildCollisionGroups(List<TimeRange> sorted) {
  final groups = <CollisionGroup>[];
  if (sorted.isEmpty) return groups;

  var currentGroup = CollisionGroup([sorted.first], sorted.first.endMinutes);

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
      currentGroup = CollisionGroup([item], item.endMinutes);
    }
  }
  groups.add(currentGroup);

  return groups;
}
