// F4 위젯: TimetableDayCol — 단일 요일 열 (그리드 라인 + 루틴 블록)
import 'package:flutter/material.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../shared/models/routine.dart';
import 'timetable_block.dart';
import 'timetable_overlap_layout.dart';

/// 단일 요일 열 (그리드 라인 + 루틴 블록)
class TimetableDayCol extends StatelessWidget {
  final List<Routine> routines;
  final int startHour;
  final double hh;
  final bool isZoomed;

  const TimetableDayCol({
    required this.routines,
    required this.startHour,
    required this.hh,
    required this.isZoomed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final overlapLayout = computeOverlapLayout(routines);

    return LayoutBuilder(
      builder: (context, constraints) {
        final colWidth = constraints.maxWidth;
        return Stack(
          children: [
            // 그리드 라인
            ...List.generate(
              TimelineLayout.timetableEndHour - TimelineLayout.timetableStartHour,
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
              final info =
                  overlapLayout[r.id] ?? const OverlapInfo(0, 1);
              final slotWidth = colWidth / info.totalCols;
              final blockLeft = info.colIndex * slotWidth + 1;
              final blockWidth = (slotWidth - 2).clamp(8.0, colWidth);
              return TimetableBlock(
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
