// F2 위젯: WeeklyViewWidgets - 주간 뷰 공용 하위 위젯 (SRP 분리)
// weekly_view.dart에서 추출한다.
// 포함: WeeklyEventBlock, WeeklyCurrentTimeLine, WeeklyTimeColumn
import 'package:flutter/material.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../providers/event_provider.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';

// 1시간당 픽셀 높이 (WeeklyView와 동일 값 공유)
const double kWeeklyHourHeight = 56.0;

/// 이벤트 블록 위젯
/// 시작 시간과 지속 시간에 따라 Positioned로 배치된다
class WeeklyEventBlock extends StatelessWidget {
  final CalendarEvent event;

  const WeeklyEventBlock({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final startMin = (event.startHour ?? 0) * 60 + (event.startMinute ?? 0);
    final endMin = event.endHour != null
        ? event.endHour! * 60 + (event.endMinute ?? 0)
        : startMin + 60;
    final duration = endMin - startMin;

    final top = startMin * (kWeeklyHourHeight / 60);
    final height =
        (duration * kWeeklyHourHeight / 60).clamp(20.0, double.infinity);
    final eventColor = ColorTokens.eventColor(event.colorIndex);

    return Positioned(
      top: top,
      left: AppSpacing.xxs,
      right: AppSpacing.xxs,
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
        decoration: BoxDecoration(
          color: eventColor.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border(
            left: BorderSide(color: eventColor, width: 2),
          ),
        ),
        child: Text(
          event.title,
          // captionSm 토큰(10px)으로 fontSize 하드코딩 제거
          style: AppTypography.captionSm.copyWith(color: context.themeColors.textPrimary),
          maxLines: height > 30 ? 2 : 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

/// 현재 시간 빨간 가로선 위젯 (AC-CL-03)
/// 오늘 열에만 표시되며 현재 분까지 정밀하게 위치를 계산한다
class WeeklyCurrentTimeLine extends StatelessWidget {
  final DateTime now;

  const WeeklyCurrentTimeLine({super.key, required this.now});

  @override
  Widget build(BuildContext context) {
    final topOffset =
        now.hour * kWeeklyHourHeight + now.minute * (kWeeklyHourHeight / 60);
    return Positioned(
      top: topOffset,
      left: 0,
      right: 0,
      child: Container(
        height: 1.5,
        color: ColorTokens.error,
      ),
    );
  }
}

/// 시간 레이블 열 (00:00 ~ 23:00)
/// 왼쪽 고정 열로 24시간 눈금 텍스트를 표시한다
class WeeklyTimeColumn extends StatelessWidget {
  final double width;

  const WeeklyTimeColumn({super.key, required this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Stack(
        children: List.generate(AppLayout.hoursInDay, (hour) {
          return Positioned(
            top: hour * kWeeklyHourHeight - 7,
            left: 0,
            right: AppSpacing.xs,
            child: Text(
              hour.toString().padLeft(2, '0'),
              // captionSm 토큰(10px)으로 fontSize 하드코딩 제거
              style: AppTypography.captionSm.copyWith(
                color: context.themeColors.textPrimaryWithAlpha(0.40),
              ),
              textAlign: TextAlign.right,
            ),
          );
        }),
      ),
    );
  }
}
