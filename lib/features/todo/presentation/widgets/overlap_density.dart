// 겹침 밀도 계산 로직
// 같은 시간대에 겹치는 이벤트 수를 시간 범위별로 산출한다.
// 배경 밀도 스트립 렌더링에 사용한다.

import 'dart:math';

import '../../../../core/theme/layout_tokens.dart';
import 'overlap_layout_result.dart';

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
    // startTime이 null인 항목은 밀도 계산에서 제외한다
    if (layout.todo.startTime == null) continue;
    final start = layout.todo.startTime!;
    final startMin = start.hour * 60 + start.minute;

    int endMin;
    if (layout.todo.endTime != null) {
      endMin = layout.todo.endTime!.hour * 60 + layout.todo.endTime!.minute;
      if (endMin <= startMin) endMin = AppLayout.hoursInDay * 60;
    } else {
      endMin = min(
        startMin + TimelineLayout.defaultDurationMinutes,
        AppLayout.hoursInDay * 60,
      );
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
