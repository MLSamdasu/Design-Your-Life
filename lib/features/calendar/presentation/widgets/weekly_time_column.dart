// F2 위젯: WeeklyTimeColumn - 시간 레이블 열 (SRP 분리)
// 왼쪽 고정 열로 24시간 눈금 텍스트를 표시한다.
import 'package:flutter/material.dart';

import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';
import 'weekly_view_constants.dart';

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
            top: hour * kWeeklyHourHeight - TimelineLayout.weeklyTimeLabelOffset,
            left: 0,
            right: AppSpacing.xs,
            child: Text(
              hour.toString().padLeft(2, '0'),
              // captionSm 토큰(10px)으로 fontSize 하드코딩 제거
              style: AppTypography.captionSm.copyWith(
                color: context.themeColors.textPrimaryWithAlpha(0.55),
              ),
              textAlign: TextAlign.right,
            ),
          );
        }),
      ),
    );
  }
}
