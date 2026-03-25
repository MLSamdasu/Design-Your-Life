// F2 위젯: DailyTimeLines - 일간 타임라인의 수평 시간 구분선
import 'package:flutter/material.dart';

import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/theme_colors.dart';

/// 수평 시간 구분선 (각 시간대마다 가로선을 그린다)
class DailyTimeLines extends StatelessWidget {
  /// 1시간당 픽셀 높이
  final double hourHeight;

  const DailyTimeLines({
    super.key,
    required this.hourHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(AppLayout.hoursInDay, (i) {
        return Container(
          height: hourHeight,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: context.themeColors.textPrimaryWithAlpha(0.16),
                width: AppLayout.borderThin,
              ),
            ),
          ),
        );
      }),
    );
  }
}
