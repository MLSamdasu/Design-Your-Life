// F4 위젯: WeeklyTimetable - 주간 시간표 그리드
// 요일(가로) x 시간(세로) 축으로 활성 루틴 블록을 시각화한다.
// 축소: 7요일 전부 표시, 현재 시간 중앙 정렬
// 확대: 현재 요일 기준 확대, 좌우 스크롤로 다른 요일 확인 가능
import 'package:flutter/material.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../shared/models/routine.dart';
import 'timetable_zoom_toggle.dart';
import 'timetable_day_header.dart';
import 'timetable_time_axis.dart';
import 'timetable_day_col.dart';

/// 주간 시간표 그리드 (확대/축소 지원)
class WeeklyTimetable extends StatefulWidget {
  final List<Routine> routines;

  const WeeklyTimetable({required this.routines, super.key});

  @override
  State<WeeklyTimetable> createState() => _WeeklyTimetableState();
}

class _WeeklyTimetableState extends State<WeeklyTimetable> {
  static const int _sh = TimelineLayout.timetableStartHour;
  static const int _eh = TimelineLayout.timetableEndHour;
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
    final viewportWidth =
        _horizontalScrollController.position.viewportDimension;
    final targetOffset = (todayIdx * _zoomedColWidth -
            viewportWidth / 2 +
            _zoomedColWidth / 2 +
            _timeLabelWidth)
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
            TimetableZoomToggle(
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
            if (_isZoomed) ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                controller: _horizontalScrollController,
                child: SizedBox(
                  width: totalWidth,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TimetableDayHeader(
                        labelWidth: _timeLabelWidth,
                        colWidth: colWidth,
                      ),
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
              TimetableDayHeader(
                labelWidth: _timeLabelWidth,
                colWidth: colWidth,
              ),
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
        TimetableTimeAxis(
          startHour: _sh,
          endHour: _eh,
          hh: hh,
          width: _timeLabelWidth,
        ),
        ...List.generate(7, (i) {
          final day = i + 1;
          final dayCol = TimetableDayCol(
            routines:
                widget.routines.where((r) => r.repeatDays.contains(day)).toList(),
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
