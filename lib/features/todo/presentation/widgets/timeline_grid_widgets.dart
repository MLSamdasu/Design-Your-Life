// 타임라인 격자선 + 현재시간 표시 위젯
// daily_schedule_view.dart에서 분리된 배경 요소 위젯
import 'package:flutter/material.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import 'timeline_constants.dart';

/// 시간 격자선 (배경)
class HourGridLine extends StatelessWidget {
  final int hour;
  final bool isCurrentHour;

  const HourGridLine({
    super.key,
    required this.hour,
    required this.isCurrentHour,
  });

  @override
  Widget build(BuildContext context) {
    final top = hour * timelineHourHeight;
    return Positioned(
      top: top,
      left: 0,
      right: 0,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 시간 라벨
          SizedBox(
            width: timelineTimeColumnWidth,
            child: Text(
              '${hour.toString().padLeft(2, '0')}:00',
              style: AppTypography.captionMd.copyWith(
                color: isCurrentHour
                    ? context.themeColors.textPrimary
                    : context.themeColors.textPrimaryWithAlpha(0.4),
                fontWeight: isCurrentHour
                    ? AppTypography.weightSemiBold
                    : AppTypography.weightRegular,
              ),
            ),
          ),
          // 구분선
          Expanded(
            child: Container(
              height: AppLayout.dividerHeight,
              margin: const EdgeInsets.only(top: AppSpacing.sm),
              color: context.themeColors.textPrimaryWithAlpha(0.08),
            ),
          ),
        ],
      ),
    );
  }
}

/// 현재 시간 표시선 (빨간 점 + 수평선)
class CurrentTimeIndicator extends StatelessWidget {
  final DateTime now;

  const CurrentTimeIndicator({super.key, required this.now});

  @override
  Widget build(BuildContext context) {
    final minuteOffset = now.hour * 60 + now.minute;
    final top = minuteOffset * (timelineHourHeight / 60.0);

    return Positioned(
      top: top - TimelineLayout.timelineCurrentTimeOffset,
      left: timelineTimeColumnWidth,
      right: 0,
      child: Row(
        children: [
          Container(
            width: AppSpacing.sm,
            height: AppSpacing.sm,
            decoration: BoxDecoration(
              color: ColorTokens.error,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Container(
              height: AppLayout.lineHeightMedium,
              color: ColorTokens.error.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
