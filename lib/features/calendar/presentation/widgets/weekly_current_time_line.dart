// F2 위젯: WeeklyCurrentTimeLine - 현재 시간 빨간 가로선 (SRP 분리)
// 오늘 열에만 표시되며 현재 분까지 정밀하게 위치를 계산한다.
import 'package:flutter/material.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import 'weekly_view_constants.dart';

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
        height: AppLayout.lineHeightMedium,
        color: ColorTokens.error,
      ),
    );
  }
}
