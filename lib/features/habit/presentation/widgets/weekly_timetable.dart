// F4 위젯: WeeklyTimetable - 주간 시간표 그리드
// 요일(가로) × 시간(세로) 축으로 활성 루틴 블록을 시각화한다.
import 'package:flutter/material.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../shared/models/routine.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';

/// 주간 시간표 그리드 (05~23시, 요일별 루틴 블록 표시)
class WeeklyTimetable extends StatelessWidget {
  final List<Routine> routines;

  static const int _sh = AppLayout.timetableStartHour; // 시작 시간
  static const int _eh = AppLayout.timetableEndHour; // 종료 시간
  static const double _hh = 40.0; // 시간당 높이
  static const double _lw = 36.0; // 시간 레이블 너비
  static const double _cw = 44.0; // 요일 열 너비

  const WeeklyTimetable({required this.routines, super.key});

  @override
  Widget build(BuildContext context) {
    // 수평+수직 모두 스크롤 가능하도록 하여 작은 화면에서도 오버플로우 방지
    return LayoutBuilder(
      builder: (context, constraints) {
        final gridHeight = (_eh - _sh) * _hh;
        // 헤더(28) + 간격(4) + 그리드 영역을 합산한 전체 높이
        final totalHeight = 28.0 + 4.0 + gridHeight;
        // 사용 가능한 높이가 전체보다 작으면 스크롤 가능하게 제한한다
        final needsVerticalScroll = constraints.maxHeight.isFinite &&
            constraints.maxHeight < totalHeight;

        final content = SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: _lw + 7 * _cw,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DayHeader(labelWidth: _lw, colWidth: _cw),
                const SizedBox(height: AppSpacing.xs),
                SizedBox(
                  height: gridHeight,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TimeAxis(startHour: _sh, endHour: _eh, hh: _hh, width: _lw),
                      ...List.generate(AppLayout.daysInWeek, (i) {
                        final day = i + 1;
                        return _DayCol(
                          routines: routines.where((r) => r.repeatDays.contains(day)).toList(),
                          startHour: _sh,
                          hh: _hh,
                          width: _cw,
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );

        // 세로 공간이 부족하면 수직 스크롤도 지원한다
        if (needsVerticalScroll) {
          return SizedBox(
            height: constraints.maxHeight,
            child: SingleChildScrollView(child: content),
          );
        }

        return content;
      },
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
      children: [
        SizedBox(width: labelWidth),
        ...List.generate(AppLayout.daysInWeek, (i) {
          final isToday = i == todayIdx;
          return SizedBox(
            width: colWidth,
            child: Center(
              child: Container(
                width: 28,
                height: 28,
                // 오늘 날짜 표시 원: 배경 테마에 맞는 악센트 색상을 사용한다
                decoration: isToday
                    ? BoxDecoration(
                        color: context.themeColors.accentWithAlpha(0.7),
                        shape: BoxShape.circle)
                    : null,
                child: Center(
                  child: Text(
                    days[i],
                    // 요일 텍스트: 악센트 배경 위이므로 테마 인식 색상 사용
                    style: AppTypography.captionLg.copyWith(
                      color: isToday
                          ? context.themeColors.textPrimary
                          : i >= 5
                              ? context.themeColors.textPrimaryWithAlpha(0.5)
                              : context.themeColors.textPrimaryWithAlpha(0.7),
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
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
  const _TimeAxis({required this.startHour, required this.endHour,
      required this.hh, required this.width});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        child: Stack(
          children: List.generate(
            endHour - startHour,
            (i) => Positioned(
              top: i * hh - 7, left: 0, width: width,
              child: Text('${startHour + i}',
                style: AppTypography.captionSm
                    .copyWith(color: context.themeColors.textPrimaryWithAlpha(0.4)),
                textAlign: TextAlign.right),
            ),
          ),
        ),
      );
}

/// 단일 요일 열 (그리드 라인 + 루틴 블록)
class _DayCol extends StatelessWidget {
  final List<Routine> routines;
  final int startHour;
  final double hh;
  final double width;
  const _DayCol({required this.routines, required this.startHour,
      required this.hh, required this.width});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        child: Stack(
          children: [
            ...List.generate(18, (i) => Positioned(
                  top: i * hh, left: AppSpacing.xxs, right: AppSpacing.xxs,
                  child: Container(height: 1,
                      color: context.themeColors.textPrimaryWithAlpha(0.07)))),
            ...routines.map((r) => _Block(routine: r, startHour: startHour, hh: hh)),
          ],
        ),
      );
}

/// 루틴 블록 (시간표 내 배치 단위)
class _Block extends StatelessWidget {
  final Routine routine;
  final int startHour;
  final double hh;
  const _Block({required this.routine, required this.startHour, required this.hh});
  @override
  Widget build(BuildContext context) {
    final sm = routine.startTime.hour * 60 + routine.startTime.minute;
    final em = routine.endTime.hour * 60 + routine.endTime.minute;
    final dur = (em - sm).clamp(15, 1440).toDouble();
    final top = (sm - startHour * 60) / 60 * hh;
    final h = dur / 60 * hh;
    if (top + h <= 0) return const SizedBox.shrink();

    final color = ColorTokens.eventColor(routine.colorIndex);
    return Positioned(
      top: top.clamp(0.0, double.infinity),
      left: 3,
      right: 3,
      height: h.clamp(8.0, double.infinity),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: AppSpacing.xxs),
          child: h >= 20
              ? Text(
                  routine.name,
                  style: AppTypography.captionSm.copyWith(
                    color: context.themeColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      height: 1.2),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                )
              : null,
        ),
      ),
    );
  }
}
