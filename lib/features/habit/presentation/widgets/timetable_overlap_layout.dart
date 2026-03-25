// F4 유틸: 겹침 레이아웃 알고리즘 (Google Calendar 스타일)
// Union-Find 그룹화 -> Sweep Line 최대 동시 수 -> 탐욕 열 배정
// 같은 겹침 그룹의 루틴은 동일한 totalCols를 공유한다.
import '../../../../shared/models/routine.dart';

/// 분 단위로 변환된 루틴 시간 슬롯
class TimeSlot {
  final String id;
  final int start;
  final int end;
  const TimeSlot(this.id, this.start, this.end);
}

/// 겹치는 루틴의 수평 배치 정보 (열 인덱스, 그룹 내 총 열 수)
class OverlapInfo {
  final int colIndex;
  final int totalCols;
  const OverlapInfo(this.colIndex, this.totalCols);
}

/// 겹치는 루틴의 수평 배치를 계산한다 (최대 [maxCols]열)
///
/// 알고리즘 흐름:
/// 1. 시작 시간 기준 정렬 + 분 단위 변환
/// 2. Union-Find로 직접/간접 겹침을 하나의 그룹으로 묶는다
/// 3. 그룹별 Sweep Line으로 최대 동시 겹침 수를 산출한다
/// 4. 그룹 내 탐욕 열 배정: 가장 일찍 비는 열 우선
/// 5. 같은 그룹의 루틴은 동일한 totalCols를 공유
Map<String, OverlapInfo> computeOverlapLayout(
  List<Routine> routines, {
  int maxCols = 3,
}) {
  if (routines.isEmpty) return {};
  // 단일 루틴은 계산 없이 즉시 반환
  if (routines.length == 1) {
    return {routines.first.id: const OverlapInfo(0, 1)};
  }

  // ── 1단계: 분 단위 변환 + 시작 시간 기준 정렬 ──
  final slots = routines.map((r) {
    final s = r.startTime.hour * 60 + r.startTime.minute;
    final rawE = r.endTime.hour * 60 + r.endTime.minute;
    // 종료가 시작 이하면(자정 걸침 등) 최소 15분 보정
    final e = rawE > s ? rawE : s + 15;
    return TimeSlot(r.id, s, e);
  }).toList()
    ..sort((a, b) {
      final cmp = a.start.compareTo(b.start);
      return cmp != 0 ? cmp : a.end.compareTo(b.end);
    });

  // ── 2단계: Union-Find로 겹침 그룹 구축 ──
  final parent = <String, String>{};
  final rank = <String, int>{};
  for (final s in slots) {
    parent[s.id] = s.id;
    rank[s.id] = 0;
  }

  String find(String x) {
    // 경로 압축 (path compression)
    while (parent[x] != x) {
      parent[x] = parent[parent[x]!]!;
      x = parent[x]!;
    }
    return x;
  }

  void union(String a, String b) {
    final ra = find(a), rb = find(b);
    if (ra == rb) return;
    // 랭크 기반 합치기 (union by rank)
    if (rank[ra]! < rank[rb]!) {
      parent[ra] = rb;
    } else if (rank[ra]! > rank[rb]!) {
      parent[rb] = ra;
    } else {
      parent[rb] = ra;
      rank[ra] = rank[ra]! + 1;
    }
  }

  // 정렬된 상태에서 겹침 검사
  for (int i = 0; i < slots.length; i++) {
    for (int j = i + 1; j < slots.length; j++) {
      if (slots[j].start < slots[i].end) {
        union(slots[i].id, slots[j].id);
      } else {
        break;
      }
    }
  }

  // 그룹별 분류
  final groups = <String, List<TimeSlot>>{};
  for (final s in slots) {
    groups.putIfAbsent(find(s.id), () => []).add(s);
  }

  // ── 3단계: Sweep Line + 탐욕 열 배정 ──
  final result = <String, OverlapInfo>{};

  for (final group in groups.values) {
    if (group.length == 1) {
      result[group.first.id] = const OverlapInfo(0, 1);
      continue;
    }

    // Sweep Line: 최대 동시 수 산출
    final events = <({int time, bool isStart})>[];
    for (final s in group) {
      events.add((time: s.start, isStart: true));
      events.add((time: s.end, isStart: false));
    }
    events.sort((a, b) {
      final cmp = a.time.compareTo(b.time);
      if (cmp != 0) return cmp;
      return a.isStart ? 1 : -1;
    });

    int maxConcurrent = 0, current = 0;
    for (final ev in events) {
      current += ev.isStart ? 1 : -1;
      if (current > maxConcurrent) maxConcurrent = current;
    }
    final totalCols = maxConcurrent.clamp(1, maxCols);

    // 탐욕 열 배정: 각 열의 종료 시간을 추적, 가장 일찍 비는 열 우선
    final colEndTimes = List.filled(totalCols, 0);
    for (final slot in group) {
      int bestCol = 0;
      bool foundFree = false;
      for (int c = 0; c < totalCols; c++) {
        if (colEndTimes[c] <= slot.start) {
          bestCol = c;
          foundFree = true;
          break;
        }
      }
      if (!foundFree) {
        for (int c = 1; c < totalCols; c++) {
          if (colEndTimes[c] < colEndTimes[bestCol]) bestCol = c;
        }
      }
      colEndTimes[bestCol] = slot.end;
      result[slot.id] = OverlapInfo(bestCol, totalCols);
    }
  }

  return result;
}
