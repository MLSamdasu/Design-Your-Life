// F4 위젯: WeeklyTimetable - 주간 시간표 그리드
// 요일(가로) × 시간(세로) 축으로 활성 루틴 블록을 시각화한다.
// 축소: 7요일 전부 표시, 현재 시간 중앙 정렬
// 확대: 현재 요일 기준 확대, 좌우 스크롤로 다른 요일 확인 가능
import 'package:flutter/material.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../shared/models/routine.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';

/// 주간 시간표 그리드 (확대/축소 지원)
class WeeklyTimetable extends StatefulWidget {
  final List<Routine> routines;

  const WeeklyTimetable({required this.routines, super.key});

  @override
  State<WeeklyTimetable> createState() => _WeeklyTimetableState();
}

class _WeeklyTimetableState extends State<WeeklyTimetable> {
  static const int _sh = AppLayout.timetableStartHour;
  static const int _eh = AppLayout.timetableEndHour;
  static const double _timeLabelWidth = 28.0;

  // 확대 모드: 요일 열 폭이 넓어지고 좌우 스크롤 가능
  bool _isZoomed = false;

  // 확대 모드에서의 요일 열 너비
  static const double _zoomedColWidth = 120.0;
  // 확대 모드에서의 시간당 높이
  static const double _zoomedHourHeight = 56.0;
  // 축소 모드에서의 시간당 높이
  static const double _normalHourHeight = 44.0;

  late ScrollController _horizontalScrollController;

  @override
  void initState() {
    super.initState();
    _horizontalScrollController = ScrollController();
    // 확대 모드일 때 현재 요일로 가로 스크롤
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isZoomed) _scrollToCurrentDay();
    });
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  /// 확대 모드에서 현재 요일을 중앙으로 가로 스크롤
  void _scrollToCurrentDay() {
    if (!_horizontalScrollController.hasClients) return;
    final todayIdx = DateTime.now().weekday - 1;
    final viewportWidth = _horizontalScrollController.position.viewportDimension;
    final targetOffset = (todayIdx * _zoomedColWidth - viewportWidth / 2 + _zoomedColWidth / 2 + _timeLabelWidth)
        .clamp(0.0, _horizontalScrollController.position.maxScrollExtent);
    _horizontalScrollController.jumpTo(targetOffset);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        // 축소 모드: 시간 레이블 뺀 나머지를 7등분
        final normalColWidth = (availableWidth - _timeLabelWidth) / 7;
        final colWidth = _isZoomed ? _zoomedColWidth : normalColWidth;
        final hh = _isZoomed ? _zoomedHourHeight : _normalHourHeight;
        final gridHeight = (_eh - _sh) * hh;
        final totalWidth = _timeLabelWidth + 7 * colWidth;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 상단: 확대/축소 토글 버튼
            _ZoomToggle(
              isZoomed: _isZoomed,
              onToggle: () {
                setState(() => _isZoomed = !_isZoomed);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_isZoomed) _scrollToCurrentDay();
                });
              },
            ),
            const SizedBox(height: AppSpacing.md),

            // 확대 모드: 헤더+바디를 하나의 가로 스크롤로 묶는다
            // 세로 스크롤은 부모 SingleChildScrollView가 담당하므로 내부에서는 제거
            if (_isZoomed) ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                controller: _horizontalScrollController,
                child: SizedBox(
                  width: totalWidth,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _DayHeader(labelWidth: _timeLabelWidth, colWidth: colWidth),
                      const SizedBox(height: AppSpacing.xs),
                      SizedBox(
                        height: gridHeight,
                        child: _buildGrid(colWidth, hh, isZoomed: true),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // 축소 모드: 가로 꽉 채움, 전체 시간대를 펼쳐서 보여준다
              _DayHeader(labelWidth: _timeLabelWidth, colWidth: colWidth),
              const SizedBox(height: AppSpacing.xs),
              SizedBox(
                height: gridHeight,
                child: _buildGrid(colWidth, hh, isZoomed: false),
              ),
            ],
          ],
        );
      },
    );
  }

  /// 그리드 본체 (시간 축 + 7 요일 열)
  Widget _buildGrid(double colWidth, double hh, {required bool isZoomed}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TimeAxis(startHour: _sh, endHour: _eh, hh: hh, width: _timeLabelWidth),
        ...List.generate(7, (i) {
          final day = i + 1;
          final dayCol = _DayCol(
            routines: widget.routines.where((r) => r.repeatDays.contains(day)).toList(),
            startHour: _sh,
            hh: hh,
            isZoomed: isZoomed,
          );
          // 축소 모드: Expanded로 균등 분배, 확대 모드: 고정 너비
          return isZoomed
              ? SizedBox(width: colWidth, child: dayCol)
              : Expanded(child: dayCol);
        }),
      ],
    );
  }
}

/// 확대/축소 토글 버튼
class _ZoomToggle extends StatelessWidget {
  final bool isZoomed;
  final VoidCallback onToggle;
  const _ZoomToggle({required this.isZoomed, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: onToggle,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            color: context.themeColors.accentWithAlpha(isZoomed ? 0.5 : 0.25),
            borderRadius: BorderRadius.circular(AppRadius.huge),
            border: Border.all(color: context.themeColors.accentWithAlpha(0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isZoomed ? Icons.zoom_out_rounded : Icons.zoom_in_rounded,
                size: AppLayout.iconSm,
                color: context.themeColors.textPrimary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                isZoomed ? '축소' : '확대',
                style: AppTypography.captionLg.copyWith(color: context.themeColors.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 요일 헤더 행 (오늘 강조)
class _DayHeader extends StatelessWidget {
  final double labelWidth;
  final double colWidth;
  const _DayHeader({required this.labelWidth, required this.colWidth});

  @override
  Widget build(BuildContext context) {
    const days = ['월', '화', '수', '목', '금', '토', '일'];
    final todayIdx = DateTime.now().weekday - 1;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(width: labelWidth),
        ...List.generate(7, (i) {
          final isToday = i == todayIdx;
          return SizedBox(
            width: colWidth,
            child: Center(
              child: Container(
                width: 28,
                height: 28,
                // 오늘 날짜 표시 원
                decoration: isToday
                    ? BoxDecoration(
                        color: context.themeColors.accentWithAlpha(0.7),
                        shape: BoxShape.circle)
                    : null,
                child: Center(
                  child: Text(
                    days[i],
                    style: AppTypography.bodyMd.copyWith(
                      color: isToday
                          ? context.themeColors.textPrimary
                          : i >= 5
                              ? context.themeColors.textPrimaryWithAlpha(0.5)
                              : context.themeColors.textPrimaryWithAlpha(0.7),
                      fontWeight: isToday ? AppTypography.weightBold : AppTypography.weightMedium,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

/// 시간 레이블 열
class _TimeAxis extends StatelessWidget {
  final int startHour;
  final int endHour;
  final double hh;
  final double width;
  const _TimeAxis({
    required this.startHour,
    required this.endHour,
    required this.hh,
    required this.width,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        child: Stack(
          children: List.generate(
            endHour - startHour,
            (i) => Positioned(
              top: i * hh - 6,
              left: 0,
              width: width,
              child: Text(
                '${startHour + i}',
                style: AppTypography.captionSm.copyWith(
                  color: context.themeColors.textPrimaryWithAlpha(0.5),
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ),
        ),
      );
}

// ─── 겹침 레이아웃 알고리즘 ─────────────────────────────────────────────
// Google Calendar 스타일: Union-Find 그룹화 → Sweep Line 최대 동시 수 →
// 탐욕 열 배정. 같은 겹침 그룹의 루틴은 동일한 totalCols를 공유한다.

/// 분 단위로 변환된 루틴 시간 슬롯
class _TimeSlot {
  final String id;
  final int start;
  final int end;
  const _TimeSlot(this.id, this.start, this.end);
}

/// 겹치는 루틴의 수평 배치 정보 (열 인덱스, 그룹 내 총 열 수)
class _OverlapInfo {
  final int colIndex;
  final int totalCols;
  const _OverlapInfo(this.colIndex, this.totalCols);
}

/// 단일 요일 열 (그리드 라인 + 루틴 블록)
class _DayCol extends StatelessWidget {
  final List<Routine> routines;
  final int startHour;
  final double hh;
  final bool isZoomed;
  /// 겹침 표시 최대 열 수
  static const int _maxCols = 3;

  const _DayCol({
    required this.routines,
    required this.startHour,
    required this.hh,
    required this.isZoomed,
  });

  /// 겹치는 루틴의 수평 배치를 계산한다 (최대 3열)
  ///
  /// 알고리즘 흐름:
  /// 1. 시작 시간 기준 정렬 + 분 단위 변환
  /// 2. Union-Find로 직접/간접 겹침을 하나의 그룹으로 묶는다
  /// 3. 그룹별 Sweep Line으로 최대 동시 겹침 수를 산출한다
  /// 4. 그룹 내 탐욕 열 배정: 가장 일찍 비는 열 우선, 동점이면 낮은 인덱스 우선
  /// 5. 같은 그룹의 루틴은 동일한 totalCols를 공유하여 너비 일관성을 보장한다
  static Map<String, _OverlapInfo> _computeOverlapLayout(
    List<Routine> routines,
  ) {
    if (routines.isEmpty) return {};
    // 단일 루틴은 계산 없이 즉시 반환
    if (routines.length == 1) {
      return {routines.first.id: const _OverlapInfo(0, 1)};
    }

    // ── 1단계: 분 단위 변환 + 시작 시간 기준 정렬 ──
    final slots = routines.map((r) {
      final s = r.startTime.hour * 60 + r.startTime.minute;
      final rawE = r.endTime.hour * 60 + r.endTime.minute;
      // 종료가 시작 이하면(자정 걸침 등) 최소 15분 보정
      final e = rawE > s ? rawE : s + 15;
      return _TimeSlot(r.id, s, e);
    }).toList()
      ..sort((a, b) {
        final cmp = a.start.compareTo(b.start);
        return cmp != 0 ? cmp : a.end.compareTo(b.end);
      });

    // ── 2단계: Union-Find로 겹침 그룹 구축 ──
    // 직접 겹치지 않아도 중간 루틴을 통해 연결되면 같은 그룹이다
    // 예: A(7-8)↔B(7:30-9)↔C(8:30-10) → A,B,C 모두 한 그룹
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

    // 정렬된 상태에서 O(n²) 겹침 검사 (루틴 수 최대 수십 개이므로 충분)
    // j.start >= i.end이면 이후 모든 k(>j)도 k.start >= i.end이므로 break
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
    final groups = <String, List<_TimeSlot>>{};
    for (final s in slots) {
      groups.putIfAbsent(find(s.id), () => []).add(s);
    }

    // ── 3단계: 그룹별 Sweep Line → 최대 동시 겹침 수 ──
    // 4단계: 그룹 내 탐욕 열 배정
    final result = <String, _OverlapInfo>{};

    for (final group in groups.values) {
      if (group.length == 1) {
        // 단독 루틴: 전체 너비 사용
        result[group.first.id] = const _OverlapInfo(0, 1);
        continue;
      }

      // Sweep Line: 시작/종료 이벤트를 시간순 정렬하여 최대 동시 수 산출
      // 같은 시간에 종료+시작이 겹치면 종료를 먼저 처리 (연속 루틴은 겹침 아님)
      final events = <({int time, bool isStart})>[];
      for (final s in group) {
        events.add((time: s.start, isStart: true));
        events.add((time: s.end, isStart: false));
      }
      events.sort((a, b) {
        final cmp = a.time.compareTo(b.time);
        if (cmp != 0) return cmp;
        // 같은 시간: 종료(-1) → 시작(+1) 순서로 처리
        return a.isStart ? 1 : -1;
      });

      int maxConcurrent = 0;
      int current = 0;
      for (final ev in events) {
        current += ev.isStart ? 1 : -1;
        if (current > maxConcurrent) maxConcurrent = current;
      }
      final totalCols = maxConcurrent.clamp(1, _maxCols);

      // 탐욕 열 배정: 각 열의 종료 시간을 추적, 가장 일찍 비는 열 우선
      final colEndTimes = List.filled(totalCols, 0);
      for (final slot in group) {
        int bestCol = 0;
        bool foundFree = false;
        for (int c = 0; c < totalCols; c++) {
          // 이미 비어있는 열 (종료 시간 ≤ 시작 시간)
          if (colEndTimes[c] <= slot.start) {
            bestCol = c;
            foundFree = true;
            break;
          }
        }
        if (!foundFree) {
          // 모든 열이 사용 중이면 가장 먼저 끝나는 열에 배치
          for (int c = 1; c < totalCols; c++) {
            if (colEndTimes[c] < colEndTimes[bestCol]) bestCol = c;
          }
        }
        colEndTimes[bestCol] = slot.end;
        result[slot.id] = _OverlapInfo(bestCol, totalCols);
      }
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final overlapLayout = _computeOverlapLayout(routines);

    return LayoutBuilder(
      builder: (context, constraints) {
        final colWidth = constraints.maxWidth;
        return Stack(
          children: [
            // 그리드 라인
            ...List.generate(
              AppLayout.timetableEndHour - AppLayout.timetableStartHour,
              (i) => Positioned(
                top: i * hh,
                left: 1,
                right: 1,
                child: Container(
                  height: AppLayout.dividerHeight,
                  color: context.themeColors.textPrimaryWithAlpha(0.10),
                ),
              ),
            ),
            // 루틴 블록 (겹치면 나란히 배치, 최대 3개)
            ...routines.map((r) {
              final info = overlapLayout[r.id] ?? const _OverlapInfo(0, 1);
              final slotWidth = colWidth / info.totalCols;
              final blockLeft = info.colIndex * slotWidth + 1;
              final blockWidth = (slotWidth - 2).clamp(8.0, colWidth);
              return _Block(
                routine: r,
                startHour: startHour,
                hh: hh,
                isZoomed: isZoomed,
                blockLeft: blockLeft,
                blockWidth: blockWidth,
              );
            }),
          ],
        );
      },
    );
  }
}

/// 루틴 블록 (시간표 내 배치 단위)
/// blockLeft/blockWidth로 겹치는 루틴을 나란히 배치한다
class _Block extends StatelessWidget {
  final Routine routine;
  final int startHour;
  final double hh;
  final bool isZoomed;
  final double blockLeft;
  final double blockWidth;
  const _Block({
    required this.routine,
    required this.startHour,
    required this.hh,
    required this.isZoomed,
    required this.blockLeft,
    required this.blockWidth,
  });

  /// 배경색 밝기에 따라 대비가 높은 텍스트 색상을 반환한다
  /// WCAG 기준: 밝은 배경 → 어두운 텍스트, 어두운 배경 → 흰색 텍스트
  static Color _contrastTextColor(Color bgColor) {
    // 상대 휘도 계산 (W3C 공식)
    final luminance = bgColor.computeLuminance();
    // 임계값 0.4: 밝은 이벤트 색상(노랑, 연두 등)에서 어두운 텍스트로 전환
    return luminance > 0.4
        ? ColorTokens.gray900 // 어두운 남색 대체 (밝은 배경용)
        : ColorTokens.white; // 흰색 (어두운 배경용)
  }

  @override
  Widget build(BuildContext context) {
    final sm = routine.startTime.hour * 60 + routine.startTime.minute;
    final em = routine.endTime.hour * 60 + routine.endTime.minute;
    final dur = (em - sm).clamp(15, 1440).toDouble();
    final top = (sm - startHour * 60) / 60 * hh;
    final h = dur / 60 * hh;
    if (top + h <= 0) return const SizedBox.shrink();

    final color = ColorTokens.eventColor(routine.colorIndex);
    // 블록 배경색 기준 대비 텍스트 색상 — 밝은 이벤트 색상에서도 가독성 보장
    final textColor = _contrastTextColor(color);
    return Positioned(
      top: top.clamp(0.0, double.infinity),
      left: blockLeft,
      width: blockWidth,
      height: h.clamp(12.0, double.infinity),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.80),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 루틴 이름 — 배경 밝기 기반 대비 텍스트 색상 (6개 테마 전부 대응)
              Text(
                routine.name,
                style: (isZoomed ? AppTypography.bodyMd : AppTypography.captionSm).copyWith(
                  color: textColor,
                  fontWeight: AppTypography.weightSemiBold,
                  height: 1.2,
                ),
                maxLines: isZoomed ? 2 : 1,
                overflow: TextOverflow.ellipsis,
              ),
              // 확대 모드: 시간 정보도 표시 — 약간 투명도를 낮춰 보조 텍스트 역할
              if (isZoomed && h > 30) ...[
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '${routine.startTime.hour.toString().padLeft(2, '0')}:${routine.startTime.minute.toString().padLeft(2, '0')}'
                  ' ~ '
                  '${routine.endTime.hour.toString().padLeft(2, '0')}:${routine.endTime.minute.toString().padLeft(2, '0')}',
                  style: AppTypography.captionSm.copyWith(
                    color: textColor.withValues(alpha: 0.85),
                    height: 1.2,
                  ),
                  maxLines: 1,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
