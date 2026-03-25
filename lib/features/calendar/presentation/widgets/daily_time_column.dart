// F2 위젯: DailyTimeColumn - 일간 타임라인의 시간 레이블 열 (00:00 ~ 23:00)
import 'package:flutter/material.dart';

import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';

/// 시간 레이블 열 (00:00 ~ 23:00)
/// 왼쪽에 세로로 나열되어 각 시간대를 표시한다
class DailyTimeColumn extends StatelessWidget {
  /// 1시간당 픽셀 높이
  final double hourHeight;

  /// 시간 열 폭
  final double timeColumnWidth;

  const DailyTimeColumn({
    super.key,
    required this.hourHeight,
    required this.timeColumnWidth,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: timeColumnWidth,
      child: Stack(
        children: List.generate(AppLayout.hoursInDay, (hour) {
          return Positioned(
            top: hour * hourHeight - TimelineLayout.dailyTimeLabelOffset,
            left: 0,
            right: 0,
            child: Text(
              '${hour.toString().padLeft(2, '0')}:00',
              style: AppTypography.captionMd.copyWith(
                // WCAG: 시간 레이블 텍스트 알파 0.55 이상으로 가독성 보장
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
